import 'package:uuid/uuid.dart';

enum TaskPriority { low, medium, high }

class Task {
  final String id;
  String title;
  String description;
  DateTime createdAt;
  DateTime? dueDate;
  TaskPriority priority;
  List<String> tags;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.tags = const [],
  });

  factory Task.create({
    required String title,
    String description = '',
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    List<String> tags = const [],
  }) {
    return Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      createdAt: DateTime.now(),
      dueDate: dueDate,
      priority: priority,
      tags: tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'dueDate': dueDate?.toIso8601String(),
        'priority': priority.index,
        'tags': tags,
      };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      createdAt: DateTime.parse(json['createdAt']),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: TaskPriority.values[json['priority'] ?? 1],
      tags: List<String>.from(json['tags'] ?? []),
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
