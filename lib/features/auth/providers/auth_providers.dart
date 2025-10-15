import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/features/auth/data/auth_repo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exposes the current Supabase session reactively.
final authSessionProvider = StreamProvider<Session?>((ref) {
  final client = Supabase.instance.client;

  // Emit current session firstd
  final controller = StreamController<Session?>();
  controller.add(client.auth.currentSession);

  final sub = client.auth.onAuthStateChange.listen((event) {
    controller.add(event.session);
  });

  ref.onDispose(() {
    sub.cancel();
    controller.close();
  });

  return controller.stream;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final repo = ref.read(authRepositoryProvider);
  return repo.getCurrentUserProfile();
});
