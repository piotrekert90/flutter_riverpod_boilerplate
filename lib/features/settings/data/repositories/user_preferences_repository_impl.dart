import 'package:isar_community/isar.dart';

import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/user_preferences_repository.dart';
import '../mappers/user_preferences_mapper.dart';
import '../models/user_preferences_model.dart';

/// Implementation of [UserPreferencesRepository] using Isar.
class UserPreferencesRepositoryImpl implements UserPreferencesRepository {
  /// Creates a new [UserPreferencesRepositoryImpl] with the given Isar instance.
  UserPreferencesRepositoryImpl(this._isar);

  final Isar _isar;

  UserPreferences _mapOrDefault(UserPreferencesModel? model) {
    return model?.toEntity() ?? UserPreferences.defaults();
  }

  Future<UserPreferencesModel> _getOrCreateModel() async {
    final existing = await _isar.userPreferencesModels.get(
      userPreferencesSingletonId,
    );

    if (existing != null) {
      return existing;
    }

    final model = UserPreferences.defaults().toModel();
    await _isar.userPreferencesModels.put(model);
    return model;
  }

  @override
  Stream<UserPreferences> watch() {
    return _isar.userPreferencesModels
        .watchObject(userPreferencesSingletonId, fireImmediately: true)
        .map(_mapOrDefault);
  }

  @override
  Future<UserPreferences> get() async {
    final model = await _isar.userPreferencesModels.get(
      userPreferencesSingletonId,
    );
    return _mapOrDefault(model);
  }

  @override
  Future<(bool success, String? errorMessage)> updateThemeMode(
    UserThemeMode themeMode,
  ) async {
    try {
      await _isar.writeTxn(() async {
        final model = await _getOrCreateModel();
        model.themeMode = themeMode.name;
        await _isar.userPreferencesModels.put(model);
      });
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }

  @override
  Future<(bool success, String? errorMessage)> updateNotificationsEnabled(
    bool isEnabled,
  ) async {
    try {
      await _isar.writeTxn(() async {
        final model = await _getOrCreateModel();
        model.isNotificationsEnabled = isEnabled;
        await _isar.userPreferencesModels.put(model);
      });
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }
}
