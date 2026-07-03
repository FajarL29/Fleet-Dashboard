import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/vehicle_management.dart';

class VehicleManagementService {
  const VehicleManagementService({
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

  Future<VehicleRegistryData> getVehicles({
    String? status,
    int? limit,
    int? page,
  }) async {
    final query = <String, String>{
      if (_hasValue(status)) 'status': status!.trim(),
      if (limit != null) 'limit': limit.toString(),
      if (page != null) 'page': page.toString(),
    };
    final decoded = await _send(
      'GET',
      '/vehicles',
      query: query.isEmpty ? null : query,
      logLabel: 'Fetch vehicles',
    );
    final parsed = VehicleRegistryResponse.fromJson(decoded);
    return parsed.data;
  }

  Future<void> createVehicle({
    required String plateNumber,
    required String vin,
    required String vehicleType,
    String? driverId,
    String? deviceId,
    String? imei,
    String? notes,
  }) {
    return _writeVehicle(
      method: 'POST',
      path: '/vehicles',
      body: <String, dynamic>{
        'plate_number': plateNumber,
        'vehicle_identification_number': vin,
        'vehicle_type': vehicleType,
        if (_hasValue(driverId)) 'driver_id': driverId!.trim(),
        if (_hasValue(deviceId)) 'device_id': deviceId!.trim(),
        if (_hasValue(imei)) 'imei': imei!.trim(),
        if (_hasValue(notes)) 'notes': notes!.trim(),
      },
    );
  }

  Future<void> updateVehicle({
    required String vehicleId,
    required String plateNumber,
    required String vin,
    required String vehicleType,
    String? driverId,
    String? deviceId,
    String? imei,
    String? notes,
  }) {
    return _writeVehicle(
      method: 'PUT',
      path: '/vehicles/$vehicleId',
      body: <String, dynamic>{
        'plate_number': plateNumber,
        'vehicle_identification_number': vin,
        'vehicle_type': vehicleType,
        'driver_id': _normalizeNullable(driverId),
        'device_id': _normalizeNullable(deviceId),
        'imei': _normalizeNullable(imei),
        'notes': _normalizeNullable(notes),
      },
    );
  }

  Future<void> deactivateVehicle(String vehicleId) {
    return _writeVehicle(
      method: 'PATCH',
      path: '/vehicles/$vehicleId/deactivate',
      body: const <String, dynamic>{},
    );
  }

  Future<String> exportVehiclesCsv(
    List<ManagedVehicle> vehicles, {
    String? searchQuery,
    String? statusFilter,
    String? typeFilter,
    String? assignmentFilter,
  }) async {
    final rows = <List<String>>[
      const [
        'Plate Number',
        'VIN',
        'Vehicle Type',
        'Driver',
        'Device ID',
        'IMEI',
        'Status',
        'Last Seen Minutes',
        'Last Updated',
        'Notes',
      ],
      ...vehicles.map(
        (vehicle) => [
          vehicle.plateNumber,
          vehicle.vin,
          vehicle.vehicleType,
          vehicle.driverName,
          vehicle.deviceId,
          vehicle.imei,
          vehicle.mergedStatusLabel,
          vehicle.lastSeenMinutes?.toString() ?? '',
          vehicle.lastUpdatedAt?.toIso8601String() ?? '',
          vehicle.notes,
        ],
      ),
    ];

    final csv = rows.map(_csvRow).join('\n');
    final directory = await _resolveDownloadDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final filterSuffix = [
      _safeSegment(statusFilter),
      _safeSegment(typeFilter),
      _safeSegment(assignmentFilter),
      _safeSegment(searchQuery),
    ].where((part) => part.isNotEmpty).join('_');
    final file = File(
      '${directory.path}${Platform.pathSeparator}vehicle_registry_${filterSuffix.isEmpty ? '' : '${filterSuffix}_'}$timestamp.csv',
    );
    await file.writeAsString(csv, flush: true);

    if (kDebugMode) {
      debugPrint('[Vehicles] Saved export: ${file.path}');
    }

    return file.path;
  }

  Future<void> _writeVehicle({
    required String method,
    required String path,
    required Map<String, dynamic> body,
  }) async {
    await _send(method, path, body: body, logLabel: '$method $path');
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
    String? logLabel,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: query == null || query.isEmpty ? null : query);
    final client = _client ?? http.Client();
    final shouldCloseClient = _client == null;

    try {
      if (kDebugMode && logLabel != null) {
        debugPrint('[Vehicles] $logLabel: $uri');
      }

      late http.Response response;
      switch (method.toUpperCase()) {
        case 'POST':
          response = await client.post(
            uri,
            headers: _headers(includeJsonContentType: true),
            body: json.encode(body ?? const <String, dynamic>{}),
          );
          break;
        case 'PUT':
          response = await client.put(
            uri,
            headers: _headers(includeJsonContentType: true),
            body: json.encode(body ?? const <String, dynamic>{}),
          );
          break;
        case 'PATCH':
          response = await client.patch(
            uri,
            headers: _headers(includeJsonContentType: true),
            body: json.encode(body ?? const <String, dynamic>{}),
          );
          break;
        case 'GET':
        default:
          response = await client.get(uri, headers: _headers());
          break;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Request failed ${response.statusCode}');
      }

      if (response.body.trim().isEmpty) {
        return const <String, dynamic>{'status': 'success'};
      }

      final decoded = json.decode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected API response format');
      }

      if (decoded['status'] != null && decoded['status'] != 'success') {
        throw Exception(decoded['message'] ?? 'Vehicle API request failed');
      }

      return decoded;
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  Map<String, String> _headers({bool includeJsonContentType = false}) {
    final headers = <String, String>{...defaultHeaders};
    final trimmedToken = authToken.trim();

    if (trimmedToken.isNotEmpty &&
        !headers.keys.any((key) => key.toLowerCase() == 'authorization')) {
      headers['Authorization'] = 'Bearer $trimmedToken';
    }

    if (includeJsonContentType &&
        !headers.keys.any((key) => key.toLowerCase() == 'content-type')) {
      headers['Content-Type'] = 'application/json';
    }

    return headers;
  }

  Future<Directory> _resolveDownloadDirectory() async {
    final candidates = <String?>[
      if (Platform.isWindows) Platform.environment['USERPROFILE'],
      Platform.environment['HOME'],
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

  String _csvRow(List<String> values) {
    return values
        .map((value) {
          final escaped = value.replaceAll('"', '""');
          return '"$escaped"';
        })
        .join(',');
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  String _safeSegment(String? value) {
    if (!_hasValue(value)) {
      return '';
    }

    final normalized = value!.trim().replaceAll(' ', '_').toLowerCase();
    return normalized.replaceAll(RegExp(r'[^a-z0-9_\-]'), '');
  }

  String? _normalizeNullable(String? value) {
    if (!_hasValue(value)) {
      return null;
    }
    return value!.trim();
  }
}
