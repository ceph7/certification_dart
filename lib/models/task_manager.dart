import 'dart:convert';
import 'dart:io';
import 'package:task_manager/task.dart';
import 'package:task_manager/repository/repository.dart';
import 'package:task_manager/exceptions/exceptions.dart';


class TaskManager implements Repository<Task>{


      final List<Task> _tasks = [];

      final String filePath;


      TaskManager({this.filePath = 'tasks.json'});


   @override
      void add(Task task){
        _tasks.add(task);
      }
      
      @override
      void remove(String id){
        final initialLength = _tasks.length;

        _tasks.removeWhere((task) => task.id == id);
        if (_tasks.length == initialLength) {
          throw TaskNotFoundException('Tâche avec l\'ID $id n\'a pas été trouvée.');
        }
      }


      @override
      List<Task> getAll() => List.unmodifiable(_tasks);

      List<Task> getSortedByPriority(){

        final sortedList = List<Task>.from(_tasks);
        sortedList.sort((a, b) => 
        b.priority.index.compareTo(a.priority.index));
        return sortedList;
      }

      void completeTask(String id){

        final taskIndex = _tasks.indexWhere((task) => task.id == id);
        if (taskIndex == -1) {
          throw TaskNotFoundException('Tâche avec l\'ID $id n\'a pas été trouvée.');
        }
        _tasks[taskIndex].markAsCompleted();
      }
    @override
    Future<void> save() async {
        try {
      final file = File(filePath);
      final jsonList = _tasks.map((task) => task.toJson()).toList();

        await file.writeAsString(jsonEncode(jsonList));
      } catch (e) {
        throw StorageException('Erreur lors de la sauvegarde des tâches : $e');
      }
    }

    @override
    Future<void> load() async {
      try{

        final file = File(filePath);
        if (!await file.exists()) {
          return;
        }

        final contents = await file.readAsString();
        final List<dynamic> jsonList = jsonDecode(contents);

        _tasks.clear();
        for (var jsonItem in jsonList) {
          final type = jsonItem['type'];
          final priority = Priority.values.byName(jsonItem['priority']);
          final dueDate = jsonItem['dueDate'] != null ? DateTime.parse(jsonItem['dueDate']) : null;
          

          if (type == 'urgent') {
            _tasks.add(UrgentTask(
              id: jsonItem['id'],
              title: jsonItem['title'],
              priority: priority,
              dueDate: dueDate,
              isCompleted: jsonItem['isCompleted'],
              notes: jsonItem['notes'],
            ));
          } 
          else if (type == 'standard') {
            _tasks.add(StandardTask(
              id: jsonItem['id'],
              title: jsonItem['title'],
              priority: priority,
              dueDate: dueDate,
              isCompleted: jsonItem['isCompleted'],
            ));
          }
            else{
              throw StorageException('Type de tâche inconnu : $type');
            }
}
      }

      catch (e){
        
        throw StorageException('Erreur lors du chargement des tâches depuis le fichier');
      }

    }

    }