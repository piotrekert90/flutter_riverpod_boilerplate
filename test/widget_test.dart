import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod_boilerplate/app.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/presentation/providers/user_preferences_repository_provider.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/presentation/providers/todo_repository_provider.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/presentation/screens/todo_screen_detail.dart';

import 'helpers/fake_todo_repository.dart';
import 'helpers/fake_user_preferences_repository.dart';

void main() {
  late FakeTodoRepository repository;
  late FakeUserPreferencesRepository userPreferencesRepository;

  setUp(() {
    repository = FakeTodoRepository();
    userPreferencesRepository = FakeUserPreferencesRepository();
  });

  tearDown(() {
    repository.dispose();
    userPreferencesRepository.dispose();
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
