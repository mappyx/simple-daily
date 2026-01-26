import 'package:flutter/material.dart';

class AppColors {
  // Dark Theme Colors
  static const Color background = Color(0xFF1E1E1E);
  static const Color surface = Color(0xFF252526);
  static const Color primary = Color(0xFFBB86FC); // Soft Purple
  static const Color secondary = Color(0xFF03DAC6); // Teal Accent
  static const Color error = Color(0xFFCF6679);
  static const Color onBackground = Color(0xFFE1E1E1);
  static const Color onSurface = Color(0xFFE1E1E1);
  
  // Kanban Colors
  static const Color todoColumn = Color(0xFF3C3C3C);
  static const Color inProgressColumn = Color(0xFF4C4C4C);
  static const Color doneColumn = Color(0xFF2E7D32);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
}

class AppConstants {
  static const String appName = 'SimpleDaily';
  static const String notesFileName = 'notes.json';
  static const String projectsFileName = 'projects.json';
  static const String currentVersion = '1.0.0';
  static const String repoUrl = 'https://github.com/YourUser/SimpleDaily';
}
