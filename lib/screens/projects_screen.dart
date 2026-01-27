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
        backgroundColor: AppColors.primary, // Use primary for better visibility
        shape: const RoundedRectangleBorder(), // Rectangular FAB
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
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 300, // Reasonable width for a card
              childAspectRatio: 1.0,  // Square cards
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
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
      margin: EdgeInsets.zero, // Grid handles spacing
      color: AppColors.surfaceVariant, // Lighter surface for better contrast
      shape: const RoundedRectangleBorder(), // Rectangular Card
      elevation: 0, // Flat look
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => KanbanBoard(project: project)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      project.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textSecondary),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    hoverColor: AppColors.error.withOpacity(0.1),
                    onPressed: () {
                       _deleteProject(context, project);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Created ${DateFormat.yMMMd().format(project.createdAt)}",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    "${(progress * 100).toInt()}% Done",
                     style: GoogleFonts.inter(
                       fontSize: 12, 
                       fontWeight: FontWeight.w600,
                       color: AppColors.primary
                     ),
                  ),
                  const Spacer(),
                  Text(
                    "$doneTasks/$totalTasks Tasks",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.black12,
                color: AppColors.primary,
                minHeight: 4,
                borderRadius: BorderRadius.zero, // Rectangular progress
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteProject(BuildContext context, Project project) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(), // Rectangular Dialog
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
              child: const Text("Delete", style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
  }

  void _showAddProjectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(), // Rectangular Dialog
        title: const Text("New Project"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Project Name",
            border: OutlineInputBorder(borderRadius: BorderRadius.zero), // Rectangular input
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.primary),
              borderRadius: BorderRadius.zero,
            ),
          ),
          autofocus: true,
          style: const TextStyle(color: AppColors.textPrimary),
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
