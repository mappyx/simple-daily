import 'dart:ui'; // For BackdropFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:window_manager/window_manager.dart';
import '../utils/constants.dart';
import '../utils/theme.dart';
import '../utils/search_delegate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/update_service.dart';
import '../services/pdf_export_service.dart';
import '../widgets/pomodoro_timer.dart';
import '../providers/data_provider.dart';
import 'package:provider/provider.dart';
import 'notes_screen.dart';
import 'projects_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WindowListener {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _checkForUpdates();
  }

  Future<void> _checkForUpdates() async {
    final updateService = UpdateService();
     bool needsUpdate = await updateService.isUpdateAvailable();
    if (needsUpdate && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text("Update Available"),
          content: const Text("A new version of SimpleDaily is available."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Later"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                updateService.performUpdate(context);
              },
              child: const Text("Update now"),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        children: [
          // Windows 11 Style Sidebar
          Container(
            width: 68,
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(right: BorderSide(color: AppColors.divider, width: 1)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                  // App Icon
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      // No rounded corners
                    ),
                    child: Center(
                      child: Text(
                        'SD',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Navigation Items
                  _buildNavItem(Icons.note_outlined, Icons.note, 0, 'Notes'),
                  _buildNavItem(Icons.view_kanban_outlined, Icons.view_kanban, 1, 'Projects'),
                  _buildNavItem(Icons.settings_outlined, Icons.settings, 2, 'Settings'),
                  const Spacer(),
                ],
              ),
            ),
            // Main Content
            Expanded(
              child: Container(
                color: AppColors.background,
                child: Column(
                  children: [
                    // Title Bar
                    GestureDetector(
                      onPanStart: (details) {
                        windowManager.startDragging();
                      },
                      child: Container(
                        height: 48,
                        color: AppColors.background,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                               child: Row(
                          children: [
                            // Archive dropdown menu
                            PopupMenuButton<String>(
                              offset: const Offset(0, 40),
                              shape: const RoundedRectangleBorder(),
                              color: const Color(0xFF1A1A1A),
                              onSelected: (value) async {
                                if (value == 'export_all') {
                                  try {
                                    final dataProvider = Provider.of<DataProvider>(context, listen: false);
                                    final pdfService = PdfExportService();
                                    await pdfService.exportAllNotesToPdf(dataProvider.notes);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('All notes exported to Downloads folder!')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error exporting: $e')),
                                      );
                                    }
                                  }
                                } else if (value == 'export_current') {
                                  final dataProvider = Provider.of<DataProvider>(context, listen: false);
                                  final currentNoteId = dataProvider.currentNoteId;
                                  
                                  if (currentNoteId != null) {
                                    try {
                                      final note = dataProvider.notes.firstWhere((n) => n.id == currentNoteId);
                                      final pdfService = PdfExportService();
                                      await pdfService.exportNoteToPdf(note);
                                      
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Note "${note.title}" exported to Downloads!')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error exporting note: $e')),
                                        );
                                      }
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Please select a note to export')),
                                    );
                                  }
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'export_all',
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 12),
                                      const Text('Export All'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'export_current',
                                  child: Row(
                                    children: [
                                      Icon(Icons.description, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 12),
                                      const Text('Export Actual Note'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                PopupMenuItem(
                                  value: 'exit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.exit_to_app, size: 16, color: AppColors.error),
                                      const SizedBox(width: 12),
                                      Text('Exit', style: TextStyle(color: AppColors.error)),
                                    ],
                                  ),
                                  onTap: () {
                                    Future.delayed(Duration.zero, () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          backgroundColor: AppColors.surface,
                                          shape: const RoundedRectangleBorder(),
                                          title: const Text('Exit SimpleDaily?'),
                                          content: const Text('Are you sure you want to exit?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(ctx),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
                                              onPressed: () {
                                                Navigator.pop(ctx);
                                                windowManager.close();
                                              },
                                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                              child: const Text('Exit', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                    });
                                  },
                                ),
                              ],
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Archive',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            ),
                            // About Us button
                            TextButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: AppColors.surface,
                                    shape: const RoundedRectangleBorder(), // No rounded corners
                                    title: const Text('About SimpleDaily'),
                                    content: Text(
                                      'SimpleDaily v${AppConstants.currentVersion}\n\n'
                                      'A privacy-focused productivity app with notes, '
                                      'projects, and focus tools.\n\n'
                                      'Built with Flutter.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: const RoundedRectangleBorder(), // No rounded corners
                              ),
                              child: Text(
                                'About Us',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                           const Spacer(),
                          const PomodoroTimer(),
                          const SizedBox(width: 16),
                          _buildWindowButton(Icons.remove, () => windowManager.minimize()),
                          _buildWindowButton(Icons.crop_square, () async {
                            if (await windowManager.isMaximized()) {
                              windowManager.unmaximize();
                            } else {
                              windowManager.maximize();
                            }
                          }),
                          _buildWindowButton(Icons.close, () => windowManager.close(), isClose: true),
                          ],
                        ),
                      ),
                    ),
                    // Content
                    Expanded(
                      child: IndexedStack(
                        index: _selectedIndex,
                        children: const [
                           NotesScreen(),
                           ProjectsScreen(),
                           SettingsScreen(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
  
    Widget _buildNavItem(IconData icon, IconData selectedIcon, int index, String tooltip) {
      final isSelected = _selectedIndex == index;
      return Tooltip(
        message: tooltip,
        child: Container(
          width: double.infinity, // Full width
          height: 60, // Taller buttons
          margin: EdgeInsets.zero, // No margin
          child: Material(
            color: isSelected ? AppColors.surfaceVariant : Colors.transparent, // Highlight background
            child: InkWell(
              onTap: () => setState(() => _selectedIndex = index),
              child: Center( // Center icon
                child: Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      );
    }

  Widget _buildWindowButton(IconData icon, VoidCallback onPressed, {bool isClose = false}) {
    return SizedBox(
      width: 46,
      height: 32,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          hoverColor: isClose ? Colors.red.withOpacity(0.8) : Colors.white.withOpacity(0.1),
          child: Icon(icon, size: 14, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
