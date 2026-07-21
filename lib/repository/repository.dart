/// Interface explicite (Dart 3 `interface class`) définissant le contrat
/// générique d'un dépôt de données. Contrairement à une simple classe
/// abstraite, `interface class` interdit tout héritage d'implémentation :
/// les classes concrètes doivent utiliser `implements` et fournir leur
/// propre code pour chaque méthode.
abstract interface class Repository<T> {
  void add(T item);
  void remove(String id);
  List<T> getAll();
  Future<void> save();
  Future<void> load();
}
