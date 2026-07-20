// test/task_manager_test.dart
import 'package:test/test.dart';
import 'package:task_manager/models/task_manager.dart';
import 'package:task_manager/task.dart';
import 'package:task_manager/exceptions/exceptions.dart';

void main() {
  group('Tests du TaskManager', () {
    late TaskManager manager;

    setUp(() {
      manager = TaskManager(filePath: 'test_tasks.json');
    });

    test('Ajouter une tâche', () {
      final task = StandardTask(id: '1', title: 'Test 1', priority: Priority.medium);
      manager.add(task);
      expect(manager.getAll().length, 1);
    });

    test('Marquer une tâche comme terminée', () {
      final task = StandardTask(id: '1', title: 'Test 1', priority: Priority.medium);
      manager.add(task);
      manager.completeTask('1');
      expect(manager.getAll().first.isCompleted, isTrue);
    });

    test('Lever une exception si la tâche à terminer n\'existe pas', () {
      expect(
        () => manager.completeTask('999'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });

    test('Supprimer une tâche', () {
      final task = StandardTask(id: '1', title: 'Test 1', priority: Priority.medium);
      manager.add(task);
      manager.remove('1');
      expect(manager.getAll().isEmpty, isTrue);
    });

    test('Lever une exception si la tâche à supprimer n\'existe pas', () {
      expect(
        () => manager.remove('999'),
        throwsA(isA<TaskNotFoundException>()),
      );
    });
  });
}