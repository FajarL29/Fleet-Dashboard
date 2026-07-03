import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/vehicle_status.dart';

class VehicleStatusService {
  const VehicleStatusService({
    this.baseUrl = _defaultBaseUrl,
    this.authToken = _defaultAuthToken,
    this.defaultHeaders = const <String, String>{},
    http.Client? client,
  }) : _client = client;

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  static const String _defaultAuthToken = String.fromEnvironment(
    'API_AUTH_TOKEN',
    defaultValue: '',
  );

  final String baseUrl;
  final String authToken;
  final Map<String, String> defaultHeaders;
  final http.Client? _client;

  Future<VehicleStatusData> getVehicleStatus() async {
    final uri = Uri.parse('$baseUrl/vehicles/status');
    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      if (kDebugMode) {
        debugPrint('[VehicleStatus] GET $uri');
      }

      final response = await client.get(uri, headers: _headers());
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
      if (parsed.status.isNotEmpty &&
          parsed.status.toLowerCase() != 'success') {
        throw Exception('Vehicle status API returned ${parsed.status}');
      }

      if (kDebugMode) {
        debugPrint(
          '[VehicleStatus] parsed total=${parsed.data.summary.totalVehicles} online=${parsed.data.summary.onlineVehicles} vehicles=${parsed.data.vehicles.length}',
        );
      }

      return parsed.data;
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Map<String, String> _headers() {
    final headers = <String, String>{...defaultHeaders};
    final trimmedToken = authToken.trim();

    if (trimmedToken.isNotEmpty &&
        !headers.keys.any((key) => key.toLowerCase() == 'authorization')) {
      headers['Authorization'] = 'Bearer $trimmedToken';
    }

    if (!headers.keys.any((key) => key.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }
}
