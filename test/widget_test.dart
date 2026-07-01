import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod_boilerplate/app.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/domain/entities/todo.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/domain/repositories/todo_repository.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/presentation/providers/todo_repository_provider.dart';

class FakeTodoRepository implements TodoRepository {
  final List<Todo> _todos = [];
  final _streamController = StreamController<List<Todo>>.broadcast();

  void _emit() {
    _streamController.add(List.unmodifiable(_todos));
  }

  @override
  Stream<List<Todo>> watchAll() async* {
    yield List.unmodifiable(_todos);
    yield* _streamController.stream;
  }

  @override
  Stream<Todo?> watchById(int id) async* {
    yield _todos
        .where((todo) => todo.id == id)
        .cast<Todo?>()
        .firstWhere((_) => true, orElse: () => null);
    yield* _streamController.stream.map(
      (todos) => todos
          .where((todo) => todo.id == id)
          .cast<Todo?>()
          .firstWhere((_) => true, orElse: () => null),
    );
  }

  @override
  Future<List<Todo>> getAll() async {
    return List.unmodifiable(_todos);
  }

  @override
  Future<void> add({required String title}) async {
    _todos.insert(
      0,
      Todo(
        id: _todos.length + 1,
        title: title,
        isCompleted: false,
        createdAt: DateTime.now(),
      ),
    );
    _emit();
  }

  @override
  Future<void> toggleCompleted({required int id}) async {}

  @override
  Future<void> delete({required int id}) async {}

  void dispose() {
    _streamController.close();
  }
}

void main() {
  late FakeTodoRepository repository;

  setUp(() {
    repository = FakeTodoRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  testWidgets('Todo screen loads and allows adding a task', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [todoRepositoryProvider.overrideWithValue(repository)],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Brak zadań'), findsOneWidget);

    await tester.tap(find.text('Dodaj'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField), 'Kup mleko');
    await tester.tap(find.widgetWithText(FilledButton, 'Dodaj'));
    await tester.pumpAndSettle();

    expect(find.text('Kup mleko'), findsOneWidget);
    expect(find.text('Brak zadań'), findsNothing);
  });
}
