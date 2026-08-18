class AirQualityReading {
  const AirQualityReading({
    this.airConditionId,
    this.vehicleId,
    this.deviceId,
    this.timestamp,
    this.co,
    this.co2,
    this.pm25,
    this.pm10,
    this.temperature,
    this.o2,
    this.humidity,
    this.aqi,
  });

  final int? airConditionId;
  final String? vehicleId;
  final String? deviceId;
  final DateTime? timestamp;
  final double? co;
  final double? co2;
  final double? pm25;
  final double? pm10;
  final double? temperature;
  final double? o2;
  final double? humidity;
  final double? aqi;

  factory AirQualityReading.fromJson(Map<String, dynamic> json) {
    return AirQualityReading(
      airConditionId: _toInt(json['air_condition_id']),
      vehicleId: _toString(json['vehicle_id']),
      deviceId: _toString(json['device_id']),
      timestamp: _toDateTime(json['timestamp']),
      co: _toDouble(json['co']),
      co2: _toDouble(json['co2']),
      pm25: _toDouble(json['pm25']),
      pm10: _toDouble(json['pm10']),
      temperature: _toDouble(json['temperature']),
      o2: _toDouble(json['o2']),
      humidity: _toDouble(json['humidity']),
      aqi: _toDouble(json['aqi']),
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  final text = value.toString().trim();
  return text.isEmpty ? null : double.tryParse(text);
}

String? _toString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _toDateTime(dynamic value) {
  if (value is DateTime) return value;
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}
