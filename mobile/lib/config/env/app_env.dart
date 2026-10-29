import 'dart:io';
import 'package:flutter/foundation.dart';

class AppEnv {
  AppEnv._();

  /// Your Mac machine local Wi-Fi IP address.
  /// Used for real physical devices (Android via Wi-Fi/USB & iOS).
  /// NOTE: this changes when the router/DHCP reassigns — re-check with
  /// `ipconfig getifaddr en0` on the Mac and update here if login times out.
  static const String machineIp = '192.168.1.12';

  static String get baseUrl {
    // Web: runs inside Chrome on this machine
    if (kIsWeb) {
      return 'http://localhost:3000/v1';
    }

    // Android physical device over Wi-Fi: use the Mac's LAN IP so no
    // `adb reverse` is required (phone + Mac must be on the same Wi-Fi).
    // If the connection is refused the ApiClient falls back to 127.0.0.1,
    // which works when the port IS reversed over USB
    // (`adb reverse tcp:3000 tcp:3000`).
    if (Platform.isAndroid) {
      return 'http://$machineIp:3000/v1';
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
