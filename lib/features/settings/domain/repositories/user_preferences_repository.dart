import '../entities/user_preferences.dart';

/// Repository interface for managing user preferences.
abstract class UserPreferencesRepository {
  /// Watches the user preferences.
  Stream<UserPreferences> watch();

  /// Gets the current user preferences.
  Future<UserPreferences> get();

  /// Updates the theme mode.
  Future<(bool success, String? errorMessage)> updateThemeMode(
    UserThemeMode themeMode,
  );

  /// Updates whether notifications are enabled.
  Future<(bool success, String? errorMessage)> updateNotificationsEnabled(
    bool isEnabled,
  );
}
