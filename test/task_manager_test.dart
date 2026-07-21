// test/task_manager_test.dart
import 'dart:io';
import 'package:test/test.dart';
import 'package:task_manager/models/task_manager.dart';
import 'package:task_manager/task.dart';
import 'package:task_manager/exceptions/exceptions.dart';

// Persistable, ManageableTask, Task, UrgentTask, StandardTask sont tous
// exportés par package:task_manager/task.dart.

void main() {
  group('Tests du TaskManager', () {
    late TaskManager manager;
    const testFile = 'test_tasks.json';

    setUp(() {
      manager = TaskManager(filePath: testFile);
    });

    tearDown(() async {
      final file = File(testFile);
      if (await file.exists()) {
        await file.delete();
      }
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

    test('Trier les tâches par priorité (décroissant)', () {
      manager.add(StandardTask(id: '1', title: 'Basse', priority: Priority.low));
      manager.add(StandardTask(id: '2', title: 'Haute', priority: Priority.high));
      manager.add(StandardTask(id: '3', title: 'Moyenne', priority: Priority.medium));

      final sorted = manager.getSortedByPriority();
      expect(sorted.map((t) => t.id).toList(), ['2', '3', '1']);
    });

    test('Trier les tâches par date limite (les nulles en dernier)', () {
      manager.add(StandardTask(
          id: '1', title: 'Sans date', priority: Priority.low));
      manager.add(StandardTask(
          id: '2',
          title: 'Proche',
          priority: Priority.low,
          dueDate: DateTime(2026, 1, 1)));
      manager.add(StandardTask(
          id: '3',
          title: 'Lointaine',
          priority: Priority.low,
          dueDate: DateTime(2026, 6, 1)));

      final sorted = manager.getSortedByDueDate();
      expect(sorted.map((t) => t.id).toList(), ['2', '3', '1']);
    });

    test('Une UrgentTask a un score d\'urgence supérieur à une StandardTask de même priorité', () {
      final urgent = UrgentTask(
          id: '1', title: 'Urgente', priority: Priority.low, notes: 'car urgent');
      final standard =
          StandardTask(id: '2', title: 'Standard', priority: Priority.low);

      expect(urgent.urgencyScore, greaterThan(standard.urgencyScore));
    });

    test('Terminer une UrgentTask ajoute une trace dans les notes (comportement redéfini)', () {
      final task = UrgentTask(
          id: '1', title: 'Urgente', priority: Priority.high, notes: 'raison');
      manager.add(task);
      manager.completeTask('1');

      final saved = manager.getAll().first as UrgentTask;
      expect(saved.isCompleted, isTrue);
      expect(saved.notes, contains('(terminée)'));
    });

    test('Task, ManageableTask, UrgentTask forment bien une hiérarchie à plusieurs niveaux', () {
      final task = UrgentTask(id: '1', title: 'X', priority: Priority.low, notes: 'n');
      expect(task, isA<Task>());
      expect(task, isA<ManageableTask>());
      expect(task, isA<Persistable>());
    });

    test('toJson() (interface Persistable) produit les bons champs pour chaque type', () {
      final urgent = UrgentTask(
          id: '1', title: 'Urgente', priority: Priority.high, notes: 'critique');
      final standard =
          StandardTask(id: '2', title: 'Standard', priority: Priority.low);

      expect(urgent.toJson()['type'], 'urgent');
      expect(urgent.toJson()['notes'], 'critique');
      expect(standard.toJson()['type'], 'standard');
      expect(standard.toJson().containsKey('notes'), isFalse);
    });

    test('Sauvegarder puis recharger les tâches conserve leurs données (JSON)', () async {
      manager.add(StandardTask(id: '1', title: 'Standard', priority: Priority.medium));
      manager.add(UrgentTask(
          id: '2', title: 'Urgente', priority: Priority.high, notes: 'critique'));
      await manager.save();

      final reloaded = TaskManager(filePath: testFile);
      await reloaded.load();

      expect(reloaded.getAll().length, 2);
      final urgent = reloaded.getAll().firstWhere((t) => t.id == '2') as UrgentTask;
      expect(urgent.notes, 'critique');
      expect(urgent.priority, Priority.high);
    });
  });
}
