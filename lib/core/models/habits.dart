import 'package:uuid/uuid.dart';

class Habit {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String frequency;
  final DateTime createdAt;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.frequency,
    required this.createdAt,
  });

  factory Habit.newHabit({
    required String userId,
    required String name,
    String? description,
    required String frequency,
  }) {
    return Habit(
      id: const Uuid().v4(),
      userId: userId,
      name: name,
      description: description,
      frequency: frequency,
      createdAt: DateTime.now(),
    );
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    return Habit(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      frequency: map['frequency'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'frequency': frequency,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
