class VitalSignReading {
  const VitalSignReading({
    this.healthReportId,
    this.userId,
    this.vehicleId,
    this.deviceId,
    this.time,
    this.heartRate,
    this.spo2,
    this.bodyTemperature,
    this.systolicBp,
    this.diastolicBp,
    this.respiratoryRate,
  });

  final int? healthReportId;
  final int? userId;
  final String? vehicleId;
  final String? deviceId;
  final DateTime? time;
  final double? heartRate;
  final double? spo2;
  final double? bodyTemperature;
  final double? systolicBp;
  final double? diastolicBp;
  final double? respiratoryRate;

  factory VitalSignReading.fromJson(Map<String, dynamic> json) {
    return VitalSignReading(
      healthReportId: _toInt(json['health_report_id']),
      userId: _toInt(json['user_id']),
      vehicleId: _toString(json['vehicle_id']),
      deviceId: _toString(json['device_id']),
      time: _toDateTime(json['time']),
      heartRate: _toDouble(json['heart_rate']),
      spo2: _toDouble(json['spo2']),
      bodyTemperature: _toDouble(json['body_temperature']),
      systolicBp: _toDouble(json['systolic_bp']),
      diastolicBp: _toDouble(json['diastolic_bp']),
      respiratoryRate: _toDouble(json['respiratory_rate']),
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
