class VehicleStatusResponse {
  const VehicleStatusResponse({
    required this.status,
    required this.statCode,
    required this.data,
  });

  final String status;
  final int statCode;
  final VehicleStatusData data;

  factory VehicleStatusResponse.fromJson(Map<String, dynamic> json) {
    return VehicleStatusResponse(
      status: json['status']?.toString() ?? '',
      statCode: _toInt(json['stat_code']),
      data: VehicleStatusData.fromJson(
        json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
    );
  }
}

class VehicleStatusData {
  const VehicleStatusData({required this.summary, required this.vehicles});

  final VehicleStatusSummary summary;
  final List<VehicleStatusItem> vehicles;

  factory VehicleStatusData.fromJson(Map<String, dynamic> json) {
    final vehiclesJson = json['vehicles'] as List<dynamic>? ?? const [];

    return VehicleStatusData(
      summary: VehicleStatusSummary.fromJson(
        json['summary'] is Map<String, dynamic>
            ? json['summary'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
      vehicles: vehiclesJson
          .whereType<Map<String, dynamic>>()
          .map(VehicleStatusItem.fromJson)
          .toList(),
    );
  }
}

class VehicleStatusSummary {
  const VehicleStatusSummary({
    required this.totalVehicles,
    required this.onlineVehicles,
    required this.moving,
    required this.idle,
    required this.warning,
    required this.offline,
    required this.alert,
  });

  final int totalVehicles;
  final int onlineVehicles;
  final int moving;
  final int idle;
  final int warning;
  final int offline;
  final int alert;

  factory VehicleStatusSummary.fromJson(Map<String, dynamic> json) {
    return VehicleStatusSummary(
      totalVehicles: _toInt(json['total_vehicles']),
      onlineVehicles: _toInt(json['online_vehicles']),
      moving: _toInt(json['moving']),
      idle: _toInt(json['idle']),
      warning: _toInt(json['warning']),
      offline: _toInt(json['offline']),
      alert: _toInt(json['alert']),
    );
  }
}

class VehicleStatusItem {
  const VehicleStatusItem({
    required this.vehicleId,
    required this.vehicleIdentificationNumber,
    required this.plateNumber,
    required this.driverName,
    required this.lastTelemetryTime,
    required this.lastSeenMinutes,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.deviceStatus,
    required this.movementStatus,
    required this.safetyStatus,
    required this.displayStatus,
    required this.statusReason,
  });

  final String vehicleId;
  final String vehicleIdentificationNumber;
  final String plateNumber;
  final String driverName;
  final DateTime? lastTelemetryTime;
  final int? lastSeenMinutes;
  final double? latitude;
  final double? longitude;
  final double? speed;
  final String deviceStatus;
  final String movementStatus;
  final String safetyStatus;
  final String displayStatus;
  final String statusReason;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory VehicleStatusItem.fromJson(Map<String, dynamic> json) {
    return VehicleStatusItem(
      vehicleId: _toString(json['vehicle_id']),
      vehicleIdentificationNumber: _toString(
        json['vehicle_identification_number'],
      ),
      plateNumber: _toString(json['plate_number']),
      driverName: _toString(json['driver_name']),
      lastTelemetryTime: _parseDate(json['last_telemetry_time']),
      lastSeenMinutes: _toNullableInt(json['last_seen_minutes']),
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      speed: _toDouble(json['speed']),
      deviceStatus: _toString(json['device_status']),
      movementStatus: _toString(json['movement_status']),
      safetyStatus: _toString(json['safety_status']),
      displayStatus: _toString(json['display_status']),
      statusReason: _toString(json['status_reason']),
    );
  }
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final direct = int.tryParse(value);
    if (direct != null) return direct;
    return double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    final direct = int.tryParse(trimmed);
    if (direct != null) return direct;
    return double.tryParse(trimmed)?.toInt();
  }
  return null;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
  return null;
}

DateTime? _parseDate(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
  return null;
}

String _toString(dynamic value) {
  if (value == null) return '';
  final result = value.toString().trim();
  return result;
}
