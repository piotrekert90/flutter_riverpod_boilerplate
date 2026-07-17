import 'package:isar_community/isar.dart';

import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../mappers/todo_mapper.dart';
import '../models/todo_model.dart';

/// Default implementation of [TodoRepository] backed by Isar.
/// Implementation of [TodoRepository] using Isar.
class TodoRepositoryImpl implements TodoRepository {
  /// Creates a new [TodoRepositoryImpl] with the given Isar instance.
  TodoRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Stream<List<Todo>> watchAll() {
    return _isar.todoModels
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .map((models) => models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<Todo?> watchById(int id) {
    return _isar.todoModels
        .watchObject(id, fireImmediately: true)
        .map((model) => model?.toEntity());
  }

  @override
  Future<List<Todo>> getAll() async {
    final models = await _isar.todoModels
        .where()
        .sortByCreatedAtDesc()
        .findAll();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<(bool success, String? errorMessage)> add({
    required String title,
  }) async {
    try {
      final model = TodoModel()
        ..title = title.trim()
        ..createdAt = DateTime.now();

      await _isar.writeTxn(() async {
        await _isar.todoModels.put(model);
      });
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }

  @override
  Future<(bool success, String? errorMessage)> toggleCompleted({
    required int id,
  }) async {
    try {
      await _isar.writeTxn(() async {
        final model = await _isar.todoModels.get(id);
        if (model == null) {
          return;
        }

        model.isCompleted = !model.isCompleted;
        await _isar.todoModels.put(model);
      });
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }

  @override
  Future<(bool success, String? errorMessage)> delete({required int id}) async {
    try {
      await _isar.writeTxn(() async {
        await _isar.todoModels.delete(id);
      });
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }
}
