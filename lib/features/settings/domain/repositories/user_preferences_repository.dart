import '../entities/user_preferences.dart';

/// Repository interface for managing user preferences.
abstract class UserPreferencesRepository {
  Stream<UserPreferences> watch();

  Future<UserPreferences> get();

  Future<void> updateThemeMode(UserThemeMode themeMode);

  Future<void> updateNotificationsEnabled(bool isEnabled);
}
