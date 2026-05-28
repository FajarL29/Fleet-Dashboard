import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/driver_behavior_summary.dart';
import '../models/drowsiness_driver_option.dart';
import '../models/drowsiness_report.dart';

class DrowsinessReportService {
  const DrowsinessReportService({
    this.baseUrl = 'http://localhost:3000/api/v1',
    http.Client? client,
  }) : _client = client;

  final String baseUrl;
  final http.Client? _client;

  Future<DrowsinessReport> getReport({
    required String vehicleId,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    final query = <String, String>{};
    if (startDate != null) query['start_date'] = _dateOnly(startDate);
    if (endDate != null) query['end_date'] = _dateOnly(endDate);
    if (userId != null) query['user_id'] = userId.toString();

    final response = await _get(
      '/drowsiness/report/$vehicleId',
      query.isEmpty ? null : query,
    );
    return DrowsinessReport.fromJson(response);
  }

  Future<List<DrowsinessDriverOption>> fetchDrowsinessDrivers({
    required String vehicleId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final query = <String, String>{};
    if (startDate != null) query['start_date'] = _dateOnly(startDate);
    if (endDate != null) query['end_date'] = _dateOnly(endDate);

    final response = await _get(
      '/drowsiness/drivers/$vehicleId',
      query.isEmpty ? null : query,
    );
    final data = response['data'] as List<dynamic>? ?? const [];
    final drivers = data
        .whereType<Map<String, dynamic>>()
        .map((item) {
          try {
            return DrowsinessDriverOption.fromJson(item);
          } on FormatException {
            return null;
          }
        })
        .whereType<DrowsinessDriverOption>()
        .toList();

    return [
      DrowsinessDriverOption.allDrivers(),
      ...drivers,
    ];
  }

  Future<List<DrowsinessEvent>> getEventsByVehicle({
    required String vehicleId,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
    int limit = 100,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
    };
    if (startDate != null) query['start_date'] = _dateOnly(startDate);
    if (endDate != null) query['end_date'] = _dateOnly(endDate);
    if (userId != null) query['user_id'] = userId.toString();

    final response = await _get('/drowsiness/events/$vehicleId', query);
    final data = response['data'] as List<dynamic>? ?? const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(DrowsinessEvent.fromJson)
        .toList();
  }

  Future<List<DrowsinessEvent>> getEvents({
    required String vehicleId,
    required DateTime startDate,
    required DateTime endDate,
    int? userId,
    int limit = 100,
  }) {
    return getEventsByVehicle(
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
      userId: userId,
      limit: limit,
    );
  }

  Future<List<DriverBehaviorSummary>> getDriverBehavior({
    String? vehicleId,
    int limit = 100,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
    };
    if (vehicleId != null && vehicleId.trim().isNotEmpty) {
      query['vehicle_id'] = vehicleId.trim();
    }

    final response = await _get('/drowsiness/driver-behavior', query);
    final data = response['data'] as List<dynamic>? ?? const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(DriverBehaviorSummary.fromJson)
        .toList();
  }

  Future<DrowsinessEvent> updateDrowsinessReview({
    required int drowsinessId,
    required String reviewStatus,
    String? reviewNote,
    String? followUpNote,
    String? reviewedBy,
  }) async {
    final body = <String, dynamic>{
      'review_status': reviewStatus,
    };

    if (reviewNote != null) {
      body['review_note'] = reviewNote;
    }
    if (followUpNote != null) {
      body['follow_up_note'] = followUpNote;
    }
    if (reviewedBy != null) {
      body['reviewed_by'] = reviewedBy;
    }

    final response = await _send(
      'PATCH',
      '/drowsiness/review/$drowsinessId',
      body: body,
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return DrowsinessEvent.fromJson(data);
    }

    throw Exception('Unexpected review update response format');
  }

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    return _send('GET', path, query: query);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      final response = await _request(
        client,
        method,
        uri,
        body: body,
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed ${response.statusCode}: ${response.body}');
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected API response format');
      }

      if (decoded['status'] != null && decoded['status'] != 'success') {
        throw Exception(decoded['message'] ?? 'API returned ${decoded['status']}');
      }

      return decoded;
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Future<http.Response> _request(
    http.Client client,
    String method,
    Uri uri, {
    Map<String, dynamic>? body,
  }) {
    switch (method.toUpperCase()) {
      case 'PATCH':
        return client.patch(
          uri,
          headers: const {
            'Content-Type': 'application/json',
          },
          body: json.encode(body ?? const <String, dynamic>{}),
        );
      case 'GET':
      default:
        return client.get(uri);
    }
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
