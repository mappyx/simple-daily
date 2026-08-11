import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/preferences_service.dart';
import '../providers/language_provider.dart';
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
  String _supabaseUrl = '';
  String _supabaseAnonKey = '';
  String _syncMode = 'local';
  
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  @override
  void dispose() {
    _urlController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final time = await _prefs.getReminderTime();
    final launch = await _prefs.getLaunchAtStartup();
    final url = await _prefs.getSupabaseUrl();
    final key = await _prefs.getSupabaseAnonKey();
    final mode = await _prefs.getSyncMode();
    
    if (mounted) {
      setState(() {
        if (time != null) _reminderTime = time;
        _launchAtStartup = launch;
        _supabaseUrl = url ?? '';
        _supabaseAnonKey = key ?? '';
        _syncMode = mode;
        
        _urlController.text = _supabaseUrl;
        _keyController.text = _supabaseAnonKey;
        
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
      if (mounted) {
        setState(() {
          _reminderTime = picked;
        });
      }
      await _prefs.saveReminderTime(picked);
    }
  }

  Future<void> _toggleStartup(bool value) async {
    if (mounted) {
      setState(() {
        _launchAtStartup = value;
      });
    }
    await _prefs.setLaunchAtStartup(value);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    final lang = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.translate('settings'),
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
                  // Daily Reminder
                  Tooltip(
                    message: lang.translate('daily_reminder_tooltip'),
                    child: ListTile(
                      leading: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
                      title: Text(lang.translate('daily_reminder')),
                      subtitle: Text("Notify me at ${_reminderTime.format(context)}"),
                      trailing: TextButton(
                        onPressed: () => _selectTime(context),
                        child: Text(lang.translate('change')),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),
                  
                  // Startup
                  Tooltip(
                    message: lang.translate('launch_startup_tooltip'),
                    child: ListTile(
                      leading: const Icon(Icons.rocket_launch_outlined, color: AppColors.secondary),
                      title: Text(lang.translate('launch_startup')),
                      subtitle: Text(lang.translate('launch_startup')), // Usually subtitle would be something small
                      trailing: Switch(
                        value: _launchAtStartup,
                        activeColor: AppColors.secondary,
                        onChanged: _toggleStartup,
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Colors.white10),

                  // Language Switch
                  ListTile(
                    leading: const Icon(Icons.language, color: Colors.blueAccent),
                    title: Text(lang.translate('language')),
                    subtitle: Text(lang.currentLocale.languageCode == 'es' ? 'Español' : 'English'),
                    trailing: Switch(
                      value: lang.currentLocale.languageCode == 'en',
                      activeColor: Colors.blueAccent,
                      activeTrackColor: Colors.blueAccent.withOpacity(0.5),
                      inactiveThumbColor: Colors.orangeAccent,
                      inactiveTrackColor: Colors.orangeAccent.withOpacity(0.5),
                      onChanged: (val) {
                        lang.setLanguage(val ? 'en' : 'es');
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Cloud Sync Section
            Text(
              'Cloud Sync (Supabase)',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    value: _syncMode,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Sync Mode',
                      labelStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'local', child: Text('Local Only')),
                      DropdownMenuItem(value: 'cloud', child: Text('Cloud Only')),
                      DropdownMenuItem(value: 'dual', child: Text('Dual (Collaborative & Offline)')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _syncMode = newValue;
                        });
                        _prefs.setSyncMode(newValue);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _urlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Supabase URL',
                      labelStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _prefs.setSupabaseUrl(value),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _keyController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Supabase Anon Key',
                      labelStyle: TextStyle(color: Colors.white54),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _prefs.setSupabaseAnonKey(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
             Text(
              lang.translate('about'),
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
                    "${lang.translate('version')} ${AppConstants.currentVersion}",
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
