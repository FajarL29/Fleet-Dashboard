import 'dart:async';

import 'package:http/http.dart' as http;

typedef AccessTokenProvider = String? Function();
typedef RefreshSessionCallback = Future<bool> Function();
typedef SessionInvalidCallback = Future<void> Function();

class AuthenticatedHttpClient extends http.BaseClient {
  AuthenticatedHttpClient({
    required http.Client innerClient,
    AccessTokenProvider? accessToken,
    RefreshSessionCallback? refreshSession,
    SessionInvalidCallback? onSessionInvalid,
  }) : _innerClient = innerClient,
       _accessToken = accessToken ?? _noAccessToken,
       _refreshSession = refreshSession ?? _cannotRefresh,
       _onSessionInvalid = onSessionInvalid ?? _ignoreInvalidSession;

  static final AuthenticatedHttpClient instance = AuthenticatedHttpClient(
    innerClient: http.Client(),
  );

  final http.Client _innerClient;
  AccessTokenProvider _accessToken;
  RefreshSessionCallback _refreshSession;
  SessionInvalidCallback _onSessionInvalid;

  void configure({
    required AccessTokenProvider accessToken,
    required RefreshSessionCallback refreshSession,
    required SessionInvalidCallback onSessionInvalid,
  }) {
    _accessToken = accessToken;
    _refreshSession = refreshSession;
    _onSessionInvalid = onSessionInvalid;
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bodyBytes = await request.finalize().toBytes();
    final initialToken = _accessToken()?.trim();
    final firstResponse = await _innerClient.send(
      _copyRequest(request, bodyBytes, accessToken: initialToken),
    );

    if (firstResponse.statusCode != 401) return firstResponse;

    if (initialToken == null || initialToken.isEmpty) {
      await _onSessionInvalid();
      return firstResponse;
    }

    var refreshedToken = _accessToken()?.trim();
    final anotherRequestAlreadyRefreshed =
        refreshedToken != null &&
        refreshedToken.isNotEmpty &&
        refreshedToken != initialToken;
    if (!anotherRequestAlreadyRefreshed) {
      final refreshed = await _refreshSession();
      if (!refreshed) {
        await _onSessionInvalid();
        return firstResponse;
      }
      refreshedToken = _accessToken()?.trim();
    }

    await firstResponse.stream.drain<void>();
    if (refreshedToken == null || refreshedToken.isEmpty) {
      await _onSessionInvalid();
      return http.StreamedResponse(
        const Stream<List<int>>.empty(),
        401,
        request: request,
      );
    }

    final retryResponse = await _innerClient.send(
      _copyRequest(request, bodyBytes, accessToken: refreshedToken),
    );
    if (retryResponse.statusCode == 401) await _onSessionInvalid();
    return retryResponse;
  }

  http.Request _copyRequest(
    http.BaseRequest source,
    List<int> bodyBytes, {
    required String? accessToken,
  }) {
    final request = http.Request(source.method, source.url)
      ..followRedirects = source.followRedirects
      ..maxRedirects = source.maxRedirects
      ..persistentConnection = source.persistentConnection
      ..headers.addAll(source.headers)
      ..bodyBytes = bodyBytes;

    for (final key in request.headers.keys.toList()) {
      if (key.toLowerCase() == 'authorization') request.headers.remove(key);
    }
    if (accessToken != null && accessToken.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $accessToken';
    }
    return request;
  }

  @override
  void close() => _innerClient.close();

  static String? _noAccessToken() => null;

  static Future<bool> _cannotRefresh() async => false;

  static Future<void> _ignoreInvalidSession() async {}
}
