// lib/core/providers/supabase_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Auth state provider (listens to login/logout)
final authStateProvider = StreamProvider<AuthState>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user;
});

final userProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final authState = ref.watch(authStateProvider).value;

  final user = authState?.session?.user;
  if (user == null) return null;

  final response =
      await client
          .from('profiles')
          .select('name, phone, surname, email')
          .eq('id', user.id)
          .maybeSingle();

  return response;
});

// ----------------- Questionnaire Repository -----------------

class QuestionnaireRepository {
  final SupabaseClient _client;
  QuestionnaireRepository(this._client);

  /// Check whether the user has completed the questionnaire.
  Future<bool> isCompleted(String userId) async {
    final resp =
        await _client
            .from('profiles')
            .select('questionnaire_completed')
            .eq('id', userId)
            .maybeSingle();

    if (resp == null) return false;

    try {
      final map = resp as Map;
      return map['questionnaire_completed'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Save the questionnaire responses into the `profiles` table and mark completed.
  /// This uses upsert on `profiles` (requires `id` as primary key in the table).
  Future<void> saveResponses(
    String userId,
    Map<String, dynamic> responses,
  ) async {
    final authUser = _client.auth.currentUser;

    if (authUser == null) {
      throw Exception('No authenticated user in QuestionnaireRepository');
    }

    await _client.from('profiles').upsert({
      'id': userId,
      'email': authUser.email, // ✅ make NOT NULL constraint happy
      'questionnaire': responses, // json/jsonb column
      'questionnaire_completed': true,
    });
  }

  /// Optionally clear completion to allow retakes (if you want to allow retake later).
  Future<void> clearCompletion(String userId) async {
    await _client
        .from('profiles')
        .update({'questionnaire_completed': false})
        .eq('id', userId);
  }
}

final questionnaireRepoProvider = Provider<QuestionnaireRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return QuestionnaireRepository(client);
});

// Family provider to check completion status for a user id
final questionnaireCompletedProvider = FutureProvider.family<bool, String>((
  ref,
  userId,
) async {
  final repo = ref.watch(questionnaireRepoProvider);
  return repo.isCompleted(userId);
});
