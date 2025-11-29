import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:habit_app/core/models/contants.dart';
import 'package:habit_app/features/auth/providers/auth_providers.dart';
import 'package:habit_app/features/auth/view/auth_page.dart';
import 'package:habit_app/features/home/view/home_page/home_page.dart';
import 'package:habit_app/core/navigation.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);

    // profile guard runs silently
    ref.watch(profileGuardProvider);

    // ✅ remove native splash once session is resolved (not loading)
    ref.listen(authSessionProvider, (prev, next) {
      if (next is AsyncData || next is AsyncError) {
        FlutterNativeSplash.remove();
      }
    });

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'SFPro',
        scaffoldBackgroundColor: AppColors.backgroundCream,
        canvasColor: AppColors.backgroundCream,
        colorScheme: const ColorScheme.light(
          primary: AppColors.primaryBlue,
          secondary: AppColors.accentRed,
          background: AppColors.backgroundCream,
          surface: Colors.white,
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
        data: (session) {
          return session == null ? const AuthPage() : const MainPage();
        },
      ),
    );
  }
}
