import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String keyReminderTimeHour = 'reminder_hour';
  static const String keyReminderTimeMinute = 'reminder_minute';
  static const String keyLaunchAtStartup = 'launch_startup';

  Future<void> saveReminderTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(keyReminderTimeHour, time.hour);
    await prefs.setInt(keyReminderTimeMinute, time.minute);
  }

  Future<TimeOfDay?> getReminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(keyReminderTimeHour);
    final minute = prefs.getInt(keyReminderTimeMinute);
    if (hour != null && minute != null) {
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null; // Default handled by consumer
  }

  Future<void> setLaunchAtStartup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyLaunchAtStartup, value);
    
    if (Platform.isLinux) {
      if (value) {
        await _enableLinuxAutostart();
      } else {
        await _disableLinuxAutostart();
      }
    } else if (Platform.isWindows) {
      if (value) {
        await _enableWindowsAutostart();
      } else {
        await _disableWindowsAutostart();
      }
    }
  }

  Future<bool> getLaunchAtStartup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyLaunchAtStartup) ?? false;
  }

  // Linux Autostart Logic
  Future<void> _enableLinuxAutostart() async {
    try {
      final home = Platform.environment['HOME'];
      if (home == null) return;

      final autostartDir = Directory('$home/.config/autostart');
      if (!await autostartDir.exists()) {
        await autostartDir.create(recursive: true);
      }

      final desktopFile = File('${autostartDir.path}/simple_daily.desktop');
      final executablePath = Platform.resolvedExecutable;

      final content = '''
[Desktop Entry]
Type=Application
Name=SimpleDaily
Exec=$executablePath
Icon=simple_daily
Comment=Start SimpleDaily on login
X-GNOME-Autostart-enabled=true
''';

      await desktopFile.writeAsString(content);
      debugPrint("Linux Autostart Enabled at: ${desktopFile.path}");
    } catch (e) {
      debugPrint("Error enabling Linux Autostart: $e");
    }
  }

  Future<void> _disableLinuxAutostart() async {
    try {
      final home = Platform.environment['HOME'];
      if (home == null) return;

      final desktopFile = File('$home/.config/autostart/simple_daily.desktop');
      if (await desktopFile.exists()) {
        await desktopFile.delete();
      }
      debugPrint("Linux Autostart Disabled");
    } catch (e) {
      debugPrint("Error disabling Linux Autostart: $e");
    }
  }

  // Windows Autostart Logic
  Future<void> _enableWindowsAutostart() async {
    try {
      final executablePath = Platform.resolvedExecutable;
      // Using 'reg' command to add entry to CurrentVersion\Run
      await Process.run('reg', [
        'add',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
        '/v',
        'SimpleDaily',
        '/t',
        'REG_SZ',
        '/d',
        '"$executablePath"',
        '/f'
      ]);
      debugPrint("Windows Autostart Enabled");
    } catch (e) {
      debugPrint("Error enabling Windows Autostart: $e");
    }
  }

  Future<void> _disableWindowsAutostart() async {
    try {
      await Process.run('reg', [
        'delete',
        'HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run',
        '/v',
        'SimpleDaily',
        '/f'
      ]);
      debugPrint("Windows Autostart Disabled");
    } catch (e) {
      debugPrint("Error disabling Windows Autostart: $e");
    }
  }
}
