import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fleet_dashboard/services/auth_service.dart';

/// Builds a JWT-shaped token whose payload expires [inSeconds] from now.
String _jwt({required int inSeconds}) {
  String segment(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(json.encode(value))).replaceAll('=', '');

  final exp = DateTime.now().add(Duration(seconds: inSeconds));
  return '${segment({'alg': 'HS256'})}'
      '.${segment({'exp': exp.millisecondsSinceEpoch ~/ 1000})}'
      '.signature';
}

void main() {
  setUp(() => AuthService.instance.reset());
  tearDown(() {
    AuthService.instance.clientOverride = null;
    AuthService.instance.reset();
  });

  test('no credentials configured yields no token instead of throwing', () async {
    var calls = 0;
    AuthService.instance.clientOverride = MockClient((_) async {
      calls++;
      return http.Response('{}', 200);
    });

    // API_USERNAME / API_PASSWORD are unset in tests.
    expect(await AuthService.instance.token(), isNull);
    expect(calls, 0, reason: 'must not attempt a login without credentials');
  });

  test('finds the token however the response nests it', () {
    final extract = AuthServiceTestAccess.extractToken;

    expect(extract({'token': 'abc'}), 'abc');
    expect(extract({'data': {'access_token': 'nested'}}), 'nested');
    expect(extract({'data': {'user': {'jwt': 'deep'}}}), 'deep');
    expect(extract({'message': 'no token here'}), isNull);
  });

  test('reads the expiry out of a JWT payload', () {
    final expiry = AuthServiceTestAccess.expiryOf(_jwt(inSeconds: 3600));

    expect(expiry, isNotNull);
    final remaining = expiry!.difference(DateTime.now());
    expect(remaining.inMinutes, closeTo(60, 1));
  });

  test('a token that is not a JWT has no expiry rather than crashing', () {
    expect(AuthServiceTestAccess.expiryOf('plain-opaque-token'), isNull);
  });
}
