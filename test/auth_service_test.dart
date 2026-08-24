import 'dart:convert';

import 'package:fleet_dashboard/models/auth_session.dart';
import 'package:fleet_dashboard/models/auth_user.dart';
import 'package:fleet_dashboard/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('AuthService', () {
    test('uses the documented login contract and parses its session', () async {
      late http.Request captured;
      final service = AuthService(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            json.encode(<String, dynamic>{
              'status': 'success',
              'stat_code': 200,
              'data': <String, dynamic>{
                'token': _jwt(const Duration(hours: 1)),
                'refreshToken': _jwt(const Duration(days: 7)),
                'user': <String, dynamic>{
                  'user_id': 1,
                  'username': 'driver',
                  'fullname': 'Driver Name',
                  'email': 'driver@example.test',
                },
              },
            }),
            200,
          );
        }),
      );

      final session = await service.login(
        username: 'driver',
        password: 'test-only-secret',
      );

      expect(captured.method, 'POST');
      expect(captured.url.path, '/api/v1/auth/login');
      expect(json.decode(captured.body), <String, dynamic>{
        'username': 'driver',
        'password': 'test-only-secret',
      });
      expect(session.user.username, 'driver');
      expect(session.user.userId, '1');
    });

    test('maps HTTP 401 login to an invalid-credentials error', () async {
      final service = AuthService(
        client: MockClient(
          (_) async => http.Response(
            json.encode(<String, dynamic>{
              'stat_code': 401,
              'status': 'Your username / password wrong',
              'message': 'Your username / password wrong',
            }),
            401,
          ),
        ),
      );

      await expectLater(
        service.login(username: 'unknown', password: 'invalid'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.kind,
            'kind',
            AuthFailureKind.invalidCredentials,
          ),
        ),
      );
    });

    test('reports timeout without exposing a lower-level exception', () async {
      final service = AuthService(
        requestTimeout: const Duration(milliseconds: 1),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        service.login(username: 'driver', password: 'test-only-secret'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.kind,
            'kind',
            AuthFailureKind.timeout,
          ),
        ),
      );
    });

    test('reports malformed successful responses', () async {
      final service = AuthService(
        client: MockClient((_) async => http.Response('not-json', 200)),
      );

      await expectLater(
        service.login(username: 'driver', password: 'test-only-secret'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.kind,
            'kind',
            AuthFailureKind.malformedResponse,
          ),
        ),
      );
    });

    test('reports an unavailable backend', () async {
      final service = AuthService(
        client: MockClient((_) async => throw http.ClientException('offline')),
      );

      await expectLater(
        service.login(username: 'driver', password: 'test-only-secret'),
        throwsA(
          isA<AuthException>().having(
            (error) => error.kind,
            'kind',
            AuthFailureKind.backendUnavailable,
          ),
        ),
      );
    });

    test('uses the confirmed registration payload', () async {
      late http.Request captured;
      final service = AuthService(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            json.encode(<String, dynamic>{
              'status': 'success',
              'stat_code': 200,
              'data': 'Account created',
            }),
            200,
          );
        }),
      );

      await service.register(
        fullname: 'Fleet Operator',
        username: 'operator',
        password: 'test-only-secret',
        role: 'Supervisor',
        division: 'Operations',
      );

      expect(captured.url.path, '/api/v1/auth/register');
      expect(json.decode(captured.body), <String, dynamic>{
        'fullname': 'Fleet Operator',
        'username': 'operator',
        'password': 'test-only-secret',
        'role': 'Supervisor',
        'division': 'Operations',
      });
    });

    test('throws a safe duplicate-username registration error', () async {
      final service = AuthService(
        client: MockClient(
          (_) async => http.Response(
            json.encode(<String, dynamic>{
              'status': 'failed',
              'stat_code': 409,
              'message': 'Duplicate username already exists',
            }),
            409,
          ),
        ),
      );

      await expectLater(
        service.register(
          fullname: 'Fleet Operator',
          username: 'operator',
          password: 'test-only-secret',
          role: 'Supervisor',
          division: 'Operations',
        ),
        throwsA(
          isA<AuthException>()
              .having(
                (error) => error.kind,
                'kind',
                AuthFailureKind.invalidInput,
              )
              .having(
                (error) => error.message,
                'message',
                'Username already exists.',
              ),
        ),
      );
    });

    test('reports a registration timeout', () async {
      final service = AuthService(
        requestTimeout: const Duration(milliseconds: 1),
        client: MockClient((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return http.Response('{}', 200);
        }),
      );

      await expectLater(
        service.register(
          fullname: 'Fleet Operator',
          username: 'operator',
          password: 'test-only-secret',
          role: 'Supervisor',
          division: 'Operations',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.kind,
            'kind',
            AuthFailureKind.timeout,
          ),
        ),
      );
    });

    test('reports a malformed successful registration response', () async {
      final service = AuthService(
        client: MockClient((_) async => http.Response('not-json', 200)),
      );

      await expectLater(
        service.register(
          fullname: 'Fleet Operator',
          username: 'operator',
          password: 'test-only-secret',
          role: 'Supervisor',
          division: 'Operations',
        ),
        throwsA(
          isA<AuthException>().having(
            (error) => error.kind,
            'kind',
            AuthFailureKind.malformedResponse,
          ),
        ),
      );
    });

    test('masks malformed backend registration failures', () async {
      final service = AuthService(
        client: MockClient((_) async => http.Response('SQL failure', 503)),
      );

      await expectLater(
        service.register(
          fullname: 'Fleet Operator',
          username: 'operator',
          password: 'test-only-secret',
          role: 'Supervisor',
          division: 'Operations',
        ),
        throwsA(
          isA<AuthException>()
              .having(
                (error) => error.kind,
                'kind',
                AuthFailureKind.backendUnavailable,
              )
              .having(
                (error) => error.message,
                'message',
                isNot(contains('SQL')),
              ),
        ),
      );
    });

    test('does not trust a failed envelope inside HTTP 200', () async {
      final service = AuthService(
        client: MockClient(
          (_) async => http.Response(
            json.encode(<String, dynamic>{
              'status': 'failed',
              'stat_code': 400,
              'message': 'SQL constraint failure',
            }),
            200,
          ),
        ),
      );

      await expectLater(
        service.register(
          fullname: 'Fleet Operator',
          username: 'operator',
          password: 'test-only-secret',
          role: 'Supervisor',
          division: 'Operations',
        ),
        throwsA(
          isA<AuthException>()
              .having((error) => error.kind, 'kind', AuthFailureKind.unexpected)
              .having(
                (error) => error.message,
                'message',
                isNot(contains('SQL')),
              ),
        ),
      );
    });

    test('refreshes with refreshToken and parses rotated tokens', () async {
      final oldSession = _session();
      late Map<String, dynamic> capturedBody;
      final newAccess = _jwt(const Duration(hours: 1));
      final newRefresh = _jwt(const Duration(days: 7));
      final service = AuthService(
        client: MockClient((request) async {
          capturedBody = json.decode(request.body) as Map<String, dynamic>;
          return http.Response(
            json.encode(<String, dynamic>{
              'status': 'success',
              'stat_code': 200,
              'data': <String, dynamic>{
                'accessToken': newAccess,
                'refreshToken': newRefresh,
              },
            }),
            200,
          );
        }),
      );

      final refreshed = await service.refreshSession(oldSession);

      expect(capturedBody, <String, dynamic>{
        'refreshToken': oldSession.refreshToken,
      });
      expect(refreshed.accessToken, newAccess);
      expect(refreshed.refreshToken, newRefresh);
      expect(refreshed.user.username, oldSession.user.username);
    });

    test('logout sends the active access token', () async {
      late http.Request captured;
      final service = AuthService(
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            json.encode(<String, dynamic>{
              'status': 'success',
              'stat_code': 200,
              'data': 'Successfully logged out',
            }),
            200,
          );
        }),
      );

      await service.logout('active-access-token');

      expect(captured.url.path, '/api/v1/auth/logout');
      expect(captured.headers['authorization'], 'Bearer active-access-token');
      expect(captured.body, isEmpty);
    });
  });
}

String _jwt(Duration lifetime) {
  String segment(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(json.encode(value))).replaceAll('=', '');
  final expiration =
      DateTime.now().toUtc().add(lifetime).millisecondsSinceEpoch ~/
      Duration.millisecondsPerSecond;
  return '${segment(<String, dynamic>{'alg': 'none'})}.${segment(<String, dynamic>{'exp': expiration})}.signature';
}

AuthSession _session() {
  return AuthSession(
    accessToken: _jwt(const Duration(hours: 1)),
    refreshToken: _jwt(const Duration(days: 7)),
    user: const AuthUser(
      userId: '1',
      username: 'driver',
      fullname: 'Driver Name',
      email: 'driver@example.test',
    ),
  );
}
