import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/air_quality_reading.dart';

class AirQualityService {
  const AirQualityService({
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

  Future<AirQualityReading?> getLatestByVehicle(String vehicleId) async {
    final data = await _get(
      '/air-monitor/latest/${Uri.encodeComponent(vehicleId)}',
    );
    final item = _singleItem(data);
    return item == null ? null : AirQualityReading.fromJson(item);
  }

  Future<List<AirQualityReading>> getHistoryByVehicle(
    String vehicleId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final data = await _get(
      '/air-monitor/history/${Uri.encodeComponent(vehicleId)}',
      query: _dateQuery(startDate, endDate),
    );
    return _itemList(data).map(AirQualityReading.fromJson).toList();
  }

  Future<dynamic> _get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );
    final client = _client ?? http.Client();
    final shouldClose = _client == null;

    try {
      if (kDebugMode) debugPrint('[AirQuality] GET $uri');
      final response = await client.get(uri, headers: _headers());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw AirQualityRequestException(response.statusCode, uri);
      }
      if (response.body.trim().isEmpty) return null;

      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final status = decoded['status']?.toString().toLowerCase();
        if (status != null && status != 'success') {
          throw FormatException(decoded['message']?.toString() ?? 'Invalid API response');
        }
        return decoded.containsKey('data') ? decoded['data'] : decoded;
      }
      if (decoded is List<dynamic>) return decoded;
      throw const FormatException('Unexpected Air Quality response format');
    } on FormatException {
      rethrow;
    } catch (error) {
      if (error is AirQualityRequestException) rethrow;
      throw FormatException('Unable to read Air Quality response: $error');
    } finally {
      if (shouldClose) client.close();
    }
  }

  Map<String, String> _headers() {
    final headers = <String, String>{...defaultHeaders};
    if (authToken.trim().isNotEmpty &&
        !headers.keys.any((key) => key.toLowerCase() == 'authorization')) {
      headers['Authorization'] = 'Bearer ${authToken.trim()}';
    }
    headers.putIfAbsent('Accept', () => 'application/json');
    return headers;
  }
}

class AirQualityRequestException implements Exception {
  const AirQualityRequestException(this.statusCode, this.uri);

  final int statusCode;
  final Uri uri;

  @override
  String toString() => 'Request failed $statusCode';
}

Map<String, String>? _dateQuery(DateTime? startDate, DateTime? endDate) {
  final query = <String, String>{
    if (startDate != null) 'start_date': _dateOnly(startDate),
    if (endDate != null) 'end_date': _dateOnly(endDate),
  };
  return query.isEmpty ? null : query;
}

String _dateOnly(DateTime value) {
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return '${value.year}-$month-$day';
}

Map<String, dynamic>? _singleItem(dynamic data) {
  if (data == null) return null;
  if (data is Map<String, dynamic>) return data.isEmpty ? null : data;
  if (data is List<dynamic>) {
    for (final item in data) {
      if (item is Map<String, dynamic>) return item;
    }
    return null;
  }
  throw const FormatException('Expected an Air Quality object');
}

List<Map<String, dynamic>> _itemList(dynamic data) {
  if (data == null) return const [];
  if (data is List<dynamic>) return data.whereType<Map<String, dynamic>>().toList();
  if (data is Map<String, dynamic>) {
    final nested = data['items'] ?? data['history'] ?? data['records'];
    if (nested is List<dynamic>) {
      return nested.whereType<Map<String, dynamic>>().toList();
    }
  }
  throw const FormatException('Expected an Air Quality history list');
}
