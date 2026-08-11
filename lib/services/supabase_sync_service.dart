import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/note.dart';
import '../models/project.dart';

class SupabaseSyncService {
  SupabaseClient? _client;

  Future<bool> initialize(String url, String anonKey) async {
    try {
      _client = SupabaseClient(url, anonKey);
      return true;
    } catch (e) {
      print('Error initializing Supabase client: $e');
      return false;
    }
  }

  bool get isInitialized => _client != null;

  // --- Notes ---
  Future<List<Note>> loadNotes() async {
    if (!isInitialized) return [];
    try {
      final response = await _client!.from('notes').select();
      return (response as List).map((j) => Note.fromJson(j)).toList();
    } catch (e) {
      print("Error loading notes from Supabase: $e");
      return [];
    }
  }

  Future<void> saveNotes(List<Note> notes) async {
    if (!isInitialized) return;
    try {
      if (notes.isEmpty) return;
      final jsonList = notes.map((n) => n.toJson()).toList();
      await _client!.from('notes').upsert(jsonList);
    } catch (e) {
      print("Error saving notes to Supabase: $e");
    }
  }

  // --- Projects ---
  Future<List<Project>> loadProjects() async {
    if (!isInitialized) return [];
    try {
      final response = await _client!.from('projects').select();
      return (response as List).map((j) => Project.fromJson(j)).toList();
    } catch (e) {
      print("Error loading projects from Supabase: $e");
      return [];
    }
  }

  Future<void> saveProjects(List<Project> projects) async {
    if (!isInitialized) return;
    try {
      if (projects.isEmpty) return;
      final jsonList = projects.map((p) => p.toJson()).toList();
      await _client!.from('projects').upsert(jsonList);
    } catch (e) {
      print("Error saving projects to Supabase: $e");
    }
  }
}
