import 'dart:io';
import 'package:flutter/foundation.dart';

class AppEnv {
  AppEnv._();

  /// Use the LIVE (deployed) backend on Render. Set to `false` to develop
  /// against a local server (localhost / your Mac's LAN IP) instead.
  static const bool useLiveBackend = true;

  /// Deployed backend origin — no trailing slash, no `/v1`.
  static const String liveHost = 'https://pigeon-system-backend.onrender.com';

  /// Your Mac machine local Wi-Fi IP address — ONLY used when
  /// [useLiveBackend] is false (local dev on a real device).
  /// Re-check with `ipconfig getifaddr en0` on the Mac if it changes.
  static const String machineIp = '192.168.1.12';

  static String get baseUrl {
    // Live deployment — works from any network (phone, emulator, web).
    if (useLiveBackend) return '$liveHost/v1';

    // ── local dev ──
    // Web: runs inside Chrome on this machine
    if (kIsWeb) return 'http://localhost:3000/v1';
    // Android real device over Wi-Fi uses the Mac's LAN IP (fallback to
    // 127.0.0.1 for USB `adb reverse tcp:3000 tcp:3000`).
    if (Platform.isAndroid) return 'http://$machineIp:3000/v1';
    // iOS real device needs the LAN IP; simulator can use localhost.
    if (Platform.isIOS) return 'http://$machineIp:3000/v1';
    // macOS Desktop or Linux/Windows
    return 'http://127.0.0.1:3000/v1';
  }

  /// Socket.io server base (no /v1 path) — same host as the API, for real-time.
  static String get socketUrl {
    if (useLiveBackend) return liveHost;
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid || Platform.isIOS) return 'http://$machineIp:3000';
    return 'http://127.0.0.1:3000';
  }

  static const String appVersion = '1.0.0';
}
