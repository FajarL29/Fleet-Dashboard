import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum HealthStatus {
  normal,
  warning,
  alert;

  Color getStatusColor() {
    switch (this) {
      case HealthStatus.normal:
        return AppTheme.success;
      case HealthStatus.warning:
        return AppTheme.warning;
      case HealthStatus.alert:
        return AppTheme.error;
    }
  }
}

class DriverHealth {
  final String driverId;
  final String name;
  final String imageUrl;
  final int heartRate;
  final double temperature;
  final HealthStatus status;
  final String activity;

  /// Blood oxygen saturation, in percent. Null until a vital-sign feed
  /// provides it — the API has no endpoint for this yet.
  final int? spo2;

  /// How long the driver has been on shift. Null for the same reason.
  final Duration? workDuration;

  const DriverHealth({
    required this.driverId,
    required this.name,
    required this.imageUrl,
    required this.heartRate,
    required this.temperature,
    required this.status,
    required this.activity,
    this.spo2,
    this.workDuration,
  });

  bool get isActive => activity.trim().toLowerCase() == 'active';

  Color getStatusColor() {
    switch (status) {
      case HealthStatus.normal:
        return AppTheme.success;
      case HealthStatus.warning:
        return AppTheme.warning;
      case HealthStatus.alert:
        return AppTheme.error;
    }
  }

  String getStatusText() {
    switch (status) {
      case HealthStatus.normal:
        return 'Normal';
      case HealthStatus.warning:
        return 'Warning';
      case HealthStatus.alert:
        return 'Alert';
    }
  }
}
