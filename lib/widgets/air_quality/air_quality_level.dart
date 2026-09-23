import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Air Quality Index bands, using the standard AQI breakpoints.
enum AirQualityLevel {
  good,
  moderate,
  unhealthy,
  veryUnhealthy,
  hazardous;

  /// Band an index falls into. Values below zero are treated as Good.
  static AirQualityLevel fromIndex(int index) {
    if (index <= 50) return AirQualityLevel.good;
    if (index <= 100) return AirQualityLevel.moderate;
    if (index <= 150) return AirQualityLevel.unhealthy;
    if (index <= 200) return AirQualityLevel.veryUnhealthy;
    return AirQualityLevel.hazardous;
  }

  String get label {
    switch (this) {
      case AirQualityLevel.good:
        return 'Good';
      case AirQualityLevel.moderate:
        return 'Moderate';
      case AirQualityLevel.unhealthy:
        return 'Unhealthy';
      case AirQualityLevel.veryUnhealthy:
        return 'Very Unhealthy';
      case AirQualityLevel.hazardous:
        return 'Hazardous';
    }
  }

  String get range {
    switch (this) {
      case AirQualityLevel.good:
        return '0-50';
      case AirQualityLevel.moderate:
        return '51-100';
      case AirQualityLevel.unhealthy:
        return '101-150';
      case AirQualityLevel.veryUnhealthy:
        return '151-200';
      case AirQualityLevel.hazardous:
        return '201+';
    }
  }

  Color get color {
    switch (this) {
      case AirQualityLevel.good:
        return AppAqiColors.good;
      case AirQualityLevel.moderate:
        return AppAqiColors.moderate;
      case AirQualityLevel.unhealthy:
        return AppAqiColors.unhealthy;
      case AirQualityLevel.veryUnhealthy:
        return AppAqiColors.veryUnhealthy;
      case AirQualityLevel.hazardous:
        return AppAqiColors.hazardous;
    }
  }
}
