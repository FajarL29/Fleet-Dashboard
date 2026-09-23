import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fleet_dashboard/bloc/auth/auth_cubit.dart';
import 'package:fleet_dashboard/bloc/auth/auth_state.dart';
import 'package:fleet_dashboard/models/auth_session.dart';
import 'package:fleet_dashboard/services/auth_service.dart';
import 'package:fleet_dashboard/services/auth_session_store.dart';

/// Verbatim shape of `tool/mock_api/server.js`, which wraps every payload in a
/// `{status, stat_code, data}` envelope. The tokens and refresh tokens live
/// inside `data`, so this is what catches a parser that only reads the top
/// level.
Map<String, dynamic> _envelope(Map<String, dynamic> data) => {
  'status': 'success',
  'stat_code': 200,
  'data': data,
};

String _jwt() {
  String seg(Map<String, dynamic> v) =>
      base64Url.encode(utf8.encode(json.encode(v))).replaceAll('=', '');
  final exp = DateTime.now().toUtc().add(const Duration(hours: 1));
  return '${seg({'alg': 'HS256', 'typ': 'JWT'})}'
      '.${seg({'sub': '2', 'user_id': '2', 'username': 'ghefira', 'fullname': 'Ghefira Maharani', 'exp': exp.millisecondsSinceEpoch ~/ 1000})}'
      '.sig';
}

class _MemoryStore implements AuthSessionStore {
  AuthSession? saved;
  @override
  Future<AuthSession?> read() async => saved;
  @override
  Future<void> write(AuthSession session) async => saved = session;
  @override
  Future<void> clear() async => saved = null;
}

void main() {
  tearDown(AuthService.instance.reset);

  test('a login inside a data envelope yields a complete session', () async {
    final token = _jwt();
    final service = AuthService()
      ..clientOverride = MockClient(
        (_) async => http.Response(
          json.encode(
            _envelope({
              'token': token,
              'refreshToken': 'e8ff4e522bd51158fe6b2744281ec215',
              'user': {
                'user_id': '2',
                'username': 'ghefira',
                'fullname': 'Ghefira Maharani',
                'email': 'ghefira@fleetsafe.test',
                'role': 'UI/UX Engineer',
                'status': 'active',
              },
            }),
          ),
          200,
        ),
      );

    final store = _MemoryStore();
    final cubit = AuthCubit(authService: service, sessionStore: store);

    expect(await cubit.login('ghefira', 'rahasia123', true), isNull);
    expect(cubit.state.status, AuthStatus.authenticated);

    final session = cubit.state.session!;
    expect(session.accessToken, token);
    expect(session.user.fullname, 'Ghefira Maharani');
    expect(session.user.role, 'UI/UX Engineer');

    // The refresh token must be the nested one, never a copy of the access
    // token: that mistake only surfaces an hour later, as a failed refresh.
    expect(session.refreshToken, 'e8ff4e522bd51158fe6b2744281ec215');
    expect(session.refreshToken, isNot(session.accessToken));
  });

  test('a rejected sign-in surfaces the server message verbatim', () async {
    // Captured from the live API. Note `status` here holds a sentence rather
    // than "error" — reading the message out of `status` would work by luck on
    // this route and break on the 400s, which do use `status: 'error'`.
    final service = AuthService()
      ..clientOverride = MockClient(
        (_) async => http.Response(
          json.encode({
            'stat_code': 401,
            'status': 'Your username / password wrong',
            'message': 'Your username / password wrong',
          }),
          401,
        ),
      );

    final cubit = AuthCubit(authService: service, sessionStore: _MemoryStore());

    expect(
      await cubit.login('ghefira', 'salah', false),
      'Your username / password wrong',
    );
    expect(cubit.state.status, isNot(AuthStatus.authenticated));
  });

  test('a rejected registration surfaces the 400 envelope', () async {
    final service = AuthService()
      ..clientOverride = MockClient(
        (_) async => http.Response(
          json.encode({
            'status': 'error',
            'stat_code': 400,
            'message':
                'fullname, username, password, role and division are required',
          }),
          400,
        ),
      );

    expect(
      () => service.register(
        fullname: '',
        username: 'ghefira',
        password: 'x',
        role: 'QA Engineer',
        division: 'Ops',
      ),
      throwsA(
        isA<AuthException>().having(
          (e) => e.message,
          'message',
          contains('are required'),
        ),
      ),
    );
  });

  test('register posts the fields the mock requires', () async {
    late Map<String, dynamic> sent;
    final service = AuthService()
      ..clientOverride = MockClient((request) async {
        sent = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(
          json.encode(_envelope({'username': 'ghefira', 'created': true})),
          200,
        );
      });

    await service.register(
      fullname: 'Ghefira Maharani',
      username: 'ghefira',
      password: 'rahasia123',
      role: 'UI/UX Engineer',
      division: 'Operations',
    );

    expect(
      sent.keys,
      containsAll(<String>[
        'fullname',
        'username',
        'password',
        'role',
        'division',
      ]),
    );
  });
}
