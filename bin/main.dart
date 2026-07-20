
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
      stdout.write('Priorite : (low ,  medidum ,high) : ');
      final priorityStr = stdin.readLineSync()?.toLowerCase() ?? 'medium';

      final priority = Priority.values.firstWhere((e) => e.name == priorityStr , 
      orElse: () => Priority.medium,);

      manager.add(StandardTask(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
         title: title, 
         priority: priority));
         await manager.save();
         print('Tache ajoutée !');
         break;


         case '2' :
         final tasks = manager.getSortedByPriority();
         if (tasks.isEmpty){
          print('Aucune tache');

         }
         else{
          for (var task in tasks){

            final status = task.isCompleted ? '[X]' : '[ ]';

            print('$status ${task.id} - ${task.title} (Priorité : ${task})');
      

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