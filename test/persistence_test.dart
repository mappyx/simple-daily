import 'package:flutter_test/flutter_test.dart';
import 'package:simple_daily/models/note.dart';
import 'package:simple_daily/models/project.dart';

void main() {
  group('Data Models Test', () {
    test('Note serialization', () {
      final note = Note.create(title: 'Test Note', content: 'Content');
      final json = note.toJson();
      final fromJson = Note.fromJson(json);
      
      expect(fromJson.id, note.id);
      expect(fromJson.title, 'Test Note');
    });

    test('Project serialization', () {
      final project = Project.create(title: 'Test Project');
      expect(project.columns.length, 3);
      
      final task = Task.create(title: 'Task 1');
      project.columns[0].tasks.add(task);
      
      final json = project.toJson();
      final fromJson = Project.fromJson(json);
      
      expect(fromJson.columns[0].tasks.length, 1);
      expect(fromJson.columns[0].tasks[0].title, 'Task 1');
    });
  });
}
