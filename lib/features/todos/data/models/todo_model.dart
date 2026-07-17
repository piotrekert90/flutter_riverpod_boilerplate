import 'package:isar_community/isar.dart';

part 'todo_model.g.dart';

/// Persistent representation of a [Todo] domain entity.
@collection
class TodoModel {
  Id id = Isar.autoIncrement;

  late String title;

  bool isCompleted = false;

  late DateTime createdAt;
}
