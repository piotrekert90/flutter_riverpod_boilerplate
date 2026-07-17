import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_riverpod_boilerplate/features/todos/domain/entities/todo.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/domain/repositories/todo_repository.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/presentation/providers/todo_detail_notifier.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/presentation/providers/todo_notifier.dart';
import 'package:flutter_riverpod_boilerplate/features/todos/presentation/providers/todo_repository_provider.dart';

// Mock repository based on the domain interface — completely decoupled from Isar
class MockTodoRepository extends Mock implements TodoRepository {}

// Helper test data
const _tId = 1;
final _tCreatedAt = DateTime(2024, 1, 1);
final _tTodo = Todo(
  id: _tId,
  title: 'Test Todo',
  isCompleted: false,
  createdAt: _tCreatedAt,
);
final _tTodos = [_tTodo];

ProviderContainer _makeContainer(MockTodoRepository mock) {
  return ProviderContainer(
    overrides: [todoRepositoryProvider.overrideWithValue(mock)],
  );
}

void main() {
  late MockTodoRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockTodoRepository();
  });

  tearDown(() {
    container.dispose();
  });

  // ---------------------------------------------------------------------------
  // TodoList Notifier - build() and reactivity
  // ---------------------------------------------------------------------------
  group('TodoList Notifier - build()', skip: 'Rewrite in Zadanie 5', () {
    test(
      'returns list from the first stream event (without separate getAll call)',
      () async {
        // Arrange
        when(
          () => mockRepo.watchAll(),
        ).thenAnswer((_) => Stream.value(_tTodos));

        container = _makeContainer(mockRepo);

        // Act
        final result = await container.read(todoListProvider.future);

        // Assert
        expect(result, _tTodos);
        verify(() => mockRepo.watchAll()).called(1);
        // getAll() should never be called
        verifyNever(() => mockRepo.getAll());
      },
    );

    test('state becomes AsyncData on every new stream event', () async {
      // Arrange
      final controller = StreamController<List<Todo>>();
      when(() => mockRepo.watchAll()).thenAnswer((_) => controller.stream);

      container = _makeContainer(mockRepo);

      // Emit first event — build() awaits on Completer
      final updatedTodo = _tTodo.copyWith(title: 'Updated');
      controller.add(_tTodos);

      await container.read(todoListProvider.future); // wait for init

      // Act — second event from the stream
      controller.add([updatedTodo]);
      await Future.microtask(() {});

      // Assert
      final state = container.read(todoListProvider);
      expect(state, isA<AsyncData<List<Todo>>>());
      expect(state.value, [updatedTodo]);

      await controller.close();
    });

    test(
      'future throws exception when stream errors out before first event',
      () async {
        // Arrange
        final exception = Exception('Isar Error');
        when(
          () => mockRepo.watchAll(),
        ).thenAnswer((_) => Stream.error(exception));

        container = _makeContainer(mockRepo);

        // Act & Assert: future throws
        await expectLater(
          container.read(todoListProvider.future),
          throwsA(isA<Exception>()),
        );

        // State after failed build() has hasError: true (error remembered during retry)
        final state = container.read(todoListProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<Exception>());
      },
    );

    test(
      'state becomes AsyncError when stream throws an error after first event',
      () async {
        // Arrange
        final controller = StreamController<List<Todo>>();
        when(() => mockRepo.watchAll()).thenAnswer((_) => controller.stream);

        container = _makeContainer(mockRepo);

        controller.add(_tTodos);
        await container.read(todoListProvider.future);

        // Act — error after initialization
        controller.addError(Exception('Runtime error'));
        await Future.microtask(() {});

        // Assert
        final state = container.read(todoListProvider);
        expect(state, isA<AsyncError>());

        await controller.close();
      },
    );
  });

  // ---------------------------------------------------------------------------
  // TodoList Notifier - CRUD operations
  // ---------------------------------------------------------------------------
  group('TodoList Notifier - addTodo()', skip: 'Rewrite in Zadanie 5', () {
    setUp(() {
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value(_tTodos));
    });

    test('calls repository.add with trimmed title', () async {
      when(() => mockRepo.add(title: 'New task')).thenAnswer((_) async {});
      container = _makeContainer(mockRepo);
      await container.read(todoListProvider.future);

      await container.read(todoListProvider.notifier).addTodo('  New task  ');

      verify(() => mockRepo.add(title: 'New task')).called(1);
    });

    test(
      'does not call add when title is empty or contains only whitespace',
      () async {
        container = _makeContainer(mockRepo);
        await container.read(todoListProvider.future);
        final notifier = container.read(todoListProvider.notifier);

        await notifier.addTodo('');
        await notifier.addTodo('   ');

        verifyNever(() => mockRepo.add(title: any(named: 'title')));
      },
    );

    test('sets AsyncError when repository.add throws an exception', () async {
      when(
        () => mockRepo.add(title: any(named: 'title')),
      ).thenThrow(Exception('Database error'));

      container = _makeContainer(mockRepo);
      await container.read(todoListProvider.future);

      await container.read(todoListProvider.notifier).addTodo('New task');

      expect(container.read(todoListProvider), isA<AsyncError>());
    });
  });

  group('TodoList Notifier - toggleTodo()', skip: 'Rewrite in Zadanie 5', () {
    setUp(() {
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value(_tTodos));
    });

    test('calls repository.toggleCompleted with correct id', () async {
      when(() => mockRepo.toggleCompleted(id: _tId)).thenAnswer((_) async {});
      container = _makeContainer(mockRepo);
      await container.read(todoListProvider.future);

      await container.read(todoListProvider.notifier).toggleTodo(_tId);

      verify(() => mockRepo.toggleCompleted(id: _tId)).called(1);
    });

    test(
      'sets AsyncError when repository.toggleCompleted throws an exception',
      () async {
        when(
          () => mockRepo.toggleCompleted(id: any(named: 'id')),
        ).thenThrow(Exception('Database error'));

        container = _makeContainer(mockRepo);
        await container.read(todoListProvider.future);

        await container.read(todoListProvider.notifier).toggleTodo(_tId);

        expect(container.read(todoListProvider), isA<AsyncError>());
      },
    );
  });

  group('TodoList Notifier - deleteTodo()', skip: 'Rewrite in Zadanie 5', () {
    setUp(() {
      when(() => mockRepo.watchAll()).thenAnswer((_) => Stream.value(_tTodos));
    });

    test('calls repository.delete with correct id', () async {
      when(() => mockRepo.delete(id: _tId)).thenAnswer((_) async {});
      container = _makeContainer(mockRepo);
      await container.read(todoListProvider.future);

      await container.read(todoListProvider.notifier).deleteTodo(_tId);

      verify(() => mockRepo.delete(id: _tId)).called(1);
    });

    test(
      'sets AsyncError when repository.delete throws an exception',
      () async {
        when(
          () => mockRepo.delete(id: any(named: 'id')),
        ).thenThrow(Exception('Database error'));

        container = _makeContainer(mockRepo);
        await container.read(todoListProvider.future);

        await container.read(todoListProvider.notifier).deleteTodo(_tId);

        expect(container.read(todoListProvider), isA<AsyncError>());
      },
    );
  });

  group(
    'TodoList Notifier - Memory management',
    skip: 'Rewrite in Zadanie 5',
    () {
      test('cancels stream subscription when container is disposed', () async {
        final controller = StreamController<List<Todo>>();
        when(() => mockRepo.watchAll()).thenAnswer((_) => controller.stream);

        container = _makeContainer(mockRepo);
        controller.add(_tTodos);
        await container.read(todoListProvider.future);

        container.dispose();

        expect(() => controller.add([]), returnsNormally);
        await controller.close();
      });
    },
  );

  // ---------------------------------------------------------------------------
  // TodoDetail Notifier Tests
  // ---------------------------------------------------------------------------
  group('TodoDetailNotifier Tests', skip: 'Rewrite in Zadanie 5', () {
    test('emits AsyncData(Todo) state based on watchById(id) stream', () async {
      // Arrange
      when(
        () => mockRepo.watchById(_tId),
      ).thenAnswer((_) => Stream.value(_tTodo));

      container = _makeContainer(mockRepo);

      // Act
      final result = await container.read(todoDetailProvider(_tId).future);

      // Assert
      expect(result, _tTodo);
      verify(() => mockRepo.watchById(_tId)).called(1);
    });

    test(
      'sets error (Riverpod retry mode) when watchById errors out before first emission',
      () async {
        // Arrange
        final exception = Exception('Database access denied');
        when(
          () => mockRepo.watchById(_tId),
        ).thenAnswer((_) => Stream.error(exception));

        container = _makeContainer(mockRepo);

        // Act & Assert
        await expectLater(
          container.read(todoDetailProvider(_tId).future),
          throwsA(isA<Exception>()),
        );

        final state = container.read(todoDetailProvider(_tId));
        expect(state.hasError, isTrue);
        expect(state.error, isA<Exception>());
      },
    );

    test(
      'state becomes AsyncError when stream throws an error after first data emission',
      () async {
        // Arrange
        final controller = StreamController<Todo?>();
        when(
          () => mockRepo.watchById(_tId),
        ).thenAnswer((_) => controller.stream);

        container = _makeContainer(mockRepo);

        // Emit success, provider has AsyncData state
        controller.add(_tTodo);
        await container.read(todoDetailProvider(_tId).future);

        // Act — sudden error
        controller.addError(Exception('Database failure while listening'));
        await Future.microtask(() {});

        // Assert
        final state = container.read(todoDetailProvider(_tId));
        expect(state, isA<AsyncError>());

        await controller.close();
      },
    );

    test('cancels single object subscription upon dispose', () async {
      // Arrange
      final controller = StreamController<Todo?>();
      when(() => mockRepo.watchById(_tId)).thenAnswer((_) => controller.stream);

      container = _makeContainer(mockRepo);

      controller.add(_tTodo);
      await container.read(todoDetailProvider(_tId).future);

      // Act
      container.dispose();

      // Assert
      expect(() => controller.add(null), returnsNormally);
      await controller.close();
    });
  });
}
