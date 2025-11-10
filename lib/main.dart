import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:habit_app/core/link/auth_link_handler.dart';
import 'package:habit_app/firebase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:habit_app/core/env.dart';
import 'package:habit_app/app.dart';

Future<void> safeInitializeFirebase() async {
  try {
    // 🕒 Wait briefly in case native iOS initialization finishes first
    await Future.delayed(const Duration(milliseconds: 500));

    if (Firebase.apps.isNotEmpty) {
      print('✅ Firebase already initialized (native or Dart).');
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized manually.');
  } catch (e) {
    if (e.toString().contains('duplicate-ata.bapp')) {
      print('⚠️ Duplicate Firebase app detected — safe to ignore.');
    } else {
      print('❌ Firebase init failed: $e');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  await safeInitializeFirebase();

  try {
    final messaging = FirebaseMessaging.instance;
    final fcmToken = await messaging.getToken();
    String? apnsToken;

    if (!Platform.isIOS) {
      apnsToken = null;
    } else {
      final isSimulator = Platform.environment.containsKey(
        'SIMULATOR_DEVICE_NAME',
      );
      apnsToken = isSimulator ? null : await messaging.getAPNSToken();
    }

    print('📱 FCM Token: $fcmToken');
    print('🍎 APNs Token: $apnsToken');
  } catch (e) {
    print('⚠️ Firebase Messaging init error: $e');
  }
  runApp(const ProviderScope(child: AuthLinkHandler(child: MyApp())));
}
