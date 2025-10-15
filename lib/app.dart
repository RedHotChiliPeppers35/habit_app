import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/features/auth/providers/auth_providers.dart';
import 'package:habit_app/features/auth/view/auth_page.dart';
import 'package:habit_app/features/home/view/home_page.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(authSessionProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
      ),
      home: sessionAsync.when(
        loading:
            () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
        error: (e, _) => Scaffold(body: Center(child: Text('Auth error: $e'))),
        data:
            (session) =>
                session == null ? const AuthPage() : const HabitsPage(),
      ),
    );
  }
}
