import 'vehicle_status.dart';

class VehicleRegistryResponse {
  const VehicleRegistryResponse({
    required this.status,
    required this.statCode,
    required this.data,
  });

  final String status;
  final int statCode;
  final VehicleRegistryData data;

  factory VehicleRegistryResponse.fromJson(Map<String, dynamic> json) {
    return VehicleRegistryResponse(
      status: json['status']?.toString() ?? '',
      statCode: _toInt(json['stat_code']),
      data: VehicleRegistryData.fromJson(
        json['data'] is Map<String, dynamic>
            ? json['data'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
    );
  }
}

class VehicleRegistryData {
  const VehicleRegistryData({
    required this.summary,
    required this.page,
    required this.limit,
    required this.vehicles,
  });

  final VehicleRegistrySummary summary;
  final int page;
  final int limit;
  final List<VehicleRegistryItem> vehicles;

  VehicleRegistryData copyWith({
    VehicleRegistrySummary? summary,
    int? page,
    int? limit,
    List<VehicleRegistryItem>? vehicles,
  }) {
    return VehicleRegistryData(
      summary: summary ?? this.summary,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      vehicles: vehicles ?? this.vehicles,
    );
  }

  factory VehicleRegistryData.fromJson(Map<String, dynamic> json) {
    final vehiclesJson = json['vehicles'] as List<dynamic>? ?? const [];

    return VehicleRegistryData(
      summary: VehicleRegistrySummary.fromJson(
        json['summary'] is Map<String, dynamic>
            ? json['summary'] as Map<String, dynamic>
            : const <String, dynamic>{},
      ),
      page: _toInt(json['page']),
      limit: _toInt(json['limit']),
      vehicles: vehiclesJson
          .whereType<Map<String, dynamic>>()
          .map(VehicleRegistryItem.fromJson)
          .toList(),
    );
  }
}

class VehicleRegistrySummary {
  const VehicleRegistrySummary({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.inactiveVehicles,
  });

  final int totalVehicles;
  final int activeVehicles;
  final int inactiveVehicles;

  VehicleRegistrySummary copyWith({
    int? totalVehicles,
    int? activeVehicles,
    int? inactiveVehicles,
  }) {
    return VehicleRegistrySummary(
      totalVehicles: totalVehicles ?? this.totalVehicles,
      activeVehicles: activeVehicles ?? this.activeVehicles,
      inactiveVehicles: inactiveVehicles ?? this.inactiveVehicles,
    );
  }

  factory VehicleRegistrySummary.fromJson(Map<String, dynamic> json) {
    return VehicleRegistrySummary(
      totalVehicles: _toInt(json['total_vehicles']),
      activeVehicles: _toInt(json['active_vehicles']),
      inactiveVehicles: _toInt(json['inactive_vehicles']),
    );
  }
}

class VehicleRegistryItem {
  const VehicleRegistryItem({
    required this.vehicleId,
    required this.vehicleIdentificationNumber,
    required this.plateNumber,
    required this.vehicleType,
    required this.driverId,
    required this.driverName,
    required this.deviceId,
    required this.imei,
    required this.isActive,
    required this.notes,
    required this.createdDt,
    required this.updatedDt,
  });

  final String vehicleId;
  final String vehicleIdentificationNumber;
  final String plateNumber;
  final String vehicleType;
  final String driverId;
  final String driverName;
  final String deviceId;
  final String imei;
  final bool isActive;
  final String notes;
  final DateTime? createdDt;
  final DateTime? updatedDt;

  VehicleRegistryItem copyWith({
    String? vehicleId,
    String? vehicleIdentificationNumber,
    String? plateNumber,
    String? vehicleType,
    String? driverId,
    String? driverName,
    String? deviceId,
    String? imei,
    bool? isActive,
    String? notes,
    DateTime? createdDt,
    DateTime? updatedDt,
  }) {
    return VehicleRegistryItem(
      vehicleId: vehicleId ?? this.vehicleId,
      vehicleIdentificationNumber:
          vehicleIdentificationNumber ?? this.vehicleIdentificationNumber,
      plateNumber: plateNumber ?? this.plateNumber,
      vehicleType: vehicleType ?? this.vehicleType,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      deviceId: deviceId ?? this.deviceId,
      imei: imei ?? this.imei,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdDt: createdDt ?? this.createdDt,
      updatedDt: updatedDt ?? this.updatedDt,
    );
  }

  factory VehicleRegistryItem.fromJson(Map<String, dynamic> json) {
    return VehicleRegistryItem(
      vehicleId: _toString(json['vehicle_id']),
      vehicleIdentificationNumber: _toString(
        json['vehicle_identification_number'],
      ),
      plateNumber: _toString(json['plate_number']),
      vehicleType: _toString(json['vehicle_type']),
      driverId: _toString(json['driver_id']),
      driverName: _toString(json['driver_name']),
      deviceId: _toString(json['device_id']),
      imei: _toString(json['imei']),
      isActive: _toBool(json['is_active']),
      notes: _toString(json['notes']),
      createdDt: _toDateTime(json['created_dt']),
      updatedDt: _toDateTime(json['updated_dt']),
    );
  }
}

class ManagedVehicle {
  const ManagedVehicle({required this.registry, this.status});

  final VehicleRegistryItem registry;
  final VehicleStatusItem? status;

  ManagedVehicle copyWith({
    VehicleRegistryItem? registry,
    VehicleStatusItem? status,
    bool clearStatus = false,
  }) {
    return ManagedVehicle(
      registry: registry ?? this.registry,
      status: clearStatus ? null : (status ?? this.status),
    );
  }

  String get vehicleId => registry.vehicleId;
  String get vin => registry.vehicleIdentificationNumber;
  String get plateNumber => registry.plateNumber;
  String get vehicleType => registry.vehicleType;
  String get driverId => registry.driverId;
  String get driverName => registry.driverName;
  String get deviceId => registry.deviceId;
  String get imei => registry.imei;
  bool get isActive => registry.isActive;
  String get notes => registry.notes;
  DateTime? get updatedDt => registry.updatedDt;

  bool get hasAssignedDriver =>
      driverName.trim().isNotEmpty || driverId.trim().isNotEmpty;
  bool get hasLinkedDevice =>
      deviceId.trim().isNotEmpty || imei.trim().isNotEmpty;

  String get assignedDriverLabel {
    if (driverName.trim().isNotEmpty) {
      return driverName;
    }
    if (driverId.trim().isNotEmpty) {
      return 'Driver #$driverId';
    }
    return 'Unassigned';
  }

  String get mergedStatusLabel {
    if (!isActive) return 'Inactive';

    final displayStatus = status?.displayStatus.trim().toLowerCase();
    switch (displayStatus) {
      case 'alert':
        return 'Alert';
      case 'warning':
        return 'Warning';
      case 'moving':
        return 'Moving';
      case 'idle':
        return 'Idle';
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
    }

    final movementStatus = status?.movementStatus.trim().toLowerCase();
    switch (movementStatus) {
      case 'moving':
        return 'Moving';
      case 'idle':
        return 'Idle';
    }

    final deviceStatus = status?.deviceStatus.trim().toLowerCase();
    switch (deviceStatus) {
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
      case 'warning':
        return 'Warning';
    }

    return 'Unknown';
  }

  String get statusReason {
    final reason = status?.statusReason.trim() ?? '';
    return reason.isEmpty ? 'No notes available' : reason;
  }

  DateTime? get lastUpdatedAt => status?.lastTelemetryTime ?? updatedDt;
  int? get lastSeenMinutes => status?.lastSeenMinutes;

  String get searchBlob => [
    plateNumber,
    vin,
    vehicleType,
    driverName,
    driverId,
    deviceId,
    imei,
  ].join(' ').toLowerCase();
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final parsed = int.tryParse(value);
    if (parsed != null) return parsed;
    return double.tryParse(value)?.toInt() ?? 0;
  }
  return 0;
}

String _toString(dynamic value) {
  if (value == null) return '';
  return value.toString().trim();
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is int) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

DateTime? _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
  return null;
}
