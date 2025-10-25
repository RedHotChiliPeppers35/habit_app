import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:habit_app/core/providers/habit_service_provider.dart';
import 'package:habit_app/features/home/view/home_page/home_page.dart';
import 'package:intl/intl.dart';

class FilteredHabitsPage extends ConsumerStatefulWidget {
  final String frequency;

  const FilteredHabitsPage({super.key, required this.frequency});

  @override
  ConsumerState<FilteredHabitsPage> createState() => _FilteredHabitsPageState();
}

class _FilteredHabitsPageState extends ConsumerState<FilteredHabitsPage> {
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
        startDate: habit.startDate,
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

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        leading: IconButton(
          onPressed: Navigator.of(context).pop,
          icon: Icon(Icons.chevron_left, color: Colors.white, size: 35),
        ),
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          '${widget.frequency[0].toUpperCase()}${widget.frequency.substring(1)} Habits',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading habits: $e')),
        data: (habits) {
          final filteredHabits =
              widget.frequency == 'all'
                  ? habits
                  : habits
                      .where((h) => h.frequency == widget.frequency)
                      .toList();

          if (filteredHabits.isEmpty) {
            return Center(
              child: Text(
                'No ${widget.frequency} habits found.',
                style: const TextStyle(fontSize: 16),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(habitsProvider),
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
                        onPressed: () => _editHabit(habit),
                      ),
                      buildActionButton(
                        icon: Icons.delete,
                        color: AppColors.accentRed,
                        onPressed: () => _deleteHabit(habit.id),
                      ),
                    ],
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.shade300,
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
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Created: ${DateFormat('MMM d, yyyy').format(habit.createdAt)}',
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Frequency: ${habit.frequency[0].toUpperCase()}${habit.frequency.substring(1)}',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
