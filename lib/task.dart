// lib/task.dart
enum Priority { low, medium, high }

/// Classe abstraite représentant une tâche générique.
///
/// Les sous-classes doivent fournir leur propre sérialisation JSON
/// ainsi qu'un comportement spécifique pour le calcul d'urgence
/// (`urgencyScore`) et le résumé affiché (`summary`), ce qui illustre
/// un vrai polymorphisme de comportement (et pas seulement de données).
abstract class Task {
  String id;
  String title;
  Priority priority;
  DateTime? dueDate;
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    required this.priority,
    this.dueDate,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson();

  /// Score numérique utilisé pour trier/prioriser les tâches.
  /// Chaque sous-classe calcule ce score différemment.
  int get urgencyScore;

  /// Résumé texte de la tâche, formaté différemment selon le type.
  String summary();

  /// Marque la tâche comme terminée. Peut être redéfini par les
  /// sous-classes pour ajouter un comportement spécifique.
  void markAsCompleted() {
    isCompleted = true;
  }
}

class UrgentTask extends Task {
  String notes;

  UrgentTask({
    required super.id,
    required super.title,
    required super.priority,
    super.dueDate,
    super.isCompleted,
    required this.notes,
  });

  /// Une tâche urgente reçoit toujours un bonus de +10 par rapport à
  /// une tâche standard de même priorité : elle doit systématiquement
  /// remonter en tête de liste.
  @override
  int get urgencyScore => priority.index + 10;

  @override
  String summary() {
    final status = isCompleted ? '[X]' : '[ ]';
    return '$status $id - $title (URGENT, priorité : ${priority.name}) '
        '↳ Notes : $notes';
  }

  /// Comportement spécifique : lorsqu'une tâche urgente est terminée,
  /// on trace l'information dans les notes plutôt que de simplement
  /// basculer un booléen comme le fait la classe de base.
  @override
  void markAsCompleted() {
    super.markAsCompleted();
    if (!notes.contains('(terminée)')) {
      notes = '$notes (terminée)';
    }
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'type': 'urgent',
        'notes': notes,
      };
}

class StandardTask extends Task {
  StandardTask({
    required super.id,
    required super.title,
    required super.priority,
    super.dueDate,
    super.isCompleted,
  });

  /// Une tâche standard garde simplement le poids de sa priorité.
  @override
  int get urgencyScore => priority.index;

  @override
  String summary() {
    final status = isCompleted ? '[X]' : '[ ]';
    return '$status $id - $title (priorité : ${priority.name})';
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'type': 'standard',
      };
}
