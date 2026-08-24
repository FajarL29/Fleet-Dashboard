import 'dart:convert';

import 'package:fleet_dashboard/services/authenticated_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('attaches bearer token, refreshes on 401, and retries once', () async {
    var accessToken = 'first-token';
    var refreshCalls = 0;
    final seenAuthorization = <String?>[];
    final client = AuthenticatedHttpClient(
      innerClient: MockClient((request) async {
        seenAuthorization.add(request.headers['authorization']);
        if (seenAuthorization.length == 1) {
          return http.Response('unauthorized', 401);
        }
        return http.Response(json.encode(<String, dynamic>{'ok': true}), 200);
      }),
      accessToken: () => accessToken,
      refreshSession: () async {
        refreshCalls += 1;
        accessToken = 'refreshed-token';
        return true;
      },
      onSessionInvalid: () async {},
    );

    final response = await client.get(Uri.parse('http://localhost/protected'));

    expect(response.statusCode, 200);
    expect(refreshCalls, 1);
    expect(seenAuthorization, <String?>[
      'Bearer first-token',
      'Bearer refreshed-token',
    ]);
  });

  test(
    'clears the session when a retried request is still unauthorized',
    () async {
      var invalidations = 0;
      final client = AuthenticatedHttpClient(
        innerClient: MockClient(
          (_) async => http.Response('unauthorized', 401),
        ),
        accessToken: () => 'access-token',
        refreshSession: () async => true,
        onSessionInvalid: () async => invalidations += 1,
      );

      final response = await client.get(
        Uri.parse('http://localhost/protected'),
      );

      expect(response.statusCode, 401);
      expect(invalidations, 1);
    },
  );
}
