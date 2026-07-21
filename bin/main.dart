
import 'dart:io';
import 'package:task_manager/models/task_manager.dart';
import 'package:task_manager/task.dart';
import 'package:task_manager/exceptions/exceptions.dart';



void main() async {

  final manager = TaskManager();

  await manager.load();

  while (true){
    stdout.writeln('BIENVENUE DANS LE GESTIONNAIRE DE TACHES.');
    stdout.writeln('1. Ajouter une tâche');
    stdout.writeln('2. Lister les tâches');
    stdout.writeln('3. Marquer une tâche comme terminée');
    stdout.writeln('4. Supprimer une tâche');
    stdout.writeln('5. Quitter');
    stdout.write('Choisissez une option : ');

     final choice = stdin.readLineSync();

     switch(choice){
      case '1':
      stdout.write('Titre :');
      final title = stdin.readLineSync() ?? '';
      stdout.write('Type de tâche (1 = standard, 2 = urgente) : ');
      final typeChoice = stdin.readLineSync();
      stdout.write('Priorite (low / medium / high) : ');
      final priorityStr = stdin.readLineSync()?.toLowerCase() ?? '';

      try{
      final priority = Priority.values.firstWhere((e) => e.name == priorityStr ,
      orElse: () => throw InvalidPriorityException('"$priorityStr" n\'est pas une priorité valide. Utilise low, medium ou high.'),);

      stdout.write('Date limite (AAAA-MM-JJ), laisser vide si aucune : ');
      final dueDateStr = stdin.readLineSync() ?? '';
      final dueDate = dueDateStr.trim().isEmpty ? null : DateTime.parse(dueDateStr.trim());

      if (typeChoice == '2'){
        stdout.write('Notes (raison de l\'urgence) : ');
        final notes = stdin.readLineSync() ?? '';
        manager.add(UrgentTask(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
          priority: priority,
          dueDate: dueDate,
          notes: notes));
      } else {
      manager.add(StandardTask(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
         title: title, 
         priority: priority,
         dueDate: dueDate));
      }
         await manager.save();
         print('Tache ajoutée !');
      } on InvalidPriorityException catch (e){
        print(e);
      } on FormatException{
        print('Erreur de saisie : date invalide, utilise le format AAAA-MM-JJ.');
      }
         break;


         case '2' :
         stdout.write('Trier par (1 = priorité, 2 = date limite) : ');
         final sortChoice = stdin.readLineSync();
         final tasks = sortChoice == '2'
          ? manager.getSortedByDueDate()
          : manager.getSortedByPriority();
         if (tasks.isEmpty){
          print('Aucune tache');

         }
         else{
          for (var task in tasks){

            final status = task.isCompleted ? '[X]' : '[ ]';
            final dueStr = task.dueDate == null ? 'aucune' : task.dueDate!.toIso8601String().split('T').first;
            final typeTag = task is UrgentTask ? 'URGENT' : 'standard';

            print('$status ${task.id} - ${task.title} (Priorité : ${task.priority.name} , Date limite : $dueStr, Type : $typeTag)');
            if (task is UrgentTask){
              print('     ↳ Notes : ${task.notes}');
            }
      

          }
         }
    break;


    case '3':
    stdout.write('ID de la tâche à terminer :');
    final id = stdin.readLineSync() ?? '';
    try{
      manager.completeTask(id);
      await manager.save();
      print('Tache marquée comme terminée !');
    } on TaskNotFoundException catch (e){
      print(e);
    }
break;


case '4':
stdout.write('ID de la tâche à supprimer :');
final id = stdin.readLineSync() ?? '';
try{

  manager.remove(id);
  await manager.save();
  print('Tâche supprimée !');

} on TaskNotFoundException catch(e){

  print(e);
}
 break;
    
    case '5':
    print('Au revoir et merci !');
    exit(0);


    default:
    print('Option invalide');


  }

   
  }
  
}