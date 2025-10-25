import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:habit_app/features/home/view/stats_dart/filtered_habits.dart';
import 'package:habit_app/features/home/view/stats_dart/statistics.dart';

class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: const Text('My Stats', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
      ),

      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading stats: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(child: Text('No habits yet to track stats.'));
          }

          final dailyCount = habits.where((h) => h.frequency == 'daily').length;
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
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder: (context) => StatisticsPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 100,
                        vertical: 20,
                      ),
                    ),
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('View Stats'),
                  ),
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 20),
                const Text(
                  'Habit Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const FilteredHabitsPage(frequency: 'all'),
                      ),
                    );
                  },
                  icon: Icons.bar_chart,
                  label: 'Total Habits',
                  value: '$totalHabits',
                  color: AppColors.accentDark,
                ),
                const SizedBox(height: 12),
                _buildStatCard(
                  icon: Icons.today,
                  label: 'Daily Habits',
                  value: '$dailyCount',
                  color: AppColors.primaryBlue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => const FilteredHabitsPage(frequency: 'daily'),
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
                            (_) =>
                                const FilteredHabitsPage(frequency: 'weekly'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                _buildStatCard(
                  icon: Icons.calendar_month,
                  label: 'Monthly Habits',
                  value: '$monthlyCount',
                  color: AppColors.accentDark,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) =>
                                const FilteredHabitsPage(frequency: 'monthly'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                const Divider(),
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
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
