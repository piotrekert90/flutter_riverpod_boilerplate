import 'package:isar_community/isar.dart';

import '../../domain/entities/todo.dart';
import '../../domain/repositories/todo_repository.dart';
import '../mappers/todo_mapper.dart';
import '../models/todo_model.dart';

class TodoRepositoryImpl implements TodoRepository {
  TodoRepositoryImpl(this._isar);

  final Isar _isar;

  @override
  Stream<List<Todo>> watchAll() {
    return _isar.todoModels
        .where()
        .sortByCreatedAtDesc()
        .watch(fireImmediately: true)
        .map((models) => models.map((model) => model.toEntity()).toList());
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
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<void> add({required String title}) async {
    final model = TodoModel()
      ..title = title.trim()
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.todoModels.put(model);
    });
  }

  @override
  Future<void> toggleCompleted({required int id}) async {
    await _isar.writeTxn(() async {
      final model = await _isar.todoModels.get(id);
      if (model == null) {
        return;
      }

      model.isCompleted = !model.isCompleted;
      await _isar.todoModels.put(model);
    });
  }

  @override
  Future<void> delete({required int id}) async {
    await _isar.writeTxn(() async {
      await _isar.todoModels.delete(id);
    });
  }
}
