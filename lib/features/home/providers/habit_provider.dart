// lib/features/habits/providers/habits_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:habit_app/core/providers/habit_service_provider.dart';
import 'package:habit_app/features/auth/providers/auth_providers.dart';

final selectedDateIndexProvider = StateProvider<int>((ref) => 0);
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

final habitsProvider = FutureProvider<List<Habit>>((ref) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return [];

  final habitService = ref.read(habitServiceProvider);
  return habitService.fetchHabits(session.user.id);
});
