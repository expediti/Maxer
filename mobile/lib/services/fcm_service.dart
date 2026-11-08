import 'package:flutter/foundation.dart';
import '../core/supabase_client.dart';

class FCMNotificationService {
  FCMNotificationService._();

  static Future<void> registerDeviceToken({
    required String candidateId,
    required String fcmToken,
    String platform = 'android',
  }) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      debugPrint('[REXAM FCM] Emulating device token registration for $candidateId.');
      return;
    }

    try {
      await client.from('device_tokens').upsert(
        {
          'candidate_id': candidateId,
          'fcm_token': fcmToken,
          'platform': platform,
          'last_active_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'fcm_token',
      );
      debugPrint('[REXAM FCM] Device token registered with Supabase.');
    } catch (e) {
      debugPrint('[REXAM FCM] Token registration error: $e');
    }
  }
}

