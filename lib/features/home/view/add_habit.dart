import 'dart:developer';
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

  final List<IconData> _availableIcons = const [
    Icons.favorite,
    Icons.water_drop,
    Icons.book,
    Icons.run_circle,
    Icons.fitness_center,
    Icons.self_improvement,
    Icons.brush,
    Icons.fastfood,
    Icons.nightlight_round,
    Icons.star,
  ];

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
        _selectedIcon = Icons.favorite;
        _enableNotification = false;
      });
    } catch (e) {
      log(e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error adding habit: $e')));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundCream,
        appBar: AppBar(
          backgroundColor: AppColors.primaryBlue,
          title: const Text(
            'Add New Habit',
            style: TextStyle(color: Colors.white),
          ),
          centerTitle: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                _buildCard(
                  child: TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Habit Name',
                      prefixIcon: Icon(Icons.title),
                      // --- IMPORTANT: Remove the border ---
                      border: InputBorder.none,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a habit name';
                      }
                      return null;
                    },
                  ),
                ),
                _buildCard(
                  padding: const EdgeInsets.all(
                    16,
                  ), // This card needs more padding
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose an Icon',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _availableIcons.length,
                          itemBuilder: (context, index) {
                            final icon = _availableIcons[index];
                            final isSelected = icon == _selectedIcon;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedIcon = icon),
                              child: Container(
                                width: 60, // Give it a fixed width
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color:
                                      isSelected
                                          ? AppColors.primaryBlue
                                          : Colors.grey.shade200,
                                ),
                                child: Icon(
                                  icon,
                                  color:
                                      isSelected
                                          ? Colors.white
                                          : Colors.black54,
                                  size: 32,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _buildCard(
                  child: DropdownButtonFormField<String>(
                    value: _selectedFrequency,
                    decoration: InputDecoration(
                      labelText: 'Frequency',
                      prefixIcon: Icon(Icons.repeat),
                      // --- IMPORTANT: Remove the border ---
                      border: InputBorder.none,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Daily')),
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
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
                _buildCard(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      prefixIcon: Icon(Icons.description),
                      // --- IMPORTANT: Remove the border ---
                      border: InputBorder.none,
                    ),
                    maxLines: 3,
                  ),
                ),
                _buildCard(
                  padding: EdgeInsets.zero, // ListTile has its own padding
                  child: ListTile(
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
                      DateFormat('E, MMM d, yyyy').format(_selectedDate),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                    ),
                    onTap: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (newDate != null) {
                        setState(() {
                          _selectedDate = newDate;
                        });
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 75),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Add Habit',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    onPressed: _saveHabit,
                  ),
                ),
                const SizedBox(height: 20), // E
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Widget _buildCard({
  required Widget child,
  EdgeInsetsGeometry? padding, // Make padding optional
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 16), // Space *between* cards
    padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.07),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    // ClipRRect ensures the child (like ListTile) also has rounded corners
    child: ClipRRect(borderRadius: BorderRadius.circular(20.0), child: child),
  );
}
