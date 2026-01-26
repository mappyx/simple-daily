import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../utils/constants.dart';

class JsonDataService {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    final dataDir = Directory('${directory.path}/${AppConstants.appName}_Data');
    if (!await dataDir.exists()) {
      await dataDir.create(recursive: true);
    }
    return dataDir.path;
  }

  Future<File> get _notesFile async {
    final path = await _localPath;
    return File('$path/${AppConstants.notesFileName}');
  }

  Future<File> get _projectsFile async {
    final path = await _localPath;
    return File('$path/${AppConstants.projectsFileName}');
  }

  // --- Notes ---
  Future<List<Note>> loadNotes() async {
    try {
      final file = await _notesFile;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => Note.fromJson(j)).toList();
    } catch (e) {
      print("Error loading notes: $e");
      return [];
    }
  }

  Future<void> saveNotes(List<Note> notes) async {
    try {
      final file = await _notesFile;
      final jsonList = notes.map((n) => n.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print("Error saving notes: $e");
    }
  }

  // --- Projects ---
  Future<List<Project>> loadProjects() async {
    try {
      final file = await _projectsFile;
      if (!await file.exists()) return [];
      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((j) => Project.fromJson(j)).toList();
    } catch (e) {
      print("Error loading projects: $e");
      return [];
    }
  }

  Future<void> saveProjects(List<Project> projects) async {
    try {
      final file = await _projectsFile;
      final jsonList = projects.map((p) => p.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print("Error saving projects: $e");
    }
  }
}
