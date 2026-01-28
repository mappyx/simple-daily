import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/system_tray_service.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _currentLocale = const Locale('es');
  Map<String, String> _localizedStrings = {};

  Locale get currentLocale => _currentLocale;

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? languageCode = prefs.getString('language_code');
    if (languageCode != null) {
      _currentLocale = Locale(languageCode);
    }
    await _loadStrings();
    notifyListeners();
  }

  Future<void> _loadStrings() async {
    String jsonString = await rootBundle.loadString('assets/l10n/${_currentLocale.languageCode}.json');
    Map<String, dynamic> jsonMap = json.decode(jsonString);
    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
    
    // Update system tray icons/text if initialized
    SystemTrayService().updateMenu(
      showLabel: translate('show'),
      hideLabel: translate('hide'),
      exitLabel: translate('exit'),
    );
  }

  Future<void> setLanguage(String languageCode) async {
    if (_currentLocale.languageCode == languageCode) return;
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    await _loadStrings();
    notifyListeners();
  }

  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

extension LocalizationExtension on BuildContext {
  String t(String key) => (this.read<LanguageProvider>() ?? (this.watch<LanguageProvider>())).translate(key);
}
