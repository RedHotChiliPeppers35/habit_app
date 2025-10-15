import 'package:uuid/uuid.dart';

class HabitLog {
  final String id;
  final String habitId;
  final DateTime date;
  final bool isCompleted;
  final DateTime createdAt;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.date,
    required this.isCompleted,
    required this.createdAt,
  });

  factory HabitLog.newLog({
    required String habitId,
    required DateTime date,
    bool isCompleted = false,
  }) {
    return HabitLog(
      id: const Uuid().v4(),
      habitId: habitId,
      date: date,
      isCompleted: isCompleted,
      createdAt: DateTime.now(),
    );
  }

  factory HabitLog.fromMap(Map<String, dynamic> map) {
    return HabitLog(
      id: map['id'] as String,
      habitId: map['habit_id'] as String,
      date: DateTime.parse(map['date'] as String),
      isCompleted: map['is_completed'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habit_id': habitId,
      'date': date.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
