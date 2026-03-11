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
  final String plateNumber;
  final String type;
  final String driverName;
  final String activityTime;
  LatLng position; // Using latlong2 LatLng - made mutable
  final VehicleStatus status;
  double heading;

  Vehicle({
    required this.id,
    required this.plateNumber,
    required this.type,
    required this.driverName,
    required this.activityTime,
    required this.position,
    required this.status,
    this.heading = 0.0,
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
}