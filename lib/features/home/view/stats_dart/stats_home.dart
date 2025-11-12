// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/core/providers/supabase_provider.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:habit_app/features/home/view/stats_dart/filtered_habits.dart';
import 'package:habit_app/features/home/view/stats_dart/statistics.dart';
import 'package:habit_app/features/onboarding/questionnaire_screen.dart';

class StatsPage extends ConsumerWidget {
  StatsPage({super.key});

  final questionnaireCompletedProvider = FutureProvider<bool>((ref) async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      // No user: treat as completed so no "quiz" button
      return true;
    }

    final repo = ref.read(questionnaireRepoProvider);
    return repo.isCompleted(user.id);
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    final questionnaireCompletedAsync = ref.watch(
      questionnaireCompletedProvider,
    );

    final hasTakenAssessment = questionnaireCompletedAsync.maybeWhen(
      data: (completed) => completed,
      orElse: () => true, // while loading, hide the button to avoid flicker
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark, // koyu ikonlar (beyaz zeminde okunur)
      child: SafeArea(
        child: Scaffold(
          backgroundColor: AppColors.backgroundCream,
          body: habitsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error loading stats: $e')),
            data: (habits) {
              if (habits.isEmpty) {
                return const Center(
                  child: Text('No habits yet to track stats.'),
                );
              }

              final dailyCount =
                  habits.where((h) => h.frequency == 'daily').length;
              final weeklyCount =
                  habits.where((h) => h.frequency == 'weekly').length;
              final monthlyCount =
                  habits.where((h) => h.frequency == 'monthly').length;

              final totalHabits = habits.length;
              final startDate = habits
                  .map((h) => h.createdAt)
                  .reduce((a, b) => a.isBefore(b) ? a : b);
              final daysSinceStart =
                  DateTime.now().difference(startDate).inDays + 1;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'See your statistics with charts',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildStatCard(
                      icon: Icons.bar_chart,
                      label: 'View Stats',
                      value: "",
                      color: AppColors.surfaceDark,
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (context) => StatisticsPage(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Habit Overview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) =>
                                    const FilteredHabitsPage(frequency: 'all'),
                          ),
                        );
                      },
                      icon: Icons.bar_chart,
                      label: 'Total Habits',
                      value: '$totalHabits',
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.today,
                      label: 'Daily Habits',
                      value: '$dailyCount',
                      color: AppColors.accentRed,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => const FilteredHabitsPage(
                                  frequency: 'daily',
                                ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.calendar_view_week,
                      label: 'Weekly Habits',
                      value: '$weeklyCount',
                      color: AppColors.accentRed,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => const FilteredHabitsPage(
                                  frequency: 'weekly',
                                ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildStatCard(
                      icon: Icons.calendar_month,
                      label: 'Monthly Habits',
                      value: '$monthlyCount',
                      color: AppColors.accentRed,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => const FilteredHabitsPage(
                                  frequency: 'monthly',
                                ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Active Days Since First Habit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$daysSinceStart days',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          floatingActionButton:
              hasTakenAssessment
                  ? null // no FAB if already taken
                  : TextButton(
                    onPressed: () async {
                      // Navigate to questionnaire
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => const QuestionnaireScreen(),
                        ),
                      );

                      // If questionnaire saved successfully (pop(true) in QuestionnaireScreen)
                      if (result == true) {
                        // Refresh the completion state so FAB disappears
                        ref.invalidate(questionnaireCompletedProvider);
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: AppColors.accentRed,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: const Text(
                        'Take Onboarding Quiz',
                        style: TextStyle(
                          color: AppColors.backgroundCream,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(26),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),

                color: Colors.white.withOpacity(0.06),
                border: Border.all(
                  color: Colors.white.withOpacity(0.35),
                  width: 1.0,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.14),
                    Colors.white.withOpacity(0.03),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Camın üstünde duran renkli icon chip
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withOpacity(0.95),
                          color.withOpacity(0.75),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (value.isNotEmpty)
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        // her kartın kendi accent rengi
                        color: AppColors.surfaceDark,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
