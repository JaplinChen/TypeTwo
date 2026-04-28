import ctypes
import logging
import threading
import time
from email.utils import parsedate_to_datetime

import requests
import win32clipboard
import win32con

from config import BRIDGE_URL, load_cfg, load_locale

_VK_CONTROL = 0x11
_VK_MENU    = 0x12  # Alt
_VK_SHIFT   = 0x10
_VK_C       = 0x43
_VK_T       = 0x54
_VK_V       = 0x56
_VK_RETURN  = 0x0D
_VK_SPACE   = 0x20
_VK_TAB     = 0x09
_VK_ESCAPE  = 0x1B
_VK_BACK    = 0x08
_VK_DELETE  = 0x2E
_VK_INSERT  = 0x2D
_VK_HOME    = 0x24
_VK_END     = 0x23
_VK_PRIOR   = 0x21
_VK_NEXT    = 0x22
_VK_UP      = 0x26
_VK_DOWN    = 0x28
_VK_LEFT    = 0x25
_VK_RIGHT   = 0x27
_KEYEVENTF_KEYUP = 0x0002

_PASTE_SETTLE   = 0.10   # wait after Ctrl+V before restoring clipboard
_RESTORE_SETTLE = 0.05   # final buffer before clipboard restore

_lock = threading.Lock()
active_hotkey = "Ctrl+Alt+T"  # updated at startup from config
active_hotkey_vk = _VK_T

_SPECIAL_KEY_VKS = {
    "enter": _VK_RETURN,
    "space": _VK_SPACE,
    "tab": _VK_TAB,
    "escape": _VK_ESCAPE,
    "backspace": _VK_BACK,
    "delete": _VK_DELETE,
    "insert": _VK_INSERT,
    "home": _VK_HOME,
    "end": _VK_END,
    "pageup": _VK_PRIOR,
    "pagedown": _VK_NEXT,
    "arrowup": _VK_UP,
    "arrowdown": _VK_DOWN,
    "arrowleft": _VK_LEFT,
    "arrowright": _VK_RIGHT,
    "minus": 0xBD,
    "equal": 0xBB,
    "comma": 0xBC,
    "period": 0xBE,
    "slash": 0xBF,
    "semicolon": 0xBA,
    "quote": 0xDE,
    "backquote": 0xC0,
    "backslash": 0xDC,
    "bracketleft": 0xDB,
    "bracketright": 0xDD,
}

# ── Locale strings ────────────────────────────────────────────────────────────

_MSGS: dict[str, dict[str, str]] = {
    "zh": {
        "no_selection":        "請先選取要翻譯的文字，再按 {hotkey}。",
        "not_allowed":         "目前視窗未在允許的 App 清單內。",
        "translate_failed":    "翻譯失敗。{hint}\n\n錯誤：{e}",
        "service_unavailable": "AI 服務暫時不可用（伺服器端問題），請稍後重試。",
        "quota_exceeded":      "已超過 API 請求限額，請稍後重試。",
        "invalid_api_key":     "API Key 錯誤，請至設定確認。",
        "connection_failed":   "無法連線，請確認 AI 服務（Ollama 等）是否正在執行。",
        "check_settings":      "請確認 provider 設定是否正確。",
        "paste_failed":        "翻譯已完成，但無法寫入剪貼簿，請手動複製。",
    },
    "en": {
        "no_selection":        "Please select text first, then press {hotkey}.",
        "not_allowed":         "Current window is not in the allowed app list.",
        "translate_failed":    "Translation failed. {hint}\n\nError: {e}",
        "service_unavailable": "AI service is temporarily unavailable. Please try again later.",
        "quota_exceeded":      "API quota exceeded. Please try again later.",
        "invalid_api_key":     "Invalid API key. Please check settings.",
        "connection_failed":   "Cannot connect. Make sure the AI service (Ollama etc.) is running.",
        "check_settings":      "Please check your provider settings.",
        "paste_failed":        "Translation done, but failed to write to clipboard. Please copy manually.",
    },
    "vi": {
        "no_selection":        "Vui lòng chọn văn bản trước, rồi nhấn {hotkey}.",
        "not_allowed":         "Cửa sổ hiện tại không có trong danh sách ứng dụng được phép.",
        "translate_failed":    "Dịch thất bại. {hint}\n\nLỗi: {e}",
        "service_unavailable": "Dịch vụ AI tạm thời không khả dụng. Vui lòng thử lại sau.",
        "quota_exceeded":      "Đã vượt quá hạn mức API. Vui lòng thử lại sau.",
        "invalid_api_key":     "API Key không hợp lệ. Vui lòng kiểm tra cài đặt.",
        "connection_failed":   "Không thể kết nối. Hãy đảm bảo dịch vụ AI (Ollama, v.v.) đang chạy.",
        "check_settings":      "Vui lòng kiểm tra cài đặt provider.",
        "paste_failed":        "Dịch xong nhưng không ghi được vào clipboard. Vui lòng sao chép thủ công.",
    },
}

def _msg(key: str) -> str:
    locale = load_locale()
    return _MSGS.get(locale, _MSGS["zh"])[key]


# ── Process filter ────────────────────────────────────────────────────────────

def _foreground_process() -> str:
    hwnd = ctypes.windll.user32.GetForegroundWindow()
    pid = ctypes.c_ulong()
    ctypes.windll.user32.GetWindowThreadProcessId(hwnd, ctypes.byref(pid))
    h = ctypes.windll.kernel32.OpenProcess(0x1000, False, pid.value)
    if not h:
        return ""
    buf = ctypes.create_unicode_buffer(260)
    size = ctypes.c_ulong(260)
    ctypes.windll.kernel32.QueryFullProcessImageNameW(h, 0, buf, ctypes.byref(size))
    ctypes.windll.kernel32.CloseHandle(h)
    from pathlib import Path
    return Path(buf.value).name if buf.value else ""


def is_allowed() -> bool:
    cfg = load_cfg()
    restrict = cfg.get("restrictToAllowedProcesses")
    allowed = cfg.get("allowedProcesses", [])
    if restrict is None:
        restrict = bool(allowed)
    if not restrict:
        return True
    if not allowed:
        return False
    proc = _foreground_process().lower()
    return any(proc == a.lower() for a in allowed)


# ── Win32 helpers ─────────────────────────────────────────────────────────────

def _msgbox(msg: str):
    ctypes.windll.user32.MessageBoxW(0, msg, "TypeTwo", 0x40)


def _keybd(vk: int, up: bool = False):
    ctypes.windll.user32.keybd_event(vk, 0, _KEYEVENTF_KEYUP if up else 0, 0)


def _release_modifiers():
    for vk in (_VK_CONTROL, _VK_MENU, _VK_SHIFT):
        _keybd(vk, up=True)


def hotkey_key_to_vk(key_name: str) -> int | None:
    key = key_name.strip().lower()
    if len(key) == 1:
        code = ctypes.windll.user32.VkKeyScanW(ord(key.upper()))
        vk = code & 0xFF
        return None if vk == 0xFF else vk
    if key.startswith("f") and key[1:].isdigit():
        fn = int(key[1:])
        if 1 <= fn <= 24:
            return 0x6F + fn
    return _SPECIAL_KEY_VKS.get(key)


def _ctrl_c():
    _release_modifiers()
    time.sleep(0.05)
    _keybd(_VK_CONTROL); _keybd(_VK_C)
    _keybd(_VK_C, up=True); _keybd(_VK_CONTROL, up=True)


def _ctrl_v():
    _release_modifiers()
    time.sleep(0.05)
    _keybd(_VK_CONTROL); _keybd(_VK_V)
    _keybd(_VK_V, up=True); _keybd(_VK_CONTROL, up=True)


# ── Clipboard helpers ─────────────────────────────────────────────────────────

def _clip_save() -> dict:
    saved = {}
    try:
        win32clipboard.OpenClipboard()
        fmt = win32clipboard.EnumClipboardFormats(0)
        while fmt:
            try:
                saved[fmt] = win32clipboard.GetClipboardData(fmt)
            except Exception as e:
                logging.debug("clip_save: skipped fmt %d: %s", fmt, e)
            fmt = win32clipboard.EnumClipboardFormats(fmt)
    except Exception as e:
        logging.warning("clip_save: OpenClipboard failed: %s", e)
    finally:
        try:
            win32clipboard.CloseClipboard()
        except Exception as e:
            logging.debug("clip_save: CloseClipboard failed: %s", e)
    return saved


def _clip_restore(saved: dict):
    try:
        win32clipboard.OpenClipboard()
        win32clipboard.EmptyClipboard()
        for fmt, data in saved.items():
            try:
                win32clipboard.SetClipboardData(fmt, data)
            except Exception as e:
                logging.debug("clip_restore: skipped fmt %d: %s", fmt, e)
    except Exception as e:
        logging.warning("clip_restore: OpenClipboard failed: %s", e)
    finally:
        try:
            win32clipboard.CloseClipboard()
        except Exception as e:
            logging.debug("clip_restore: CloseClipboard failed: %s", e)


def _clip_get_text() -> str:
    try:
        win32clipboard.OpenClipboard()
        if win32clipboard.IsClipboardFormatAvailable(win32con.CF_UNICODETEXT):
            return win32clipboard.GetClipboardData(win32con.CF_UNICODETEXT)
        return ""
    finally:
        win32clipboard.CloseClipboard()


def _clip_seq() -> int:
    return ctypes.windll.user32.GetClipboardSequenceNumber()


def _poll_clipboard_text(seq_before: int, timeout: float = 0.5, interval: float = 0.02) -> str:
    """Detect seq change, then wait 40ms for all clipboard formats to be written."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if _clip_seq() != seq_before:
            time.sleep(0.04)  # browser writes CF_HTML first, CF_UNICODETEXT shortly after
            return _clip_get_text()
        time.sleep(interval)
    logging.warning("poll_clipboard_text: timeout (seq_before=%d, seq_now=%d)", seq_before, _clip_seq())
    return ""


def _clip_set_text(text: str) -> bool:
    try:
        win32clipboard.OpenClipboard()
        win32clipboard.EmptyClipboard()
        win32clipboard.SetClipboardText(text, win32con.CF_UNICODETEXT)
        return True
    except Exception as e:
        logging.warning("clip_set_text failed: %s", e)
        return False
    finally:
        try:
            win32clipboard.CloseClipboard()
        except Exception:
            pass


# ── Error classification ──────────────────────────────────────────────────────

def _classify_error(exc: Exception) -> str:
    status = None
    retry_after = None
    if isinstance(exc, requests.HTTPError) and exc.response is not None:
        status = exc.response.status_code
        retry_after = exc.response.headers.get("Retry-After")
    if status == 503:
        return _msg("service_unavailable")
    if status == 429:
        seconds = _retry_after_seconds(retry_after)
        if seconds:
            locale = load_locale()
            if locale == "en":
                return f"API quota exceeded. Please retry in about {seconds} seconds."
            if locale == "vi":
                return f"Đã vượt quá hạn mức API. Vui lòng thử lại sau khoảng {seconds} giây."
            return f"已超過 API 請求限額，請約 {seconds} 秒後重試。"
        return _msg("quota_exceeded")
    if status in (401, 403):
        return _msg("invalid_api_key")
    if isinstance(exc, requests.ConnectionError):
        return _msg("connection_failed")
    return _msg("check_settings")


def _error_detail(exc: Exception) -> str:
    if isinstance(exc, requests.HTTPError) and exc.response is not None:
        body = (exc.response.text or "").strip()
        if body:
            return body
    return str(exc)


def _retry_after_seconds(value: str | None) -> int | None:
    if not value:
        return None
    try:
        return max(0, int(float(value)))
    except ValueError:
        pass
    try:
        retry_at = parsedate_to_datetime(value)
    except (TypeError, ValueError, IndexError):
        return None
    delta = retry_at.timestamp() - time.time()
    return max(0, int(delta))


# ── Hotkey handler ────────────────────────────────────────────────────────────

def _wait_hotkey_released(timeout: float = 1.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ctrl = ctypes.windll.user32.GetAsyncKeyState(_VK_CONTROL) & 0x8000
        alt  = ctypes.windll.user32.GetAsyncKeyState(_VK_MENU)    & 0x8000
        shift = ctypes.windll.user32.GetAsyncKeyState(_VK_SHIFT)  & 0x8000
        hotkey = active_hotkey_vk and (ctypes.windll.user32.GetAsyncKeyState(active_hotkey_vk) & 0x8000)
        if not ctrl and not alt and not shift and not hotkey:
            return
        time.sleep(0.01)
    if active_hotkey_vk:
        _keybd(active_hotkey_vk, up=True)
    _release_modifiers()
    time.sleep(0.05)


def on_hotkey():
    global active_hotkey
    if not _lock.acquire(blocking=False):
        return

    try:
        _wait_hotkey_released()
        logging.debug("HOTKEY fired")

        if not is_allowed():
            logging.debug("HOTKEY ignored: process not allowed (%s)", _foreground_process())
            return

        saved = _clip_save()
        try:
            win32clipboard.OpenClipboard()
            win32clipboard.EmptyClipboard()
            win32clipboard.CloseClipboard()
        except Exception as e:
            logging.warning("EmptyClipboard failed: %s", e)

        seq_before = _clip_seq()
        logging.debug("seq_before=%d", seq_before)
        _ctrl_c()
        text = _poll_clipboard_text(seq_before).strip()
        logging.debug("seq_after=%d text=%r", _clip_seq(), text[:80] if text else "")
        if not text:
            _clip_restore(saved)
            _msgbox(_msg("no_selection").format(hotkey=active_hotkey))
            return

        try:
            r = requests.post(
                f"{BRIDGE_URL}/translate",
                json={"text": text},
                timeout=60,
            )
            r.raise_for_status()
            output = r.text
            if not output:
                raise RuntimeError("empty response")
            if not _clip_set_text(output):
                _msgbox(_msg("paste_failed"))
                return
            _ctrl_v()
            time.sleep(_PASTE_SETTLE)
        except Exception as e:
            hint = _classify_error(e)
            _msgbox(_msg("translate_failed").format(hint=hint, e=_error_detail(e)))
        finally:
            time.sleep(_RESTORE_SETTLE)
            _clip_restore(saved)
    finally:
        _lock.release()
