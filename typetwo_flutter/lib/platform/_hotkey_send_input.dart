part of 'hotkey_service.dart';

void _sendKeyUp(int vk) {
  final input = calloc<INPUT>(1);
  try {
    input[0].type = _inputKeyboard;
    input[0].ki.wVk = vk;
    input[0].ki.dwFlags = _keyEventfKeyUp;
    SendInput(1, input, sizeOf<INPUT>());
  } finally {
    calloc.free(input);
  }
}

void _sendCtrl(int vk) {
  final inputs = calloc<INPUT>(4);
  try {
    inputs[0].type = _inputKeyboard;
    inputs[0].ki.wVk = _vkControl;
    inputs[0].ki.dwFlags = 0;
    inputs[1].type = _inputKeyboard;
    inputs[1].ki.wVk = vk;
    inputs[1].ki.dwFlags = 0;
    inputs[2].type = _inputKeyboard;
    inputs[2].ki.wVk = vk;
    inputs[2].ki.dwFlags = _keyEventfKeyUp;
    inputs[3].type = _inputKeyboard;
    inputs[3].ki.wVk = _vkControl;
    inputs[3].ki.dwFlags = _keyEventfKeyUp;
    SendInput(4, inputs, sizeOf<INPUT>());
  } finally {
    calloc.free(inputs);
  }
}

void _clearClipboard() {
  final hwnd = GetForegroundWindow();
  for (int i = 0; i < _clipboardOpenRetries; i++) {
    if (OpenClipboard(hwnd) != 0) {
      try {
        EmptyClipboard();
        return;
      } finally {
        CloseClipboard();
      }
    }
    sleep(_clipboardRetryDelay);
  }
}

Future<String> _pollClipboardText(int seqBefore) async {
  final deadline = DateTime.now().add(const Duration(milliseconds: 900));
  while (DateTime.now().isBefore(deadline)) {
    if (GetClipboardSequenceNumber() != seqBefore) {
      await Future.delayed(const Duration(milliseconds: 40));
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text ?? '';
    }
    await Future.delayed(const Duration(milliseconds: 20));
  }
  return '';
}

Future<void> _waitHotkeyReleased(List<String> mods, String key) async {
  final shouldWaitCtrl = mods.contains('ctrl');
  final shouldWaitAlt = mods.contains('alt');
  final shouldWaitShift = mods.contains('shift');
  final hotkeyVk = _vkMap[key];
  final deadline = DateTime.now().add(const Duration(seconds: 1));
  while (DateTime.now().isBefore(deadline)) {
    final ctrlDown =
        shouldWaitCtrl && (GetAsyncKeyState(_vkControl) & 0x8000) != 0;
    final altDown =
        shouldWaitAlt && (GetAsyncKeyState(_vkAlt) & 0x8000) != 0;
    final shiftDown =
        shouldWaitShift && (GetAsyncKeyState(_vkShift) & 0x8000) != 0;
    final hotkeyDown =
        hotkeyVk != null && (GetAsyncKeyState(hotkeyVk) & 0x8000) != 0;
    if (!ctrlDown && !altDown && !shiftDown && !hotkeyDown) return;
    await Future.delayed(const Duration(milliseconds: 10));
  }
  if (hotkeyVk != null) _sendKeyUp(hotkeyVk);
  if (shouldWaitAlt) _sendKeyUp(_vkAlt);
  if (shouldWaitShift) _sendKeyUp(_vkShift);
  if (shouldWaitCtrl) _sendKeyUp(_vkControl);
  await Future.delayed(const Duration(milliseconds: 50));
}

void _msgBox(String msg) {
  using((arena) {
    MessageBox(
      NULL,
      msg.toNativeUtf16(allocator: arena),
      'TypeTwo'.toNativeUtf16(allocator: arena),
      MB_ICONASTERISK,
    );
  });
}
