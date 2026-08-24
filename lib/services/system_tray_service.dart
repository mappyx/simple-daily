import 'dart:io';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/constants.dart';

class SystemTrayService {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  final SystemTray _systemTray = SystemTray();
  bool _initialized = false;

  Future<void> init() async {
    String iconPath = 
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon.png';
    
    await _systemTray.initSystemTray(
      title: AppConstants.appName,
      iconPath: iconPath,
    );

    _initialized = true;

    await updateMenu(showLabel: 'Show', hideLabel: 'Hide', exitLabel: 'Exit');

    // Handle clicks
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? windowManager.show() : _systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? _systemTray.popUpContextMenu() : windowManager.show();
      }
    });
  }

  Future<void> updateMenu({
    required String showLabel,
    required String hideLabel,
    required String exitLabel,
  }) async {
    if (!_initialized) return;
    
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: showLabel, onClicked: (menuItem) => windowManager.show()),
      MenuItemLabel(label: hideLabel, onClicked: (menuItem) => windowManager.hide()),
      MenuItemLabel(label: exitLabel, onClicked: (menuItem) => windowManager.destroy()),
    ]);

    await _systemTray.setContextMenu(menu);
  }
}
