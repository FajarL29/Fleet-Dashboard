import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fleet_dashboard/bloc/auth/auth_cubit.dart';
import 'package:fleet_dashboard/bloc/auth/auth_state.dart';
import 'package:fleet_dashboard/models/auth_session.dart';
import 'package:fleet_dashboard/services/auth_service.dart';
import 'package:fleet_dashboard/services/auth_session_store.dart';

String _jwt() {
  String seg(Map<String, dynamic> v) =>
      base64Url.encode(utf8.encode(json.encode(v))).replaceAll('=', '');
  final exp = DateTime.now().toUtc().add(const Duration(hours: 1));
  return '${seg({'alg': 'HS256'})}'
      '.${seg({
        'user_id': '1',
        'username': 'ghefira',
        'fullname': 'Ghefira Maharani',
        'exp': exp.millisecondsSinceEpoch ~/ 1000,
      })}'
      '.sig';
}

/// A keychain that is simply not available — what macOS does when the app has
/// no keychain entitlement, and what a browser does with site data blocked.
class _BrokenStore implements AuthSessionStore {
  int writeAttempts = 0;

  @override
  Future<AuthSession?> read() async =>
      throw Exception('SecItemCopyMatching failed: -34018');

  @override
  Future<void> write(AuthSession session) async {
    writeAttempts++;
    throw Exception('SecItemAdd failed: -34018');
  }

  @override
  Future<void> clear() async => throw Exception('SecItemDelete failed: -34018');
}

AuthService _serviceReturningSession() {
  return AuthService()
    ..clientOverride = MockClient(
      (_) async => http.Response(
        json.encode({
          'status': 'success',
          'data': {
            'token': _jwt(),
            'refreshToken': 'r-1',
            'user': {
              'user_id': '1',
              'username': 'ghefira',
              'fullname': 'Ghefira Maharani',
              'email': '',
            },
          },
        }),
        200,
      ),
    );
}

void main() {
  tearDown(AuthService.instance.reset);

  test('an unusable keychain does not block signing in', () async {
    final store = _BrokenStore();
    final cubit = AuthCubit(
      authService: _serviceReturningSession(),
      sessionStore: store,
    );

    expect(
      await cubit.login('ghefira', 'rahasia123', true),
      isNull,
      reason: 'the credentials were good; storage is not the user\'s problem',
    );
    expect(cubit.state.status, AuthStatus.authenticated);
    expect(cubit.state.session!.user.fullname, 'Ghefira Maharani');
    expect(store.writeAttempts, 1);
  });

  test('signing in without remember-me survives a failing clear', () async {
    final cubit = AuthCubit(
      authService: _serviceReturningSession(),
      sessionStore: _BrokenStore(),
    );

    expect(await cubit.login('ghefira', 'rahasia123', false), isNull);
    expect(cubit.state.status, AuthStatus.authenticated);
  });

  test('restore falls back to the login page when the store throws', () async {
    final cubit = AuthCubit(
      authService: _serviceReturningSession(),
      sessionStore: _BrokenStore(),
    );

    await cubit.restore();

    expect(cubit.state.status, AuthStatus.unauthenticated);
  });

  test('logout still signs out when the store throws', () async {
    final cubit = AuthCubit(
      authService: _serviceReturningSession(),
      sessionStore: _BrokenStore(),
    );

    await cubit.login('ghefira', 'rahasia123', true);
    await cubit.logout();

    expect(cubit.state.status, AuthStatus.unauthenticated);
    expect(cubit.state.session, isNull);
  });
}
