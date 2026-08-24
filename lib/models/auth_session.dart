import 'dart:convert';

import 'auth_user.dart';

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final AuthUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final accessToken = json['accessToken']?.toString().trim() ?? '';
    final refreshToken = json['refreshToken']?.toString().trim() ?? '';
    final userJson = json['user'];
    if (accessToken.isEmpty ||
        refreshToken.isEmpty ||
        userJson is! Map<String, dynamic>) {
      throw const FormatException('Stored authentication session is invalid');
    }

    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: AuthUser.fromJson(userJson),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'user': user.toJson(),
    };
  }

  AuthSession copyWithTokens({
    required String accessToken,
    required String refreshToken,
  }) {
    return AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
    );
  }

  bool isAccessTokenUsable({
    DateTime? now,
    Duration clockSkew = const Duration(seconds: 30),
  }) {
    final expiration = jwtExpiration(accessToken);
    if (expiration == null) return false;
    return expiration.isAfter((now ?? DateTime.now().toUtc()).add(clockSkew));
  }

  bool isRefreshTokenUsable({DateTime? now}) {
    final expiration = jwtExpiration(refreshToken);
    if (expiration == null) return false;
    return expiration.isAfter(now ?? DateTime.now().toUtc());
  }
}

DateTime? jwtExpiration(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    if (payload is! Map<String, dynamic>) return null;
    final expiration = payload['exp'];
    final seconds = expiration is num
        ? expiration.toInt()
        : int.tryParse(expiration?.toString() ?? '');
    if (seconds == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * Duration.millisecondsPerSecond,
      isUtc: true,
    );
  } catch (_) {
    return null;
  }
}
