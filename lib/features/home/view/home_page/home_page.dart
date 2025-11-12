import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final List<Widget> _pages = [HabitsPage(), AddHabitPage(), StatsPage()];

  @override
  Widget build(BuildContext context) {
    final currentIndex = ref.watch(bottomNavIndexProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundCream,
      body: _pages[currentIndex],
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 176, 208, 255),
            ),
            child: SafeArea(
              top: false,
              minimum: const EdgeInsets.only(top: 6),
              child: CupertinoTabBar(
                currentIndex: currentIndex,
                onTap: (index) {
                  ref.read(bottomNavIndexProvider.notifier).state = index;
                  HapticFeedback.selectionClick();
                },
                backgroundColor: Colors.transparent,
                border: const Border(),
                activeColor: AppColors.accentRed,
                inactiveColor: const Color.fromARGB(255, 29, 38, 60),
                iconSize: 22,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.check_mark_circled),
                    activeIcon: Icon(CupertinoIcons.check_mark_circled_solid),
                    label: 'Habits',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.add_circled),
                    activeIcon: Icon(CupertinoIcons.add_circled_solid),
                    label: 'Add Habit',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(CupertinoIcons.chart_bar),
                    activeIcon: Icon(CupertinoIcons.chart_bar_alt_fill),
                    label: 'Stats',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
