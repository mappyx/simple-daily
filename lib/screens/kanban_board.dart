import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_selector/file_selector.dart';
import '../models/project.dart';
import '../providers/data_provider.dart';
import '../providers/language_provider.dart';
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

  void _showImageFull(String path) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: Image.file(File(path), fit: BoxFit.contain),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewTask() {
    // Default to first column (usually TODO)
    if (_project.columns.isEmpty) return;
    final column = _project.columns.first;
    
    TaskPriority selectedPriority = TaskPriority.medium;
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final tagsController = TextEditingController(); 
    final appPathController = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    List<String> imagePaths = [];

    final lang = context.read<LanguageProvider>();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(), // Rectangular Dialog
              title: Text(lang.translate('add_task')),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          hintText: lang.translate('title'),
                          labelText: lang.translate('title'),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: AppColors.primary)),
                        ),
                        autofocus: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      
                      // Description
                      TextField(
                        controller: descriptionController,
                        maxLines: 8, // Made larger
                        decoration: InputDecoration(
                          hintText: lang.translate('description'),
                          labelText: lang.translate('description'),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          alignLabelWithHint: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      // Images section
                      Text(lang.translate('add_images'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (imagePaths.isNotEmpty)
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imagePaths.length,
                            itemBuilder: (context, index) {
                              return Stack(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: InkWell(
                                      onTap: () => _showImageFull(imagePaths[index]),
                                      child: Image.file(File(imagePaths[index]), fit: BoxFit.cover),
                                    ),
                                  ),
                                  Positioned(
                                    right: 4,
                                    top: 0,
                                    child: InkWell(
                                      onTap: () {
                                        setDialogState(() => imagePaths.removeAt(index));
                                      },
                                      child: const CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.black54,
                                        child: Icon(Icons.close, size: 12, color: Colors.white),
                                      ),
                                    ),
                                  )
                                ],
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          const XTypeGroup typeGroup = XTypeGroup(
                            label: 'Images',
                            extensions: ['jpg', 'png', 'jpeg'],
                          );
                          final List<XFile> files = await openFiles(acceptedTypeGroups: [typeGroup]);
                          if (files.isNotEmpty) {
                            setDialogState(() {
                              imagePaths.addAll(files.map((f) => f.path));
                            });
                          }
                        },
                        icon: const Icon(Icons.add_a_photo, size: 16),
                        label: Text(lang.translate('add_images')),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          shape: const RoundedRectangleBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Scheduling Row
                      Text(lang.translate('schedule_automation'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null && context.mounted) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(startDate ?? DateTime.now()),
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      startDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                    });
                                  }
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: lang.translate('start_time'),
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                                ),
                                child: Text(
                                  startDate != null ? DateFormat('MM/dd HH:mm').format(startDate!) : lang.translate('start_time'),
                                  style: TextStyle(color: startDate != null ? AppColors.textPrimary : Colors.grey),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? (startDate ?? DateTime.now()),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null && context.mounted) {
                                  final time = await showTimePicker(
                                    context: context,
                                    initialTime: TimeOfDay.fromDateTime(endDate ?? DateTime.now()),
                                  );
                                  if (time != null) {
                                    setDialogState(() {
                                      endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                    });
                                  }
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: lang.translate('end_time'),
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                                ),
                                child: Text(
                                  endDate != null ? DateFormat('MM/dd HH:mm').format(endDate!) : lang.translate('end_time'),
                                  style: TextStyle(color: endDate != null ? AppColors.textPrimary : Colors.grey),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Automation: App Launch
                      Text(lang.translate('automation'), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: appPathController,
                        decoration: InputDecoration(
                          hintText: "Path (e.g. /usr/bin/slack)",
                          labelText: lang.translate('app_path'),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          prefixIcon: const Icon(Icons.apps, size: 16),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.folder_open, size: 16),
                            onPressed: () async {
                              const XTypeGroup typeGroup = XTypeGroup(
                                label: 'Executables',
                              );
                              try {
                                 final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
                                 if (file != null) {
                                   appPathController.text = file.path;
                                 }
                              } catch (e) {
                                debugPrint('Error picking file: $e');
                              }
                            },
                          ),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TaskPriority>(
                              value: selectedPriority,
                              decoration: InputDecoration(
                                labelText: lang.translate('priority'),
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                              ),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: tagsController,
                        decoration: InputDecoration(
                          hintText: lang.translate('tags'),
                          labelText: lang.translate('tags'),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          prefixIcon: const Icon(Icons.tag, size: 16),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(lang.translate('cancel')),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.isNotEmpty) {
                      List<String> tags = tagsController.text
                          .split(',')
                          .map((e) => e.trim())
                          .where((e) => e.isNotEmpty)
                          .toList();
                      
                      final newTask = Task.create(
                        title: titleController.text,
                        description: descriptionController.text,
                        priority: selectedPriority,
                        tags: tags,
                        startDate: startDate,
                        endDate: endDate,
                        appPath: appPathController.text.isNotEmpty ? appPathController.text : null,
                        imagePaths: imagePaths,
                      );
                      setState(() {
                        column.tasks.add(newTask);
                      });
                      _saveProject();
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: Text(lang.translate('add'), style: const TextStyle(color: Colors.black)),
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
                    if (task.imagePaths.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.image, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        "${task.imagePaths.length}",
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ],
                ),
                if (task.imagePaths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: task.imagePaths.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white10),
                          ),
                          child: InkWell(
                            onTap: () => _showImageFull(task.imagePaths[index]),
                            child: Image.file(File(task.imagePaths[index]), fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
                ],
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
    final descriptionController = TextEditingController(text: task.description);
    final tagsController = TextEditingController(text: task.tags.join(', '));
    final appPathController = TextEditingController(text: task.appPath);
    TaskPriority selectedPriority = task.priority;
    DateTime? startDate = task.startDate;
    DateTime? endDate; // Should have been task.endDate, fixing while here
    if (task.endDate != null) endDate = task.endDate;
    List<String> imagePaths = List.from(task.imagePaths);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: const RoundedRectangleBorder(),
              title: const Text("Edit Task"),
              content: SizedBox(
                width: 500, // Wider for detailed fields
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Title
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          hintText: "Task Title",
                          labelText: "Title",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),
                      
                      // Description
                      TextField(
                        controller: descriptionController,
                        maxLines: 8, // Made larger
                        decoration: const InputDecoration(
                          hintText: "Detailed description...",
                          labelText: "Description",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          alignLabelWithHint: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      // Images section
                      const Text("Images", style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (imagePaths.isNotEmpty)
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: imagePaths.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        margin: const EdgeInsets.only(right: 8),
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.white24),
                                        ),
                                        child: InkWell(
                                          onTap: () => _showImageFull(imagePaths[index]),
                                          child: Image.file(File(imagePaths[index]), fit: BoxFit.cover),
                                        ),
                                      ),
                                      Positioned(
                                        right: 4,
                                        top: 0,
                                        child: InkWell(
                                          onTap: () {
                                            setDialogState(() => imagePaths.removeAt(index));
                                          },
                                          child: const CircleAvatar(
                                            radius: 10,
                                            backgroundColor: Colors.black54,
                                            child: Icon(Icons.close, size: 12, color: Colors.white),
                                          ),
                                        ),
                                      )
                                    ],
                                  );
                                },
                              ),
                            ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () async {
                              const XTypeGroup typeGroup = XTypeGroup(
                                label: 'Images',
                                extensions: ['jpg', 'png', 'jpeg'],
                              );
                              final List<XFile> files = await openFiles(acceptedTypeGroups: [typeGroup]);
                              if (files.isNotEmpty) {
                                setDialogState(() {
                                  imagePaths.addAll(files.map((f) => f.path));
                                });
                              }
                            },
                            icon: const Icon(Icons.add_a_photo, size: 16),
                            label: const Text("Add Images"),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              foregroundColor: AppColors.primary,
                              shape: const RoundedRectangleBorder(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Scheduling Row
                      const Text("Schedule (Automation)", style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: startDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  if (context.mounted) {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(startDate ?? DateTime.now()),
                                    );
                                    if (time != null) {
                                      setDialogState(() {
                                        startDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                      });
                                    }
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Start Time", style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                    const SizedBox(height: 4),
                                    Text(
                                      startDate != null ? DateFormat('MM/dd HH:mm').format(startDate!) : "Set Start Time",
                                      style: TextStyle(color: startDate != null ? AppColors.textPrimary : Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: endDate ?? (startDate ?? DateTime.now()),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  if (context.mounted) {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.fromDateTime(endDate ?? DateTime.now()),
                                    );
                                    if (time != null) {
                                      setDialogState(() {
                                        endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                                      });
                                    }
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white24),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("End Time", style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                                    const SizedBox(height: 4),
                                    Text(
                                      endDate != null ? DateFormat('MM/dd HH:mm').format(endDate!) : "Set End Time",
                                      style: TextStyle(color: endDate != null ? AppColors.textPrimary : Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Automation: App Launch
                      const Text("Automation", style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: appPathController,
                        decoration: InputDecoration(
                          hintText: "/path/to/application (e.g. /usr/bin/slack)",
                          labelText: "App Path Execution",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          prefixIcon: const Icon(Icons.apps, size: 16),
                          border: const OutlineInputBorder(borderRadius: BorderRadius.zero),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.folder_open, size: 16),
                            onPressed: () async {
                              const XTypeGroup typeGroup = XTypeGroup(
                                label: 'Executables',
                              );
                              final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);
                              if (file != null) {
                                appPathController.text = file.path;
                              }
                            },
                          ),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<TaskPriority>(
                              value: selectedPriority,
                              decoration: const InputDecoration(
                                labelText: "Priority",
                                floatingLabelBehavior: FloatingLabelBehavior.always,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                              ),
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      TextField(
                        controller: tagsController,
                        decoration: const InputDecoration(
                          hintText: "Tags (comma separated)",
                          labelText: "Tags",
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          prefixIcon: Icon(Icons.tag, size: 16),
                          border: OutlineInputBorder(borderRadius: BorderRadius.zero),
                        ),
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
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
                         task.description = descriptionController.text;
                         task.priority = selectedPriority;
                         task.tags = tags;
                         task.startDate = startDate;
                         task.endDate = endDate;
                         task.appPath = appPathController.text.isEmpty ? null : appPathController.text;
                         task.imagePaths = imagePaths;
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
