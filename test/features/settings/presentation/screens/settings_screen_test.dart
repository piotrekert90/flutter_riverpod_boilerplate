import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod_boilerplate/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/presentation/providers/user_preferences_repository_provider.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/presentation/screens/settings_screen.dart';

class FakeUserPreferencesRepository implements UserPreferencesRepository {
  UserPreferences _preferences = UserPreferences.defaults();
  final _streamController = StreamController<UserPreferences>.broadcast();

  void _emit() {
    _streamController.add(_preferences);
  }

  @override
  Stream<UserPreferences> watch() async* {
    yield _preferences;
    yield* _streamController.stream;
  }

  @override
  Future<UserPreferences> get() async {
    return _preferences;
  }

  @override
  Future<(bool success, String? errorMessage)> updateThemeMode(
    UserThemeMode themeMode,
  ) async {
    _preferences = _preferences.copyWith(themeMode: themeMode);
    _emit();
    return (true, null);
  }

  @override
  Future<(bool success, String? errorMessage)> updateNotificationsEnabled(
    bool isEnabled,
  ) async {
    _preferences = _preferences.copyWith(isNotificationsEnabled: isEnabled);
    _emit();
    return (true, null);
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  late FakeUserPreferencesRepository repository;

  setUp(() {
    repository = FakeUserPreferencesRepository();
  });

  tearDown(() {
    repository.dispose();
  });

  testWidgets('Settings screen updates theme mode and notifications', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Systemowy'), findsOneWidget);
    expect(find.text('Jasny'), findsOneWidget);
    expect(find.text('Ciemny'), findsOneWidget);
    expect(find.text('Powiadomienia'), findsOneWidget);

    await tester.tap(find.text('Ciemny'));
    await tester.pumpAndSettle();

    expect((await repository.get()).themeMode, UserThemeMode.dark);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect((await repository.get()).isNotificationsEnabled, isFalse);
  });
}
