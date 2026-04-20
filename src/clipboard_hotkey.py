import ctypes
import logging
import threading
import time

import requests
import win32clipboard
import win32con

from config import BRIDGE_URL, load_cfg

_VK_CONTROL = 0x11
_VK_MENU    = 0x12  # Alt
_VK_SHIFT   = 0x10
_VK_C       = 0x43
_VK_V       = 0x56
_KEYEVENTF_KEYUP = 0x0002
_CLIPBOARD_DELAY = 0.3

_lock = threading.Lock()
active_hotkey = "Ctrl+Alt+Enter"  # updated at startup from config


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
    allowed = load_cfg().get("allowedProcesses", [])
    if not allowed:
        return True
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
            except Exception:
                pass
            fmt = win32clipboard.EnumClipboardFormats(fmt)
    except Exception:
        pass
    finally:
        try:
            win32clipboard.CloseClipboard()
        except Exception:
            pass
    return saved


def _clip_restore(saved: dict):
    try:
        win32clipboard.OpenClipboard()
        win32clipboard.EmptyClipboard()
        for fmt, data in saved.items():
            try:
                win32clipboard.SetClipboardData(fmt, data)
            except Exception:
                pass
    except Exception:
        pass
    finally:
        try:
            win32clipboard.CloseClipboard()
        except Exception:
            pass


def _clip_get_text() -> str:
    try:
        win32clipboard.OpenClipboard()
        if win32clipboard.IsClipboardFormatAvailable(win32con.CF_UNICODETEXT):
            return win32clipboard.GetClipboardData(win32con.CF_UNICODETEXT)
        return ""
    finally:
        win32clipboard.CloseClipboard()


def _clip_set_text(text: str):
    try:
        win32clipboard.OpenClipboard()
        win32clipboard.EmptyClipboard()
        win32clipboard.SetClipboardText(text, win32con.CF_UNICODETEXT)
    except Exception:
        pass
    finally:
        try:
            win32clipboard.CloseClipboard()
        except Exception:
            pass


# ── Hotkey handler ────────────────────────────────────────────────────────────

def on_hotkey():
    global active_hotkey
    if not _lock.acquire(blocking=False):
        return

    try:
        time.sleep(0.1)  # let modifier keys settle after hotkey fires
        logging.debug("HOTKEY fired")

        if not is_allowed():
            logging.debug("HOTKEY blocked: process not allowed (%s)", _foreground_process())
            _msgbox("目前視窗未在允許的 App 清單內。")
            return

        saved = _clip_save()
        try:
            win32clipboard.OpenClipboard()
            win32clipboard.EmptyClipboard()
            win32clipboard.CloseClipboard()
        except Exception:
            pass

        _ctrl_c()
        time.sleep(_CLIPBOARD_DELAY)

        text = _clip_get_text().strip()
        logging.debug("CLIPBOARD text=%r", text[:80] if text else "")
        if not text:
            _clip_restore(saved)
            _msgbox(f"請先選取要翻譯的文字，再按 {active_hotkey}。")
            return

        try:
            r = requests.post(
                f"{BRIDGE_URL}/translate",
                json={"text": text},
                timeout=60,
            )
            if r.status_code != 200:
                raise RuntimeError(f"HTTP {r.status_code}: {r.text[:200]}")
            output = r.text
            if not output:
                raise RuntimeError("empty response")
            _clip_set_text(output)
            _ctrl_v()
            time.sleep(_CLIPBOARD_DELAY)
        except Exception as e:
            _msgbox(f"翻譯失敗。請確認 provider 設定是否正確。\n\n錯誤：{e}")
        finally:
            time.sleep(_CLIPBOARD_DELAY)
            _clip_restore(saved)
    finally:
        _lock.release()
