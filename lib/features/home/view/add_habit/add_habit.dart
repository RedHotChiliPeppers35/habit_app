import 'dart:developer';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:habit_app/core/providers/habit_service_provider.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddHabitPage extends ConsumerStatefulWidget {
  const AddHabitPage({super.key});

  @override
  ConsumerState<AddHabitPage> createState() => _AddHabitPageState();
}

class _AddHabitPageState extends ConsumerState<AddHabitPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  String _selectedFrequency = 'daily';
  IconData _selectedIcon = Icons.favorite;
  bool _enableNotification = false;

  final Map<String, IconData> _availableIcons = const {
    'Sleep': Icons.nightlight_round,
    'Water': Icons.water_drop,
    'Work': Icons.laptop,
    'Health': Icons.favorite,
    'Fitness': Icons.fitness_center,
    'Read': Icons.menu_book,
    'Run': Icons.run_circle,
    'Meditate': Icons.self_improvement,
    'Diet': Icons.fastfood,
    'Art': Icons.brush,
  };

  @override
  void initState() {
    super.initState();
    _selectedIcon = _availableIcons.values.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveHabit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final newHabit = Habit(
      id: '',
      userId: user.id,
      name: _nameController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      startDate: _selectedDate,
      frequency: _selectedFrequency,
      icon: _selectedIcon.codePoint.toString(),
      notificationEnabled: _enableNotification,
      createdAt: DateTime.now(),
    );

    try {
      final habitService = ref.read(habitServiceProvider);
      await habitService.addHabit(newHabit);
      ref.invalidate(habitsProvider);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit added successfully!')),
      );

      // Navigate back to Home tab after adding
      ref.read(bottomNavIndexProvider.notifier).state = 0;

      _formKey.currentState!.reset();
      setState(() {
        _selectedFrequency = 'daily';
        _selectedIcon = _availableIcons.values.first;
        _enableNotification = false;
        _selectedDate = DateTime.now();
      });
    } catch (e) {
      log(e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding habit: $e')));
    }
  }

  Future<DateTime?> _showCupertinoDatePicker(
    BuildContext context,
    DateTime initialDate,
  ) async {
    DateTime tempPickedDate = initialDate;

    return showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (ctx) {
        return Container(
          height: 300,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 18,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                height: 44,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.of(ctx).pop(null),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                    const Text(
                      'Select Date',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      onPressed: () => Navigator.of(ctx).pop(tempPickedDate),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: AppColors.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 0),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: initialDate,
                  minimumDate: DateTime(2020),
                  maximumDate: DateTime(2100, 12, 31),
                  onDateTimeChanged: (DateTime newDate) {
                    tempPickedDate = newDate;
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Create a Habit',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Customize your habit with an icon, frequency, and start date.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ICON PICKER
                  _buildGlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Choose an Icon',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              'swipe to see more',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 70,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableIcons.length,
                            itemBuilder: (context, index) {
                              final name = _availableIcons.keys.elementAt(
                                index,
                              );
                              final icon = _availableIcons.values.elementAt(
                                index,
                              );
                              final isSelected = icon == _selectedIcon;
                              return GestureDetector(
                                onTap:
                                    () => setState(() => _selectedIcon = icon),
                                child: Container(
                                  width: 70,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(999),
                                    gradient:
                                        isSelected
                                            ? LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                AppColors.accentRed.withOpacity(
                                                  0.95,
                                                ),
                                                AppColors.accentRed.withOpacity(
                                                  0.8,
                                                ),
                                              ],
                                            )
                                            : LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white.withOpacity(0.55),
                                                Colors.white.withOpacity(0.22),
                                              ],
                                            ),
                                    border: Border.all(
                                      color:
                                          isSelected
                                              ? Colors.white.withOpacity(0.9)
                                              : Colors.white.withOpacity(0.6),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        icon,
                                        color:
                                            isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                        size: 30,
                                      ),
                                      const SizedBox(height: 6),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: Text(
                                          name,
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isSelected
                                                    ? Colors.white
                                                    : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // NAME
                  _buildGlassCard(
                    child: TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Habit Name',
                        icon: Icon(Icons.title),
                        iconColor: AppColors.primaryBlue,
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 14),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a habit name';
                        }
                        return null;
                      },
                    ),
                  ),

                  // FREQUENCY
                  _buildGlassCard(
                    child: DropdownButtonFormField<String>(
                      value: _selectedFrequency,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        icon: Icon(Icons.repeat),
                        iconColor: AppColors.primaryBlue,
                        border: InputBorder.none,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
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
                          setState(() => _selectedFrequency = value);
                        }
                      },
                    ),
                  ),

                  // START DATE – Cupertino date picker
                  _buildGlassCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 16,
                      ),
                      leading: const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.primaryBlue,
                      ),
                      title: const Text(
                        'Start Date',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        DateFormat('E, MMM d, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      onTap: () async {
                        final newDate = await _showCupertinoDatePicker(
                          context,
                          _selectedDate,
                        );
                        if (newDate != null) {
                          setState(() {
                            _selectedDate = DateTime(
                              newDate.year,
                              newDate.month,
                              newDate.day,
                            );
                          });
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 75),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 6,
                        shadowColor: AppColors.primaryBlue.withOpacity(0.35),
                      ),
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        'Add Habit',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      onPressed: _saveHabit,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// GLASSMORPHIC CARD – matches the style of habit cards on HabitsPage
Widget _buildGlassCard({required Widget child, EdgeInsetsGeometry? padding}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white.withOpacity(0.18),
            border: Border.all(
              color: Colors.white.withOpacity(0.55),
              width: 1.2,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.28),
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
          child: child,
        ),
      ),
    ),
  );
}
