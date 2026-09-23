import 'package:flutter/material.dart';

import '../../models/vehicle_status.dart';
import '../../theme/app_theme.dart';

/// Buckets a vehicle can fall into on the Live Tracking page. These drive both
/// the filter chips and the status pill on each row.
enum LiveTrackingStatus {
  moving,
  idle,
  emergency,
  offline,

  /// Reported a status we do not bucket (e.g. plain "Online"). Has no chip of
  /// its own, so the chip counts can add up to less than "All".
  unknown,
}

extension LiveTrackingStatusDisplay on LiveTrackingStatus {
  String get label {
    switch (this) {
      case LiveTrackingStatus.moving:
        return 'Moving';
      case LiveTrackingStatus.idle:
        return 'Idle';
      case LiveTrackingStatus.emergency:
        return 'Emergency';
      case LiveTrackingStatus.offline:
        return 'Offline';
      case LiveTrackingStatus.unknown:
        return 'Unknown';
    }
  }

  Color get dotColor {
    switch (this) {
      case LiveTrackingStatus.moving:
        return AppColors.green;
      case LiveTrackingStatus.idle:
        return AppColors.amber;
      case LiveTrackingStatus.emergency:
        return AppColors.red;
      case LiveTrackingStatus.offline:
      case LiveTrackingStatus.unknown:
        return AppColors.textMuted;
    }
  }

  Color get backgroundColor {
    switch (this) {
      case LiveTrackingStatus.moving:
        return AppColors.greenSoft;
      case LiveTrackingStatus.idle:
        return AppColors.amberSoft;
      case LiveTrackingStatus.emergency:
        return AppColors.redSoft;
      case LiveTrackingStatus.offline:
      case LiveTrackingStatus.unknown:
        return AppColors.tileBackground;
    }
  }

  Color get textColor {
    switch (this) {
      case LiveTrackingStatus.moving:
        return AppColors.greenText;
      case LiveTrackingStatus.idle:
        return AppColors.amberText;
      case LiveTrackingStatus.emergency:
        return AppColors.redText;
      case LiveTrackingStatus.offline:
      case LiveTrackingStatus.unknown:
        return AppColors.textSecondary;
    }
  }
}

/// Best available status wording for [item], preferring the display status the
/// backend already resolved.
String liveTrackingStatusLabel(VehicleStatusItem item) {
  for (final candidate in [
    item.displayStatus,
    item.movementStatus,
    item.deviceStatus,
  ]) {
    final trimmed = candidate.trim();
    if (trimmed.isNotEmpty) return _titleCase(trimmed);
  }
  return 'Unknown';
}

LiveTrackingStatus liveTrackingStatusOf(VehicleStatusItem item) {
  switch (liveTrackingStatusLabel(item).toLowerCase()) {
    case 'moving':
      return LiveTrackingStatus.moving;
    case 'idle':
      return LiveTrackingStatus.idle;
    case 'alert':
    case 'warning':
      return LiveTrackingStatus.emergency;
    case 'offline':
      return LiveTrackingStatus.offline;
    default:
      return LiveTrackingStatus.unknown;
  }
}

/// Stable identity for a vehicle across refreshes.
String liveTrackingVehicleKey(VehicleStatusItem item) {
  for (final candidate in [
    item.vehicleId,
    item.vehicleIdentificationNumber,
    item.plateNumber,
  ]) {
    final trimmed = candidate.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '';
}

String liveTrackingPlateLabel(VehicleStatusItem item) {
  for (final candidate in [
    item.plateNumber,
    item.vehicleIdentificationNumber,
    item.vehicleId,
  ]) {
    final trimmed = candidate.trim();
    if (trimmed.isNotEmpty) return trimmed;
  }
  return '-';
}

String liveTrackingLastSeenLabel(VehicleStatusItem item) {
  final minutes = item.lastSeenMinutes;
  if (minutes != null) {
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '$minutes min ago';
    if (minutes < 1440) return '${minutes ~/ 60} hr ago';
    final days = minutes ~/ 1440;
    return '$days day${days == 1 ? '' : 's'} ago';
  }

  final telemetry = item.lastTelemetryTime?.toLocal();
  if (telemetry == null) return '-';
  final hour = telemetry.hour.toString().padLeft(2, '0');
  final minute = telemetry.minute.toString().padLeft(2, '0');
  return '$hour.$minute';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
