import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/driver_behavior_summary.dart';
import '../models/drowsiness_driver_option.dart';
import '../models/drowsiness_report.dart';
import 'authenticated_http_client.dart';

class DrowsinessReportService {
  const DrowsinessReportService({
    this.baseUrl = _defaultBaseUrl,
    this.defaultHeaders = const <String, String>{},
    http.Client? client,
  }) : _client = client;

  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api/v1',
  );
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final http.Client? _client;

  Future<Map<String, dynamic>?> getLatestByVehicle(String vehicleId) async {
    final response = await _get(
      '/drowsiness/latest/${Uri.encodeComponent(vehicleId)}',
      null,
      logLabel: 'Fetch latest drowsiness',
    );
    final data = response['data'];
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    throw const FormatException('Unexpected latest drowsiness response');
  }

  Future<DrowsinessReport> getReport({
    required String vehicleId,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    final response = await _get(
      '/drowsiness/report/$vehicleId',
      _reportQuery(startDate: startDate, endDate: endDate, userId: userId),
      logLabel: 'Fetch report',
    );
    return DrowsinessReport.fromJson(response);
  }

  Future<String> exportDrowsinessReportCsv({
    required String vehicleId,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) {
    return _exportDrowsinessReport(
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
      userId: userId,
      extension: 'csv',
      path: '/drowsiness/report/$vehicleId/export/csv',
    );
  }

  Future<String> exportDrowsinessReportPdf({
    required String vehicleId,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) {
    return _exportDrowsinessReport(
      vehicleId: vehicleId,
      startDate: startDate,
      endDate: endDate,
      userId: userId,
      extension: 'pdf',
      path: '/drowsiness/report/$vehicleId/export/pdf',
    );
  }

  Future<List<DrowsinessDriverOption>> fetchDrowsinessDrivers({
    required String vehicleId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final response = await _get(
      '/drowsiness/drivers/$vehicleId',
      _reportQuery(startDate: startDate, endDate: endDate),
      logLabel: 'Fetch drivers',
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

    return [DrowsinessDriverOption.allDrivers(), ...drivers];
  }

  Future<List<DrowsinessEvent>> getEventsByVehicle({
    required String vehicleId,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
    int limit = 100,
  }) async {
    final response = await _get(
      '/drowsiness/events/$vehicleId',
      _reportQuery(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
        extra: <String, String>{'limit': limit.toString()},
      ),
      logLabel: 'Fetch events',
    );
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
    final query = <String, String>{'limit': limit.toString()};
    if (vehicleId != null && vehicleId.trim().isNotEmpty) {
      query['vehicle_id'] = vehicleId.trim();
    }

    final response = await _get(
      '/drowsiness/driver-behavior',
      _reportQuery(),
      query: query,
    );
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
    final body = <String, dynamic>{'review_status': reviewStatus};

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

  Future<DrowsinessAiSuggestion> generateAiSuggestion(int drowsinessId) async {
    final response = await _send(
      'POST',
      '/drowsiness/ai-suggestion/$drowsinessId',
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return DrowsinessAiSuggestion.fromJson(data);
    }

    throw Exception('Unexpected AI suggestion response format');
  }

  Future<DrowsinessBatchAiSuggestionResult> generateBatchAiSuggestion({
    required String vehicleId,
    required DateTime startDate,
    required DateTime endDate,
    required int limit,
    required bool onlyMissingAi,
    List<String>? status,
  }) async {
    final body = <String, dynamic>{
      'vehicle_id': vehicleId,
      'start_date': _dateOnly(startDate),
      'end_date': _dateOnly(endDate),
      'limit': limit,
      'only_missing_ai': onlyMissingAi,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    final response = await _send(
      'POST',
      '/drowsiness/ai-suggestion/batch',
      body: body,
    );

    final data = response['data'];
    if (data is Map<String, dynamic>) {
      return DrowsinessBatchAiSuggestionResult.fromJson(data);
    }

    throw Exception('Unexpected batch AI suggestion response format');
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String>? reportQuery, {
    Map<String, String>? query,
    String? logLabel,
  }) async {
    final mergedQuery = <String, String>{
      if (reportQuery != null) ...reportQuery,
      if (query != null) ...query,
    };
    return _send(
      'GET',
      path,
      query: mergedQuery.isEmpty ? null : mergedQuery,
      logLabel: logLabel,
    );
  }

  Future<String> _exportDrowsinessReport({
    required String vehicleId,
    required String path,
    required String extension,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) async {
    final uri = _buildUri(
      path,
      query: _reportQuery(
        startDate: startDate,
        endDate: endDate,
        userId: userId,
      ),
    );
    final client = _client ?? AuthenticatedHttpClient.instance;
    final shouldCloseClient =
        _client == null && client is! AuthenticatedHttpClient;

    try {
      _logRequest(
        extension.toLowerCase() == 'pdf' ? 'Export PDF' : 'Export CSV',
        uri,
      );

      final response = await _request(client, 'GET', uri, headers: _headers());
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _requestException(response, uri);
      }

      final fileName = _resolveExportFileName(
        response: response,
        vehicleId: vehicleId,
        startDate: startDate,
        endDate: endDate,
        userId: userId,
        extension: extension,
      );
      final directory = await _resolveDownloadDirectory();
      final file = File('${directory.path}${Platform.pathSeparator}$fileName');
      await file.writeAsBytes(response.bodyBytes, flush: true);
      _logSavedExport(file.path);
      return file.path;
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    String? logLabel,
  }) async {
    final uri = _buildUri(path, query: query);
    final client = _client ?? AuthenticatedHttpClient.instance;
    final shouldCloseClient =
        _client == null && client is! AuthenticatedHttpClient;

    try {
      if (logLabel != null) {
        _logRequest(logLabel, uri);
      }

      final response = await _request(
        client,
        method,
        uri,
        body: body,
        headers: _headers(includeJsonContentType: body != null),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _requestException(response, uri);
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected API response format');
      }

      if (decoded['status'] != null && decoded['status'] != 'success') {
        throw Exception(
          decoded['message'] ?? 'API returned ${decoded['status']}',
        );
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
    Map<String, String>? headers,
  }) {
    switch (method.toUpperCase()) {
      case 'POST':
        return client.post(
          uri,
          headers: headers,
          body: json.encode(body ?? const <String, dynamic>{}),
        );
      case 'PATCH':
        return client.patch(
          uri,
          headers: headers,
          body: json.encode(body ?? const <String, dynamic>{}),
        );
      case 'GET':
      default:
        return client.get(uri, headers: headers);
    }
  }

  Map<String, String>? _reportQuery({
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
    Map<String, String>? extra,
  }) {
    final query = <String, String>{
      if (extra != null) ...extra,
      if (startDate != null) 'start_date': _dateOnly(startDate),
      if (endDate != null) 'end_date': _dateOnly(endDate),
      if (userId != null) 'user_id': userId.toString(),
    };
    return query.isEmpty ? null : query;
  }

  Uri _buildUri(String path, {Map<String, String>? query}) {
    return Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
  }

  Map<String, String> _headers({bool includeJsonContentType = false}) {
    final headers = <String, String>{...defaultHeaders};

    if (includeJsonContentType &&
        !headers.keys.any((key) => key.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  String _dateOnly(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<Directory> _resolveDownloadDirectory() async {
    final candidates = <String?>[
      if (Platform.isWindows) _environment('USERPROFILE'),
      _environment('HOME'),
    ];

    for (final root in candidates) {
      if (root == null || root.isEmpty) continue;
      final downloadDirectory = Directory(
        '$root${Platform.pathSeparator}Downloads',
      );
      if (await downloadDirectory.exists()) {
        return downloadDirectory;
      }
    }

    return Directory.current;
  }

  String _resolveExportFileName({
    required http.Response response,
    required String vehicleId,
    required String extension,
    DateTime? startDate,
    DateTime? endDate,
    int? userId,
  }) {
    final header = response.headers['content-disposition'];
    final fileNameFromHeader = _fileNameFromContentDisposition(header);
    if (fileNameFromHeader != null && fileNameFromHeader.isNotEmpty) {
      return fileNameFromHeader;
    }

    final start = startDate == null ? 'all' : _dateOnly(startDate);
    final end = endDate == null ? 'all' : _dateOnly(endDate);
    final driver = userId == null ? 'all_drivers' : 'user_$userId';

    return 'drowsiness_report_${_safeSegment(vehicleId)}_${_safeSegment(start)}_${_safeSegment(end)}_${_safeSegment(driver)}.$extension';
  }

  String? _fileNameFromContentDisposition(String? header) {
    if (header == null || header.isEmpty) return null;

    final utf8Match = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(header);
    if (utf8Match != null) {
      return Uri.decodeComponent(utf8Match.group(1)!);
    }

    final simpleMatch = RegExp(
      r'filename="?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(header);
    return simpleMatch?.group(1);
  }

  String _safeSegment(String value) {
    return value.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');
  }

  String? _environment(String key) {
    try {
      return Platform.environment[key];
    } catch (_) {
      return null;
    }
  }

  void _logRequest(String label, Uri uri) {
    if (!kDebugMode) return;
    debugPrint('[Report] $label: $uri');
  }

  void _logSavedExport(String path) {
    if (!kDebugMode) return;
    debugPrint('[Report] Saved export: $path');
  }

  ApiRequestException _requestException(http.Response response, Uri uri) {
    String? message;

    try {
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) {
        final apiMessage = decoded['message']?.toString().trim();
        if (apiMessage != null && apiMessage.isNotEmpty) {
          message = apiMessage;
        }
      }
    } catch (_) {
      // Keep the fallback message below when the response is not JSON.
    }

    final resolvedMessage = message?.isNotEmpty == true
        ? message!
        : 'Request failed ${response.statusCode}';

    return ApiRequestException(
      statusCode: response.statusCode,
      message: resolvedMessage,
      uri: uri,
      responseBody: response.body,
    );
  }
}

class ApiRequestException implements Exception {
  const ApiRequestException({
    required this.statusCode,
    required this.message,
    required this.uri,
    this.responseBody,
  });

  final int statusCode;
  final String message;
  final Uri uri;
  final String? responseBody;

  @override
  String toString() {
    return 'Request failed $statusCode: $message';
  }
}

class DrowsinessAiSuggestion {
  const DrowsinessAiSuggestion({
    required this.drowsinessId,
    this.aiSuggestion,
    this.aiConfidence,
    this.aiReason,
    this.aiCorrectedLabel,
    this.aiEvidenceQuality,
    this.aiReviewedAt,
  });

  final int drowsinessId;
  final String? aiSuggestion;
  final double? aiConfidence;
  final String? aiReason;
  final String? aiCorrectedLabel;
  final String? aiEvidenceQuality;
  final DateTime? aiReviewedAt;

  factory DrowsinessAiSuggestion.fromJson(Map<String, dynamic> json) {
    return DrowsinessAiSuggestion(
      drowsinessId: _serviceToInt(json['drowsiness_id']),
      aiSuggestion: _serviceOptionalString(json['ai_suggestion']),
      aiConfidence: _serviceToDouble(json['ai_confidence']),
      aiReason: _serviceOptionalString(json['ai_reason']),
      aiCorrectedLabel: _serviceOptionalString(json['ai_corrected_label']),
      aiEvidenceQuality: _serviceOptionalString(json['ai_evidence_quality']),
      aiReviewedAt: _serviceParseDate(json['ai_reviewed_at']),
    );
  }
}

class DrowsinessBatchAiSuggestionResult {
  const DrowsinessBatchAiSuggestionResult({
    required this.requested,
    required this.processed,
    required this.success,
    required this.failed,
    required this.skipped,
    required this.results,
  });

  final int requested;
  final int processed;
  final int success;
  final int failed;
  final int skipped;
  final List<DrowsinessBatchAiSuggestionItem> results;

  factory DrowsinessBatchAiSuggestionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawResults = json['results'] as List<dynamic>? ?? const [];

    return DrowsinessBatchAiSuggestionResult(
      requested: _serviceToInt(json['requested']),
      processed: _serviceToInt(json['processed']),
      success: _serviceToInt(json['success']),
      failed: _serviceToInt(json['failed']),
      skipped: _serviceToInt(json['skipped']),
      results: rawResults
          .whereType<Map<String, dynamic>>()
          .map(DrowsinessBatchAiSuggestionItem.fromJson)
          .toList(),
    );
  }
}

class DrowsinessBatchAiSuggestionItem {
  const DrowsinessBatchAiSuggestionItem({
    required this.drowsinessId,
    required this.status,
    this.aiSuggestion,
    this.aiConfidence,
    this.aiCorrectedLabel,
    this.aiEvidenceQuality,
  });

  final int drowsinessId;
  final String status;
  final String? aiSuggestion;
  final double? aiConfidence;
  final String? aiCorrectedLabel;
  final String? aiEvidenceQuality;

  factory DrowsinessBatchAiSuggestionItem.fromJson(Map<String, dynamic> json) {
    return DrowsinessBatchAiSuggestionItem(
      drowsinessId: _serviceToInt(json['drowsiness_id']),
      status: json['status']?.toString() ?? '',
      aiSuggestion: _serviceOptionalString(json['ai_suggestion']),
      aiConfidence: _serviceToDouble(json['ai_confidence']),
      aiCorrectedLabel: _serviceOptionalString(json['ai_corrected_label']),
      aiEvidenceQuality: _serviceOptionalString(json['ai_evidence_quality']),
    );
  }
}

int _serviceToInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double? _serviceToDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

String? _serviceOptionalString(dynamic value) {
  final stringValue = value?.toString().trim();
  if (stringValue == null || stringValue.isEmpty) {
    return null;
  }
  return stringValue;
}

DateTime? _serviceParseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
