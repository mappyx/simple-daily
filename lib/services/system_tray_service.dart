import 'dart:io';
import 'package:flutter/services.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/constants.dart';

class SystemTrayService {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  final SystemTray _systemTray = SystemTray();
  final AppWindow _appWindow = AppWindow();

  Future<void> init() async {
    String iconPath = 
        Platform.isWindows ? 'windows/runner/resources/app_icon.ico' : 'assets/app_icon.png';
    
    await _systemTray.initSystemTray(
      title: AppConstants.appName,
      iconPath: iconPath,
    );

    await updateMenu(showLabel: 'Show', hideLabel: 'Hide', exitLabel: 'Exit');

    // Handle clicks
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        Platform.isWindows ? _appWindow.show() : _systemTray.popUpContextMenu();
      } else if (eventName == kSystemTrayEventRightClick) {
        Platform.isWindows ? _systemTray.popUpContextMenu() : _appWindow.show();
      }
    });
  }

  Future<void> updateMenu({
    required String showLabel,
    required String hideLabel,
    required String exitLabel,
  }) async {
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(label: showLabel, onClicked: (menuItem) => _appWindow.show()),
      MenuItemLabel(label: hideLabel, onClicked: (menuItem) => _appWindow.hide()),
      MenuItemLabel(label: exitLabel, onClicked: (menuItem) => _appWindow.close()),
    ]);

    await _systemTray.setContextMenu(menu);
  }
}
