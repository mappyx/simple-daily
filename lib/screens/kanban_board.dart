import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/project.dart';
import '../providers/data_provider.dart';
import '../utils/theme.dart';

class KanbanBoard extends StatefulWidget {
  final Project project;

  const KanbanBoard({super.key, required this.project});

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  late Project _project;

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  void _onItemReorder(
      int oldItemIndex, int oldListIndex, int newItemIndex, int newListIndex) {
    setState(() {
      var movedItem = _project.columns[oldListIndex].tasks.removeAt(oldItemIndex);
      _project.columns[newListIndex].tasks.insert(newItemIndex, movedItem);
    });
    _saveProject();
  }

  void _onListReorder(int oldListIndex, int newListIndex) {
    setState(() {
      var movedList = _project.columns.removeAt(oldListIndex);
      _project.columns.insert(newListIndex, movedList);
    });
    _saveProject();
  }

  void _saveProject() {
    Provider.of<DataProvider>(context, listen: false).updateProject(_project);
  }

  void _addNewTask(KanbanColumn column) {
    TaskPriority selectedPriority = TaskPriority.medium;
    final titleController = TextEditingController();
    final tagsController = TextEditingController(); // CSV for tags simple impl

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("New Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(hintText: "Task Title"),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<TaskPriority>(
                    value: selectedPriority,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    items: TaskPriority.values.map((p) {
                      return DropdownMenuItem(
                        value: p,
                        child: Text(
                          p.toString().split('.').last.toUpperCase(),
                          style: TextStyle(
                            color: _getPriorityColor(p),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedPriority = val!);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      hintText: "Tags (comma separated)",
                      prefixIcon: Icon(Icons.tag, size: 16),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      List<String> tags = tagsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      
                      setState(() {
                        column.tasks.add(Task.create(
                          title: titleController.text,
                          priority: selectedPriority,
                          tags: tags,
                        ));
                      });
                      _saveProject();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Color _getPriorityColor(TaskPriority p) {
    switch (p) {
      case TaskPriority.high: return Colors.redAccent;
      case TaskPriority.medium: return Colors.orangeAccent;
      case TaskPriority.low: return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_project.title),
        backgroundColor: AppColors.surface,
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: DragAndDropLists(
        children: List.generate(_project.columns.length, (index) {
          return _buildList(index);
        }),
        onItemReorder: _onItemReorder,
        onListReorder: _onListReorder,
        axis: Axis.horizontal,
        listWidth: 320,
        listDraggingWidth: 320,
        listPadding: const EdgeInsets.all(12.0),
      ),
    );
  }

  DragAndDropList _buildList(int index) {
    final column = _project.columns[index];
    return DragAndDropList(
      header: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          border: Border(bottom: BorderSide(color: Colors.grey[800]!)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              column.title.toUpperCase(),
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 1.2,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "${column.tasks.length}",
                style: const TextStyle(fontSize: 12),
              ),
            )
          ],
        ),
      ),
      footer: GestureDetector(
         onTap: () => _addNewTask(column),
         child: Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(
             color: AppColors.surface,
             borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.add, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text("Add Task", style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
         ),
      ),
      leftSide: const VerticalDivider(color: Colors.transparent, width: 12, thickness: 0),
      rightSide: const VerticalDivider(color: Colors.transparent, width: 0, thickness: 0),
      children: List.generate(column.tasks.length, (i) {
        return _buildItem(column.tasks[i]);
      }),
      contentsWhenEmpty: Container(
        height: 60,
        color: AppColors.surface,
        alignment: Alignment.center,
        child: Text(
          "Empty List",
          style: TextStyle(color: Colors.grey[800], fontStyle: FontStyle.italic),
        ),
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
    );
  }

  DragAndDropItem _buildItem(Task task) {
    return DragAndDropItem(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: _getPriorityColor(task.priority),
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary, 
                      fontSize: 15,
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),
              ],
            ),
            if (task.tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: task.tags.map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(color: AppColors.primary, fontSize: 10),
                  ),
                )).toList(),
              )
            ],
            if (task.dueDate != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('MMM d').format(task.dueDate!),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ]
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }
}
