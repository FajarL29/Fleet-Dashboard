import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/vehicle_status.dart';
import 'api_config.dart';
import 'authenticated_http_client.dart';

class VehicleStatusService {
  const VehicleStatusService({
    this.baseUrl = _defaultBaseUrl,
    this.authToken = _defaultAuthToken,
    this.defaultHeaders = const <String, String>{},
    http.Client? client,
    this.requestTimeout = kApiRequestTimeout,
  }) : _client = client;

  static const String _defaultBaseUrl = kApiBaseUrl;
  static const String _defaultAuthToken = kApiAuthToken;

  final String baseUrl;
  final String authToken;
  final Map<String, String> defaultHeaders;
  final Duration requestTimeout;
  final http.Client? _client;

  Future<VehicleStatusData> getVehicleStatus() async {
    final uri = Uri.parse('$baseUrl/vehicles/status');
    final client = _client ?? AuthenticatedHttpClient.instance;
    if (kDebugMode) {
      debugPrint('[VehicleStatus] GET $uri');
    }

    final response = await client
        .get(uri, headers: await _headers())
        .timeout(requestTimeout);
    if (kDebugMode) {
      final preview = response.body.length > 500
          ? response.body.substring(0, 500)
          : response.body;
      debugPrint('[VehicleStatus] status=${response.statusCode}');
      debugPrint('[VehicleStatus] body=$preview');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Vehicle status request failed ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected vehicle status response format');
    }

    final parsed = VehicleStatusResponse.fromJson(decoded);
    if (parsed.status.isNotEmpty && parsed.status.toLowerCase() != 'success') {
      throw Exception('Vehicle status API returned ${parsed.status}');
    }

    if (kDebugMode) {
      debugPrint(
        '[VehicleStatus] parsed total=${parsed.data.summary.totalVehicles} online=${parsed.data.summary.onlineVehicles} vehicles=${parsed.data.vehicles.length}',
      );
    }

    return parsed.data;
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{...defaultHeaders};
    // Authorization is left to [AuthenticatedHttpClient], which stamps the
    // current token on and is the only thing that knows when one was just
    // refreshed. An explicit token in [defaultHeaders] still wins.

    if (!headers.keys.any((key) => key.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }
}
