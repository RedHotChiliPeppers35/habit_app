import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/core/models/habits.dart';
import 'package:habit_app/core/providers/habit_service_provider.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
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
    return Scaffold(
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
              // Habit Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Habit Name',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a habit name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Habit Icon Selector
              const Text(
                'Choose an Icon',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 10),
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
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,

                          color:
                              isSelected
                                  ? AppColors.primaryBlue
                                  : Colors.grey.shade200,
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primaryBlue
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: isSelected ? Colors.white : Colors.black54,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Frequency Dropdown
              DropdownButtonFormField<String>(
                value: _selectedFrequency,
                decoration: InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.repeat),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Daily')),
                  DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                  DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedFrequency = value);
                  }
                },
              ),
              const SizedBox(height: 20),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Notification Toggle
              SwitchListTile(
                title: const Text('Enable Daily Push Notification'),
                value: _enableNotification,
                activeColor: AppColors.primaryBlue,
                onChanged: (value) {
                  setState(() => _enableNotification = value);
                },
              ),
              const SizedBox(height: 30),

              // Submit Button
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
            ],
          ),
        ),
      ),
    );
  }
}
