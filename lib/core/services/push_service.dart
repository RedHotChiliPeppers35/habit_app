import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushService {
  static final _messaging = FirebaseMessaging.instance;
  static final _supabase = Supabase.instance.client;

  static Future<void> initAndRegisterToken() async {
    try {
      await _messaging.requestPermission();

      // Retrieve both tokens
      final fcmToken = await _messaging.getToken();
      final apnsToken = Platform.isIOS ? await _messaging.getAPNSToken() : null;

      if (fcmToken == null && apnsToken == null) {
        print('❌ No push tokens available.');
        return;
      }

      final user = _supabase.auth.currentUser;
      if (user == null) {
        print('❌ No user logged in.');
        return;
      }

      final environment = kDebugMode ? 'sandbox' : 'production';

      // 💾 Store both tokens in Supabase
      await _supabase.from('device_tokens').upsert({
        'user_id': user.id,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'environment': environment,
        'token': apnsToken, // APNs (for direct Apple route)
        'fcm_token': fcmToken, // FCM fallback
      });

      print('✅ Registered tokens → APNs: $apnsToken, FCM: $fcmToken');
    } catch (e) {
      print('🚨 Error registering tokens: $e');
    }

    // Listen for token refresh
    _messaging.onTokenRefresh.listen((newToken) async {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      await _supabase.from('device_tokens').upsert({
        'user_id': user.id,
        'fcm_token': newToken,
        'platform': Platform.isIOS ? 'ios' : 'android',
        'environment': kDebugMode ? 'sandbox' : 'production',
      });

      print('🔄 FCM token refreshed: $newToken');
    });
  }
}
