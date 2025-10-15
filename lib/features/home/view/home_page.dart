import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:habit_app/core/providers/habit_service_provider.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HabitsPage extends ConsumerStatefulWidget {
  const HabitsPage({super.key});

  @override
  ConsumerState<HabitsPage> createState() => _HabitsPageState();
}

class _HabitsPageState extends ConsumerState<HabitsPage> {
  Future<void> _addHabit() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final newHabit = Habit.newHabit(
      userId: user.id,
      name: 'Drink Water',
      frequency: 'daily',
    );

    final habitService = ref.read(habitServiceProvider);
    await habitService.addHabit(newHabit);
    ref.invalidate(habitsProvider);
  }

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

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Habits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
            return const Center(child: Text('No habits yet.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(habitsProvider),
            child: ListView.builder(
              itemCount: habits.length,
              itemBuilder: (context, index) {
                final habit = habits[index];
                return ListTile(
                  title: Text(habit.name),
                  subtitle: Text('Frequency: ${habit.frequency}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _editHabit(habit),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteHabit(habit.id),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addHabit,
        child: const Icon(Icons.add),
      ),
    );
  }
}
