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

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: _pages[currentIndex],
      bottomNavigationBar: BottomAppBar(
        color: AppColors.surfaceDark,
        height: MediaQuery.of(context).size.height * 0.08,
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
              icon: Icons.add,
              label: 'Add Habit',
              index: 1,
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

    final color = isSelected ? AppColors.primaryBlue : Colors.white;

    return Expanded(
      child: InkWell(
        onTap: () {
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
