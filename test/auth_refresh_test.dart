import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fleet_dashboard/bloc/auth/auth_cubit.dart';
import 'package:fleet_dashboard/bloc/auth/auth_state.dart';
import 'package:fleet_dashboard/models/auth_session.dart';
import 'package:fleet_dashboard/models/auth_user.dart';
import 'package:fleet_dashboard/services/auth_service.dart';
import 'package:fleet_dashboard/services/auth_session_store.dart';
import 'package:fleet_dashboard/services/authenticated_http_client.dart';

/// Tokens are compared by value in these tests, and `exp` only has
/// second resolution, so every token carries a counter to keep two issued in
/// the same second from being byte-identical.
var _tokenSerial = 0;

String _jwt({required int inSeconds, String user = 'jane'}) {
  String segment(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(json.encode(value))).replaceAll('=', '');

  final exp = DateTime.now().toUtc().add(Duration(seconds: inSeconds));
  return '${segment({'alg': 'HS256'})}'
      '.${segment({'exp': exp.millisecondsSinceEpoch ~/ 1000, 'jti': '${_tokenSerial++}', 'user_id': 'u-1', 'username': user, 'fullname': 'Jane Doe'})}'
      '.signature';
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

/// Stands in for the API: `/auth/*` is served by the auth client, everything
/// else by the shared authenticated client under test.
class _Backend {
  _Backend({required this.liveToken});

  /// Opaque, like most real refresh tokens: the client cannot read an expiry
  /// out of it and has to ask the server.
  String refreshToken = 'refresh-ok';

  /// The only access token the data endpoint currently accepts.
  String liveToken;

  int refreshCalls = 0;
  final List<String?> dataAuthHeaders = [];

  /// Set to false to make the refresh endpoint reject, as it would once the
  /// refresh token itself has expired.
  bool refreshSucceeds = true;

  http.Client get authClient => MockClient((request) async {
    if (request.url.path.endsWith('/auth/login')) {
      return http.Response(
        json.encode({'token': liveToken, 'refreshToken': refreshToken}),
        200,
      );
    }
    if (request.url.path.endsWith('/auth/refresh')) {
      refreshCalls++;
      if (!refreshSucceeds) {
        return http.Response(json.encode({'message': 'expired'}), 401);
      }
      liveToken = _jwt(inSeconds: 3600);
      return http.Response(json.encode({'token': liveToken}), 200);
    }
    return http.Response('{}', 404);
  });

  http.Client get dataClient => MockClient((request) async {
    final header = request.headers['Authorization'];
    dataAuthHeaders.add(header);
    if (header != 'Bearer $liveToken') {
      return http.Response(json.encode({'message': 'unauthorized'}), 401);
    }
    return http.Response(json.encode({'data': 'ok'}), 200);
  });
}

({AuthCubit cubit, AuthenticatedHttpClient client}) _wire(
  _Backend backend,
  _MemoryStore store,
) {
  final client = AuthenticatedHttpClient(innerClient: backend.dataClient);
  final cubit = AuthCubit(
    authService: AuthService()..clientOverride = backend.authClient,
    sessionStore: store,
    httpClient: client,
  );
  return (cubit: cubit, client: client);
}

void main() {
  tearDown(AuthService.instance.reset);

  final dataUri = Uri.parse('https://example.test/api/v1/vehicles');

  test(
    'a 401 refreshes the token and retries, transparently to the caller',
    () async {
      final backend = _Backend(liveToken: _jwt(inSeconds: 3600));
      final wired = _wire(backend, _MemoryStore());

      await wired.cubit.login('jane', 'secret', true);

      // The server rotates its token behind the app's back, so the token the
      // app holds is now stale — exactly what an expiry looks like in practice.
      backend.liveToken = _jwt(inSeconds: 3600, user: 'jane');

      final response = await wired.client.get(dataUri);

      expect(
        response.statusCode,
        200,
        reason: 'the retry should have succeeded',
      );
      expect(backend.refreshCalls, 1);
      expect(backend.dataAuthHeaders, hasLength(2));
      expect(
        backend.dataAuthHeaders.last,
        'Bearer ${backend.liveToken}',
        reason: 'the retry must carry the refreshed token',
      );
      expect(wired.cubit.state.status, AuthStatus.authenticated);
    },
  );

  test(
    'a refreshed session is written back for a remembered sign-in',
    () async {
      final backend = _Backend(liveToken: _jwt(inSeconds: 3600));
      final store = _MemoryStore();
      final wired = _wire(backend, store);

      await wired.cubit.login('jane', 'secret', true);
      final before = store.saved!.accessToken;

      backend.liveToken = _jwt(inSeconds: 3600);
      await wired.client.get(dataUri);

      expect(store.saved!.accessToken, isNot(before));
      expect(store.saved!.accessToken, backend.liveToken);
    },
  );

  test('when the refresh token is dead too, the user is signed out', () async {
    final backend = _Backend(liveToken: _jwt(inSeconds: 3600));
    final store = _MemoryStore();
    final wired = _wire(backend, store);

    await wired.cubit.login('jane', 'secret', true);
    expect(wired.cubit.state.status, AuthStatus.authenticated);

    backend
      ..refreshSucceeds = false
      ..liveToken = _jwt(inSeconds: 3600);

    final response = await wired.client.get(dataUri);

    expect(response.statusCode, 401);
    expect(
      wired.cubit.state.status,
      AuthStatus.unauthenticated,
      reason: 'AuthGate watches this, and swaps in the login page',
    );
    expect(store.saved, isNull, reason: 'the dead session must not persist');
  });

  test('a burst of 401s triggers exactly one refresh', () async {
    final backend = _Backend(liveToken: _jwt(inSeconds: 3600));
    final wired = _wire(backend, _MemoryStore());

    await wired.cubit.login('jane', 'secret', true);
    backend.liveToken = _jwt(inSeconds: 3600);

    final responses = await Future.wait([
      wired.client.get(dataUri),
      wired.client.get(dataUri),
      wired.client.get(dataUri),
    ]);

    expect(responses.map((r) => r.statusCode), everyElement(200));
    expect(
      backend.refreshCalls,
      1,
      reason: 'three concurrent 401s must not sign in three times',
    );
  });

  test(
    'restore refreshes a stored session whose access token has lapsed',
    () async {
      final backend = _Backend(liveToken: _jwt(inSeconds: 3600));
      final store = _MemoryStore()
        ..saved = AuthSession(
          accessToken: _jwt(inSeconds: -60),
          refreshToken: _jwt(inSeconds: 86400),
          user: const AuthUser(
            userId: 'u-1',
            username: 'jane',
            fullname: 'Jane Doe',
            email: '',
          ),
        );

      final wired = _wire(backend, store);
      await wired.cubit.restore();

      expect(wired.cubit.state.status, AuthStatus.authenticated);
      expect(backend.refreshCalls, 1);
    },
  );
}
