import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/todo.dart';
import 'todo_repository_provider.dart';

part 'todo_notifier.g.dart';

@riverpod
class TodoList extends _$TodoList {
  @override
  Stream<List<Todo>> build() {
    final repository = ref.watch(todoRepositoryProvider);
    return repository.watchAll();
  }

  Future<void> addTodo(String title) async {
    final trimmedTitle = title.trim();
    if (trimmedTitle.isEmpty) {
      return;
    }
    await ref.read(todoRepositoryProvider).add(title: trimmedTitle);
  }

  Future<void> toggleTodo(int id) async {
    await ref.read(todoRepositoryProvider).toggleCompleted(id: id);
  }

  Future<void> deleteTodo(int id) async {
    await ref.read(todoRepositoryProvider).delete(id: id);
  }
}
