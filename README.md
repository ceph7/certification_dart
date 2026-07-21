<!-- A sample command-line application with an entrypoint in `bin/`, library code
in `lib/`, and example unit test in `test/`. -->
# certification_dart
# Task Manager CLI

Apph
dart pub get
​```

## Utilisation

​```bash
dart run bin/main.dart add "Titre de la tâche"
dart run bin/main.dart list
dart run bin/main.dart complete 1
dart run bin/main.dart remove 1
​```

## Lancer les tests

​```bash
dart test
​```

## Structure du projet

- `models/` : `Task`, `UrgentTask`, `StandardTask`
- `repository/` : `TaskManager` (implémente `Repository<T>`)
- `exceptions/` : exceptions personnalisées
- `test/` : tests unitaireslication CLI de gestion de tâches en Dart.

## Installation

​```bas