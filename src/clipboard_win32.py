import ctypes
import logging
import time

import win32clipboard
import win32con

PASTE_SETTLE   = 0.10   # wait after Ctrl+V before restoring clipboard
RESTORE_SETTLE = 0.05   # final buffer before clipboard restore


def clip_save() -> dict:
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


def clip_restore(saved: dict):
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


def clip_get_text() -> str:
    try:
        win32clipboard.OpenClipboard()
        if win32clipboard.IsClipboardFormatAvailable(win32con.CF_UNICODETEXT):
            return win32clipboard.GetClipboardData(win32con.CF_UNICODETEXT)
        return ""
    finally:
        win32clipboard.CloseClipboard()


def clip_seq() -> int:
    return ctypes.windll.user32.GetClipboardSequenceNumber()


def poll_clipboard_text(seq_before: int, timeout: float = 0.5, interval: float = 0.02) -> str:
    """Detect seq change, then wait 40ms for all clipboard formats to be written."""
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if clip_seq() != seq_before:
            time.sleep(0.04)  # browser writes CF_HTML first, CF_UNICODETEXT shortly after
            return clip_get_text()
        time.sleep(interval)
    logging.warning("poll_clipboard_text: timeout (seq_before=%d, seq_now=%d)", seq_before, clip_seq())
    return ""


def clip_set_text(text: str) -> bool:
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
