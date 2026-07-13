/// Supported application theme modes.
enum UserThemeMode { light, dark, system }

/// Domain entity representing user preferences.
class UserPreferences {
  const UserPreferences({
    required this.themeMode,
    required this.isNotificationsEnabled,
  });

  factory UserPreferences.defaults() {
    return const UserPreferences(
      themeMode: UserThemeMode.system,
      isNotificationsEnabled: true,
    );
  }

  final UserThemeMode themeMode;
  final bool isNotificationsEnabled;

  UserPreferences copyWith({
    UserThemeMode? themeMode,
    bool? isNotificationsEnabled,
  }) {
    return UserPreferences(
      themeMode: themeMode ?? this.themeMode,
      isNotificationsEnabled:
          isNotificationsEnabled ?? this.isNotificationsEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is UserPreferences &&
            other.themeMode == themeMode &&
            other.isNotificationsEnabled == isNotificationsEnabled;
  }

  @override
  int get hashCode => Object.hash(themeMode, isNotificationsEnabled);
}
