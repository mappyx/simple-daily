import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../models/project.dart';
import '../utils/theme.dart';
import 'kanban_board.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProjectDialog(context),
        backgroundColor: AppColors.secondary,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: Consumer<DataProvider>(
        builder: (context, data, child) {
          if (data.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (data.projects.isEmpty) {
            return Center(
              child: Text(
                "No projects. Start one!",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.projects.length,
            itemBuilder: (context, index) {
              final project = data.projects[index];
              return _buildProjectTile(context, project);
            },
          );
        },
      ),
    );
  }

  Widget _buildProjectTile(BuildContext context, Project project) {
    // Calculate progress
    int totalTasks = 0;
    int doneTasks = 0;
    for (var col in project.columns) {
      totalTasks += col.tasks.length;
      if (col.title.toLowerCase() == 'done') { // Simple heuristic
        doneTasks += col.tasks.length;
      }
    }
    double progress = totalTasks == 0 ? 0 : doneTasks / totalTasks;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surface,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => KanbanBoard(project: project)),
          );
        },
        title: Text(
          project.title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              "Created ${DateFormat.yMMMd().format(project.createdAt)}",
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[800],
              color: AppColors.secondary,
              minHeight: 4,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () {
            // Confirm delete
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text("Delete Project?"),
                content: const Text("This cannot be undone."),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      Provider.of<DataProvider>(context, listen: false)
                          .deleteProject(project.id);
                      Navigator.pop(ctx);
                    },
                    child: const Text("Delete", style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddProjectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Project"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Project Name"),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                final project = Project.create(title: controller.text);
                Provider.of<DataProvider>(context, listen: false)
                    .addProject(project);
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}
