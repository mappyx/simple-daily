import 'dart:io';
import 'package:flutter/services.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/constants.dart';

class SystemTrayService {
  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();

  Future<void> init() async {
    String iconPath = 
        Platform.isWindows ? 'windows/runner/resources/app_icon.ico' : 'assets/app_icon.png';
    // Note: For Linux, system_tray often uses a specific path or the app icon if configured in linux runner.
    // For simplicity, we assume system default or bundled assets. 
    // In production, we need to ensure the icon is correctly placed for linux.
    
    // Using a simple workaround for icon if assets not set up perfect:
    // system_tray requires a path to an icon file.
    
    final SystemTray systemTray = SystemTray();

    await systemTray.initSystemTray(
      title: AppConstants.appName,
      iconPath: iconPath,
    );

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: 'Show', onClicked: (menuItem) => _appWindow.show()),
      MenuItemLabel(label: 'Hide', onClicked: (menuItem) => _appWindow.hide()),
      MenuItemLabel(label: 'Exit', onClicked: (menuItem) => _appWindow.close()),
    ]);

    await systemTray.setContextMenu(menu);

    // Handle clicks
    systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? _appWindow.show() : systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? systemTray.popUpContextMenu() : _appWindow.show();
      }
    });
  }
}
