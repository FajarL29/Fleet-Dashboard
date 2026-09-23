import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;

import 'package:fleet_dashboard/bloc/auth/auth_cubit.dart';
import 'package:fleet_dashboard/bloc/auth/auth_state.dart';
import 'package:fleet_dashboard/models/auth_session.dart';
import 'package:fleet_dashboard/models/auth_user.dart';
import 'package:fleet_dashboard/services/auth_service.dart';
import 'package:fleet_dashboard/services/auth_session_store.dart';

/// A JWT-shaped token expiring [inSeconds] from now, carrying the claims the
/// session falls back to when the response body describes no user.
String _jwt({required int inSeconds, String user = 'jane'}) {
  String segment(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(json.encode(value))).replaceAll('=', '');

  final exp = DateTime.now().toUtc().add(Duration(seconds: inSeconds));
  return '${segment({'alg': 'HS256'})}'
      '.${segment({
        'exp': exp.millisecondsSinceEpoch ~/ 1000,
        'user_id': 'u-1',
        'username': user,
        'fullname': 'Jane Doe',
        'role': 'Supervisor',
      })}'
      '.signature';
}

/// Session store backed by a field, so a test can assert what "remember me"
/// actually persisted without touching the platform keychain.
class _MemoryStore implements AuthSessionStore {
  AuthSession? saved;

  @override
  Future<AuthSession?> read() async => saved;

  @override
  Future<void> write(AuthSession session) async => saved = session;

  @override
  Future<void> clear() async => saved = null;
}

AuthService _serviceReturning(http.Response Function(http.Request) handler) {
  return AuthService()..clientOverride = MockClient((r) async => handler(r));
}

void main() {
  tearDown(AuthService.instance.reset);

  group('AuthCubit', () {
    test('starts unknown so the gate can hold a spinner, not the login form', () {
      final cubit = AuthCubit(
        authService: _serviceReturning((_) => http.Response('{}', 200)),
        sessionStore: _MemoryStore(),
      );
      expect(cubit.state.status, AuthStatus.initial);
      expect(cubit.state.session, isNull);
    });

    test('a successful sign-in authenticates and adopts the token', () async {
      final token = _jwt(inSeconds: 3600);
      final cubit = AuthCubit(
        authService: _serviceReturning(
          (_) => http.Response(json.encode({'token': token}), 200),
        ),
        sessionStore: _MemoryStore(),
      );

      expect(await cubit.login('jane', 'secret', false), isNull);
      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.session!.user.username, 'jane');

      // The data services read their bearer token from the shared instance, so
      // a sign-in has to land there too or the dashboard queries as the
      // build-time service account.
      expect(await AuthService.instance.token(), token);
    });

    test('a rejected sign-in returns the server message and stays signed out',
        () async {
      final cubit = AuthCubit(
        authService: _serviceReturning(
          (_) => http.Response(json.encode({'message': 'Wrong password'}), 401),
        ),
        sessionStore: _MemoryStore(),
      );

      expect(await cubit.login('jane', 'nope', false), 'Wrong password');
      expect(cubit.state.status, AuthStatus.initial);
      expect(cubit.state.session, isNull);
    });

    test('an unreachable server reads as a connection problem, not a bad password',
        () async {
      final cubit = AuthCubit(
        authService: AuthService()
          ..clientOverride = MockClient((_) async => throw const SocketishError()),
        sessionStore: _MemoryStore(),
      );

      expect(await cubit.login('jane', 'secret', false), contains('reach'));
      expect(cubit.state.status, AuthStatus.initial);
    });

    test('only a remember-me sign-in is persisted', () async {
      final store = _MemoryStore();
      final cubit = AuthCubit(
        authService: _serviceReturning(
          (_) => http.Response(
            json.encode({'token': _jwt(inSeconds: 3600)}),
            200,
          ),
        ),
        sessionStore: store,
      );

      await cubit.login('jane', 'secret', false);
      expect(store.saved, isNull);

      await cubit.login('jane', 'secret', true);
      expect(store.saved, isNotNull);
    });

    test('restore signs in from a stored session', () async {
      final store = _MemoryStore();
      final cubit = AuthCubit(
        authService: _serviceReturning(
          (_) => http.Response(
            json.encode({'token': _jwt(inSeconds: 3600)}),
            200,
          ),
        ),
        sessionStore: store,
      );

      await cubit.login('jane', 'secret', true);

      final restored = AuthCubit(
        authService: _serviceReturning((_) => http.Response('{}', 500)),
        sessionStore: store,
      );
      await restored.restore();

      expect(restored.state.status, AuthStatus.authenticated);
      expect(restored.state.session!.user.username, 'jane');
    });

    test('an expired stored session is dropped rather than trusted', () async {
      final store = _MemoryStore()
        ..saved = AuthSession(
          accessToken: _jwt(inSeconds: -60),
          refreshToken: _jwt(inSeconds: -60),
          user: const AuthUser(
            userId: 'u-1',
            username: 'jane',
            fullname: 'Jane Doe',
            email: '',
          ),
        );

      final cubit = AuthCubit(
        authService: _serviceReturning((_) => http.Response('{}', 500)),
        sessionStore: store,
      );
      await cubit.restore();

      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(store.saved, isNull, reason: 'the dead session should be cleared');
    });

    test('logout clears both the state and the stored session', () async {
      final store = _MemoryStore();
      final cubit = AuthCubit(
        authService: _serviceReturning(
          (_) => http.Response(
            json.encode({'token': _jwt(inSeconds: 3600)}),
            200,
          ),
        ),
        sessionStore: store,
      );

      await cubit.login('jane', 'secret', true);
      await cubit.logout();

      expect(cubit.state.status, AuthStatus.unauthenticated);
      expect(cubit.state.session, isNull);
      expect(store.saved, isNull);
    });
  });

  group('AuthService.register', () {
    test('surfaces the server message as an AuthException', () async {
      final service = _serviceReturning(
        (_) => http.Response(json.encode({'message': 'Username taken'}), 409),
      );

      expect(
        () => service.register(
          fullname: 'Jane Doe',
          username: 'jane',
          password: 'secret',
          role: 'Supervisor',
          division: 'Ops',
        ),
        throwsA(
          isA<AuthException>().having((e) => e.message, 'message', 'Username taken'),
        ),
      );
    });

    test('a created account completes without throwing', () async {
      late Map<String, dynamic> sent;
      final service = _serviceReturning((request) {
        sent = json.decode(request.body) as Map<String, dynamic>;
        return http.Response('{}', 201);
      });

      await service.register(
        fullname: '  Jane Doe  ',
        username: '  jane  ',
        password: 'secret',
        role: 'Supervisor',
        division: 'Ops',
      );

      // Trimmed, so a stray space in the form does not create "jane " as a
      // second, unreachable account.
      expect(sent['username'], 'jane');
      expect(sent['fullname'], 'Jane Doe');
    });
  });
}

/// Stands in for a transport failure without depending on dart:io, which the
/// web target does not have.
class SocketishError implements Exception {
  const SocketishError();
}
