import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/driver_behavior_summary.dart';
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
  }) async {
    final query = <String, String>{};
    if (startDate != null) query['start_date'] = _dateOnly(startDate);
    if (endDate != null) query['end_date'] = _dateOnly(endDate);

    final response = await _get(
      '/drowsiness/report/$vehicleId',
      query.isEmpty ? null : query,
    );
    return DrowsinessReport.fromJson(response);
  }

  Future<List<DrowsinessEvent>> getEventsByVehicle({
    required String vehicleId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 100,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
    };
    if (startDate != null) query['start_date'] = _dateOnly(startDate);
    if (endDate != null) query['end_date'] = _dateOnly(endDate);

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
    int limit = 100,
  }) {
    return getEventsByVehicle(
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
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

  Future<Map<String, dynamic>> _get(
    String path, [
    Map<String, String>? query,
  ]) async {
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: query);
    final response = _client == null
        ? await http.get(uri)
        : await _client!.get(uri);

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
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
