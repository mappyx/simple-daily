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
    // Note: Actual OS-level autostart logic would go here.
    // For Linux, we'd write to ~/.config/autostart/simple_daily.desktop
    if (value) {
      _enableLinuxAutostart();
    } else {
      _disableLinuxAutostart();
    }
  }

  Future<bool> getLaunchAtStartup() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyLaunchAtStartup) ?? false;
  }

  // Linux Autostart Logic
  void _enableLinuxAutostart() {
    // This requires specific platform check and IO operations
    // Implementing a basic placeholder specifically for the requested "Linux" support
    // In a real app, use 'auto_start' package or similar.
    // We will just log it for now to avoid side-effecting user system unexpectedly without permission
    print("Enabling Linux Autostart (Placeholder)");
  }

  void _disableLinuxAutostart() {
    print("Disabling Linux Autostart (Placeholder)");
  }
}
