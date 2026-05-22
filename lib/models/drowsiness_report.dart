import 'api_helpers.dart';

class DrowsinessReport {
  const DrowsinessReport({
    required this.summary,
    required this.eventsByDay,
    required this.eventsByHour,
  });

  final DrowsinessReportSummary summary;
  final List<DrowsinessEventsByDay> eventsByDay;
  final List<DrowsinessEventsByHour> eventsByHour;

  factory DrowsinessReport.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final days = data['events_by_day'] as List<dynamic>? ?? const [];
    final hours = data['events_by_hour'] as List<dynamic>? ?? const [];

    return DrowsinessReport(
      summary: DrowsinessReportSummary.fromJson(
        data['summary'] as Map<String, dynamic>? ?? const {},
      ),
      eventsByDay: days
          .whereType<Map<String, dynamic>>()
          .map(DrowsinessEventsByDay.fromJson)
          .toList(),
      eventsByHour: hours
          .whereType<Map<String, dynamic>>()
          .map(DrowsinessEventsByHour.fromJson)
          .toList(),
    );
  }
}

class DrowsinessReportSummary {
  const DrowsinessReportSummary({
    required this.vehicleId,
    required this.totalEvents,
    required this.highRiskEvents,
    required this.peakHour,
    this.peakDate,
  });

  final String vehicleId;
  final int totalEvents;
  final int highRiskEvents;
  final int peakHour;
  final DateTime? peakDate;

  factory DrowsinessReportSummary.fromJson(Map<String, dynamic> json) {
    return DrowsinessReportSummary(
      vehicleId: (json['vehicle_id'] ?? '').toString(),
      totalEvents: _toInt(json['total_events']),
      highRiskEvents: _toInt(json['high_risk_events']),
      peakHour: _toInt(json['peak_hour']),
      peakDate: _parseDate(json['peak_date']),
    );
  }
}



class DrowsinessEventsByDay {
  const DrowsinessEventsByDay({
    required this.date,
    required this.totalEvents,
  });

  final DateTime date;
  final int totalEvents;

  factory DrowsinessEventsByDay.fromJson(Map<String, dynamic> json) {
    return DrowsinessEventsByDay(
      date: _parseDate(json['event_date']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      totalEvents: _toInt(json['total_events']),
    );
  }
}

class DrowsinessEventsByHour {
  const DrowsinessEventsByHour({
    required this.hour,
    required this.totalEvents,
  });

  final int hour;
  final int totalEvents;

  factory DrowsinessEventsByHour.fromJson(Map<String, dynamic> json) {
    return DrowsinessEventsByHour(
      hour: _toInt(json['event_hour']),
      totalEvents: _toInt(json['total_events']),
    );
  }
}

class DrowsinessEvent {
  const DrowsinessEvent({
    required this.id,
    required this.vehicleId,
    required this.userId,
    required this.time,
    required this.status,
    required this.riskLevel,
    this.behaviorType,
    this.imageUrl,
    this.previewBase64,
    this.location,
    this.latitude,
    this.longitude,
    this.speedAtEvent,
    this.telemetryTimestamp,
    this.tripId,
    this.telemetryStatusId,
    this.speedSource,
  });

  final int id;
  final String vehicleId;
  final int userId;
  final DateTime time;
  final String status;
  final String riskLevel;
  final String? behaviorType;
  final String? imageUrl;
  final String? previewBase64;
  final String? location;
  final double? latitude;
  final double? longitude;
  final double? speedAtEvent;
  final DateTime? telemetryTimestamp;
  final int? tripId;
  final int? telemetryStatusId;
  final String? speedSource;

  String get driverLabel => userId > 0 ? 'User #$userId' : 'Unknown';
  bool get hasSpeedContext => speedAtEvent != null;
  String? get formattedSpeed =>
      speedAtEvent == null ? null : '${speedAtEvent!.toStringAsFixed(0)} km/h';
  String? get formattedTelemetryTime =>
      telemetryTimestamp == null
          ? null
          : telemetryTimestamp!.toLocal().toIso8601String();

  factory DrowsinessEvent.fromJson(Map<String, dynamic> json) {
    final locationData = json['location'];
    final locationMap = locationData is Map<String, dynamic> ? locationData : null;

    return DrowsinessEvent(
      id: _toInt(json['drowsiness_id']),
      vehicleId: (json['vehicle_identification_number'] ?? json['vehicle_id'] ?? '').toString(),
      userId: _toInt(json['user_id']),
      time: _parseDate(json['event_time'] ?? json['time']) ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: (json['status'] ?? '').toString(),
      riskLevel: (json['risk_level'] ?? '').toString(),
      behaviorType: _optionalString(json['behavior_type']),
      imageUrl: json['img_path']?.toString(),
      previewBase64: json['powerbi_preview']?.toString(),
      location: _locationName(json, locationMap),
      latitude: _toDouble(
        json['latitude'] ??
            json['lat'] ??
            locationMap?['latitude'] ??
            locationMap?['lat'],
      ),
      longitude: _toDouble(
        json['longitude'] ??
            json['lng'] ??
            json['lon'] ??
            locationMap?['longitude'] ??
            locationMap?['lng'] ??
            locationMap?['lon'],
      ),
      speedAtEvent: _toDouble(json['speed_at_event']),
      telemetryTimestamp: _parseDate(json['telemetry_timestamp']),
      tripId: _toNullableInt(json['trip_id']),
      telemetryStatusId: _toNullableInt(json['telemetry_status_id']),
      speedSource: _optionalString(json['speed_source']),
    );
  }
}

String? _locationName(
  Map<String, dynamic> json,
  Map<String, dynamic>? locationMap,
) {
  final value = json['location_name'] ??
      json['locationName'] ??
      json['area_name'] ??
      locationMap?['location_name'] ??
      locationMap?['locationName'] ??
      locationMap?['area_name'];

  if (value != null) return value.toString();
  if (json['location'] is String) return json['location'].toString();
  return null;
}

int _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

String? _optionalString(dynamic value) {
  final stringValue = value?.toString().trim();
  if (stringValue == null || stringValue.isEmpty) {
    return null;
  }
  return stringValue;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
