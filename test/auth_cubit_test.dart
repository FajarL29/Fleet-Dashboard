import 'dart:async';
import 'dart:convert';

import 'package:fleet_dashboard/bloc/auth/auth_cubit.dart';
import 'package:fleet_dashboard/bloc/auth/auth_state.dart';
import 'package:fleet_dashboard/models/auth_session.dart';
import 'package:fleet_dashboard/models/auth_user.dart';
import 'package:fleet_dashboard/services/auth_service.dart';
import 'package:fleet_dashboard/services/auth_session_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('fresh restore remains unauthenticated', () async {
    final store = _MemorySessionStore();
    final cubit = _cubit(store, (_) async => http.Response('{}', 500));

    await cubit.restoreSession();

    expect(cubit.state.status, AuthStatus.unauthenticated);
    await cubit.close();
  });

  test('Remember Me persists a successful login session', () async {
    final store = _MemorySessionStore();
    final cubit = _cubit(store, (request) async {
      expect(request.url.path, '/api/v1/auth/login');
      return _loginResponse();
    });

    final error = await cubit.login('driver', 'test-only-secret', true);

    expect(error, isNull);
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(store.session?.user.username, 'driver');
    await cubit.close();
  });

  test('login without Remember Me only keeps the session in memory', () async {
    final store = _MemorySessionStore(session: _session());
    final cubit = _cubit(store, (_) async => _loginResponse());

    final error = await cubit.login('driver', 'test-only-secret', false);

    expect(error, isNull);
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.session, isNotNull);
    expect(store.session, isNull);
    await cubit.close();
  });

  test(
    'expired access token is refreshed and rotated during restore',
    () async {
      final original = _session(accessLifetime: const Duration(minutes: -1));
      final store = _MemorySessionStore(session: original);
      final cubit = _cubit(store, (request) async {
        expect(request.url.path, '/api/v1/auth/refresh');
        expect(json.decode(request.body), <String, dynamic>{
          'refreshToken': original.refreshToken,
        });
        return http.Response(
          json.encode(<String, dynamic>{
            'status': 'success',
            'stat_code': 200,
            'data': <String, dynamic>{
              'accessToken': _jwt(const Duration(hours: 1)),
              'refreshToken': _jwt(const Duration(days: 7)),
            },
          }),
          200,
        );
      });

      await cubit.restoreSession();

      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.session?.accessToken, isNot(original.accessToken));
      expect(store.session?.refreshToken, cubit.session?.refreshToken);
      await cubit.close();
    },
  );

  test('failed refresh clears the persisted session', () async {
    final store = _MemorySessionStore(
      session: _session(accessLifetime: const Duration(minutes: -1)),
    );
    final cubit = _cubit(
      store,
      (_) async => http.Response(
        json.encode(<String, dynamic>{
          'stat_code': 401,
          'status': 'Your username / password wrong',
          'message': 'Invalid or expired refresh token',
        }),
        401,
      ),
    );

    await cubit.restoreSession();

    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(store.session, isNull);
    await cubit.close();
  });

  test('simultaneous refresh callers share one backend request', () async {
    final store = _MemorySessionStore();
    var refreshCalls = 0;
    final cubit = _cubit(store, (request) async {
      if (request.url.path.endsWith('/login')) return _loginResponse();
      refreshCalls += 1;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return http.Response(
        json.encode(<String, dynamic>{
          'status': 'success',
          'stat_code': 200,
          'data': <String, dynamic>{
            'accessToken': _jwt(const Duration(hours: 1)),
            'refreshToken': _jwt(const Duration(days: 7)),
          },
        }),
        200,
      );
    });
    await cubit.login('driver', 'test-only-secret', false);

    final results = await Future.wait(<Future<bool>>[
      cubit.refreshSession(),
      cubit.refreshSession(),
    ]);

    expect(results, everyElement(isTrue));
    expect(refreshCalls, 1);
    await cubit.close();
  });

  test('logout clears local state even when backend logout fails', () async {
    final store = _MemorySessionStore();
    var requestCount = 0;
    final cubit = _cubit(store, (_) async {
      requestCount += 1;
      if (requestCount == 1) return _loginResponse();
      return http.Response('backend unavailable', 503);
    });
    await cubit.login('driver', 'test-only-secret', true);

    await cubit.logout();

    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.session, isNull);
    expect(store.session, isNull);
    await cubit.close();
  });

  test('logout wins over an in-flight refresh response', () async {
    final refreshResponse = Completer<http.Response>();
    final refreshStarted = Completer<void>();
    final store = _MemorySessionStore();
    final cubit = _cubit(store, (request) async {
      if (request.url.path.endsWith('/login')) return _loginResponse();
      if (request.url.path.endsWith('/refresh')) {
        refreshStarted.complete();
        return refreshResponse.future;
      }
      if (request.url.path.endsWith('/logout')) {
        return http.Response(
          json.encode(<String, dynamic>{'status': 'success', 'stat_code': 200}),
          200,
        );
      }
      return http.Response('{}', 404);
    });
    await cubit.login('driver', 'test-only-secret', true);

    final refresh = cubit.refreshSession();
    await refreshStarted.future;
    final logout = cubit.logout();
    refreshResponse.complete(
      http.Response(
        json.encode(<String, dynamic>{
          'status': 'success',
          'stat_code': 200,
          'data': <String, dynamic>{
            'accessToken': _jwt(const Duration(hours: 1)),
            'refreshToken': _jwt(const Duration(days: 7)),
          },
        }),
        200,
      ),
    );

    expect(await refresh, isFalse);
    await logout;
    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.session, isNull);
    expect(store.session, isNull);
    await cubit.close();
  });
}

AuthCubit _cubit(
  AuthSessionStore store,
  Future<http.Response> Function(http.Request) handler,
) {
  return AuthCubit(
    service: AuthService(client: MockClient(handler)),
    store: store,
  );
}

http.Response _loginResponse() {
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
}

AuthSession _session({Duration accessLifetime = const Duration(hours: 1)}) {
  return AuthSession(
    accessToken: _jwt(accessLifetime),
    refreshToken: _jwt(const Duration(days: 7)),
    user: const AuthUser(
      userId: '1',
      username: 'driver',
      fullname: 'Driver Name',
      email: 'driver@example.test',
    ),
  );
}

String _jwt(Duration lifetime) {
  String segment(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(json.encode(value))).replaceAll('=', '');
  final expiration =
      DateTime.now().toUtc().add(lifetime).millisecondsSinceEpoch ~/
      Duration.millisecondsPerSecond;
  return '${segment(<String, dynamic>{'alg': 'none'})}.${segment(<String, dynamic>{'exp': expiration})}.signature';
}

class _MemorySessionStore implements AuthSessionStore {
  _MemorySessionStore({this.session});

  AuthSession? session;

  @override
  Future<void> clear() async => session = null;

  @override
  Future<AuthSession?> read() async => session;

  @override
  Future<void> write(AuthSession value) async => session = value;
}
