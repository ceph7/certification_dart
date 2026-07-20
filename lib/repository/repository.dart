// lib/repository.dart
abstract class Repository<T> {
  void add(T item);
  void remove(String id);
  List<T> getAll();
  Future<void> save();
  Future<void> load();
}