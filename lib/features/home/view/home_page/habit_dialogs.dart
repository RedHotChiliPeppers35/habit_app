import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:habit_app/core/providers/habit_service_provider.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:habit_app/features/home/view/chat/chat_screen.dart';
import 'package:habit_app/features/home/view/home_page/profile.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitsPage extends ConsumerStatefulWidget {
  const HabitsPage({super.key});

  @override
  ConsumerState<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends ConsumerState<HabitsPage> {
  Future<void> _deleteHabit(String habitId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Habit'),
            content: const Text('Are you sure you want to delete this habit?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentRed,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      final habitService = ref.read(habitServiceProvider);
      await habitService.deleteHabit(habitId);
      ref.invalidate(habitsProvider);
    }
  }

  Future<void> _editHabit(Habit habit) async {
    final nameController = TextEditingController(text: habit.name);
    final descriptionController = TextEditingController(
      text: habit.description,
    );
    String selectedFrequency = habit.frequency;
    String? selectedIconCodePoint = habit.icon;
    DateTime selectedStartDate = habit.startDate; // ✅ make start date editable

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Edit Habit',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Habit name ---
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Habit Name',
                          labelStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.backgroundCream,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // --- Description ---
                      TextField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          labelStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.backgroundCream,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String>(
                        value: selectedFrequency,
                        decoration: InputDecoration(
                          labelText: 'Frequency',
                          labelStyle: const TextStyle(color: Colors.black54),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: AppColors.backgroundCream,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                          if (value != null) selectedFrequency = value;
                        },
                      ),
                      const SizedBox(height: 16),

                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 16,
                        ),
                        leading: Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.primaryBlue,
                        ),
                        title: const Text('Start Date'),
                        subtitle: Text(
                          DateFormat(
                            'E, MMM d, yyyy',
                          ).format(selectedStartDate), // ✅ show current date
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                        ),
                        onTap: () async {
                          final newDate = await showDatePicker(
                            context: context,
                            initialDate: selectedStartDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (newDate != null) {
                            dialogSetState(() {
                              selectedStartDate =
                                  newDate; // ✅ update date inside dialog
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          selectedIconCodePoint != null
                              ? IconData(
                                int.parse(selectedIconCodePoint!),
                                fontFamily: 'MaterialIcons',
                              )
                              : Icons.emoji_emotions_outlined,
                          color: AppColors.primaryBlue,
                          size: 30,
                        ),
                        title: const Text('Change Icon'),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
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
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(foregroundColor: Colors.black54),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      final newDescription = descriptionController.text.trim();

      final updatedHabit = Habit(
        id: habit.id,
        userId: habit.userId,
        name: nameController.text.trim(),
        startDate: selectedStartDate, // ✅ new start date
        description: newDescription.isEmpty ? null : newDescription,
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
          content: Text('Habit updated successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<IconData?> _showIconPicker(BuildContext context) async {
    final List<IconData> icons = [
      Icons.nightlight_round,
      Icons.water_drop,
      Icons.laptop,
      Icons.favorite,
      Icons.fitness_center,
      Icons.menu_book,
      Icons.run_circle,
      Icons.self_improvement,
      Icons.fastfood,
      Icons.brush,
    ];

    return showDialog<IconData>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select an Icon'),
          content: SizedBox(
            width: double.maxFinite,

            child: GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                final icon = icons[index];
                return InkWell(
                  onTap: () {
                    Navigator.pop(context, icon);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Icon(icon, size: 30, color: AppColors.primaryBlue),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Logged out successfully')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Logout failed: $e')));
    }
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
        SnackBar(content: Text('Error updating habit completion: $e')),
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

  Future<int> _getCompletedCount(DateTime selectedDate) async {
    final supabase = Supabase.instance.client;
    final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

    final res = await supabase
        .from('habit_logs')
        .select('id')
        .eq('date', formattedDate)
        .eq('is_completed', true);

    return res.length;
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

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          padding: const EdgeInsets.all(16),
          onPressed: () {
            Navigator.of(context).push(
              CupertinoDialogRoute(
                builder: (context) => const ProfilePage(),
                context: context,
              ),
            );
          },
          icon: const Icon(CupertinoIcons.person_fill, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        title: const Text('My Habits', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            padding: EdgeInsets.all(10),
            onPressed: () async {
              Navigator.of(context).push(
                CupertinoModalPopupRoute(
                  builder: (context) {
                    return HabitChatPage();
                  },
                ),
              );
            },
            icon: Icon(CupertinoIcons.chat_bubble_2_fill, color: Colors.white),
          ),
        ],
      ),

      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading habits: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'You don’t have habits yet.',
                    style: TextStyle(fontSize: 20),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(
                        AppColors.accentRed,
                      ),
                    ),

                    onPressed: () {
                      ref.read(bottomNavIndexProvider.notifier).state = 1;
                    },
                    child: Text(
                      "Create One",
                      style: TextStyle(color: Colors.white),
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

                    // Handle months with fewer days gracefully
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
                const HorizontalDateSelector(),
                FutureBuilder<int>(
                  future: _getCompletedCount(selectedDate),
                  builder: (context, snapshot) {
                    final completed = snapshot.data ?? 0;
                    final total = filteredHabits.length;
                    final progress = total == 0 ? 0 : completed / total;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                progressTitle,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),

                              Text(
                                '$completed / $total completed',
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: progress.toDouble(),
                              backgroundColor: AppColors.backgroundCream,
                              color: AppColors.primaryBlue,
                              minHeight: 10,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredHabits.length,
                    itemBuilder: (context, index) {
                      final habit = filteredHabits[index];
                      return Slidable(
                        key: ValueKey(habit.id),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          extentRatio: 0.5,
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

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: AppColors.backgroundCream,
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ListTile(
                                    leading:
                                        habit.icon != null
                                            ? Icon(
                                              IconData(
                                                int.parse(habit.icon!),
                                                fontFamily: 'MaterialIcons',
                                              ),
                                              color: AppColors.primaryBlue,
                                            )
                                            : const Icon(Icons.circle_outlined),
                                    title: Text(
                                      habit.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    subtitle: Text(
                                      'Frequency: ${habit.frequency}${streak > 0 ? '  •  Streak: $streak 🔥' : ''}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 14,
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
                                                : Colors.grey,
                                      ),
                                      onPressed: () {
                                        if (selectedDateOnly == todayDateOnly) {
                                          _toggleHabitCompletion(
                                            habit,
                                            selectedDate,
                                          );
                                        } else {
                                          showAdaptiveDialog(
                                            context: context,
                                            builder:
                                                (
                                                  context,
                                                ) => CupertinoAlertDialog(
                                                  title: Text(
                                                    "You can not edit future habits ",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () {
                                                        Navigator.of(
                                                          context,
                                                        ).pop();
                                                      },
                                                      child: Text("Close"),
                                                    ),
                                                  ],
                                                ),
                                          );
                                        }
                                      },
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
      height: 90,
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
              width: 70,
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.accentRed : Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 20,
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
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(30),
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white),
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
