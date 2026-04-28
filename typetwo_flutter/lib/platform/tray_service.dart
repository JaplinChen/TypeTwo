import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._();
  factory TrayService() => _instance;
  TrayService._();

  static const _labels = <String, (String, String)>{
    'zh': ('顯示 TypeTwo', '退出'),
    'en': ('Show TypeTwo', 'Quit'),
    'vi': ('Hiển thị TypeTwo', 'Thoát'),
  };

  Future<void> init(String locale) async {
    if (!Platform.isWindows) return;
    trayManager.addListener(this);
    await trayManager.setIcon('assets/tray_icon.ico');
    await _rebuildMenu(locale);
  }

  Future<void> updateLocale(String locale) async {
    if (!Platform.isWindows) return;
    await _rebuildMenu(locale);
  }

  Future<void> _rebuildMenu(String locale) async {
    final (show, quit) = _labels[locale] ?? _labels['zh']!;
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: show),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: quit),
    ]));
  }

  @override
  void onTrayIconMouseDown() {
    if (Platform.isWindows) {
      windowManager.show();
      windowManager.focus();
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    if (Platform.isWindows) trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'quit') {
      windowManager.destroy();
    }
  }
}
