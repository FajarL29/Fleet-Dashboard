import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';

enum VehicleStatus {
  active,
  warning,
  error,
}

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
  });

  // Helper method to get status color
  Color getStatusColor() {
    switch (status) {
      case VehicleStatus.active:
        return AppTheme.success;
      case VehicleStatus.warning:
        return AppTheme.warning;
      case VehicleStatus.error:
        return AppTheme.error;
    }
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
    );
  }
}
