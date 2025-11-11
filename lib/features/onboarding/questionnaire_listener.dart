import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_app/core/providers/supabase_provider.dart';
import 'package:habit_app/features/onboarding/questionnaire_screen.dart';
import 'package:habit_app/core/navigation.dart';

/// Place this widget near the top of your app (for example inside the widget returned by `App` or in `main`'s home)
/// It listens for auth state changes and — on first login — will show the questionnaire if not completed.
class QuestionnaireOnLoginLauncher extends ConsumerStatefulWidget {
  const QuestionnaireOnLoginLauncher({Key? key, required this.child})
    : super(key: key);

  final Widget child;

  @override
  ConsumerState<QuestionnaireOnLoginLauncher> createState() =>
      _QuestionnaireOnLoginLauncherState();
}

class _QuestionnaireOnLoginLauncherState
    extends ConsumerState<QuestionnaireOnLoginLauncher> {
  bool _launchedForThisSession = false;
  bool _listenerRegistered = false;

  void _registerListenerIfNeeded() {
    if (_listenerRegistered) return;
    _listenerRegistered = true;

    // Register the listener inside build-time context (allowed by Riverpod)
    ref.listen(authStateProvider, (previous, next) async {
      final authState = next.value;
      final user = authState?.session?.user;
      if (user != null && !_launchedForThisSession) {
        // Check completion
        final repo = ref.read(questionnaireRepoProvider);
        final completed = await repo.isCompleted(user.id);
        if (!completed && mounted) {
          // show questionnaire once
          _launchedForThisSession = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            // Use the app's global navigator key to ensure we push on the MaterialApp's
            // navigator. The listener widget is above MaterialApp in the tree, so
            // its BuildContext does not contain a Navigator.
            appNavigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const QuestionnaireScreen()),
            );
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Ensure listener is registered during build (Riverpod requires listen to be used in build)
    _registerListenerIfNeeded();
    return widget.child;
  }
}
