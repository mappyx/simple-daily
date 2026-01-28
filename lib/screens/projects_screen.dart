import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../providers/data_provider.dart';
import '../providers/language_provider.dart';
import '../models/project.dart';
import '../utils/theme.dart';
import 'kanban_board.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  Project? _selectedProject;

  @override
  Widget build(BuildContext context) {
    if (_selectedProject != null) {
      return KanbanBoard(
        project: _selectedProject!,
        onBack: () {
          if (mounted) {
            setState(() {
              _selectedProject = null;
            });
          }
        },
      );
    }

    final lang = context.watch<LanguageProvider>();
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
                lang.translate('no_projects'),
                style: const TextStyle(color: AppColors.textSecondary),
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
              return _buildProjectTile(context, project, lang);
            },
          );
        },
      ),
    );
  }

  Widget _buildProjectTile(BuildContext context, Project project, LanguageProvider lang) {
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
          if (mounted) {
            setState(() {
              _selectedProject = project;
            });
          }
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
                "${lang.translate('created')} ${DateFormat.yMMMd().format(project.createdAt)}",
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    "${(progress * 100).toInt()}% ${lang.translate('done')}",
                     style: GoogleFonts.inter(
                       fontSize: 12, 
                       fontWeight: FontWeight.w600,
                       color: AppColors.primary
                     ),
                  ),
                  const Spacer(),
                  Text(
                    "$doneTasks/$totalTasks ${lang.translate('tasks')}",
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
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
      final lang = context.read<LanguageProvider>();
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: const RoundedRectangleBorder(), // Rectangular Dialog
          title: Text(lang.translate('delete_project')),
          content: Text(lang.translate('undone_msg')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(lang.translate('cancel')),
            ),
            TextButton(
              onPressed: () {
                Provider.of<DataProvider>(context, listen: false)
                    .deleteProject(project.id);
                Navigator.pop(ctx);
              },
              child: Text(lang.translate('delete'), style: const TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
  }

  void _showAddProjectDialog(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(), // Rectangular Dialog
        title: Text(lang.translate('new_project')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: lang.translate('project_name'),
            border: const OutlineInputBorder(borderRadius: BorderRadius.zero), // Rectangular input
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
              borderRadius: BorderRadius.zero,
            ),
            focusedBorder: const OutlineInputBorder(
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
            child: Text(lang.translate('cancel')),
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
            child: Text(lang.translate('create')),
          ),
        ],
      ),
    );
  }
}
