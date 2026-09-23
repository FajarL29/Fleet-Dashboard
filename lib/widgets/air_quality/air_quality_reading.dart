import 'package:latlong2/latlong.dart';

import 'air_quality_level.dart';

/// One cabin air sample from a vehicle.
///
/// Every measurement is nullable: a device may report some sensors and not
/// others, so the UI shows a dash for whatever a reading does not carry rather
/// than a number nobody measured.
class AirQualityReading {
  const AirQualityReading({
    required this.recordedAt,
    this.vehicleId,
    this.plateNumber,
    this.vin,
    this.aqi,
    this.co2Ppm,
    this.coPpm,
    this.o2Percent,
    this.temperatureCelsius,
    this.humidityPercent,
    this.position,
  });

  final DateTime recordedAt;
  final String? vehicleId;
  final String? plateNumber;
  final String? vin;

  final int? aqi;
  final double? co2Ppm;
  final double? coPpm;
  final double? o2Percent;
  final double? temperatureCelsius;
  final double? humidityPercent;

  final LatLng? position;

  AirQualityLevel? get level =>
      aqi == null ? null : AirQualityLevel.fromIndex(aqi!);
}

/// Parses one row of `/air-monitor/get-air-by-date`.
///
/// The live payload carries no coordinates today, so [position] stays null and
/// the map card explains itself instead of drawing nothing. It is read when
/// present so the map starts working the day the backend adds the columns.
AirQualityReading airQualityReadingFromJson(Map<String, dynamic> json) {
  return AirQualityReading(
    recordedAt:
        _parseDate(json['timestamp']) ??
        _parseDate(json['created_dt']) ??
        DateTime.fromMillisecondsSinceEpoch(0),
    vehicleId: _optionalString(json['vehicle_id']),
    // Without these the page's Vehicle filter matches nothing: it compares
    // the picked plate against reading.plateNumber.
    plateNumber: _optionalString(json['plate_number']),
    vin: _optionalString(json['vehicle_identification_number']),
    aqi: _toInt(json['aqi']),
    co2Ppm: _toDouble(json['co2']),
    coPpm: _toDouble(json['co']),
    o2Percent: _toDouble(json['o2']),
    temperatureCelsius: _toDouble(json['temperature']),
    humidityPercent: _toDouble(json['humidity']),
    position: _parsePosition(json),
  );
}

LatLng? _parsePosition(Map<String, dynamic> json) {
  final latitude = _toDouble(json['latitude'] ?? json['lat']);
  final longitude = _toDouble(json['longitude'] ?? json['lng'] ?? json['lon']);
  if (latitude == null || longitude == null) return null;
  return LatLng(latitude, longitude);
}

DateTime? _parseDate(dynamic value) {
  if (value is String && value.trim().isNotEmpty) {
    return DateTime.tryParse(value)?.toLocal();
  }
  return null;
}

String? _optionalString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _toDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// How far back the trend chart looks.
