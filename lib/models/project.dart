import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  String title;
  String description;
  DateTime createdAt;
  DateTime? dueDate;
  DateTime? startDate; // For automation start time
  DateTime? endDate;   // For automation end time
  TaskPriority priority;
  List<String> tags;
  String? appPath;     // For launching apps
  List<String> imagePaths;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.dueDate,
    this.startDate,
    this.endDate,
    this.priority = TaskPriority.medium,
    this.tags = const [],
    this.appPath,
    this.imagePaths = const [],
  });

  factory Task.create({
    required String title,
    String description = '',
    DateTime? dueDate,
    DateTime? startDate,
    DateTime? endDate,
    TaskPriority priority = TaskPriority.medium,
    List<String> tags = const [],
    String? appPath,
    List<String> imagePaths = const [],
  }) {
    return Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      startDate: startDate,
      endDate: endDate,
      priority: priority,
      tags: tags,
      appPath: appPath,
      imagePaths: imagePaths,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'startDate': startDate?.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'priority': priority.index,
        'tags': tags,
        'appPath': appPath,
        'imagePaths': imagePaths,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      priority: TaskPriority.values[json['priority'] ?? 1],
      tags: List<String>.from(json['tags'] ?? []),
      appPath: json['appPath'],
      imagePaths: List<String>.from(json['imagePaths'] ?? []),
    );
  }
}

class KanbanColumn {
  final String id;
  String title;
  List<Task> tasks;

  KanbanColumn({
    required this.id,
    required this.title,
    required this.tasks,
  });

  factory KanbanColumn.create({required String title}) {
    return KanbanColumn(
      id: const Uuid().v4(),
      title: title,
      tasks: [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'tasks': tasks.map((t) => t.toJson()).toList(),
      };

  factory KanbanColumn.fromJson(Map<String, dynamic> json) {
    return KanbanColumn(
      id: json['id'],
      title: json['title'],
      tasks: (json['tasks'] as List).map((t) => Task.fromJson(t)).toList(),
    );
  }
}

class Project {
  final String id;
  String title;
  List<KanbanColumn> columns;
  DateTime createdAt;

  Project({
    required this.id,
    required this.title,
    required this.columns,
    required this.createdAt,
  });

  factory Project.create({required String title}) {
    // Default columns
    return Project(
      id: const Uuid().v4(),
      title: title,
      columns: [
        KanbanColumn.create(title: "To Do"),
        KanbanColumn.create(title: "In Progress"),
        KanbanColumn.create(title: "Done"),
      ],
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'columns': columns.map((c) => c.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      title: json['title'],
      columns: (json['columns'] as List)
          .map((c) => KanbanColumn.fromJson(c))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }
}
