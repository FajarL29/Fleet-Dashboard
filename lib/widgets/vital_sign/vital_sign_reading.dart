/// One row of the Driver Vital Sign Overview table.
///
/// One reading per driver, as `/drivers/vitals` returns them: the wearable's
/// measurements plus the plate of whatever vehicle they are assigned to.
class VitalSignReading {
  const VitalSignReading({
    required this.driverId,
    required this.driverName,
    required this.vehicleLabel,
    required this.heartRate,
    required this.spo2,
    required this.workDuration,
    required this.lastTelemetry,
    required this.isActive,
  });

  final String driverId;
  final String driverName;
  final String vehicleLabel;

  /// Null when the driver has no usable reading.
  final int? heartRate;
  final int? spo2;
  final Duration? workDuration;
  final DateTime? lastTelemetry;
  final bool isActive;

  /// Free-text blob the search box matches against.
  String get searchBlob => '$driverName $vehicleLabel'.toLowerCase();
}

/// Parses one row of `/drivers/vitals`.
///
/// Every measurement is nullable: a wearable may report a pulse but no SpO2,
/// and the table shows a dash for whatever nobody measured rather than a zero.
VitalSignReading vitalSignReadingFromJson(Map<String, dynamic> json) {
  final minutes = _toInt(json['work_duration_minutes']);

  return VitalSignReading(
    driverId: _string(json['driver_id'] ?? json['user_id']),
    driverName: _string(json['driver_name']).isEmpty
        ? 'Unknown Driver'
        : _string(json['driver_name']),
    vehicleLabel:
        _string(
          json['plate_number'] ?? json['vehicle_identification_number'],
        ).isEmpty
        ? '-'
        : _string(
            json['plate_number'] ?? json['vehicle_identification_number'],
          ),
    heartRate: _toInt(json['heart_rate']),
    spo2: _toInt(json['spo2']),
    workDuration: minutes == null ? null : Duration(minutes: minutes),
    lastTelemetry: _toDate(json['timestamp'] ?? json['last_telemetry_time']),
    // Absent means "we do not know", and an unknown driver is not on shift.
    isActive:
        json['is_active'] == true ||
        _string(json['activity']).toLowerCase() == 'active',
  );
}

String _string(dynamic value) => value?.toString().trim() ?? '';

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

DateTime? _toDate(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}
