import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  static const _tokenKey = 'pigeonfly_session_jwt';
  static const _userKey = 'pigeonfly_user_json';
  static const _deviceKey = 'pigeonfly_device_id';

  /// Stable per-install device id (created once, reused). Sent to /auth/session.
  Future<String> getOrCreateDeviceId() async {
    try {
      var id = await _storage.read(key: _deviceKey);
      if (id == null || id.isEmpty) {
        id = 'android-${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().hashCode}';
        await _storage.write(key: _deviceKey, value: id);
      }
      return id;
    } catch (_) {
      return 'android-${DateTime.now().microsecondsSinceEpoch}';
    }
  }

  Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } catch (_) {}
  }

  Future<String?> getToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } catch (_) {
      return null;
    }
  }

  /// Current user's id, decoded from the session JWT's `sub` claim. Null if no
  /// (valid) token. Used by the UI to tell "my" messages from the other side's.
  Future<String?> getUserId() async {
    final token = await getToken();
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final map = jsonDecode(utf8.decode(base64.decode(payload))) as Map<String, dynamic>;
      return map['sub']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveUserData(String userJson) async {
    try {
      await _storage.write(key: _userKey, value: userJson);
    } catch (_) {}
  }

  Future<String?> getUserData() async {
    try {
      return await _storage.read(key: _userKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _tokenKey);
      await _storage.delete(key: _userKey);
    } catch (_) {}
  }

  Future<void> writeCustom(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }

  Future<String?> readCustom(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }
}
