import 'dart:io';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

class TrayService with TrayListener {
  static final TrayService _instance = TrayService._();
  factory TrayService() => _instance;
  TrayService._();

  Future<void> init() async {
    if (!Platform.isWindows) return;
    trayManager.addListener(this);
    await trayManager.setIcon('assets/tray_icon.ico');
    await trayManager.setContextMenu(Menu(items: [
      MenuItem(key: 'show', label: '顯示 TypeTwo'),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: '退出'),
    ]));
  }

  @override
  void onTrayIconMouseDown() {
    if (Platform.isWindows) windowManager.show();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show') {
      windowManager.show();
    } else if (menuItem.key == 'quit') {
      windowManager.destroy();
    }
  }
}

