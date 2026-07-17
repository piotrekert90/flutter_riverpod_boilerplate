import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'core/providers/isar_provider.dart';
import 'features/settings/data/models/user_preferences_model.dart';
import 'features/todos/data/models/todo_model.dart';

/// Initializes Isar and launches the app with injected dependencies.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final directory = await getApplicationDocumentsDirectory();
  final isar =
      Isar.getInstance() ??
      await Isar.open([
        TodoModelSchema,
        UserPreferencesModelSchema,
      ], directory: directory.path);

  runApp(
    ProviderScope(
      overrides: [isarProvider.overrideWithValue(isar)],
      child: const App(),
    ),
  );
}
