import logging
import subprocess
import sys
import threading
import time
from ctypes import wintypes
import ctypes

import pystray
import requests
from PIL import Image

from clipboard_hotkey import on_hotkey
import clipboard_hotkey
from config import BRIDGE_URL, base_dir, load_cfg, load_locale
from translate_engine import run_bridge, set_quit_handler

_TRAY_LABELS: dict[str, tuple[str, str, str]] = {
    "zh": ("開啟設定", "結束 TypeTwo", "找不到 TypeTwoUI.exe"),
    "en": ("Open Settings", "Quit TypeTwo", "TypeTwoUI.exe not found"),
    "vi": ("Mở cài đặt", "Thoát TypeTwo", "Không tìm thấy TypeTwoUI.exe"),
}

_WM_HOTKEY = 0x0312
_HOTKEY_ID = 1
_MOD_ALT = 0x0001
_MOD_CONTROL = 0x0002
_MOD_SHIFT = 0x0004
_MOD_WIN = 0x0008
_MOD_NOREPEAT = 0x4000
_BRIDGE_APP = "TypeTwo"
_BRIDGE_API_VERSION = 1
_ERROR_ALREADY_EXISTS = 183
_INSTANCE_MUTEX_NAME = "Local\\TypeTwo.SingleInstance"
_QUIT_EVENT_NAME = "Local\\TypeTwo.Quit"
_instance_mutex = None
_quit_event = None


def _create_quit_event():
    global _quit_event
    kernel32 = ctypes.windll.kernel32
    event = kernel32.CreateEventW(None, False, False, _QUIT_EVENT_NAME)
    if not event:
        raise ctypes.WinError()
    _quit_event = event


def _signal_running_instance_to_quit() -> bool:
    kernel32 = ctypes.windll.kernel32
    EVENT_MODIFY_STATE = 0x0002
    event = kernel32.OpenEventW(EVENT_MODIFY_STATE, False, _QUIT_EVENT_NAME)
    if not event:
        return False
    try:
        if not kernel32.SetEvent(event):
            raise ctypes.WinError()
        return True
    finally:
        kernel32.CloseHandle(event)


def _signal_running_instance_to_quit_via_bridge() -> bool:
    try:
        response = requests.post(f"{BRIDGE_URL}/quit", timeout=1)
        response.raise_for_status()
        data = response.json()
    except Exception:
        return False
    return bool(data.get("ok"))


def _request_process_quit():
    if _quit_event is None:
        return
    if not ctypes.windll.kernel32.SetEvent(_quit_event):
        raise ctypes.WinError()


def _open_settings(locale: str):
    base = base_dir()
    candidates = [
        base / "TypeTwoUI.exe",
        base / "../typetwo_flutter/build/windows/x64/runner/Release/typetwo.exe",
        base / "../typetwo_flutter/build/windows/x64/runner/Debug/typetwo.exe",
    ]
    for exe in candidates:
        if exe.exists():
            subprocess.Popen([str(exe.resolve())], creationflags=subprocess.CREATE_NO_WINDOW)
            return
    import ctypes
    _, _, not_found_msg = _TRAY_LABELS.get(locale, _TRAY_LABELS["zh"])
    ctypes.windll.user32.MessageBoxW(0, not_found_msg, "TypeTwo", 0x40)


def _run_tray(locale: str):
    icon_path = base_dir() / "tray_icon.ico"
    img = Image.open(icon_path) if icon_path.exists() else Image.new("RGB", (64, 64), color=(30, 120, 200))
    open_label, quit_label, _ = _TRAY_LABELS.get(locale, _TRAY_LABELS["zh"])
    icon = pystray.Icon("TypeTwo", img, "TypeTwo")
    menu = pystray.Menu(
        pystray.MenuItem(open_label, lambda icon, item: _open_settings(locale)),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem(quit_label, lambda icon, item: icon.stop()),
    )
    icon.menu = menu

    if _quit_event is not None:
        def _watch_quit_event():
            wait_result = ctypes.windll.kernel32.WaitForSingleObject(_quit_event, 0xFFFFFFFF)
            if wait_result == 0:
                icon.stop()

        threading.Thread(target=_watch_quit_event, daemon=True).start()

    icon.run()


def _msgbox(msg: str):
    ctypes.windll.user32.MessageBoxW(0, msg, "TypeTwo", 0x40)


def _acquire_single_instance() -> bool:
    global _instance_mutex
    kernel32 = ctypes.windll.kernel32
    kernel32.SetLastError(0)
    mutex = kernel32.CreateMutexW(None, False, _INSTANCE_MUTEX_NAME)
    if not mutex:
        raise ctypes.WinError()
    if kernel32.GetLastError() == _ERROR_ALREADY_EXISTS:
        kernel32.CloseHandle(mutex)
        return False
    _instance_mutex = mutex
    return True


def _hotkey_modifier_flags(modifiers: list[str]) -> int:
    flags = 0
    for modifier in modifiers:
        key = modifier.strip().lower()
        if key == "ctrl":
            flags |= _MOD_CONTROL
        elif key == "alt":
            flags |= _MOD_ALT
        elif key == "shift":
            flags |= _MOD_SHIFT
        elif key == "meta":
            flags |= _MOD_WIN
    return flags


def _keyboard_loop():
    cfg = load_cfg()
    modifiers = cfg.get("hotkeyModifiers", ["ctrl", "alt"])
    key = cfg.get("hotkeyKey", "t")
    hotkey = "+".join(modifiers + [key])
    clipboard_hotkey.active_hotkey = "+".join(m.capitalize() for m in modifiers) + "+" + key.capitalize()
    vk = clipboard_hotkey.hotkey_key_to_vk(key) or clipboard_hotkey._VK_RETURN
    clipboard_hotkey.active_hotkey_vk = vk
    mod_flags = _hotkey_modifier_flags(modifiers) | _MOD_NOREPEAT

    user32 = ctypes.windll.user32
    if not user32.RegisterHotKey(None, _HOTKEY_ID, mod_flags, vk):
        raise OSError(f"RegisterHotKey failed for {hotkey}")

    msg = wintypes.MSG()
    try:
        while user32.GetMessageW(ctypes.byref(msg), None, 0, 0) != 0:
            if msg.message == _WM_HOTKEY and msg.wParam == _HOTKEY_ID:
                threading.Thread(target=on_hotkey, daemon=True).start()
            user32.TranslateMessage(ctypes.byref(msg))
            user32.DispatchMessageW(ctypes.byref(msg))
    finally:
        user32.UnregisterHotKey(None, _HOTKEY_ID)


def _hotkey_thread_main():
    try:
        _keyboard_loop()
    except Exception:
        logging.exception("Hotkey loop terminated unexpectedly")
        raise


def _bridge_health_ok() -> bool:
    try:
        response = requests.get(f"{BRIDGE_URL}/health", timeout=0.5)
        response.raise_for_status()
        data = response.json()
        api_version = int(data.get("apiVersion", 0))
    except Exception:
        return False
    return (
        bool(data.get("ok"))
        and data.get("app") == _BRIDGE_APP
        and api_version == _BRIDGE_API_VERSION
        and "/translate" in (data.get("routes") or [])
    )


def main():
    logging.basicConfig(
        filename=base_dir() / "typetwo.log",
        level=logging.DEBUG,
        format="%(asctime)s %(message)s",
        encoding="utf-8",
    )

    if "--quit" in sys.argv[1:]:
        if _signal_running_instance_to_quit() or _signal_running_instance_to_quit_via_bridge():
            logging.info("Sent quit signal to existing TypeTwo instance")
            return
        logging.info("No running TypeTwo instance responded to quit signal")
        return

    if not _acquire_single_instance():
        logging.info("TypeTwo is already running; skipping duplicate startup")
        return

    _create_quit_event()
    set_quit_handler(_request_process_quit)

    locale = load_locale()

    bridge_thread = threading.Thread(target=run_bridge, daemon=True)
    bridge_thread.start()

    bridge_ready = False
    for _ in range(20):
        if _bridge_health_ok():
            bridge_ready = True
            break
        time.sleep(0.5)

    if bridge_ready:
        threading.Thread(target=_hotkey_thread_main, daemon=True).start()
    else:
        logging.error("Bridge health check failed or port 8765 is occupied by another service")
        _msgbox(
            "TypeTwo bridge 啟動失敗，或 127.0.0.1:8765 已被其他程式占用。\n\n"
            "請先完全關閉舊版 TypeTwo / translator_bridge，或檢查是否有其他本機服務使用 8765，再重新啟動 TypeTwo。"
        )
    _run_tray(locale)


if __name__ == "__main__":
    main()
