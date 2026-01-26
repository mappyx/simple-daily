import 'package:flutter_test/flutter_test.dart';
import 'package:simple_daily/models/project.dart';

void main() {
  group('Phase 2 Models Test', () {
    test('Task Priority and Tags serialization', () {
      final task = Task.create(
        title: 'Priority Task',
        priority: TaskPriority.high,
        tags: ['urgent', 'work'],
      );
      
      final json = task.toJson();
      final fromJson = Task.fromJson(json);
      
      expect(fromJson.priority, TaskPriority.high);
      expect(fromJson.tags.length, 2);
      expect(fromJson.tags, contains('urgent'));
      expect(fromJson.tags, contains('work'));
    });

    test('Default Task values', () {
      final task = Task.create(title: 'Simple Task');
      expect(task.priority, TaskPriority.medium);
      expect(task.tags, isEmpty);
    });
  });
}
