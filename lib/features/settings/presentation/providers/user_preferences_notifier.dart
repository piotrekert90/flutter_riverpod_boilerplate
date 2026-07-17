import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../domain/entities/user_preferences.dart';
import 'user_preferences_repository_provider.dart';

part 'user_preferences_notifier.g.dart';

@riverpod
class UserPreferencesNotifier extends _$UserPreferencesNotifier {
  @override
  Stream<UserPreferences> build() {
    final repository = ref.watch(userPreferencesRepositoryProvider);
    return repository.watch();
  }

  Future<void> updateThemeMode(UserThemeMode themeMode) async {
    await ref
        .read(userPreferencesRepositoryProvider)
        .updateThemeMode(themeMode);
  }

  Future<void> updateNotificationsEnabled(bool isEnabled) async {
    await ref
        .read(userPreferencesRepositoryProvider)
        .updateNotificationsEnabled(isEnabled);
  }
}
