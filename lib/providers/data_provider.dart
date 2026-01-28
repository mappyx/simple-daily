import 'dart:async';
import 'package:flutter/material.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../services/json_data_service.dart';

class DataProvider extends ChangeNotifier {
  final JsonDataService _dataService = JsonDataService();

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

    _notes = await _dataService.loadNotes();
    _projects = await _dataService.loadProjects();

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
    await _dataService.saveNotes(_notes);
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
    await _dataService.saveProjects(_projects);
  }

  Future<void> saveData() async {
    await _saveProjects();
    await _saveNotes();
  }
}
