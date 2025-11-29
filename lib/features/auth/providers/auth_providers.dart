import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/features/auth/data/auth_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exposes the current Supabase session reactively.
final authSessionProvider = StreamProvider<Session?>((ref) {
  final client = Supabase.instance.client;

  final controller = StreamController<Session?>();

  // Emit current session first
  controller.add(client.auth.currentSession);

  // Then emit on every auth state change
  final sub = client.auth.onAuthStateChange.listen((event) {
    controller.add(event.session);
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Repository provider
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Fetch current user profile (one-shot)
final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.getCurrentUserProfile();
});

/// ✅ Profile Guard:
/// If session exists BUT profile row is deleted, force sign out.
/// This solves your "I deleted DB users but app still logged in" issue.
final profileGuardProvider = StreamProvider<void>((ref) {
  final client = Supabase.instance.client;

  return client.auth.onAuthStateChange.asyncMap((event) async {
    final session = event.session;
    if (session == null) return;

    final userId = session.user.id;

    final profile =
        await client
            .from('profiles') // <-- if your table name differs, change here
            .select('id')
            .eq('id', userId)
            .maybeSingle();

    if (profile == null) {
      // Profile removed from DB → logout user
      await client.auth.signOut();
    }
  });
});
