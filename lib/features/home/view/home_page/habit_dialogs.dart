// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:habit_app/core/providers/habit_service_provider.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:habit_app/features/home/view/chat/chat_screen.dart';
import 'package:habit_app/features/home/view/home_page/profile/profile.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitsPage extends ConsumerStatefulWidget {
  const HabitsPage({super.key});

  @override
  ConsumerState<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends ConsumerState<HabitsPage> {
  Future<void> _deleteHabit(String habitId) async {
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Delete Habit', style: TextStyle(fontSize: 16)),
          content: const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text(
              'Are you sure you want to delete this habit?',
              style: TextStyle(fontSize: 14),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      final habitService = ref.read(habitServiceProvider);
      await habitService.deleteHabit(habitId);
      ref.invalidate(habitsProvider);
    }
  }

  Future<void> _editHabit(Habit habit) async {
    final nameController = TextEditingController(text: habit.name);

    String selectedFrequency = habit.frequency;
    String? selectedIconCodePoint = habit.icon;

    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return CupertinoAlertDialog(
              title: const Text(
                'Edit Habit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontSize: 18,
                ),
              ),
              content: Material(
                color: Colors.transparent,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),
                      // Name
                      TextField(
                        controller: nameController,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          labelText: 'Habit Name',
                          labelStyle: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: AppColors.backgroundCream,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Frequency
                      DropdownButtonFormField<String>(
                        value: selectedFrequency,
                        decoration: InputDecoration(
                          labelText: 'Frequency',
                          labelStyle: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: AppColors.backgroundCream,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Daily'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            selectedFrequency = value;
                          }
                        },
                      ),
                      const SizedBox(height: 12),

                      // Icon picker
                      ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        leading: Icon(
                          selectedIconCodePoint != null
                              ? IconData(
                                int.parse(selectedIconCodePoint!),
                                fontFamily: 'MaterialIcons',
                              )
                              : Icons.emoji_emotions_outlined,
                          color: AppColors.primaryBlue,
                          size: 24,
                        ),
                        title: const Text(
                          'Change Icon',
                          style: TextStyle(fontSize: 14),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                        ),
                        onTap: () async {
                          final IconData? newIcon = await _showIconPicker(
                            context,
                          );
                          if (newIcon != null) {
                            dialogSetState(() {
                              selectedIconCodePoint =
                                  newIcon.codePoint.toString();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                CupertinoDialogAction(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                CupertinoDialogAction(
                  isDefaultAction: true,
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text(
                    'Save',
                    style: TextStyle(color: AppColors.primaryBlue),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      final updatedHabit = Habit(
        id: habit.id,
        userId: habit.userId,
        name: nameController.text.trim(),
        startDate: habit.startDate,

        frequency: selectedFrequency,
        icon: selectedIconCodePoint,
        notificationEnabled: habit.notificationEnabled,
        createdAt: habit.createdAt,
        lastCompletedAt: habit.lastCompletedAt,
      );

      final habitService = ref.read(habitServiceProvider);
      await habitService.updateHabit(updatedHabit);

      if (mounted) {
        ref.invalidate(habitsProvider);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Habit updated successfully!',
            style: TextStyle(fontSize: 14),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<IconData?> _showIconPicker(BuildContext context) async {
    final List<IconData> icons = [
      Icons.nightlight_round,
      Icons.water_drop,
      Icons.fitness_center,
      Icons.run_circle,
      Icons.fastfood,
      Icons.menu_book,
      Icons.brush,
      Icons.self_improvement,
      Icons.favorite,
    ];

    return showCupertinoDialog<IconData>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('Select an Icon', style: TextStyle(fontSize: 16)),
          content: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Material(
              color: Colors.transparent,
              child: SizedBox(
                width: double.maxFinite,
                height: 180,
                child: GridView.builder(
                  shrinkWrap: true,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 5,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: icons.length,
                  itemBuilder: (context, index) {
                    final icon = icons[index];
                    return InkWell(
                      onTap: () {
                        Navigator.pop(context, icon);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Icon(icon, size: 24, color: AppColors.primaryBlue),
                    );
                  },
                ),
              ),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleHabitCompletion(
    Habit habit,
    DateTime selectedDate,
  ) async {
    final supabase = Supabase.instance.client;
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    try {
      final existing =
          await supabase
              .from('habit_logs')
              .select()
              .eq('habit_id', habit.id)
              .eq('date', formattedDate)
              .maybeSingle();

      if (existing != null) {
        final currentStatus = existing['is_completed'] as bool? ?? false;

        await supabase
            .from('habit_logs')
            .update({'is_completed': !currentStatus})
            .eq('id', existing['id']);
      } else {
        await supabase.from('habit_logs').insert({
          'habit_id': habit.id,
          'date': formattedDate,
          'is_completed': true,
        });
      }

      ref.invalidate(habitsProvider);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error updating habit completion: $e',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      );
    }
  }

  Future<bool> _isHabitCompletedOn(Habit habit, DateTime date) async {
    final supabase = Supabase.instance.client;
    final formattedDate = DateFormat('yyyy-MM-dd').format(date);

    final res =
        await supabase
            .from('habit_logs')
            .select('is_completed')
            .eq('habit_id', habit.id)
            .eq('date', formattedDate)
            .maybeSingle();

    return res?['is_completed'] ?? false;
  }

  Future<int> _getHabitStreak(Habit habit) async {
    if (habit.frequency != 'daily') {
      return 0;
    }

    final supabase = Supabase.instance.client;

    final logs = await supabase
        .from('habit_logs')
        .select('date')
        .eq('habit_id', habit.id)
        .eq('is_completed', true)
        .order('date', ascending: false);

    if (logs.isEmpty) {
      return 0;
    }

    final allDates = logs.map((log) => DateTime.parse(log['date'])).toList();
    final dates = <DateTime>[];
    for (final date in allDates) {
      final dateOnly = DateUtils.dateOnly(date);
      if (!dates.contains(dateOnly)) {
        dates.add(dateOnly);
      }
    }

    if (dates.isEmpty) {
      return 0;
    }

    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    if (dates[0].isBefore(yesterday)) {
      return 0;
    }

    int streak = 1;
    var lastDate = dates[0];

    for (int i = 1; i < dates.length; i++) {
      final currentDate = dates[i];
      final expectedDate = lastDate.subtract(const Duration(days: 1));

      if (currentDate == expectedDate) {
        streak++;
        lastDate = currentDate;
      } else {
        break;
      }
    }

    return streak;
  }

  Future<int> _getCompletedForEligibleHabits(
    List<Habit> eligibleHabits,
    DateTime selectedDate,
  ) async {
    if (eligibleHabits.isEmpty) return 0;

    final supabase = Supabase.instance.client;
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
    final ids = eligibleHabits.map((h) => h.id).toList();

    var query = supabase
        .from('habit_logs')
        .select('habit_id')
        .eq('date', formattedDate)
        .eq('is_completed', true);

    // Prefer inFilter when available
    try {
      query = query.inFilter('habit_id', ids);
    } catch (_) {
      // Fallback: raw "in" operator expects a parenthesized, comma-separated list
      final list = ids.map((e) => '"$e"').join(',');
      query = query.filter('habit_id', 'in', '($list)');
    }

    final res = await query;

    // Count each habit at most once
    final completedIds = res.map((r) => r['habit_id'] as String).toSet();
    return completedIds.length;
  }

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          padding: const EdgeInsets.all(12),
          onPressed: () {
            Navigator.of(context).push(
              CupertinoDialogRoute(
                builder: (context) => const ProfilePage(),
                context: context,
              ),
            );
          },
          icon: const Icon(
            CupertinoIcons.person_fill,
            color: Colors.white,
            size: 22,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        title: const Text(
          'My Habits',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          IconButton(
            padding: const EdgeInsets.all(8),
            onPressed: () async {
              Navigator.of(context).push(
                CupertinoModalPopupRoute(
                  builder: (context) {
                    return HabitChatPage();
                  },
                ),
              );
            },
            icon: const Icon(
              CupertinoIcons.chat_bubble_2_fill,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
      body: habitsAsync.when(
        loading:
            () => const Center(
              child: SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
        error:
            (e, _) => Center(
              child: Text(
                'Error loading habits: $e',
                style: const TextStyle(fontSize: 14),
              ),
            ),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'You don’t have habits yet.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        AppColors.accentRed,
                      ),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                    onPressed: () {
                      ref.read(bottomNavIndexProvider.notifier).state = 1;
                    },
                    child: const Text(
                      "Create One",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }

          final selectedIndex = ref.watch(selectedDateIndexProvider);
          final today = DateTime.now();
          final selectedDate = today.add(Duration(days: selectedIndex));
          final todayDateOnly = DateUtils.dateOnly(today);
          final selectedDateOnly = DateUtils.dateOnly(selectedDate);

          String progressTitle;
          if (selectedDateOnly == todayDateOnly) {
            progressTitle = "Today's Progress";
          } else if (selectedDateOnly ==
              todayDateOnly.subtract(const Duration(days: 1))) {
            progressTitle = "Yesterday's Progress";
          } else {
            progressTitle =
                "Progress for ${DateFormat('MMM d').format(selectedDate)}";
          }

          final filteredHabits =
              habits.where((habit) {
                if (DateUtils.dateOnly(
                  habit.startDate,
                ).isAfter(selectedDateOnly)) {
                  return false;
                }

                switch (habit.frequency) {
                  case 'daily':
                    return true;
                  case 'weekly':
                    return habit.startDate.weekday == selectedDate.weekday;
                  case 'monthly':
                    final daysInMonth = DateUtils.getDaysInMonth(
                      selectedDate.year,
                      selectedDate.month,
                    );

                    final targetDay =
                        habit.startDate.day > daysInMonth
                            ? daysInMonth
                            : habit.startDate.day;

                    return selectedDate.day == targetDay;

                  default:
                    return true;
                }
              }).toList();

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(habitsProvider),
            child: Column(
              children: [
                SizedBox(height: 16),
                FutureBuilder<int>(
                  future: _getCompletedForEligibleHabits(
                    filteredHabits,
                    selectedDate,
                  ),
                  builder: (context, snapshot) {
                    final completed = snapshot.data ?? 0;
                    final total = filteredHabits.length;
                    final progress =
                        total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
                    final percentage = (progress * 100).round();
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlueSoft.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      progressTitle,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      '$completed of $total habits',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(999),
                                  child: LinearProgressIndicator(
                                    value: progress.toDouble(),
                                    backgroundColor: Colors.white.withOpacity(
                                      0.6,
                                    ),
                                    color: AppColors.primaryBlue,
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 12),

                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$percentage%',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  child: const HorizontalDateSelector(),
                ),
                SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredHabits.length,
                    itemBuilder: (context, index) {
                      final habit = filteredHabits[index];
                      return Slidable(
                        key: ValueKey(habit.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.3,
                          children: [
                            buildActionButton(
                              icon: Icons.edit,
                              color: AppColors.primaryBlue,
                              onPressed: () async {
                                Slidable.of(context)?.close();
                                await _editHabit(habit);
                              },
                            ),
                            buildActionButton(
                              icon: Icons.delete,
                              color: AppColors.accentRed,
                              onPressed: () => _deleteHabit(habit.id),
                            ),
                          ],
                        ),
                        child: FutureBuilder<bool>(
                          future: _isHabitCompletedOn(habit, selectedDate),
                          builder: (context, completionSnapshot) {
                            final isCompleted =
                                completionSnapshot.data ?? false;

                            return FutureBuilder<int>(
                              future: _getHabitStreak(habit),
                              builder: (context, streakSnapshot) {
                                final streak = streakSnapshot.data ?? 0;

                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 16,
                                        sigmaY: 16,
                                      ),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          // subtle frosted glass background
                                          color: Colors.white.withOpacity(0.18),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.55,
                                            ),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.08,
                                              ),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                          // optional: very soft gradient to mimic Apple cards
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Colors.white.withOpacity(0.28),
                                              Colors.white.withOpacity(0.10),
                                            ],
                                          ),
                                        ),
                                        child: ListTile(
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 16,
                                              ),
                                          minVerticalPadding: 6,
                                          leading: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: AppColors.primaryBlue
                                                  .withOpacity(0.10),
                                            ),
                                            alignment: Alignment.center,
                                            child:
                                                habit.icon != null
                                                    ? Icon(
                                                      IconData(
                                                        int.parse(habit.icon!),
                                                        fontFamily:
                                                            'MaterialIcons',
                                                      ),
                                                      color:
                                                          AppColors.primaryBlue,
                                                      size: 22,
                                                    )
                                                    : const Icon(
                                                      Icons.circle_outlined,
                                                      size: 22,
                                                      color: Colors.black54,
                                                    ),
                                          ),
                                          title: Text(
                                            habit.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${habit.frequency.toUpperCase()}${streak > 0 ? '  •  Streak: $streak 🔥' : ''}',
                                            style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 13,
                                            ),
                                          ),
                                          trailing: IconButton(
                                            icon: Icon(
                                              isCompleted
                                                  ? Icons.check_circle
                                                  : Icons.circle_outlined,
                                              color:
                                                  isCompleted
                                                      ? AppColors.primaryBlue
                                                      : Colors.black26,
                                              size: 24,
                                            ),
                                            onPressed: () {
                                              if (selectedDateOnly ==
                                                  todayDateOnly) {
                                                _toggleHabitCompletion(
                                                  habit,
                                                  selectedDate,
                                                );
                                              } else {
                                                showAdaptiveDialog(
                                                  barrierDismissible: true,
                                                  context: context,
                                                  builder:
                                                      (
                                                        context,
                                                      ) => CupertinoAlertDialog(
                                                        title: const Text(
                                                          "You can not edit future habits",
                                                        ),
                                                        actions: [
                                                          CupertinoDialogAction(
                                                            isDefaultAction:
                                                                true,
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(),
                                                            child: const Text(
                                                              'OK',
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                );
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class HorizontalDateSelector extends ConsumerWidget {
  const HorizontalDateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(selectedDateIndexProvider);
    final today = DateTime.now();

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = today.add(Duration(days: index));
          final isSelected = selectedIndex == index;

          return GestureDetector(
            onTap:
                () =>
                    ref.read(selectedDateIndexProvider.notifier).state = index,
            child: Container(
              width: 50,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentRed : Colors.white,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 16,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

Widget buildActionButton({
  required IconData icon,
  required Color color,
  required Future<void> Function() onPressed,
}) {
  return Builder(
    builder: (context) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: 18),
          padding: const EdgeInsets.all(8),
          constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
          onPressed: () async {
            final slidable = Slidable.of(context);
            slidable?.close();

            await onPressed();

            WidgetsBinding.instance.addPostFrameCallback((_) {
              slidable?.close();
            });
          },
        ),
      );
    },
  );
}
