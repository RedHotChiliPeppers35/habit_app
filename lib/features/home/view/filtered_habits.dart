import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:habit_app/core/providers/habit_service_provider.dart';
import 'package:intl/intl.dart';

class FilteredHabitsPage extends ConsumerStatefulWidget {
  final String frequency;

  const FilteredHabitsPage({super.key, required this.frequency});

  @override
  ConsumerState<FilteredHabitsPage> createState() => _FilteredHabitsPageState();
}

class _FilteredHabitsPageState extends ConsumerState<FilteredHabitsPage> {
  Future<void> _editHabit(Habit habit) async {
    final nameController = TextEditingController(text: habit.name);
    final freqController = TextEditingController(text: habit.frequency);

    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Habit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Habit Name'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: freqController,
                  decoration: const InputDecoration(labelText: 'Frequency'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (result == true && mounted) {
      final updatedHabit = Habit(
        id: habit.id,
        userId: habit.userId,
        name: nameController.text.trim(),
        description: habit.description,
        frequency: freqController.text.trim(),
        icon: habit.icon,
        notificationEnabled: habit.notificationEnabled,
        createdAt: habit.createdAt,
      );

      final habitService = ref.read(habitServiceProvider);
      await habitService.updateHabit(updatedHabit);
      ref.invalidate(habitsProvider);
    }
  }

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
                      subtitle: Text(
                        'Created: ${DateFormat('MMM d, yyyy').format(habit.createdAt)}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
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
