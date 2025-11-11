import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatisticsPage extends ConsumerWidget {
  const StatisticsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        title: const Text('Statistics', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors.primaryBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        leading: BackButton(color: Colors.white),
      ),
      body: habitsAsync.when(
        data: (habits) => _buildCharts(context, habits),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCharts(BuildContext context, List<Habit> habits) {
    if (habits.isEmpty) {
      return const Center(child: Text("No habits yet — start building!"));
    }

    // Frequency counts
    final dailyCount =
        habits.where((h) => h.frequency == 'daily').length.toDouble();
    final weeklyCount =
        habits.where((h) => h.frequency == 'weekly').length.toDouble();
    final monthlyCount =
        habits.where((h) => h.frequency == 'monthly').length.toDouble();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          _buildCard(
            context: context,
            title: "Habit Frequency Distribution",
            infoText:
                "See how your habits are divided across daily, weekly, and monthly routines. This helps you understand the rhythm of your lifestyle — whether you prefer steady daily actions or spaced-out goals.",
            child: _animatedChart(
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        value: dailyCount,

                        color: AppColors.primaryBlue.withOpacity(0.6),
                        titleStyle: TextStyle(color: Colors.black),
                        title: 'Daily',
                        radius: 50,
                      ),
                      PieChartSectionData(
                        value: weeklyCount,
                        color: AppColors.accentRed,
                        title: 'Weekly',
                        titleStyle: TextStyle(color: Colors.black),
                        radius: 50,
                      ),
                      PieChartSectionData(
                        value: monthlyCount,
                        color: Color(0xFFCBF3BB),
                        title: 'Monthly',
                        titleStyle: TextStyle(color: Colors.black),
                        radius: 50,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildCard(
            context: context,
            title: "Your Consistency Journey",
            infoText:
                "This line shows how your habit streaks have grown over time. Each point represents your daily consistency — the higher the line, the longer you’ve maintained your habits. It’s a visual record of your discipline journey!",
            child: _animatedChart(
              FutureBuilder<List<double>>(
                future: _calculateDailyCompletionRates(habits),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final rates = snapshot.data!;
                  return SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  "${(value * 100).toInt()}%",
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black54,
                                  ),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 28,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Mon',
                                  'Tue',
                                  'Wed',
                                  'Thu',
                                  'Fri',
                                  'Sat',
                                  'Sun',
                                ];
                                final index = value.toInt();
                                if (index < 0 || index > 6)
                                  return const SizedBox.shrink();
                                return Text(
                                  days[index],
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            color: AppColors.accentRed,
                            barWidth: 3,
                            isCurved: true,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Color(0xFF16476A).withOpacity(0.2),
                            ),
                            spots: List.generate(
                              rates.length,
                              (i) => FlSpot(i.toDouble(), rates[i]),
                            ),
                          ),
                        ],
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildCard(
            context: context,
            title: "Where Your Energy Goes",
            infoText:
                "This pie chart shows which types of habits you focus on the most — like health, learning, or mindfulness. It helps you find balance and notice where your energy truly flows.",
            child: SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sections: _generateEnergyDistributionFromIcons(habits),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildCard(
            context: context,
            title: "Your Discipline Calendar",
            infoText:
                "Each square represents a day, and its color intensity shows how many habits you completed. The darker the color, the stronger your day. Keep your streak alive and aim for a full, glowing month!",
            child: FutureBuilder<Map<DateTime, int>>(
              future: _fetchDailyCompletions(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final completions = snapshot.data!;
                final today = DateTime.now();

                // Align to start of week (Monday)
                final weekday = today.weekday; // Monday=1
                final startOfCurrentWeek = today.subtract(
                  Duration(days: weekday - 1),
                );
                final startDate = startOfCurrentWeek.subtract(
                  const Duration(days: 21),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🏷 Weekday labels
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        right: 4,
                        bottom: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children:
                            ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                                .map(
                                  (d) => Expanded(
                                    child: Center(
                                      child: Text(
                                        d,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
                    ),

                    // 📆 4-week heatmap
                    SizedBox(
                      height: 300,
                      child: GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 7,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                        itemCount: 28,
                        itemBuilder: (context, index) {
                          final currentDate = startDate.add(
                            Duration(days: index),
                          );
                          final normalized = DateTime(
                            currentDate.year,
                            currentDate.month,
                            currentDate.day,
                          );

                          final completedCount = completions[normalized] ?? 0;
                          final totalHabits =
                              habits.isEmpty ? 1 : habits.length;
                          final completionRate = (completedCount / totalHabits)
                              .clamp(0.0, 1.0);

                          final color = Color.lerp(
                            Colors.grey.shade200,
                            AppColors.accentRed,
                            completionRate,
                          );

                          return Container(
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          _buildCard(
            context: context,
            title: "Weekly Habit Retention Rate",
            infoText:
                "This line shows the percentage of habits you’ve maintained over the past weeks. A higher line means you’re sticking with your routines consistently — a clear measure of your long-term discipline.",
            child: _animatedChart(
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _calculateHabitRetentionWithDates(habits),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 200,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final data = snapshot.data!;
                  final retentionRates =
                      data.map((e) => e['rate'] as double).toList();
                  final labels = data.map((e) => e['label'] as String).toList();

                  return SizedBox(
                    height: 220,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  "${(value * 100).toInt()}%",
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 36,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                final index = value.toInt();
                                if (index < 0 || index >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  labels[index],
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 9),
                                );
                              },
                            ),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            color: AppColors.accentRed,
                            barWidth: 3,
                            isCurved: true,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: true),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Color(0xFF16476A).withOpacity(0.15),
                            ),
                            spots: List.generate(
                              retentionRates.length,
                              (i) => FlSpot(i.toDouble(), retentionRates[i]),
                            ),
                          ),
                        ],
                        minX: 0,
                        maxX: retentionRates.length.toDouble() - 1,
                        minY: 0,
                        maxY: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _calculateHabitRetentionWithDates(
    List<Habit> habits,
  ) async {
    final supabase = Supabase.instance.client;
    final now = DateTime.now();
    final List<Map<String, dynamic>> data = [];

    for (int i = 5; i >= 0; i--) {
      final weekStart = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: i * 7 + now.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      final label = DateFormat('MMM d').format(weekStart); // Example: "Oct 7"

      final existingHabits =
          habits.where((h) => h.createdAt.isBefore(weekEnd)).toList();

      if (existingHabits.isEmpty) {
        data.add({'rate': 0.0, 'label': label});
        continue;
      }

      final logs = await supabase
          .from('habit_logs')
          .select('habit_id, date')
          .gte('date', weekStart.toIso8601String().split('T').first)
          .lte('date', weekEnd.toIso8601String().split('T').first)
          .eq('is_completed', true);

      final completedHabitIds =
          logs.map((log) => log['habit_id'] as String).toSet();
      final retainedCount =
          existingHabits.where((h) => completedHabitIds.contains(h.id)).length;

      final rate = retainedCount / existingHabits.length;
      data.add({'rate': rate, 'label': label});
    }

    return data;
  }

  Future<Map<DateTime, int>> _fetchDailyCompletions() async {
    final supabase = Supabase.instance.client;
    final today = DateTime.now();

    // Start 4 weeks ago (aligned to Monday)
    final weekday = today.weekday; // Monday=1
    final startOfCurrentWeek = today.subtract(Duration(days: weekday - 1));
    final startDate = startOfCurrentWeek.subtract(const Duration(days: 21));

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59);

    final response = await supabase
        .from('habit_logs')
        .select('date')
        .eq('is_completed', true)
        .gte('date', start.toIso8601String())
        .lte('date', end.toIso8601String());

    // 🧮 Group logs by normalized date
    final Map<DateTime, int> completions = {};
    for (var row in response) {
      final date = DateTime.parse(row['date']).toLocal();
      final normalized = DateTime(date.year, date.month, date.day);
      completions[normalized] = (completions[normalized] ?? 0) + 1;
    }

    return completions;
  }

  Future<List<double>> _calculateDailyCompletionRates(
    List<Habit> habits,
  ) async {
    final supabase = Supabase.instance.client;
    final today = DateTime.now();
    final List<double> completionRates = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));
      final formattedDate = DateFormat('yyyy-MM-dd').format(date);

      // Fetch all completed habits for that date
      final completedLogs = await supabase
          .from('habit_logs')
          .select('habit_id')
          .eq('date', formattedDate)
          .eq('is_completed', true);

      final totalHabits = habits.length;
      final completedCount = completedLogs.length;

      final rate =
          totalHabits == 0
              ? 0.0
              : (completedCount / totalHabits).clamp(0.0, 1.0);

      completionRates.add(rate);
    }

    return completionRates;
  }

  Widget _animatedChart(Widget child) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, _) => Opacity(opacity: value, child: child),
    );
  }

  List<PieChartSectionData> _generateEnergyDistributionFromIcons(
    List<Habit> habits,
  ) {
    final Map<IconData, String> iconToCategory = {
      Icons.nightlight_round: 'Health',
      Icons.water_drop: 'Health',
      Icons.fitness_center: 'Health',
      Icons.run_circle: 'Health',
      Icons.fastfood: 'Health',

      Icons.menu_book: 'Learning',
      Icons.brush: 'Learning',
      Icons.laptop: 'Learning',

      Icons.self_improvement: 'Mind',
      Icons.favorite: 'Mind',
    };

    final Map<String, int> categoryCount = {
      'Health': 0,
      'Learning': 0,
      'Mind': 0,
      'Other': 0,
    };

    for (final habit in habits) {
      final iconCode = int.tryParse(habit.icon ?? '') ?? 0;

      final matchedCategory =
          iconToCategory.entries
              .firstWhere(
                (entry) => entry.key.codePoint == iconCode,
                orElse: () => const MapEntry(Icons.error, 'Other'),
              )
              .value;

      categoryCount[matchedCategory] =
          (categoryCount[matchedCategory] ?? 0) + 1;
    }

    final total = categoryCount.values.fold(0, (a, b) => a + b);
    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: "No Data",
          color: Colors.grey.shade300,
          titleStyle: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
      ];
    }

    // Build chart sections
    return [
      PieChartSectionData(
        value: (categoryCount['Health']! / total) * 100,
        color: Color(0XFF1D546C),
        title: "Health",

        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: (categoryCount['Learning']! / total) * 100,
        color: Color(0xFFABE7B2),

        title: "Learning",
        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: (categoryCount['Mind']! / total) * 100,
        color: AppColors.accentRed,
        title: "Mind",

        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
      PieChartSectionData(
        value: (categoryCount['Other']! / total) * 100,
        color: Color(0xFFCBF3BB),
        title: "Other",
        titleStyle: const TextStyle(
          fontSize: 10,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    ];
  }

  List<double> calculateWeeklyCompletion(List<Habit> habits) {
    final today = DateTime.now();
    final List<double> completionRates = [];

    for (int i = 6; i >= 0; i--) {
      final date = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: i));

      final activeHabits =
          habits.where((habit) {
            if (habit.startDate.isAfter(date)) return false;
            switch (habit.frequency) {
              case 'daily':
                return true;
              case 'weekly':
                final daysSinceStart = date.difference(habit.startDate).inDays;
                return daysSinceStart % 7 == 0;
              case 'monthly':
                return habit.startDate.day == date.day;
              default:
                return false;
            }
          }).toList();

      final completedHabits =
          activeHabits.length * (0.5 + (0.5 * (i / 6))); // placeholder pattern
      final rate =
          activeHabits.isEmpty
              ? 0.0
              : (completedHabits / activeHabits.length).clamp(0.0, 1.0);
      completionRates.add(rate);
    }

    return completionRates;
  }
}

Widget _buildCard({
  required BuildContext context,
  required String title,
  required Widget child,
  String? infoText,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            // glass base
            color: Colors.white.withOpacity(0.18),
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.30),
                Colors.white.withOpacity(0.10),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (infoText != null)
                    IconButton(
                      icon: const Icon(Icons.info_outline, size: 20),
                      color: Colors.grey[600],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        showCupertinoDialog(
                          context: context,
                          builder: (context) {
                            return CupertinoAlertDialog(
                              title: Text(title),
                              content: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  infoText,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              actions: [
                                CupertinoDialogAction(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Got it'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    ),
  );
}
