import 'dart:io';
import 'package:task_manager/models/task_manager.dart';
import 'package:task_manager/task.dart';
import 'package:task_manager/exceptions/exceptions.dart';

/// Point d'entrée. Deux modes sont supportés :
///
/// - **Mode interactif** (aucun argument) : menu classique.
/// - **Mode ligne de commande** (arguments fournis) :
///     dart run bin/main.dart add "Titre" --type=urgent --priority=high --due=2026-08-01 --notes="raison"
///     dart run bin/main.dart list --sort=urgency
///     dart run bin/main.dart complete <id>
///     dart run bin/main.dart remove <id>
Future<void> main(List<String> arguments) async {
  final manager = TaskManager();
  await manager.load();

  if (arguments.isNotEmpty) {
    await CliArgumentsRunner(manager).run(arguments);
    return;
  }

  final cli = TaskManagerCli(manager);
  await cli.run();
}

/// Gère l'exécution en mode "arguments de ligne de commande" (non interactif),
/// pour un usage scriptable typique d'un outil CLI.
class CliArgumentsRunner {
  final TaskManager manager;

  CliArgumentsRunner(this.manager);

  Future<void> run(List<String> arguments) async {
    final command = arguments.first;
    final rest = arguments.skip(1).toList();
    final options = _parseOptions(rest);
    final positional = _positional(rest);

    try {
      switch (command) {
        case 'add':
          await _add(positional, options);
          break;
        case 'list':
          _list(options);
          break;
        case 'complete':
          await _complete(positional);
          break;
        case 'remove':
          await _remove(positional);
          break;
        default:
          print('Commande inconnue : $command');
          print('Commandes disponibles : add, list, complete, remove');
      }
    } on InvalidPriorityException catch (e) {
      print(e);
    } on FormatException {
      print('Erreur de saisie : date invalide, utilise le format AAAA-MM-JJ.');
    } on TaskNotFoundException catch (e) {
      print(e);
    }
  }

  Map<String, String> _parseOptions(List<String> args) {
    final options = <String, String>{};
    for (final arg in args) {
      if (arg.startsWith('--') && arg.contains('=')) {
        final idx = arg.indexOf('=');
        options[arg.substring(2, idx)] = arg.substring(idx + 1);
      }
    }
    return options;
  }

  List<String> _positional(List<String> args) =>
      args.where((a) => !a.startsWith('--')).toList();

  Future<void> _add(List<String> positional, Map<String, String> options) async {
    final title = positional.join(' ');
    if (title.isEmpty) {
      print('Usage : dart run bin/main.dart add "<titre>" '
          '[--type=standard|urgent] [--priority=low|medium|high] '
          '[--due=AAAA-MM-JJ] [--notes="..."]');
      return;
    }

    final priorityStr = options['priority'] ?? 'medium';
    final priority = Priority.values.firstWhere(
      (e) => e.name == priorityStr,
      orElse: () => throw InvalidPriorityException(
          '"$priorityStr" n\'est pas une priorité valide. Utilise low, medium ou high.'),
    );

    final dueStr = options['due'];
    final dueDate = (dueStr == null || dueStr.isEmpty) ? null : DateTime.parse(dueStr);
    final id = DateTime.now().microsecondsSinceEpoch.toString();

    if ((options['type'] ?? 'standard') == 'urgent') {
      manager.add(UrgentTask(
        id: id,
        title: title,
        priority: priority,
        dueDate: dueDate,
        notes: options['notes'] ?? '',
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
  }

  void _list(Map<String, String> options) {
    final sort = options['sort'] ?? 'priority';
    final List<Task> tasks;
    switch (sort) {
      case 'due':
        tasks = manager.getSortedByDueDate();
        break;
      case 'urgency':
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

  Future<void> _complete(List<String> positional) async {
    if (positional.isEmpty) {
      print('Usage : dart run bin/main.dart complete <id>');
      return;
    }
    manager.completeTask(positional.first);
    await manager.save();
    print('Tache marquée comme terminée !');
  }

  Future<void> _remove(List<String> positional) async {
    if (positional.isEmpty) {
      print('Usage : dart run bin/main.dart remove <id>');
      return;
    }
    manager.remove(positional.first);
    await manager.save();
    print('Tâche supprimée !');
  }
}

/// Encapsule la logique du menu CLI interactif, une méthode par action.
class TaskManagerCli {
  final TaskManager manager;

  TaskManagerCli(this.manager);

  Future<void> run() async {
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
