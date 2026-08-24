import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/auth_session.dart';
import '../models/auth_user.dart';

enum AuthFailureKind {
  invalidInput,
  invalidCredentials,
  sessionExpired,
  backendUnavailable,
  timeout,
  malformedResponse,
  unexpected,
}

class AuthException implements Exception {
  const AuthException(this.kind, this.message, {this.statusCode});

  final AuthFailureKind kind;
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuthService {
  AuthService({
    this.baseUrl = _defaultBaseUrl,
    http.Client? client,
    this.requestTimeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );

  final String baseUrl;
  final Duration requestTimeout;
  final http.Client _client;
  final bool _ownsClient;

  Future<AuthSession> login({
    required String username,
    required String password,
  }) async {
    final response = await _postJson(
      '/auth/login',
      body: <String, dynamic>{'username': username, 'password': password},
    );
    final decoded = _decodeEnvelope(response, operation: 'login');

    if (response.statusCode == 401) {
      throw AuthException(
        AuthFailureKind.invalidCredentials,
        'Username or password is incorrect.',
        statusCode: response.statusCode,
      );
    }
    if (response.statusCode == 400) {
      throw AuthException(
        AuthFailureKind.invalidInput,
        _message(decoded) ?? 'Username and password are required.',
        statusCode: response.statusCode,
      );
    }
    _throwForFailure(response, decoded, operation: 'login');

    try {
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Missing login data');
      }
      final accessToken = data['token']?.toString().trim() ?? '';
      final refreshToken = data['refreshToken']?.toString().trim() ?? '';
      final userJson = data['user'];
      if (accessToken.isEmpty ||
          refreshToken.isEmpty ||
          userJson is! Map<String, dynamic>) {
        throw const FormatException('Incomplete login response');
      }
      return AuthSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: AuthUser.fromJson(userJson),
      );
    } on FormatException {
      throw AuthException(
        AuthFailureKind.malformedResponse,
        'The authentication server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> register({
  required String fullname,
  required String username,
  required String password,
  required String role,
  required String division,
}) async {
  final response = await _client.post(
    Uri.parse('$baseUrl/auth/register'),
    headers: const {
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'fullname': fullname,
      'username': username,
      'password': password,
      'role': role,
      'division': division,
    }),
  );

  final Map<String, dynamic> body =
      jsonDecode(response.body) as Map<String, dynamic>;

  if (response.statusCode >= 200 &&
      response.statusCode < 300 &&
      body['stat_code'] == 200) {
    return;
  }

  final message =
      body['message']?.toString() ??
      body['status']?.toString() ??
      'Unable to create account';

  //throw AuthException(message);
}

  Future<AuthSession> refreshSession(AuthSession current) async {
    final response = await _postJson(
      '/auth/refresh',
      body: <String, dynamic>{'refreshToken': current.refreshToken},
    );
    final decoded = _decodeEnvelope(response, operation: 'refresh');
    if (response.statusCode == 401) {
      throw AuthException(
        AuthFailureKind.sessionExpired,
        _message(decoded) ?? 'Your session has expired. Please sign in again.',
        statusCode: response.statusCode,
      );
    }
    _throwForFailure(response, decoded, operation: 'refresh');

    try {
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw const FormatException('Missing refresh data');
      }
      final accessToken = data['accessToken']?.toString().trim() ?? '';
      final refreshToken = data['refreshToken']?.toString().trim() ?? '';
      if (accessToken.isEmpty || refreshToken.isEmpty) {
        throw const FormatException('Incomplete refresh response');
      }
      return current.copyWithTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
    } on FormatException {
      throw AuthException(
        AuthFailureKind.malformedResponse,
        'The authentication server returned an invalid refresh response.',
        statusCode: response.statusCode,
      );
    }
  }

  Future<void> logout(String accessToken) async {
    final response = await _postJson(
      '/auth/logout',
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );
    final decoded = _decodeEnvelope(response, operation: 'logout');
    _throwForFailure(response, decoded, operation: 'logout');
  }

  Future<http.Response> _postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      return await _client
          .post(
            Uri.parse('$baseUrl$path'),
            headers: <String, String>{
              'Accept': 'application/json',
              if (body != null) 'Content-Type': 'application/json',
              ...?headers,
            },
            body: body == null ? null : json.encode(body),
          )
          .timeout(requestTimeout);
    } on TimeoutException {
      throw const AuthException(
        AuthFailureKind.timeout,
        'The authentication server took too long to respond.',
      );
    } on SocketException {
      throw const AuthException(
        AuthFailureKind.backendUnavailable,
        'Unable to reach the authentication server.',
      );
    } on http.ClientException {
      throw const AuthException(
        AuthFailureKind.backendUnavailable,
        'Unable to reach the authentication server.',
      );
    }
  }

  Map<String, dynamic> _decodeEnvelope(
    http.Response response, {
    required String operation,
  }) {
    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // The typed malformed-response error below is more useful to the UI.
    }
    throw AuthException(
      AuthFailureKind.malformedResponse,
      'The authentication server returned an invalid $operation response.',
      statusCode: response.statusCode,
    );
  }

  void _throwForFailure(
    http.Response response,
    Map<String, dynamic> decoded, {
    required String operation,
  }) {
    final isSuccess =
        response.statusCode >= 200 &&
        response.statusCode < 300 &&
        decoded['status'] == 'success';
    if (isSuccess) return;

    if (response.statusCode >= 500) {
      throw AuthException(
        AuthFailureKind.backendUnavailable,
        'The authentication server is currently unavailable.',
        statusCode: response.statusCode,
      );
    }
    throw AuthException(
      AuthFailureKind.unexpected,
      _message(decoded) ?? 'Unable to complete authentication $operation.',
      statusCode: response.statusCode,
    );
  }

  String? _message(Map<String, dynamic> envelope) {
    final message = envelope['message']?.toString().trim();
    return message == null || message.isEmpty ? null : message;
  }

  void close() {
    if (_ownsClient) _client.close();
  }
}
