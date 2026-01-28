
import 'dart:async';
import 'dart:io';
import '../models/project.dart';
import '../providers/data_provider.dart';

class TaskAutomationService {
  final DataProvider _dataProvider;
  Timer? _timer;
  
  // Index of upcoming events sorted by time
  List<_TaskEvent> _eventIndex = [];

  TaskAutomationService(this._dataProvider) {
    _buildIndex();
    // Re-build index whenever data changes
    _dataProvider.addListener(_buildIndex);
    _startService();
  }

  void _startService() {
    // Still using a 1-minute timer but now it only checks the sorted index
    // which is O(1) for the check instead of O(N^2)
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _processEvents();
    });
  }

  /// Option B: Build a flat, sorted index of all time-relevant tasks
  void _buildIndex() {
    final List<_TaskEvent> newIndex = [];
    final now = DateTime.now();

    for (var project in _dataProvider.projects) {
      for (int colIndex = 0; colIndex < project.columns.length; colIndex++) {
        final column = project.columns[colIndex];
        for (var task in column.tasks) {
          // If task has a start date and is in TODO
          if (task.startDate != null && colIndex == 0) {
            newIndex.add(_TaskEvent(
              time: task.startDate!,
              type: _EventType.start,
              task: task,
              project: project,
            ));
          }
          // If task has an end date and is NOT in DONE
          if (task.endDate != null && colIndex != 2) {
            newIndex.add(_TaskEvent(
              time: task.endDate!,
              type: _EventType.end,
              task: task,
              project: project,
            ));
          }
        }
      }
    }

    // Sort by time
    newIndex.sort((a, b) => a.time.compareTo(b.time));
    _eventIndex = newIndex;
  }

  /// Option B: Efficient event processing using the index
  void _processEvents() {
    if (_eventIndex.isEmpty) return;

    final now = DateTime.now();
    bool changed = false;
    
    // Create a list of events to execute now
    // Since index is sorted, we only check elements from the start
    int eventsExecuted = 0;
    
    for (var event in _eventIndex) {
      if (now.isAfter(event.time)) {
        _executeEvent(event);
        eventsExecuted++;
        changed = true;
      } else {
        break; // No more events due yet
      }
    }

    if (changed) {
      // Remove executed events from index
      _eventIndex.removeRange(0, eventsExecuted);
      
      _dataProvider.notifyListeners();
      // Option C: Use debounced save instead of immediate write
      _dataProvider.saveDataDebounced(); 
    }
  }

  void _executeEvent(_TaskEvent event) {
    if (event.type == _EventType.start) {
      print("Automation: Starting task '${event.task.title}'");
      _moveTaskToColumn(event.project, event.task, 1); // In Progress
      if (event.task.appPath != null) {
        _launchApp(event.task.appPath!);
      }
    } else {
      print("Automation: Completing task '${event.task.title}'");
      _moveTaskToColumn(event.project, event.task, 2); // Done
    }
  }

  void _moveTaskToColumn(Project project, Task task, int targetColIndex) {
    if (project.columns.length <= targetColIndex) return;

    // Find and remove from old column (still O(N) here but N is small per project)
    for (var col in project.columns) {
      if (col.tasks.contains(task)) {
        col.tasks.remove(task);
        break;
      }
    }
    project.columns[targetColIndex].tasks.add(task);
  }

  Future<void> _launchApp(String path) async {
    final file = File(path);
    if (!file.existsSync()) return;

    bool isExecutable = false;
    if (Platform.isWindows) {
      final ext = path.toLowerCase();
      isExecutable = ext.endsWith('.exe') || ext.endsWith('.bat') || ext.endsWith('.cmd');
    } else {
      try {
        final result = await Process.run('test', ['-x', path]);
        isExecutable = result.exitCode == 0;
      } catch (_) {}
    }

    try {
      if (isExecutable) {
        await Process.start(path, [], mode: ProcessStartMode.detached);
      } else {
        if (Platform.isWindows) {
          await Process.run('cmd', ['/c', 'start', '', path], runInShell: true);
        } else if (Platform.isLinux) {
          await Process.run('xdg-open', [path], runInShell: true);
        } else if (Platform.isMacOS) {
          await Process.run('open', [path], runInShell: true);
        }
      }
    } catch (e) {
      print("Automation Error: $e");
    }
  }

  void dispose() {
    _timer?.cancel();
    _dataProvider.removeListener(_buildIndex);
  }
}

enum _EventType { start, end }

class _TaskEvent {
  final DateTime time;
  final _EventType type;
  final Task task;
  final Project project;

  _TaskEvent({required this.time, required this.type, required this.task, required this.project});
}
