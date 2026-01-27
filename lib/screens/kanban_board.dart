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
  final VoidCallback? onBack;

  const KanbanBoard({super.key, required this.project, this.onBack});

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

  void _addNewTask() {
    // Default to first column (usually TODO)
    if (_project.columns.isEmpty) return;
    final column = _project.columns.first;
    
    TaskPriority selectedPriority = TaskPriority.medium;
    final titleController = TextEditingController();
    final tagsController = TextEditingController(); 

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(), // Rectangular Dialog
              title: const Text("New Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: "Task Title",
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    ),
                    autofocus: true,
                    style: const TextStyle(color: AppColors.textPrimary),
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
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
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
      floatingActionButton: _project.columns.isNotEmpty ? FloatingActionButton(
        onPressed: _addNewTask,
        backgroundColor: AppColors.primary,
        shape: const RoundedRectangleBorder(), // Rectangular FAB
        child: const Icon(Icons.add, color: Colors.black),
      ) : null,
      appBar: AppBar(
        title: Text(_project.title),
        backgroundColor: AppColors.surface,
        leading: BackButton(
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else {
              Navigator.pop(context);
            }
          },
        ),
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
        // itemDragOnLongPress defaults to true, enabling hold-to-drag
        itemDivider: const SizedBox(height: 8), // Gap between items during drag
        listInnerDecoration: BoxDecoration(
          color: Colors.transparent, // Background of the list content
          borderRadius: BorderRadius.circular(8),
        ),
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
          // No rounded corners
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

      leftSide: const VerticalDivider(color: Colors.transparent, width: 0, thickness: 0),
      rightSide: const VerticalDivider(color: Colors.transparent, width: 0, thickness: 0),
      children: List.generate(column.tasks.length, (i) {
        return _buildItem(column.tasks[i]);
      }),
      contentsWhenEmpty: Container(
        height: 60,
        alignment: Alignment.center,
        child: Text(
          "Empty List",
          style: TextStyle(color: Colors.grey[800], fontStyle: FontStyle.italic),
        ),
      ),
      // Use Column with stretch alignment for centering content
      verticalAlignment: CrossAxisAlignment.stretch, 
      decoration: BoxDecoration(
        color: AppColors.surface,
        // No rounded corners
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _editTask(task),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), // Increased spacing
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant, // Matches windows
              border: Border.all(color: Colors.white10),
              // No rounded corners
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Minimal priority indicator dot instead of border
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(task.priority),
                        shape: BoxShape.rectangle, // Square dot
                      ),
                    ),
                    const SizedBox(width: 12),
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: task.tags.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        // Rectangular chips
                      ),
                      child: Text(
                        tag.toUpperCase(),
                        style: GoogleFonts.inter(
                          color: AppColors.primary, 
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5
                        ),
                      ),
                    )).toList(),
                  )
                ],
                if (task.dueDate != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('MMM d').format(task.dueDate!),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ]
              ],
            ),
          ),
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  void _editTask(Task task) {
    final titleController = TextEditingController(text: task.title);
    final tagsController = TextEditingController(text: task.tags.join(', '));
    TaskPriority selectedPriority = task.priority;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(),
              title: const Text("Edit Task"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      hintText: "Task Title",
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
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
                      if (val != null) {
                        setDialogState(() => selectedPriority = val);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tagsController,
                    decoration: const InputDecoration(
                      hintText: "Tags (comma separated)",
                      prefixIcon: Icon(Icons.tag, size: 16),
                      border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                     // Delete task option
                     setState(() {
                       for(var col in _project.columns) {
                         col.tasks.remove(task);
                       }
                     });
                     _saveProject();
                     Navigator.pop(context);
                  },
                  child: const Text("Delete", style: TextStyle(color: AppColors.error)),
                ),
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
                         task.title = titleController.text;
                         task.priority = selectedPriority;
                         task.tags = tags;
                      });
                      _saveProject();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
