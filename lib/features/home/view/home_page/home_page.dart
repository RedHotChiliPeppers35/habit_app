import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/features/home/view/add_habit/add_habit.dart';
import 'package:habit_app/features/home/providers/habit_provider.dart';
import 'package:habit_app/features/home/view/home_page/habit_dialogs.dart';
import 'package:habit_app/features/home/view/stats_dart/stats_home.dart';

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
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: _pages[currentIndex],

      floatingActionButton:
          isKeyboardVisible || isAddHabitSelected
              ? null
              : FloatingActionButton(
                onPressed: () {
                  ref.read(bottomNavIndexProvider.notifier).state = 1;
                },

                backgroundColor:
                    isAddHabitSelected
                        ? AppColors.accentRed
                        : AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 4.0,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 30),
              ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: AppColors.accentDark,
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          children: <Widget>[
            _buildBottomNavItem(
              context,
              ref: ref,
              icon: Icons.check,
              label: 'Habits',
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
