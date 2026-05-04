import ctypes
import logging
import threading
import time

import requests
import win32clipboard

from config import BRIDGE_URL, load_cfg, load_locale, retry_after_seconds
from hotkey_input import (
    _VK_CONTROL, _VK_MENU, _VK_SHIFT, _VK_T,
    _keybd, _release_modifiers, hotkey_key_to_vk, ctrl_c, ctrl_v,
)
from clipboard_win32 import (
    PASTE_SETTLE, RESTORE_SETTLE,
    clip_save, clip_restore, clip_seq, poll_clipboard_text, clip_set_text,
)

_lock = threading.Lock()
active_hotkey = "Ctrl+Alt+T"  # updated at startup from config
active_hotkey_vk = _VK_T

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


# ── Error classification ──────────────────────────────────────────────────────

def _classify_error(exc: Exception) -> str:
    status = None
    retry_after = None
    if isinstance(exc, requests.HTTPError) and exc.response is not None:
        status = exc.response.status_code
        retry_after = exc.response.headers.get("Retry-After")
    if status == 429:
        seconds = retry_after_seconds(retry_after)
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
    if status is not None and 500 <= status < 600:
        return _msg("service_unavailable")
    if isinstance(exc, requests.ConnectionError):
        return _msg("connection_failed")
    return _msg("check_settings")


def _error_detail(exc: Exception) -> str:
    if isinstance(exc, requests.HTTPError) and exc.response is not None:
        body = (exc.response.text or "").strip()
        if body:
            return body
    return str(exc)


# ── Hotkey handler ────────────────────────────────────────────────────────────

def _wait_hotkey_released(timeout: float = 1.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        ctrl  = ctypes.windll.user32.GetAsyncKeyState(_VK_CONTROL) & 0x8000
        alt   = ctypes.windll.user32.GetAsyncKeyState(_VK_MENU)    & 0x8000
        shift = ctypes.windll.user32.GetAsyncKeyState(_VK_SHIFT)   & 0x8000
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

        saved = clip_save()
        try:
            win32clipboard.OpenClipboard()
            win32clipboard.EmptyClipboard()
            win32clipboard.CloseClipboard()
        except Exception as e:
            logging.warning("EmptyClipboard failed: %s", e)

        seq_before = clip_seq()
        logging.debug("seq_before=%d", seq_before)
        ctrl_c()
        text = poll_clipboard_text(seq_before).strip()
        logging.debug("seq_after=%d text=%r", clip_seq(), text[:80] if text else "")
        if not text:
            clip_restore(saved)
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
            if not clip_set_text(output):
                _msgbox(_msg("paste_failed"))
                return
            ctrl_v()
            time.sleep(PASTE_SETTLE)
        except Exception as e:
            hint = _classify_error(e)
            _msgbox(_msg("translate_failed").format(hint=hint, e=_error_detail(e)))
        finally:
            time.sleep(RESTORE_SETTLE)
            clip_restore(saved)
    finally:
        _lock.release()
