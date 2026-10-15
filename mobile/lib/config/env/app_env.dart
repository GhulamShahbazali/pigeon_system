import 'dart:io';
import 'package:flutter/foundation.dart';

class AppEnv {
  AppEnv._();

  /// Your Mac machine local Wi-Fi IP address.
  /// Used for real physical devices (Android via Wi-Fi/USB & iOS).
  static const String machineIp = '192.168.0.101';

  static String get baseUrl {
    // Web: runs inside Chrome on this machine
    if (kIsWeb) {
      return 'http://localhost:3000/v1';
    }

    // Android:
    // If USB connected or port reversed via adb (`adb reverse tcp:3000 tcp:3000`),
    // localhost:3000 connects directly at 0ms latency without Wi-Fi drops.
    // If running over Wi-Fi, 192.168.0.101 works.
    if (Platform.isAndroid) {
      return 'http://127.0.0.1:3000/v1';
    }

    // iOS Real Device needs machineIp, Simulator can use localhost.
    if (Platform.isIOS) {
      return 'http://$machineIp:3000/v1';
    }

    // macOS Desktop or Linux/Windows
    return 'http://127.0.0.1:3000/v1';
  }

  /// Socket.io server base (no /v1 path) — same host as the API, for real-time.
  static String get socketUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid || Platform.isIOS) return 'http://$machineIp:3000';
    return 'http://127.0.0.1:3000';
  }

  static const String appVersion = '1.0.0';
}
