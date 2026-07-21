// lib/task.dart
enum Priority { low, medium, high }

/// Interface explicite (Dart 3 `interface class`) : tout type qui
/// l'implémente s'engage à fournir sa propre méthode `toJson()`,
/// sans hériter d'aucune implémentation par défaut. C'est une vraie
/// interface au sens strict, distincte d'une classe abstraite classique.
abstract interface class Persistable {
  Map<String, dynamic> toJson();
}

/// Classe abstraite représentant une tâche générique.
///
/// Les sous-classes doivent fournir un comportement spécifique pour
/// le calcul d'urgence (`urgencyScore`) et le résumé affiché
/// (`summary`), ce qui illustre un vrai polymorphisme de comportement
/// (et pas seulement de données).
abstract class Task implements Persistable {
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

  /// Exigé par l'interface `Persistable`. Chaque sous-classe finale
  /// (`UrgentTask`, `StandardTask`) fournit sa propre sérialisation.
  @override
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

/// Classe intermédiaire qui approfondit la hiérarchie d'héritage :
///
///   Task  →  ManageableTask  →  UrgentTask / StandardTask
///
/// Elle implémente explicitement l'interface `Persistable` et
/// centralise la partie commune de la sérialisation JSON (`baseJson`),
/// que chaque sous-classe finale complète ensuite avec ses propres champs.
abstract class ManageableTask extends Task {
  ManageableTask({
    required super.id,
    required super.title,
    required super.priority,
    super.dueDate,
    super.isCompleted,
  });

  /// Construit le socle JSON commun à toutes les tâches. Les
  /// sous-classes l'utilisent puis y ajoutent leurs champs propres.
  Map<String, dynamic> baseJson(String type) => {
        'id': id,
        'title': title,
        'priority': priority.name,
        'dueDate': dueDate?.toIso8601String(),
        'isCompleted': isCompleted,
        'type': type,
      };
}

class UrgentTask extends ManageableTask {
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
        ...baseJson('urgent'),
        'notes': notes,
      };
}

class StandardTask extends ManageableTask {
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
  Map<String, dynamic> toJson() => baseJson('standard');
}
