import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../widgets/air_quality/air_quality_reading.dart';
import 'api_config.dart';
import 'authenticated_http_client.dart';

/// Cabin air samples from the air-monitor devices.
///
/// The API serves one day per call (`?date=YYYY-MM-DD`), so anything wider than
/// a single day is fetched a day at a time and merged by the caller.
class AirQualityService {
  const AirQualityService({
    this.baseUrl = kApiBaseUrl,
    this.authToken = kApiAuthToken,
    http.Client? client,
    this.requestTimeout = kApiRequestTimeout,
  }) : _client = client;

  final String baseUrl;
  final String authToken;
  final Duration requestTimeout;
  final http.Client? _client;

  /// Readings recorded on [date]. Returns an empty list when that day has none,
  /// which is a normal answer rather than a failure.
  Future<List<AirQualityReading>> getAirByDate(DateTime date) async {
    final day =
        '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
    final uri = Uri.parse(
      '$baseUrl/air-monitor/get-air-by-date',
    ).replace(queryParameters: {'date': day});

    final client = _client ?? AuthenticatedHttpClient.instance;
    if (kDebugMode) debugPrint('[AirQuality] GET $uri');

    final response = await client
        .get(uri, headers: await _headers())
        .timeout(requestTimeout);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Air quality request failed ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected air quality response format');
    }

    final data = decoded['data'];
    if (data is! List) return const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(airQualityReadingFromJson)
        .toList();
  }

  /// No Authorization here: [AuthenticatedHttpClient] stamps the current
  /// token on every request it sends, and is the only thing that knows when a
  /// token has just been refreshed mid-flight.
  Future<Map<String, String>> _headers() async {
    return const {'Content-Type': 'application/json'};
  }
}
