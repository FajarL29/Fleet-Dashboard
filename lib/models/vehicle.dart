import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

enum VehicleStatus { active, warning, inactive, alert }

class Vehicle {
  final String id;
  final String? apiVehicleId;
  final String plateNumber;
  final String type;
  final String driverName;
  final String activityTime;
  final LatLng position; // Using latlong2 LatLng
  //LatLng position; // Using latlong2 LatLng - made mutable
  final VehicleStatus status;
  double heading;
  final double speed; // Tambahkan atribut speed
  final String? displayStatus;
  final String? statusReason;
  final DateTime? lastTelemetryTime;
  final int? lastSeenMinutes;

  Vehicle({
    required this.id,
    this.apiVehicleId,
    required this.plateNumber,
    required this.type,
    required this.driverName,
    required this.activityTime,
    required this.position,
    required this.status,
    this.heading = 0.0,
    this.speed = 0.0, // Inisialisasi speed
    this.displayStatus,
    this.statusReason,
    this.lastTelemetryTime,
    this.lastSeenMinutes,
  });

  // Helper method to get status color
  Color getStatusColor() {
    final normalizedDisplayStatus = displayStatus?.trim().toLowerCase();

    switch (normalizedDisplayStatus) {
      case 'alert':
        return AppTheme.error;
      case 'warning':
        return AppTheme.warning;
      case 'moving':
        return AppTheme.success;
      case 'idle':
        return AppTheme.accentBlue;
      case 'online':
        return AppTheme.success;
      case 'offline':
        return const Color.fromARGB(255, 90, 95, 106);
    }

    switch (status) {
      case VehicleStatus.active:
        return AppTheme.success;
      case VehicleStatus.warning:
        return AppTheme.warning;
      case VehicleStatus.inactive:
        return const Color.fromARGB(255, 65, 58, 58);
      case VehicleStatus.alert:
        return AppTheme.error;
    }
  }

  String get statusLabel {
    final normalizedDisplayStatus = displayStatus?.trim();
    if (normalizedDisplayStatus != null && normalizedDisplayStatus.isNotEmpty) {
      return normalizedDisplayStatus
          .replaceAll('_', ' ')
          .split(' ')
          .where((part) => part.isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' ');
    }

    return status.name.toUpperCase();
  }

  // CopyWith method for immutable updates
  Vehicle copyWith({
    String? id,
    String? apiVehicleId,
    String? plateNumber,
    String? type,
    String? driverName,
    String? activityTime,
    LatLng? position,
    VehicleStatus? status,
    double? heading,
    double? speed,
    String? displayStatus,
    String? statusReason,
    DateTime? lastTelemetryTime,
    int? lastSeenMinutes,
  }) {
    return Vehicle(
      id: id ?? this.id,
      apiVehicleId: apiVehicleId ?? this.apiVehicleId,
      plateNumber: plateNumber ?? this.plateNumber,
      type: type ?? this.type,
      driverName: driverName ?? this.driverName,
      activityTime: activityTime ?? this.activityTime,
      position: position ?? this.position,
      status: status ?? this.status,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      displayStatus: displayStatus ?? this.displayStatus,
      statusReason: statusReason ?? this.statusReason,
      lastTelemetryTime: lastTelemetryTime ?? this.lastTelemetryTime,
      lastSeenMinutes: lastSeenMinutes ?? this.lastSeenMinutes,
    );
  }
}
