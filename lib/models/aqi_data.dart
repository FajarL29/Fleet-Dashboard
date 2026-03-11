import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AQIData {
  final int index;
  final double pm25;
  final double co2;
  final double no2;

  const AQIData({
    required this.index,
    required this.pm25,
    required this.co2,
    required this.no2,
  });

  String getQualityText() {
    if (index <= 50) return 'Good';
    if (index <= 100) return 'Moderate';
    if (index <= 150) return 'Unhealthy for Sensitive Groups';
    if (index <= 200) return 'Unhealthy';
    if (index <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  Color getQualityColor() {
    if (index <= 50) return AppTheme.success;
    if (index <= 100) return const Color(0xFFFFD700);
    if (index <= 150) return AppTheme.warning;
    if (index <= 200) return AppTheme.error;
    if (index <= 300) return const Color(0xFF8B0000);
    return const Color(0xFF7B001C);
  }

  double getProgressValue(String type) {
    switch (type) {
      case 'PM2.5':
        return pm25 / 100;
      case 'CO2':
        return co2 / 100;
      case 'NO2':
        return no2 / 100;
      default:
        return 0;
    }
  }
}