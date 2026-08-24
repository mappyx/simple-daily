import 'dart:async';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../services/json_data_service.dart';
import '../services/supabase_sync_service.dart';
import '../services/preferences_service.dart';

class DataProvider extends ChangeNotifier {
  final JsonDataService _localDataService = JsonDataService();
  final SupabaseSyncService _cloudSyncService = SupabaseSyncService();
  final PreferencesService _prefs = PreferencesService();

  List<Note> _notes = [];
  List<Project> _projects = [];

  List<Note> get notes => _notes;
  List<Project> get projects => _projects;

  String? _currentNoteId;
  String? get currentNoteId => _currentNoteId;

  Timer? _saveTimer;

  void setCurrentNote(String? id) {
    _currentNoteId = id;
    notifyListeners();
  }

  /// Saves data after a small delay to batch multiple rapid changes
  void saveDataDebounced() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 2), () async {
      print("DataProvider: Batch-saving data to disk...");
      await saveData();
    });
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  DataProvider() {
    _loadData();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();

    final mode = await _prefs.getSyncMode();
    final url = await _prefs.getSupabaseUrl();
    final key = await _prefs.getSupabaseAnonKey();

    bool cloudReady = false;
    if (mode != 'local' && url != null && key != null && url.isNotEmpty && key.isNotEmpty) {
      cloudReady = await _cloudSyncService.initialize(url, key);
    }

    if (mode == 'cloud' && cloudReady) {
      _notes = await _cloudSyncService.loadNotes();
      _projects = await _cloudSyncService.loadProjects();
    } else if (mode == 'dual' && cloudReady) {
      // For dual, load local first to show immediately, then fetch cloud and merge (or overwrite for simplicity)
      _notes = await _localDataService.loadNotes();
      _projects = await _localDataService.loadProjects();
      
      final cloudNotes = await _cloudSyncService.loadNotes();
      final cloudProjects = await _cloudSyncService.loadProjects();
      
      // Simple merge: cloud overwrites local for this basic implementation.
      if (cloudNotes.isNotEmpty) _notes = cloudNotes;
      if (cloudProjects.isNotEmpty) _projects = cloudProjects;
      
      // Save merged to local
      await _localDataService.saveNotes(_notes);
      await _localDataService.saveProjects(_projects);
    } else {
      // Local mode or fallback
      _notes = await _localDataService.loadNotes();
      _projects = await _localDataService.loadProjects();
    }

    _isLoading = false;
    notifyListeners();
  }

  // --- Notes Operations ---
  Future<void> addNote(Note note) async {
    _notes.add(note);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> updateNote(Note note) async {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
      await _saveNotes();
      notifyListeners();
    }
  }

  Future<void> deleteNote(String id) async {
    _notes.removeWhere((n) => n.id == id);
    await _saveNotes();
    notifyListeners();
  }

  Future<void> _saveNotes() async {
    final mode = await _prefs.getSyncMode();
    
    if (mode == 'local' || mode == 'dual') {
      await _localDataService.saveNotes(_notes);
    }
    
    if (mode == 'cloud' || mode == 'dual') {
      if (_cloudSyncService.isInitialized) {
        // Run cloud save asynchronously without blocking
        _cloudSyncService.saveNotes(_notes);
      }
    }
  }

  // --- Projects Operations ---
  Future<void> addProject(Project project) async {
    _projects.add(project);
    await _saveProjects();
    notifyListeners();
  }

  Future<void> updateProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
      await _saveProjects();
      notifyListeners();
    }
  }

  Future<void> deleteProject(String id) async {
    _projects.removeWhere((p) => p.id == id);
    await _saveProjects();
    notifyListeners();
  }

  Future<void> _saveProjects() async {
    final mode = await _prefs.getSyncMode();
    
    if (mode == 'local' || mode == 'dual') {
      await _localDataService.saveProjects(_projects);
    }
    
    if (mode == 'cloud' || mode == 'dual') {
      if (_cloudSyncService.isInitialized) {
        // Run cloud save asynchronously without blocking
        _cloudSyncService.saveProjects(_projects);
      }
    }
  }

  Future<void> saveData() async {
    await _saveProjects();
    await _saveNotes();
  }

  /// Public method to trigger UI refresh after external modifications
  void refreshUI() {
    notifyListeners();
  }
}
