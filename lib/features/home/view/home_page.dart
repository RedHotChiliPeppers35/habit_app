import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:habit_app/core/providers/habit_service_provider.dart';
import 'package:habit_app/features/home/view/add_habit.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:habit_app/features/home/view/profile.dart';
import 'package:habit_app/features/home/view/stats.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainPage extends ConsumerStatefulWidget {
  const MainPage({super.key});

  @override
  ConsumerState<MainPage> createState() => _MainPageState();
}

class _MainPageState extends ConsumerState<MainPage> {
  final List<Widget> _pages = const [HabitsPage(), AddHabitPage(), StatsPage()];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);
    final isAddHabitSelected = currentIndex == 1;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: _pages[currentIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ref.read(bottomNavIndexProvider.notifier).state = 1;
        },

        backgroundColor:
            isAddHabitSelected ? AppColors.accentRed : AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4.0,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: AppColors.accentYellow,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,

        child: Row(
          children: <Widget>[
            _buildBottomNavItem(
              context,
              ref: ref,
              icon: Icons.home,
              label: 'Home',
              index: 0,
              currentIndex: currentIndex,
            ),
            Spacer(),
            _buildBottomNavItem(
              context,
              ref: ref,
              icon: Icons.analytics,
              label: 'Stats',
              index: 2,
              currentIndex: currentIndex,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context, {
    required WidgetRef ref,
    required IconData icon,
    required String label,
    required int index,
    required int currentIndex,
  }) {
    final isSelected = currentIndex == index;
    final isFabSelected = currentIndex == 1;

    final color =
        (isSelected && !isFabSelected) ? AppColors.primaryBlue : Colors.white;

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        borderRadius: BorderRadius.circular(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }
}

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
                      TextField(
                        controller: descriptionController,
                        maxLines: 3, // Allow multi-line input
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
    // Define a list of icons to choose from
    final List<IconData> icons = [
      Icons.fitness_center,
      Icons.book,
      Icons.water_drop,
      Icons.run_circle,
      Icons.laptop,
      Icons.phone,
      Icons.bedtime,
      Icons.lightbulb,
      Icons.palette,
      Icons.music_note,
      Icons.edit,
      Icons.code,
      Icons.pets,
      Icons.star,
      Icons.favorite,
      Icons.shopping_cart,
      Icons.hail,
      Icons.spa,
      Icons.coffee,
      Icons.savings,
    ];

    return showDialog<IconData>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select an Icon'),
          content: SizedBox(
            width: double.maxFinite,
            // Use a GridView to display the icons
            child: GridView.builder(
              shrinkWrap: true, // Important to make it work in a dialog
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 5 icons per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: icons.length,
              itemBuilder: (context, index) {
                final icon = icons[index];
                return InkWell(
                  onTap: () {
                    // When an icon is tapped, pop the dialog
                    // and return the selected icon
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
              onPressed: () => Navigator.pop(context, null), // Return null
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
    // Only calculate streaks for daily habits for simplicity
    if (habit.frequency != 'daily') {
      return 0;
    }

    final supabase = Supabase.instance.client;

    // 1. Get all completed logs for this habit, newest first
    final logs = await supabase
        .from('habit_logs')
        .select('date')
        .eq('habit_id', habit.id)
        .eq('is_completed', true)
        .order('date', ascending: false);

    if (logs.isEmpty) {
      return 0; // No completions, no streak
    }

    final dates = logs.map((log) => DateTime.parse(log['date'])).toList();

    // 2. Check if the streak is "active"
    // (i.e., completed today or yesterday)
    final today = DateUtils.dateOnly(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    // If the most recent completion wasn't today or yesterday, the streak is 0
    if (dates[0] != today && dates[0] != yesterday) {
      return 0;
    }

    // 3. Count the consecutive days
    int streak = 1; // Start at 1 for the most recent log
    var lastDate = dates[0];

    for (int i = 1; i < dates.length; i++) {
      final currentDate = dates[i];
      final expectedDate = lastDate.subtract(const Duration(days: 1));

      if (currentDate == expectedDate) {
        // This is a consecutive day
        streak++;
        lastDate = currentDate;
      } else {
        // The streak is broken
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
          icon: const Icon(Icons.person, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
        ),
        title: const Text('My Habits', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            padding: const EdgeInsets.all(16),
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Log out',
            onPressed: _signOut,
          ),
        ],
      ),

      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading habits: $e')),
        data: (habits) {
          if (habits.isEmpty) {
            return const Center(
              child: Text(
                'You don’t have habits yet.',
                style: TextStyle(fontSize: 25),
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
                switch (habit.frequency) {
                  case 'daily':
                    return true;
                  case 'weekly':
                    return habit.createdAt.weekday == selectedDate.weekday;
                  case 'monthly':
                    final daysInMonth = DateUtils.getDaysInMonth(
                      selectedDate.year,
                      selectedDate.month,
                    );
                    final targetDay =
                        habit.createdAt.day > daysInMonth
                            ? daysInMonth
                            : habit.createdAt.day;
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
                      // ... (existing container styling)
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
                              // --- MODIFIED: Use the dynamic title ---
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
                            // ... (existing LinearProgressIndicator)
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
                            _buildActionButton(
                              icon: Icons.edit,
                              color: AppColors.primaryBlue,
                              onPressed: () => _editHabit(habit),
                            ),
                            _buildActionButton(
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
                                    // ... (existing container styling)
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
                                      onPressed:
                                          () => _toggleHabitCompletion(
                                            habit,
                                            selectedDate,
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

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
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
