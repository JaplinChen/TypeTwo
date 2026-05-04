part of 'hotkey_service.dart';

const int _vkAlt = 0x12;
const int _vkShift = 0x10;
const int _vkControl = 0x11;
const int _vkC = 0x43;
const int _vkV = 0x56;
const int _vkReturn = 0x0D;
const int _vkSpace = 0x20;
const int _vkTab = 0x09;
const int _vkEscape = 0x1B;
const int _vkBackspace = 0x08;
const int _vkDelete = 0x2E;
const int _vkInsert = 0x2D;
const int _vkHome = 0x24;
const int _vkEnd = 0x23;
const int _vkPageUp = 0x21;
const int _vkPageDown = 0x22;
const int _vkArrowUp = 0x26;
const int _vkArrowDown = 0x28;
const int _vkArrowLeft = 0x25;
const int _vkArrowRight = 0x27;
const int _inputKeyboard = 1;
const int _keyEventfKeyUp = 0x0002;
const int _clipboardOpenRetries = 10;
const Duration _clipboardRetryDelay = Duration(milliseconds: 20);

const _modifierMap = <String, HotKeyModifier>{
  'ctrl': HotKeyModifier.control,
  'alt': HotKeyModifier.alt,
  'shift': HotKeyModifier.shift,
  'meta': HotKeyModifier.meta,
};

const _keyMap = <String, PhysicalKeyboardKey>{
  'a': PhysicalKeyboardKey.keyA,
  'b': PhysicalKeyboardKey.keyB,
  'c': PhysicalKeyboardKey.keyC,
  'd': PhysicalKeyboardKey.keyD,
  'e': PhysicalKeyboardKey.keyE,
  'f': PhysicalKeyboardKey.keyF,
  'g': PhysicalKeyboardKey.keyG,
  'h': PhysicalKeyboardKey.keyH,
  'i': PhysicalKeyboardKey.keyI,
  'j': PhysicalKeyboardKey.keyJ,
  'k': PhysicalKeyboardKey.keyK,
  'l': PhysicalKeyboardKey.keyL,
  'm': PhysicalKeyboardKey.keyM,
  'n': PhysicalKeyboardKey.keyN,
  'o': PhysicalKeyboardKey.keyO,
  'p': PhysicalKeyboardKey.keyP,
  'q': PhysicalKeyboardKey.keyQ,
  'r': PhysicalKeyboardKey.keyR,
  's': PhysicalKeyboardKey.keyS,
  't': PhysicalKeyboardKey.keyT,
  'u': PhysicalKeyboardKey.keyU,
  'v': PhysicalKeyboardKey.keyV,
  'w': PhysicalKeyboardKey.keyW,
  'x': PhysicalKeyboardKey.keyX,
  'y': PhysicalKeyboardKey.keyY,
  'z': PhysicalKeyboardKey.keyZ,
  '0': PhysicalKeyboardKey.digit0,
  '1': PhysicalKeyboardKey.digit1,
  '2': PhysicalKeyboardKey.digit2,
  '3': PhysicalKeyboardKey.digit3,
  '4': PhysicalKeyboardKey.digit4,
  '5': PhysicalKeyboardKey.digit5,
  '6': PhysicalKeyboardKey.digit6,
  '7': PhysicalKeyboardKey.digit7,
  '8': PhysicalKeyboardKey.digit8,
  '9': PhysicalKeyboardKey.digit9,
  'f1': PhysicalKeyboardKey.f1,
  'f2': PhysicalKeyboardKey.f2,
  'f3': PhysicalKeyboardKey.f3,
  'f4': PhysicalKeyboardKey.f4,
  'f5': PhysicalKeyboardKey.f5,
  'f6': PhysicalKeyboardKey.f6,
  'f7': PhysicalKeyboardKey.f7,
  'f8': PhysicalKeyboardKey.f8,
  'f9': PhysicalKeyboardKey.f9,
  'f10': PhysicalKeyboardKey.f10,
  'f11': PhysicalKeyboardKey.f11,
  'f12': PhysicalKeyboardKey.f12,
  'enter': PhysicalKeyboardKey.enter,
  'space': PhysicalKeyboardKey.space,
  'tab': PhysicalKeyboardKey.tab,
  'escape': PhysicalKeyboardKey.escape,
  'backspace': PhysicalKeyboardKey.backspace,
  'delete': PhysicalKeyboardKey.delete,
  'insert': PhysicalKeyboardKey.insert,
  'home': PhysicalKeyboardKey.home,
  'end': PhysicalKeyboardKey.end,
  'pageup': PhysicalKeyboardKey.pageUp,
  'pagedown': PhysicalKeyboardKey.pageDown,
  'arrowup': PhysicalKeyboardKey.arrowUp,
  'arrowdown': PhysicalKeyboardKey.arrowDown,
  'arrowleft': PhysicalKeyboardKey.arrowLeft,
  'arrowright': PhysicalKeyboardKey.arrowRight,
  'minus': PhysicalKeyboardKey.minus,
  'equal': PhysicalKeyboardKey.equal,
  'comma': PhysicalKeyboardKey.comma,
  'period': PhysicalKeyboardKey.period,
  'slash': PhysicalKeyboardKey.slash,
  'semicolon': PhysicalKeyboardKey.semicolon,
  'quote': PhysicalKeyboardKey.quote,
  'backquote': PhysicalKeyboardKey.backquote,
  'backslash': PhysicalKeyboardKey.backslash,
  'bracketleft': PhysicalKeyboardKey.bracketLeft,
  'bracketright': PhysicalKeyboardKey.bracketRight,
};

const _vkMap = <String, int>{
  'a': 0x41, 'b': 0x42, 'c': 0x43, 'd': 0x44, 'e': 0x45,
  'f': 0x46, 'g': 0x47, 'h': 0x48, 'i': 0x49, 'j': 0x4A,
  'k': 0x4B, 'l': 0x4C, 'm': 0x4D, 'n': 0x4E, 'o': 0x4F,
  'p': 0x50, 'q': 0x51, 'r': 0x52, 's': 0x53, 't': 0x54,
  'u': 0x55, 'v': 0x56, 'w': 0x57, 'x': 0x58, 'y': 0x59, 'z': 0x5A,
  '0': 0x30, '1': 0x31, '2': 0x32, '3': 0x33, '4': 0x34,
  '5': 0x35, '6': 0x36, '7': 0x37, '8': 0x38, '9': 0x39,
  'f1': 0x70, 'f2': 0x71, 'f3': 0x72, 'f4': 0x73, 'f5': 0x74,
  'f6': 0x75, 'f7': 0x76, 'f8': 0x77, 'f9': 0x78, 'f10': 0x79,
  'f11': 0x7A, 'f12': 0x7B,
  'enter': _vkReturn, 'space': _vkSpace, 'tab': _vkTab,
  'escape': _vkEscape, 'backspace': _vkBackspace, 'delete': _vkDelete,
  'insert': _vkInsert, 'home': _vkHome, 'end': _vkEnd,
  'pageup': _vkPageUp, 'pagedown': _vkPageDown,
  'arrowup': _vkArrowUp, 'arrowdown': _vkArrowDown,
  'arrowleft': _vkArrowLeft, 'arrowright': _vkArrowRight,
  'minus': 0xBD, 'equal': 0xBB, 'comma': 0xBC, 'period': 0xBE,
  'slash': 0xBF, 'semicolon': 0xBA, 'quote': 0xDE, 'backquote': 0xC0,
  'backslash': 0xDC, 'bracketleft': 0xDB, 'bracketright': 0xDD,
};
