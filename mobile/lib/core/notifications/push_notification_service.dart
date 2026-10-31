import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:permission_handler/permission_handler.dart';
import '../network/api_client.dart';
import '../local_storage/secure_storage_service.dart';
import '../../config/env/app_env.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handles background push notification when the app is terminated or in the background
}

class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  static bool _initialized = false;

  /// Initializes notification permissions, background handlers, and foreground listeners.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // On Android 13+, explicitly request notification runtime permission
      if (Platform.isAndroid) {
        await Permission.notification.request();
      }

      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // Handle message when app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final title = message.notification?.title ?? message.data['title'] ?? 'PigeonFly';
        final body = message.notification?.body ?? message.data['body'];

        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            backgroundColor: const Color(0xFF1E293B),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: Color(0xFF10B981)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                      ),
                      if (body != null && body.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            body,
                            style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      });

      // Handle message click when app is opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        // App opened from notification
      });
    } catch (_) {
      // Running on environment without Play Services or web
    }
  }

  /// Retrieves the device FCM registration token safely.
  static Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      return token;
    } catch (_) {
      return null;
    }
  }

  /// Registers/updates this device and its FCM token on the backend.
  static Future<void> syncDeviceToken({
    required ApiClient api,
    required SecureStorageService storage,
  }) async {
    try {
      final deviceId = await storage.getOrCreateDeviceId();
      final fcmToken = await getToken();
      final deviceType = Platform.isIOS ? 'ios' : 'android';

      await api.post<dynamic>(
        '/auth/device',
        data: {
          'device_id': deviceId,
          'device_type': deviceType,
          'fcm_token': fcmToken,
          'app_version': AppEnv.appVersion,
        },
      );
    } catch (_) {
      // Best-effort sync on launch or background
    }
  }
}
