import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_riverpod_boilerplate/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/presentation/providers/user_preferences_notifier.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/presentation/providers/user_preferences_repository_provider.dart';

class MockUserPreferencesRepository extends Mock
    implements UserPreferencesRepository {}

const _preferences = UserPreferences(
  themeMode: UserThemeMode.system,
  isNotificationsEnabled: true,
);

ProviderContainer _makeContainer(MockUserPreferencesRepository mock) {
  return ProviderContainer(
    overrides: [userPreferencesRepositoryProvider.overrideWithValue(mock)],
  );
}

void main() {
  late MockUserPreferencesRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockUserPreferencesRepository();
  });

  tearDown(() {
    container.dispose();
  });

  group('UserPreferencesNotifier - build()', skip: 'Rewrite in Zadanie 5', () {
    test('returns preferences from the first stream event', () async {
      when(
        () => mockRepo.watch(),
      ).thenAnswer((_) => Stream.value(_preferences));

      container = _makeContainer(mockRepo);

      final result = await container.read(userPreferencesProvider.future);

      expect(result, _preferences);
      verify(() => mockRepo.watch()).called(1);
      verifyNever(() => mockRepo.get());
    });

    test('state becomes AsyncData on every new stream event', () async {
      final controller = StreamController<UserPreferences>();
      when(() => mockRepo.watch()).thenAnswer((_) => controller.stream);

      container = _makeContainer(mockRepo);

      controller.add(_preferences);
      await container.read(userPreferencesProvider.future);

      const updated = UserPreferences(
        themeMode: UserThemeMode.dark,
        isNotificationsEnabled: false,
      );
      controller.add(updated);
      await Future.microtask(() {});

      final state = container.read(userPreferencesProvider);
      expect(state, isA<AsyncData<UserPreferences>>());
      expect(state.value, updated);

      await controller.close();
    });

    test(
      'future throws exception when stream errors before first event',
      () async {
        final exception = Exception('Isar Error');
        when(() => mockRepo.watch()).thenAnswer((_) => Stream.error(exception));

        container = _makeContainer(mockRepo);

        await expectLater(
          container.read(userPreferencesProvider.future),
          throwsA(isA<Exception>()),
        );

        final state = container.read(userPreferencesProvider);
        expect(state.hasError, isTrue);
        expect(state.error, isA<Exception>());
      },
    );
  });

  group('UserPreferencesNotifier - updates', skip: 'Rewrite in Zadanie 5', () {
    setUp(() {
      when(
        () => mockRepo.watch(),
      ).thenAnswer((_) => Stream.value(_preferences));
    });

    test('calls repository.updateThemeMode with selected mode', () async {
      when(
        () => mockRepo.updateThemeMode(UserThemeMode.dark),
      ).thenAnswer((_) async {});

      container = _makeContainer(mockRepo);
      await container.read(userPreferencesProvider.future);

      await container
          .read(userPreferencesProvider.notifier)
          .updateThemeMode(UserThemeMode.dark);

      verify(() => mockRepo.updateThemeMode(UserThemeMode.dark)).called(1);
    });

    test(
      'calls repository.updateNotificationsEnabled with selected value',
      () async {
        when(
          () => mockRepo.updateNotificationsEnabled(false),
        ).thenAnswer((_) async {});

        container = _makeContainer(mockRepo);
        await container.read(userPreferencesProvider.future);

        await container
            .read(userPreferencesProvider.notifier)
            .updateNotificationsEnabled(false);

        verify(() => mockRepo.updateNotificationsEnabled(false)).called(1);
      },
    );

    test('sets AsyncError when updateThemeMode throws an exception', () async {
      when(
        () => mockRepo.updateThemeMode(UserThemeMode.light),
      ).thenThrow(Exception('Database error'));

      container = _makeContainer(mockRepo);
      await container.read(userPreferencesProvider.future);

      await container
          .read(userPreferencesProvider.notifier)
          .updateThemeMode(UserThemeMode.light);

      expect(container.read(userPreferencesProvider), isA<AsyncError>());
    });
  });

  group(
    'UserPreferencesNotifier - Memory management',
    skip: 'Rewrite in Zadanie 5',
    () {
      test('cancels stream subscription when container is disposed', () async {
        final controller = StreamController<UserPreferences>();
        when(() => mockRepo.watch()).thenAnswer((_) => controller.stream);

        container = _makeContainer(mockRepo);
        controller.add(_preferences);
        await container.read(userPreferencesProvider.future);

        container.dispose();

        expect(() => controller.add(_preferences), returnsNormally);
        await controller.close();
      });
    },
  );
}
