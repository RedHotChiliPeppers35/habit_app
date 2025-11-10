import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/features/auth/providers/auth_providers.dart';
import 'package:habit_app/features/auth/view/auth_page.dart';
import 'package:habit_app/features/home/view/home_page/home_page.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.backgroundCream,
        fontFamily: 'SFPro', // since you already added SF Pro
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryBlue,
          background: AppColors.backgroundCream,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.surfaceDark,
          contentTextStyle: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      home: sessionAsync.when(
        loading:
            () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
        error: (e, _) => Scaffold(body: Center(child: Text('Auth error: $e'))),
        data:
            (session) => session == null ? const AuthPage() : const MainPage(),
      ),
    );
  }
}
