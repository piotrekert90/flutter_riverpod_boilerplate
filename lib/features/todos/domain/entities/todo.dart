import 'category.dart';

/// Domain entity representing a single todo item.
class Todo {
  const Todo({
    required this.id,
    required this.title,
    required this.isCompleted,
    required this.createdAt,
    this.category,
  });

  final int id;
  final String title;
  final bool isCompleted;
  final DateTime createdAt;
  final Category? category;

  Todo copyWith({
    int? id,
    String? title,
    bool? isCompleted,
    DateTime? createdAt,
    Object? category = _sentinel,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      category: category == _sentinel ? this.category : category as Category?,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Todo &&
            other.id == id &&
            other.title == title &&
            other.isCompleted == isCompleted &&
            other.createdAt == createdAt &&
            other.category == category;
  }

  @override
  int get hashCode => Object.hash(id, title, isCompleted, createdAt, category);
}

const Object _sentinel = Object();
