import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod_boilerplate/app.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/presentation/providers/user_preferences_repository_provider.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/domain/entities/todo.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/domain/repositories/todo_repository.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/presentation/providers/todo_repository_provider.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/presentation/screens/todo_screen_detail.dart';

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
  Future<(bool success, String? errorMessage)> add({
    required String title,
  }) async {
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
    return (true, null);
  }

  @override
  Future<(bool success, String? errorMessage)> toggleCompleted({
    required int id,
  }) async {
    final index = _todos.indexWhere((todo) => todo.id == id);
    if (index == -1) {
      return (false, 'Not found');
    }

    final todo = _todos[index];
    _todos[index] = todo.copyWith(isCompleted: !todo.isCompleted);
    _emit();
    return (true, null);
  }

  @override
  Future<(bool success, String? errorMessage)> delete({required int id}) async {
    _todos.removeWhere((todo) => todo.id == id);
    _emit();
    return (true, null);
  }

  void dispose() {
    _streamController.close();
  }
}

class FakeUserPreferencesRepository implements UserPreferencesRepository {
  final _preferences = UserPreferences.defaults();

  @override
  Stream<UserPreferences> watch() async* {
    yield _preferences;
  }

  @override
  Future<UserPreferences> get() async {
    return _preferences;
  }

  @override
  Future<(bool success, String? errorMessage)> updateThemeMode(
    UserThemeMode themeMode,
  ) async {
    return (true, null);
  }

  @override
  Future<(bool success, String? errorMessage)> updateNotificationsEnabled(
    bool isEnabled,
  ) async {
    return (true, null);
  }
}

void main() {
  late FakeTodoRepository repository;
  late FakeUserPreferencesRepository userPreferencesRepository;

  setUp(() {
    repository = FakeTodoRepository();
    userPreferencesRepository = FakeUserPreferencesRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  testWidgets('Todo screen loads and allows adding a task', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoRepositoryProvider.overrideWithValue(repository),
          userPreferencesRepositoryProvider.overrideWithValue(
            userPreferencesRepository,
          ),
        ],
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

  testWidgets('Navigates to TodoDetailScreen when a task is tapped', (
    tester,
  ) async {
    await repository.add(title: 'Zadanie testowe');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoRepositoryProvider.overrideWithValue(repository),
          userPreferencesRepositoryProvider.overrideWithValue(
            userPreferencesRepository,
          ),
        ],
        child: const App(),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the task
    await tester.tap(find.text('Zadanie testowe'));
    await tester.pumpAndSettle();

    // Verify that we are on the details screen
    expect(find.byType(TodoDetailScreen), findsOneWidget);
    expect(find.text('Szczegóły zadania'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);

    // Simulate tapping the back button
    await tester.pageBack();
    await tester.pumpAndSettle();

    // Verify that we returned to the list screen
    expect(find.byType(TodoDetailScreen), findsNothing);
    expect(find.text('Zadanie testowe'), findsOneWidget);
  });
}
