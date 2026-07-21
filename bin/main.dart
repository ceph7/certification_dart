import 'dart:io';
import 'package:task_manager/models/task_manager.dart';
import 'package:task_manager/task.dart';
import 'package:task_manager/exceptions/exceptions.dart';

Future<void> main() async {
  final cli = TaskManagerCli(TaskManager());
  await cli.run();
}

/// Encapsule toute la logique du menu CLI, une méthode par action.
/// Extrait de `main()` pour améliorer la lisibilité et la maintenabilité.
class TaskManagerCli {
  final TaskManager manager;

  TaskManagerCli(this.manager);

  Future<void> run() async {
    await manager.load();

    var running = true;
    while (running) {
      _printMenu();
      final choice = stdin.readLineSync();

      try {
        switch (choice) {
          case '1':
            await _addTask();
            break;
          case '2':
            _listTasks();
            break;
          case '3':
            await _completeTask();
            break;
          case '4':
            await _removeTask();
            break;
          case '5':
            print('Au revoir et merci !');
            running = false;
            break;
          default:
            print('Option invalide');
        }
      } on TaskNotFoundException catch (e) {
        print(e);
      } on StorageException catch (e) {
        print(e);
      } catch (e) {
        print('Une erreur inattendue est survenue : $e');
      }
    }
  }

  void _printMenu() {
    stdout.writeln('BIENVENUE DANS LE GESTIONNAIRE DE TACHES.');
    stdout.writeln('1. Ajouter une tâche');
    stdout.writeln('2. Lister les tâches');
    stdout.writeln('3. Marquer une tâche comme terminée');
    stdout.writeln('4. Supprimer une tâche');
    stdout.writeln('5. Quitter');
    stdout.write('Choisissez une option : ');
  }

  Future<void> _addTask() async {
    stdout.write('Titre :');
    final title = stdin.readLineSync() ?? '';

    stdout.write('Type de tâche (1 = standard, 2 = urgente) : ');
    final typeChoice = stdin.readLineSync();

    stdout.write('Priorite (low / medium / high) : ');
    final priorityStr = stdin.readLineSync()?.toLowerCase() ?? '';

    try {
      final priority = Priority.values.firstWhere(
        (e) => e.name == priorityStr,
        orElse: () => throw InvalidPriorityException(
            '"$priorityStr" n\'est pas une priorité valide. Utilise low, medium ou high.'),
      );

      stdout.write('Date limite (AAAA-MM-JJ), laisser vide si aucune : ');
      final dueDateStr = stdin.readLineSync() ?? '';
      final dueDate =
          dueDateStr.trim().isEmpty ? null : DateTime.parse(dueDateStr.trim());

      final id = DateTime.now().microsecondsSinceEpoch.toString();

      if (typeChoice == '2') {
        stdout.write('Notes (raison de l\'urgence) : ');
        final notes = stdin.readLineSync() ?? '';
        manager.add(UrgentTask(
          id: id,
          title: title,
          priority: priority,
          dueDate: dueDate,
          notes: notes,
        ));
      } else {
        manager.add(StandardTask(
          id: id,
          title: title,
          priority: priority,
          dueDate: dueDate,
        ));
      }

      await manager.save();
      print('Tache ajoutée !');
    } on InvalidPriorityException catch (e) {
      print(e);
    } on FormatException {
      print('Erreur de saisie : date invalide, utilise le format AAAA-MM-JJ.');
    }
  }

  void _listTasks() {
    stdout.write('Trier par (1 = priorité, 2 = date limite, 3 = urgence) : ');
    final sortChoice = stdin.readLineSync();

    final List<Task> tasks;
    switch (sortChoice) {
      case '2':
        tasks = manager.getSortedByDueDate();
        break;
      case '3':
        tasks = manager.getSortedByUrgency();
        break;
      default:
        tasks = manager.getSortedByPriority();
    }

    if (tasks.isEmpty) {
      print('Aucune tache');
      return;
    }

    for (final task in tasks) {
      print(task.summary());
    }
  }

  Future<void> _completeTask() async {
    stdout.write('ID de la tâche à terminer :');
    final id = stdin.readLineSync() ?? '';
    manager.completeTask(id);
    await manager.save();
    print('Tache marquée comme terminée !');
  }

  Future<void> _removeTask() async {
    stdout.write('ID de la tâche à supprimer :');
    final id = stdin.readLineSync() ?? '';
    manager.remove(id);
    await manager.save();
    print('Tâche supprimée !');
  }
}
