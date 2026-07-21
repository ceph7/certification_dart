class TaskNotFoundException implements Exception{

final String message;

TaskNotFoundException(this.message);

@override
 
 String toString() => 'Erreur : $message';
}

class StorageException implements Exception{

  final String message;

  StorageException(this.message);


  @override
  String toString() => 'Erreur de stockage : $message';
}

class InvalidPriorityException implements Exception{
  final String message;

  InvalidPriorityException(this.message);


  @override
  String toString() => 'Erreur de saisie : $message';
}