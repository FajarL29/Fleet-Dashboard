import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session.dart';

abstract interface class AuthSessionStore {
  Future<AuthSession?> read();

  Future<void> write(AuthSession session);

  Future<void> clear();
}

/// Keeps the session in the platform's secure storage.
///
/// On macOS this throws unless the app carries a `keychain-access-groups`
/// entitlement — and adding one makes the build demand a development signing
/// certificate, which this project does not set up. So on an unsigned macOS
/// debug build every call here fails, and "remember me" simply does not
/// survive a restart. [AuthCubit] treats that as a convenience lost, never as
/// a failed sign-in.
///
/// To turn it on properly: open `macos/Runner.xcodeproj` in Xcode, pick a team
/// under Signing & Capabilities, then add the Keychain Sharing capability.
class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'fleet_safe_auth_session';

  final FlutterSecureStorage _storage;

  @override
  Future<AuthSession?> read() async {
    final encoded = await _storage.read(key: _sessionKey);
    if (encoded == null || encoded.trim().isEmpty) return null;

    try {
      final decoded = json.decode(encoded);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Stored session is not a JSON object');
      }
      return AuthSession.fromJson(decoded);
    } catch (_) {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(AuthSession session) {
    return _storage.write(
      key: _sessionKey,
      value: json.encode(session.toJson()),
    );
  }

  @override
  Future<void> clear() {
    return _storage.delete(key: _sessionKey);
  }
}
