import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_riverpod_boilerplate/features/settings/domain/entities/user_preferences.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/domain/repositories/user_preferences_repository.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/presentation/providers/user_preferences_repository_provider.dart';
import 'package:flutter_riverpod_boilerplate/features/settings/presentation/screens/settings_screen.dart';

class FakeUserPreferencesRepository implements UserPreferencesRepository {
  FakeUserPreferencesRepository(this._preferences);

  UserPreferences _preferences;
  final _streamController = StreamController<UserPreferences>.broadcast();

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
    _streamController.add(_preferences);
    return (true, null);
  }

  @override
  Future<(bool success, String? errorMessage)> updateNotificationsEnabled(
    bool isEnabled,
  ) async {
    _preferences = _preferences.copyWith(isNotificationsEnabled: isEnabled);
    _streamController.add(_preferences);
    return (true, null);
  }

  void dispose() {
    _streamController.close();
  }
}

void main() {
  late FakeUserPreferencesRepository repository;

  tearDown(() {
    repository.dispose();
  });

  testWidgets('Settings screen selected dark theme state', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;

    repository = FakeUserPreferencesRepository(
      const UserPreferences(
        themeMode: UserThemeMode.dark,
        isNotificationsEnabled: false,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          userPreferencesRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
            useMaterial3: true,
          ),
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SettingsScreen),
      matchesGoldenFile('goldens/settings_screen_dark.png'),
    );

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
