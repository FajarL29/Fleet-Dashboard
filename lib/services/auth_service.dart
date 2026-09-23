import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import '../models/auth_user.dart';
import 'api_config.dart';
import 'deployment_check.dart';

/// A sign-in or sign-up the server refused, carrying a message meant to be
/// shown to the user.
///
/// Anything else — a socket that never connected, a body that would not
/// parse — surfaces as its own error, so the UI can tell "your password is
/// wrong" apart from "we could not reach the server".
class AuthException implements Exception {
  const AuthException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'AuthException($statusCode): $message';
}

/// Signs in and keeps a usable bearer token around.
///
/// The API issues tokens that expire after about an hour, so pasting one into
/// the source or a --dart-define only works until it lapses. This logs in with
/// credentials and refreshes shortly before each token runs out.
class AuthService {
  AuthService({http.Client? client}) : _ownedClient = client;

  /// Shared instance: every service reads its token from the same place, so
  /// one login serves the whole app.
  static final AuthService instance = AuthService();

  /// Client this instance owns, closed by [close]. The register page builds a
  /// short-lived service and disposes it when the page pops.
  http.Client? _ownedClient;

  /// Refresh this long before the token actually lapses, so a request never
  /// leaves with a token that dies in flight.
  static const Duration _refreshMargin = Duration(minutes: 2);

  String? _token;
  DateTime? _expiresAt;

  /// The signed-in person's session, when there is one. Takes precedence over
  /// the build-time service account below, so an expiring user session can
  /// never silently downgrade the app to querying as somebody else.
  AuthSession? _session;

  /// In-flight login, shared so concurrent callers do not each sign in.
  Future<String?>? _pending;

  @visibleForTesting
  http.Client? clientOverride;

  @visibleForTesting
  void reset() {
    _token = null;
    _expiresAt = null;
    _pending = null;
    _session = null;
  }

  /// Releases the HTTP client this instance owns. Safe to call twice, and a
  /// no-op on [instance], which never owns one.
  void close() {
    _ownedClient?.close();
    _ownedClient = null;
  }

  http.Client get _client => clientOverride ?? (_ownedClient ??= http.Client());

  bool get _hasCredentials =>
      kApiUsername.trim().isNotEmpty && kApiPassword.trim().isNotEmpty;

  /// The session the app is currently acting as, or null when nobody has
  /// signed in.
  AuthSession? get session => _session;

  /// The bearer token for outgoing requests, read synchronously.
  ///
  /// [AuthenticatedHttpClient] stamps this onto every request, so it has to
  /// answer without awaiting: a signed-in session first, then the build-time
  /// escape hatch, then whatever the service account last cached.
  String? get currentToken {
    final sessionToken = _session?.accessToken.trim();
    if (sessionToken != null && sessionToken.isNotEmpty) return sessionToken;
    if (kApiAuthToken.trim().isNotEmpty) return kApiAuthToken.trim();
    return _token;
  }

  bool get _cachedTokenIsUsable {
    if (_token == null) return false;
    final expiry = _expiresAt;
    if (expiry == null) return true;
    return DateTime.now().isBefore(expiry.subtract(_refreshMargin));
  }

  /// Bearer token for outgoing requests, or null when the app has neither a
  /// preset token nor credentials to log in with.
  Future<String?> token() async {
    final sessionToken = _session?.accessToken.trim();
    if (sessionToken != null && sessionToken.isNotEmpty) return sessionToken;
    if (kApiAuthToken.trim().isNotEmpty) return kApiAuthToken.trim();
    if (_cachedTokenIsUsable) return _token;
    if (!_hasCredentials) return null;

    return _pending ??= _login().whenComplete(() => _pending = null);
  }

  /// Drops the cached token so the next request signs in again. Call this
  /// when the server rejects a token it previously accepted.
  void invalidate() {
    _token = null;
    _expiresAt = null;
  }

  /// Forgets the signed-in person. The service account, if one is configured,
  /// stays available for the pages that render before anyone logs in.
  void clearSession() {
    _session = null;
    invalidate();
    if (!identical(this, instance)) {
      instance._session = null;
      instance.invalidate();
    }
  }

  Future<String?> _login() async {
    final client = clientOverride ?? http.Client();
    final shouldClose = clientOverride == null;

    try {
      final response = await client
          .post(
            Uri.parse('$kApiBaseUrl/auth/login'),
            headers: const {'Content-Type': 'application/json'},
            body: json.encode({
              'username': kApiUsername.trim(),
              'password': kApiPassword,
            }),
          )
          .timeout(kApiRequestTimeout);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        if (kDebugMode) {
          debugPrint('[Auth] Login failed ${response.statusCode}');
        }
        return null;
      }

      final token = _extractToken(json.decode(response.body));
      if (token == null) {
        if (kDebugMode) {
          debugPrint('[Auth] Login response carried no token');
        }
        return null;
      }

      _token = token;
      _expiresAt = _expiryOf(token);
      if (kDebugMode) {
        debugPrint('[Auth] Signed in, token valid until ${_expiresAt ?? '?'}');
      }
      return token;
    } catch (error) {
      if (kDebugMode) debugPrint('[Auth] Login error: $error');
      return null;
    } finally {
      if (shouldClose) client.close();
    }
  }

  // ---------------------------------------------------------------------
  // Account operations
  //
  // The methods above keep the app's own service-to-service token alive. The
  // ones below act for a person signing in or signing up, and they throw
  // [AuthException] instead of returning null so the form can show why.
  // ---------------------------------------------------------------------

  /// Signs a person in and returns their session.
  ///
  /// Throws [AuthException] when the server rejects the credentials or answers
  /// with a body that carries no usable session.
  Future<AuthSession> signIn({
    required String username,
    required String password,
  }) async {
    final decoded = await _send('auth/login', <String, dynamic>{
      'username': username.trim(),
      'password': password,
    }, onError: 'Incorrect username or password.');

    final session = _sessionFrom(decoded);
    if (session == null) {
      throw const AuthException('Sign-in response carried no session.');
    }

    adoptSession(session);
    return session;
  }

  /// Creates an account. The API does not sign the new user in, so the caller
  /// sends them back to the login page afterwards.
  Future<void> register({
    required String fullname,
    required String username,
    required String password,
    required String role,
    required String division,
  }) async {
    await _send('auth/register', <String, dynamic>{
      'fullname': fullname.trim(),
      'username': username.trim(),
      'password': password,
      'role': role.trim(),
      'division': division.trim(),
    }, onError: 'Unable to create the account.');
  }

  /// Points the shared token cache at a signed-in person's token.
  ///
  /// Without this the data services would keep using the build-time service
  /// account, so the dashboard would show the same rows no matter who logged
  /// in.
  void adoptSession(AuthSession session) {
    _session = session;
    _token = session.accessToken;
    _expiresAt = _expiryOf(session.accessToken);

    // Mirror onto the singleton so anything still reading
    // `AuthService.instance` sees the same person. In production this *is* the
    // singleton; the copy only matters when a test injects its own service.
    if (!identical(this, instance)) {
      instance._session = session;
      instance._token = session.accessToken;
      instance._expiresAt = _expiresAt;
    }
  }

  /// Tells the server to retire the current session.
  ///
  /// Best-effort: signing out locally must succeed even when the network does
  /// not, so a failure here is logged and swallowed. Deliberately sent on this
  /// service's own client rather than [AuthenticatedHttpClient] — a 401 there
  /// would trigger the session-invalid callback, which is what called this.
  Future<void> signOut() async {
    final token = currentToken;
    if (token == null || token.isEmpty) return;

    try {
      await _client
          .post(
            Uri.parse('$kApiBaseUrl/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(kApiRequestTimeout);
    } catch (error) {
      if (kDebugMode) debugPrint('[Auth] Server sign-out failed: $error');
    }
  }

  /// Trades a refresh token for a fresh session.
  ///
  /// Throws [AuthException] when the server refuses, which the caller reads as
  /// "this session is over" rather than as a transient failure.
  Future<AuthSession> refresh(String refreshToken) async {
    final decoded = await _send('auth/refresh', <String, dynamic>{
      'refreshToken': refreshToken,
    }, onError: 'Your session has expired. Please sign in again.');

    // A refresh response usually carries only tokens. Where it does not
    // describe the user, the person we already know about is still the person
    // signed in, so reuse them rather than failing the refresh.
    final refreshed = _sessionFrom(decoded) ?? _reissue(decoded, _session);
    if (refreshed == null) {
      throw const AuthException('Refresh response carried no session.');
    }

    adoptSession(refreshed);
    return refreshed;
  }

  /// Rebuilds a session from a token-only refresh response plus the user we
  /// already had. Null when the response carried no token either.
  static AuthSession? _reissue(dynamic decoded, AuthSession? previous) {
    if (previous == null) return null;
    final accessToken = _extractToken(decoded);
    if (accessToken == null) return null;

    return previous.copyWithTokens(
      accessToken: accessToken,
      refreshToken: _findRefreshToken(decoded) ?? previous.refreshToken,
    );
  }

  /// POSTs [body] to [path] and returns the decoded response.
  ///
  /// Turns a refusal into an [AuthException] carrying the server's own message
  /// where it sends one, falling back to [onError].
  Future<dynamic> _send(
    String path,
    Map<String, dynamic> body, {
    required String onError,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$kApiBaseUrl/$path'),
            headers: const {'Content-Type': 'application/json'},
            body: json.encode(body),
          )
          .timeout(kApiRequestTimeout);
    } catch (error) {
      if (kDebugMode)
        debugPrint('[Auth] POST $kApiBaseUrl/$path failed: $error');

      // A configuration that cannot work is reported even in release: it is
      // not a transient network blip, and telling the person in front of the
      // screen to "check your connection" would send them chasing the wrong
      // thing entirely.
      final misconfigured = DeploymentCheck.problem;
      if (misconfigured != null) throw AuthException(misconfigured);

      // Otherwise the address is named in debug builds, because "could not
      // reach the server" hides the one fact that identifies the problem.
      // Pointed at a proxy that is not running, or at a host the browser
      // blocks for CORS, the symptom is identical. Release builds keep the
      // plain wording: an end user cannot act on a hostname.
      throw AuthException(
        kDebugMode
            ? 'Could not reach $kApiBaseUrl — is it running, and is this '
                  'build pointed at the right address?'
            : 'Could not reach the server. Check your connection and try '
                  'again.',
      );
    }

    final decoded = _decode(response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        _messageFrom(decoded) ?? onError,
        statusCode: response.statusCode,
      );
    }

    return decoded;
  }

  static dynamic _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return json.decode(body);
    } catch (_) {
      return null;
    }
  }

  /// Pulls the error text out of whichever field the API used for it.
  static String? _messageFrom(dynamic decoded) {
    if (decoded is! Map) return null;
    for (final key in const ['message', 'error', 'detail', 'msg']) {
      final value = decoded[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  /// Builds a session from a login response.
  ///
  /// The refresh token and the user object are optional in practice: some
  /// deployments return only an access token, so the JWT's own claims stand in
  /// rather than failing the sign-in outright.
  static AuthSession? _sessionFrom(dynamic decoded) {
    final accessToken = _extractToken(decoded);
    if (accessToken == null) return null;

    // Nested, because the API wraps its payload in a `data` envelope — the
    // same reason [_extractToken] recurses rather than reading the top level.
    final refreshToken = _findRefreshToken(decoded) ?? accessToken;

    final userJson = _findUser(decoded) ?? _claimsOf(accessToken);
    if (userJson == null) return null;

    try {
      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: AuthUser.fromJson(userJson),
      );
    } on FormatException {
      return null;
    }
  }

  /// Finds the refresh token wherever the response nests it.
  ///
  /// Kept separate from [_extractToken] so the two can never pick each other
  /// up: handing the access token back as the refresh token would make every
  /// refresh fail in a way that looks like an expired session.
  static String? _findRefreshToken(dynamic decoded) {
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        final key = entry.key.toString().toLowerCase().replaceAll('_', '');
        final value = entry.value;
        if (value is String &&
            value.trim().isNotEmpty &&
            key == 'refreshtoken') {
          return value.trim();
        }
        final nested = _findRefreshToken(value);
        if (nested != null) return nested;
      }
    } else if (decoded is List) {
      for (final value in decoded) {
        final nested = _findRefreshToken(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  /// Finds the user object wherever the response nests it, mirroring how
  /// [_extractToken] hunts for the token.
  static Map<String, dynamic>? _findUser(dynamic decoded) {
    if (decoded is Map) {
      final direct = decoded['user'] ?? decoded['data'];
      if (direct is Map<String, dynamic> && direct['username'] != null) {
        return direct;
      }
      if (decoded['username'] != null && decoded['user_id'] != null) {
        return Map<String, dynamic>.from(decoded);
      }
      for (final value in decoded.values) {
        final nested = _findUser(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  /// Falls back to the JWT's own claims when the response body describes only
  /// the token.
  static Map<String, dynamic>? _claimsOf(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final decoded = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (decoded is! Map) return null;

      final userId = decoded['user_id'] ?? decoded['sub'] ?? decoded['id'];
      final username = decoded['username'] ?? decoded['preferred_username'];
      if (userId == null || username == null) return null;

      return <String, dynamic>{
        'user_id': userId.toString(),
        'username': username.toString(),
        'fullname': decoded['fullname']?.toString() ?? username.toString(),
        'email': decoded['email']?.toString() ?? '',
        if (decoded['role'] != null) 'role': decoded['role'].toString(),
        if (decoded['status'] != null) 'status': decoded['status'].toString(),
      };
    } catch (_) {
      return null;
    }
  }

  /// Finds the token wherever the response nests it, so a change in the API's
  /// envelope does not silently break sign-in.
  static String? _extractToken(dynamic decoded) {
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        final key = entry.key.toString().toLowerCase();
        final value = entry.value;
        if (value is String &&
            value.isNotEmpty &&
            (key == 'token' ||
                key == 'access_token' ||
                key == 'accesstoken' ||
                key == 'jwt')) {
          return value;
        }
        final nested = _extractToken(value);
        if (nested != null) return nested;
      }
    } else if (decoded is List) {
      for (final value in decoded) {
        final nested = _extractToken(value);
        if (nested != null) return nested;
      }
    }
    return null;
  }

  /// Reads `exp` out of the JWT payload. Null when the token is not a JWT or
  /// carries no expiry, in which case it is used until the server rejects it.
  static DateTime? _expiryOf(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;

    try {
      final payload = parts[1];
      final normalized = base64Url.normalize(payload);
      final decoded = json.decode(utf8.decode(base64Url.decode(normalized)));
      if (decoded is! Map || decoded['exp'] is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        (decoded['exp'] as int) * 1000,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Exposes the pure helpers to tests without widening the public surface.
@visibleForTesting
class AuthServiceTestAccess {
  const AuthServiceTestAccess._();

  static String? extractToken(dynamic decoded) =>
      AuthService._extractToken(decoded);

  static DateTime? expiryOf(String token) => AuthService._expiryOf(token);
}
