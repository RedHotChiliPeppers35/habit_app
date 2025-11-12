// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:flutter/cupertino.dart';
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

  @override
  Widget build(BuildContext context) {
    final habitsAsync = ref.watch(habitsProvider);
    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      appBar: AppBar(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
        ),

        leading: IconButton(
          onPressed: Navigator.of(context).pop,
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 35),
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
                    extentRatio: 0.3,
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
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.white.withOpacity(0.06),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1.0,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.15),
                                Colors.white.withOpacity(0.04),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 14,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading:
                                habit.icon != null
                                    ? Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.10),
                                      ),
                                      alignment: Alignment.center,
                                      child: Icon(
                                        IconData(
                                          int.parse(habit.icon!),
                                          fontFamily: 'MaterialIcons',
                                        ),
                                        color: AppColors.primaryBlue,
                                        size: 22,
                                      ),
                                    )
                                    : const Icon(
                                      Icons.circle_outlined,
                                      size: 22,
                                    ),
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
