import 'package:habit_app/core/models/habit_logs.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitService {
  final _supabase = Supabase.instance.client;

  /// ✅ Fetch all habits for a specific user
  /// Includes auto-reset logic for daily completions
  Future<List<Habit>> fetchHabits(String userId) async {
    final response = await _supabase
        .from('habits')
        .select()
        .eq('user_id', userId)
        .order('created_at');

    final habits =
        (response as List).map((data) => Habit.fromMap(data)).toList();

    final today = DateTime.now();

    for (final habit in habits) {
      if (habit.lastCompletedAt != null &&
          (habit.lastCompletedAt!.year != today.year ||
              habit.lastCompletedAt!.month != today.month ||
              habit.lastCompletedAt!.day != today.day)) {
        habit.lastCompletedAt = null;

        await _supabase
            .from('habits')
            .update({'last_completed_at': null}) // ✅ renamed
            .eq('id', habit.id);
      }
    }

    return habits;
  }

  /// Add a new habit
  Future<void> addHabit(Habit habit) async {
    await _supabase.from('habits').insert(habit.toMap());
  }

  /// Delete a habit by ID
  Future<void> deleteHabit(String habitId) async {
    await _supabase.from('habits').delete().eq('id', habitId);
  }

  /// Update an existing habit
  Future<void> updateHabit(Habit habit) async {
    await _supabase.from('habits').update(habit.toMap()).eq('id', habit.id);
  }

  /// Add a log for habit completion
  Future<void> addHabitLog(HabitLog log) async {
    await _supabase.from('habit_logs').insert(log.toMap());
  }

  /// Fetch logs for a specific habit
  Future<List<HabitLog>> fetchLogs(String habitId) async {
    final res = await _supabase
        .from('habit_logs')
        .select()
        .eq('habit_id', habitId)
        .order('date');

    return (res as List).map((e) => HabitLog.fromMap(e)).toList();
  }
}
