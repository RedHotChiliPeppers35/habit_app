import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter/foundation.dart'; // kDebugMode

import 'package:habit_app/core/link/auth_link_handler.dart';
import 'package:habit_app/core/env.dart';
import 'package:habit_app/app.dart';
import 'package:habit_app/features/onboarding/questionnaire_listener.dart';

Future<void> saveAPNsTokenToSupabase(String token) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;

  // ✅ SAFE FLOW: don't write when no user
  if (user == null) {
    debugPrint("⚠️ No user yet, skipping token save.");
    return;
  }

  final environment = kDebugMode ? 'sandbox' : 'production';

  final row = <String, dynamic>{
    'platform': 'ios',
    'environment': environment,
    'token': token,
    'user_id': user.id, // ✅ always attach
  };

  try {
    await supabase
        .from('device_tokens')
        .upsert(row, onConflict: 'token,platform,environment');

    debugPrint('✅ Token upserted for logged-in user ($environment)');
  } catch (e) {
    debugPrint('❌ Error upserting APNs token to Supabase: $e');
  }
}

/// Listen for APNs token from iOS via MethodChannel
void setupAPNSTokenListener() {
  const channel = MethodChannel('apns_channel');

  channel.setMethodCallHandler((call) async {
    if (call.method == 'apnsToken') {
      final token = call.arguments as String;
      debugPrint('📲 Received APNs token from iOS: $token');
      await saveAPNsTokenToSupabase(token);
    }
  });
}

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await dotenv.load(fileName: ".env").catchError((_) {});
  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  debugPrint("✅ Supabase init completed");

  setupAPNSTokenListener();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.manual,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(
    const ProviderScope(
      child: AuthLinkHandler(
        child: QuestionnaireOnLoginLauncher(child: MyApp()),
      ),
    ),
  );
}
