import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/preferences_service.dart';
import '../utils/theme.dart';
import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PreferencesService _prefs = PreferencesService();
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  bool _launchAtStartup = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final time = await _prefs.getReminderTime();
    final launch = await _prefs.getLaunchAtStartup();
    if (mounted) {
      setState(() {
        if (time != null) _reminderTime = time;
        _launchAtStartup = launch;
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: AppTheme.darkTheme.copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
      await _prefs.saveReminderTime(picked);
    }
  }

  Future<void> _toggleStartup(bool value) async {
    setState(() {
      _launchAtStartup = value;
    });
    await _prefs.setLaunchAtStartup(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Settings",
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                    title: const Text("Daily Reminder"),
                    subtitle: Text("Notify me at ${_reminderTime.format(context)}"),
                    trailing: TextButton(
                      onPressed: () => _selectTime(context),
                      child: const Text("Change"),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  ListTile(
                    leading: const Icon(Icons.rocket_launch_outlined, color: AppColors.secondary),
                    title: const Text("Launch at Startup"),
                    subtitle: const Text("Start SimpleDaily when you log in"),
                    trailing: Switch(
                      value: _launchAtStartup,
                      activeColor: AppColors.secondary,
                      onChanged: _toggleStartup,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
             Text(
              "About",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "SimpleDaily",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Version ${AppConstants.currentVersion}",
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "A simple, privacy-focused productivity app.",
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
