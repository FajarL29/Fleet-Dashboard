import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../widgets/vital_sign/vital_sign_reading.dart';
import 'api_config.dart';
import 'authenticated_http_client.dart';

/// Driver vitals from the wearables.
///
/// The production API has no vitals endpoint yet; this is the contract the
/// mock server implements, so the page is built and reviewable now rather
/// than waiting on the backend.
class VitalSignService {
  const VitalSignService({
    this.baseUrl = kApiBaseUrl,
    this.authToken = kApiAuthToken,
    http.Client? client,
    this.requestTimeout = kApiRequestTimeout,
  }) : _client = client;

  final String baseUrl;
  final String authToken;
  final Duration requestTimeout;
  final http.Client? _client;

  /// The latest reading per driver.
  Future<List<VitalSignReading>> getDriverVitals() async {
    final uri = Uri.parse('$baseUrl/drivers/vitals');

    final client = _client ?? AuthenticatedHttpClient.instance;
    if (kDebugMode) debugPrint('[VitalSign] GET $uri');

    final response = await client
        .get(uri, headers: await _headers())
        .timeout(requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Vital sign request failed ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected vital sign response format');
    }

    final data = decoded['data'];
    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(vitalSignReadingFromJson)
        .toList();
  }

  /// Authorization is [AuthenticatedHttpClient]'s job, not this service's.
  Future<Map<String, String>> _headers() async => const {};
}
