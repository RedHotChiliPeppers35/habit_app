// lib/core/services/habit_service_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/services/habit_service.dart';

final habitServiceProvider = Provider<HabitService>((ref) {
  return HabitService();
});
