
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../providers/data_provider.dart';

class TaskAutomationService {
  final DataProvider _dataProvider;
  Timer? _timer;

  TaskAutomationService(this._dataProvider) {
    _startService();
  }

  void _startService() {
    // Check every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _checkTasks();
    });
  }

  void _checkTasks() {
    final now = DateTime.now();
    bool needsSave = false;

    for (var project in _dataProvider.projects) {
      if (project.columns.isEmpty) continue;

      // We need to iterate carefully since we might move items
      // A simple approach: Identify tasks to move/execute first
      
      // Flatten tasks to finding them easily 
      // Note: Moving tasks complicated iteration if we modify the list we are iterating.
      // So we will collect actions first.
      
      List<_TaskAction> actions = [];

      for (int colIndex = 0; colIndex < project.columns.length; colIndex++) {
        final column = project.columns[colIndex];
        
        for (var task in column.tasks) {
          // Check Start Time -> Move to In Progress (Index 1) & Launch App
          if (task.startDate != null) {
            // If current time is past start time (within a small window or just past)
            // AND task is not already in In Progress (or Done)
            // Assuming "In Progress" is index 1.
            
            // To avoid repeated execution, we might need a flag or check column.
            // Simplified logic: If task.startDate passed and it is in "To Do" (Index 0), move to "In Progress"
            final isStarted = now.isAfter(task.startDate!);
            if (isStarted && colIndex == 0) {
               actions.add(_TaskAction(task, _ActionType.moveToInProgress, project));
            }
            
            // Launch App Logic
            // We need to ensure we only launch it ONCE. 
            // We can check if it's within the last minute or add a "executed" flag in memory?
            // "Simply avisara" logic or just launch? "lo abrira"
            // For simplicity and statelessness, checking if we just moved it is a good trigger.
            // OR we can rely on the transition validation.
            
            if (isStarted && task.appPath != null && task.appPath!.isNotEmpty && colIndex == 0) {
               actions.add(_TaskAction(task, _ActionType.launchApp, project));
            }
          }

          // Check End Time -> Move to Done (Index 2)
          if (task.endDate != null) {
            final isEnded = now.isAfter(task.endDate!);
             // If ended and not in Done (Index 2)
            if (isEnded && colIndex != 2) {
               actions.add(_TaskAction(task, _ActionType.moveToDone, project));
            }
          }
        }
      }

      // Execute Actions
      for (var action in actions) {
        if (action.type == _ActionType.moveToInProgress) {
          _moveTaskToColumn(action.project, action.task, 1); // 1 = In Progress
          needsSave = true;
          print("Auto-moving task '${action.task.title}' to In Progress");
        } else if (action.type == _ActionType.moveToDone) {
          _moveTaskToColumn(action.project, action.task, 2); // 2 = Done
          needsSave = true;
          print("Auto-moving task '${action.task.title}' to Done");
        } else if (action.type == _ActionType.launchApp) {
          _launchApp(action.task.appPath!);
        }
      }
    }

    if (needsSave) {
      _dataProvider.notifyListeners(); // Trigger UI update
      _dataProvider.saveData(); // Persist changes
    }
  }

  void _moveTaskToColumn(Project project, Task task, int targetColIndex) {
    if (project.columns.length <= targetColIndex) return;

    // Find and remove from old column
    bool removed = false;
    for (var col in project.columns) {
      if (col.tasks.contains(task)) {
        col.tasks.remove(task);
        removed = true;
        break;
      }
    }

    if (removed) {
      project.columns[targetColIndex].tasks.add(task);
    }
  }

  Future<void> _launchApp(String path) async {
    print("Automation: Processing path: $path");
    final file = File(path);
    if (!file.existsSync()) {
      print("Error: File not found at $path");
      return;
    }

    bool isExecutable = false;

    // Detect if executable
    if (Platform.isWindows) {
      final ext = path.toLowerCase();
      if (ext.endsWith('.exe') || ext.endsWith('.bat') || ext.endsWith('.cmd') || ext.endsWith('.com')) {
        isExecutable = true;
      }
    } else {
      // Linux/MacOS: Check executable permission
      try {
        final result = await Process.run('test', ['-x', path]);
        if (result.exitCode == 0) {
          isExecutable = true;
        }
      } catch (e) {
        // Fallback or ignore
      }
    }

    if (isExecutable) {
      print("Identified as Executable/Program. Running...");
      try {
        await Process.start(path, [], mode: ProcessStartMode.detached);
      } catch (e) {
        print("Failed to run as executable: $e. Fallback to system open.");
        await _openSystemDefault(path);
      }
    } else {
      print("Identified as Document/File. Opening...");
      await _openSystemDefault(path);
    }
  }

  Future<void> _openSystemDefault(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', path], runInShell: true);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path], runInShell: true);
      }
    } catch (e) {
      print("Error opening file: $e");
    }
  }

  void dispose() {
    _timer?.cancel();
  }
}

enum _ActionType { moveToInProgress, moveToDone, launchApp }

class _TaskAction {
  final Task task;
  final _ActionType type;
  final Project project;

  _TaskAction(this.task, this.type, this.project);
}
