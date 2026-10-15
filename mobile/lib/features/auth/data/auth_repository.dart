import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../core/network/api_client.dart';
import '../../../core/local_storage/secure_storage_service.dart';
import '../../../config/env/app_env.dart';

/// Outcome of a Google sign-in attempt.
enum AuthOutcomeType { authenticated, onboarding, cancelled }

class AuthOutcome {
  final AuthOutcomeType type;
  final String? email;
  final String? name;
  const AuthOutcome(this.type, {this.email, this.name});
}

/// Real auth: Google sign-in -> Firebase credential -> Firebase ID token ->
/// backend POST /auth/session -> store session JWT (or temp token for onboarding).
class AuthRepository {
  final ApiClient _api;
  final SecureStorageService _storage;
  final GoogleSignIn _google = GoogleSignIn(scopes: ['email', 'profile']);

  AuthRepository(this._api, this._storage);

  Future<AuthOutcome> signInWithGoogle() async {
    try {
      print('[AuthRepository] Starting GoogleSignIn.signIn()...');
      final gUser = await _google.signIn();
      if (gUser == null) {
        print('[AuthRepository] GoogleSignIn cancelled by user');
        return const AuthOutcome(AuthOutcomeType.cancelled);
      }
      print('[AuthRepository] Google user selected: ${gUser.email}, displayName: ${gUser.displayName}');

      final gAuth = await gUser.authentication;
      print('[AuthRepository] Got google tokens: idToken=${gAuth.idToken != null}, accessToken=${gAuth.accessToken != null}');
      final credential = GoogleAuthProvider.credential(
        idToken: gAuth.idToken,
        accessToken: gAuth.accessToken,
      );
      print('[AuthRepository] Signing in to Firebase with Google credential...');
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      print('[AuthRepository] Firebase user uid: ${userCred.user?.uid}');
      final idToken = await userCred.user?.getIdToken();
      if (idToken == null) throw Exception('Could not get Firebase ID token');
      print('[AuthRepository] Got Firebase idToken (length: ${idToken.length})');

      final deviceId = await _storage.getOrCreateDeviceId();
      print('[AuthRepository] Posting to backend /auth/session...');
      final res = await _api.post<Map<String, dynamic>>(
        '/auth/session',
        data: {
          'id_token': idToken,
          'device_id': deviceId,
          'device_type': 'android',
          'app_version': AppEnv.appVersion,
        },
        fromJson: (d) => (d as Map).cast<String, dynamic>(),
      );

      if (!res.isSuccess) {
        final err = (res as dynamic).message ?? 'Sign-in failed';
        print('[AuthRepository] Backend /auth/session error: $err');
        throw Exception(err);
      }
      final data = (res as dynamic).data as Map<String, dynamic>;
      print('[AuthRepository] Backend session response: $data');

      if (data['onboarding_required'] == true) {
        print('[AuthRepository] User requires onboarding. Saving temp_token...');
        await _storage.saveToken(data['temp_token'] as String);
        return AuthOutcome(AuthOutcomeType.onboarding, email: gUser.email, name: gUser.displayName);
      }
      print('[AuthRepository] User existing session authenticated. Saving session_token...');
      await _storage.saveToken(data['session_token'] as String);
      return const AuthOutcome(AuthOutcomeType.authenticated);
    } catch (e, st) {
      print('[AuthRepository] ERROR in signInWithGoogle: $e\n$st');
      rethrow;
    }
  }

  Future<void> completeSignup({
    required String name,
    required String username,
    required String language,
  }) async {
    final deviceId = await _storage.getOrCreateDeviceId();
    final res = await _api.post<Map<String, dynamic>>(
      '/auth/complete-signup',
      data: {
        'display_name': name,
        'username': username,
        'language_code': language,
        'device_id': deviceId,
        'device_type': 'android',
      },
      fromJson: (d) => (d as Map).cast<String, dynamic>(),
    );
    if (!res.isSuccess) throw Exception((res as dynamic).message ?? 'Signup failed');
    final data = (res as dynamic).data as Map<String, dynamic>;
    await _storage.saveToken(data['session_token'] as String);
  }

  Future<AuthOutcome> checkSession() async {
    try {
      // 1. Local-first: a stored, unexpired session JWT means the user is already
      //    signed in. Trust it WITHOUT a network round-trip, so the app stays logged
      //    in across cold starts (and while offline / the backend is slow) until the
      //    user logs out or the token actually expires. This is what keeps the splash
      //    fast and stops the "log in on every launch" behaviour.
      //    Server-side revocation (block/suspend/logout-everywhere) is caught lazily:
      //    the first authenticated API call returns 401 and the app signs out then.
      final token = await _storage.getToken();
      if (token != null && token.isNotEmpty && _isTokenValid(token)) {
        return const AuthOutcome(AuthOutcomeType.authenticated);
      }

      // 2. No usable local token (missing/expired/malformed) → silent restore via
      //    Firebase Auth (persists natively on the device), which transparently mints
      //    a fresh backend session without showing the sign-in screen:
      // If user was previously logged in on this device, Firebase currentUser persists natively!
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null) {
        print('[AuthRepository] Silent restore from Firebase user: ${fbUser.email}');
        final idToken = await fbUser.getIdToken();
        if (idToken != null) {
          final deviceId = await _storage.getOrCreateDeviceId();
          final res = await _api.post<Map<String, dynamic>>(
            '/auth/session',
            data: {
              'id_token': idToken,
              'device_id': deviceId,
              'device_type': 'android',
              'app_version': AppEnv.appVersion,
            },
            fromJson: (d) => (d as Map).cast<String, dynamic>(),
          );

          if (res.isSuccess) {
            final data = (res as dynamic).data as Map<String, dynamic>;
            if (data['onboarding_required'] == true) {
              await _storage.saveToken(data['temp_token'] as String);
              return AuthOutcome(
                AuthOutcomeType.onboarding,
                email: fbUser.email,
                name: fbUser.displayName,
              );
            }
            await _storage.saveToken(data['session_token'] as String);
            return AuthOutcome(
              AuthOutcomeType.authenticated,
              email: fbUser.email,
              name: fbUser.displayName,
            );
          }
        }
      }
    } catch (e) {
      print('[AuthRepository] checkSession error: $e');
    }

    return const AuthOutcome(AuthOutcomeType.cancelled);
  }

  Future<bool> hasSession() async {
    final outcome = await checkSession();
    return outcome.type == AuthOutcomeType.authenticated;
  }

  /// True when [token] is a well-formed JWT that has not expired (10s leeway).
  /// Decodes only the `exp` claim locally — no signature check (the server stays the
  /// final authority via 401 on real calls). A token with no `exp` is treated as
  /// valid; a malformed token is invalid so we fall back to Firebase silent restore.
  bool _isTokenValid(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      var payload = parts[1].replaceAll('-', '+').replaceAll('_', '/');
      while (payload.length % 4 != 0) {
        payload += '=';
      }
      final map =
          jsonDecode(utf8.decode(base64.decode(payload))) as Map<String, dynamic>;
      final exp = map['exp'];
      if (exp is! num) return true; // no exp claim → let the server decide
      final expiryMs = exp.toInt() * 1000;
      return DateTime.now().millisecondsSinceEpoch < (expiryMs - 10000);
    } catch (_) {
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await _google.signOut();
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    await _storage.clearSession();
  }
}
