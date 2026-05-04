import ctypes
import time

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


def ctrl_c():
    _release_modifiers()
    time.sleep(0.05)
    _keybd(_VK_CONTROL); _keybd(_VK_C)
    _keybd(_VK_C, up=True); _keybd(_VK_CONTROL, up=True)


def ctrl_v():
    _release_modifiers()
    time.sleep(0.05)
    _keybd(_VK_CONTROL); _keybd(_VK_V)
    _keybd(_VK_V, up=True); _keybd(_VK_CONTROL, up=True)
