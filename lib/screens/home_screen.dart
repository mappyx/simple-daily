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
import '../widgets/pomodoro_timer.dart';
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
    // Implementation remains same as before...
     bool needsUpdate = await updateService.isUpdateAvailable();
    if (needsUpdate && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
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
      backgroundColor: Colors.transparent, // Background handled by sidebar/content
      body: Row(
        children: [
          // Glassmorphism Sidebar
          ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                width: 72, // Rail width
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.7), // Semi-transparent
                  border: const Border(right: BorderSide(color: Colors.white10)),
                ),
                child: NavigationRail(
                  backgroundColor: Colors.transparent, // Important for glass effect
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24.0),
                    child: Text(
                      'SD',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.note_alt_outlined),
                      selectedIcon: Icon(Icons.note_alt),
                      label: Text('Notes'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.view_kanban_outlined),
                      selectedIcon: Icon(Icons.view_kanban),
                      label: Text('Projects'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: AppColors.background, // Main content opaque background
              child: Column(
                children: [
                  // Title Bar & Search
                  GestureDetector(
                    onPanStart: (details) {
                      windowManager.startDragging();
                    },
                    child: Container(
                      height: 50,
                      color: AppColors.background,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                             child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 300,
                                  height: 32,
                                  decoration: BoxDecoration(
                                     color: AppColors.surface,
                                     borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(8),
                                      onTap: () {
                                        showSearch(context: context, delegate: AppSearchDelegate());
                                      },
                                      child: Row(
                                        children: [
                                          const SizedBox(width: 8),
                                          const Icon(Icons.search, size: 18, color: Colors.grey),
                                          const SizedBox(width: 8),
                                          const Text("Search notes, tasks...", style: TextStyle(color: Colors.grey, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                             ),
                          ),
                         Expanded(child: Container()),
                        const PomodoroTimer(), // Added Timer
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(Icons.minimize, size: 16),
                          onPressed: () => windowManager.minimize(),
                        ),
                          IconButton(
                            icon: const Icon(Icons.check_box_outline_blank, size: 16),
                            onPressed: () async {
                              if (await windowManager.isMaximized()) {
                                windowManager.unmaximize();
                              } else {
                                windowManager.maximize();
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: () => windowManager.close(),
                          ),
                        ],
                      ),
                    ),
                  ),
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
}
