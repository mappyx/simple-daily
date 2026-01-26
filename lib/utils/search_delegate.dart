import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/data_provider.dart';
import '../models/note.dart';
import '../models/project.dart';
import '../utils/constants.dart';

class AppSearchDelegate extends SearchDelegate {
  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: AppColors.surface,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return BackButton(
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
     return _buildResults(context);
  }

  Widget _buildResults(BuildContext context) {
    final data = Provider.of<DataProvider>(context, listen: false);
    final queryLower = query.toLowerCase();
    
    // Filter Notes
    final notes = data.notes.where((n) {
      return n.title.toLowerCase().contains(queryLower) ||
             n.content.toLowerCase().contains(queryLower);
    }).toList();

    // Filter Tasks (Flat map)
    final tasks = <_TaskResult>[];
    for (var p in data.projects) {
      for (var c in p.columns) {
        for (var t in c.tasks) {
          if (t.title.toLowerCase().contains(queryLower) || 
              (t.tags.any((tag) => tag.toLowerCase().contains(queryLower)))) {
            tasks.add(_TaskResult(t, p.title));
          }
        }
      }
    }

    if (notes.isEmpty && tasks.isEmpty) {
      return Center(
        child: Text(
          "No results found",
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (notes.isNotEmpty) ...[
          Text("Notes", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ...notes.map((n) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.note, color: AppColors.primary),
            title: Text(n.title),
            subtitle: Text(
               n.content, 
               maxLines: 1, 
               overflow: TextOverflow.ellipsis,
               style: const TextStyle(color: Colors.grey),
            ),
            onTap: () {
              // Navigation to specific note is tricky from here without context switch logic
              // For now, simple return or assume user sees it
              close(context, n);
            },
          )),
          const SizedBox(height: 16),
        ],
        if (tasks.isNotEmpty) ...[
          Text("Tasks", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          ...tasks.map((t) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.check_circle_outline, color: AppColors.secondary),
            title: Text(t.task.title),
            subtitle: Text("${t.projectName} • ${t.task.priority.name.toUpperCase()}"),
            onTap: () {
               close(context, t.task);
            },
          )),
        ]
      ],
    );
  }
}

class _TaskResult {
  final Task task;
  final String projectName;
  _TaskResult(this.task, this.projectName);
}
