import logging
import subprocess
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
from translate_engine import run_bridge

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
    menu = pystray.Menu(
        pystray.MenuItem(open_label, lambda icon, item: _open_settings(locale)),
        pystray.Menu.SEPARATOR,
        pystray.MenuItem(quit_label, lambda icon, item: icon.stop()),
    )
    pystray.Icon("TypeTwo", img, "TypeTwo", menu).run()


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
    key = cfg.get("hotkeyKey", "enter")
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


def main():
    logging.basicConfig(
        filename=base_dir() / "typetwo.log",
        level=logging.DEBUG,
        format="%(asctime)s %(message)s",
        encoding="utf-8",
    )

    locale = load_locale()

    threading.Thread(target=run_bridge, daemon=True).start()

    for _ in range(20):
        try:
            requests.get(f"{BRIDGE_URL}/health", timeout=0.5)
            break
        except Exception:
            time.sleep(0.5)

    threading.Thread(target=_hotkey_thread_main, daemon=True).start()
    _run_tray(locale)


if __name__ == "__main__":
    main()
