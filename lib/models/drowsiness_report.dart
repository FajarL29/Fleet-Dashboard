import 'package:intl/intl.dart';

import 'api_helpers.dart';

class DrowsinessReport {
  const DrowsinessReport({
    required this.summary,
    required this.reviewSummary,
    required this.eventsByDay,
    required this.eventsByHour,
  });

  final DrowsinessReportSummary summary;
  final DrowsinessReviewSummary reviewSummary;
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
      reviewSummary: DrowsinessReviewSummary.fromJson(
        data['review_summary'] as Map<String, dynamic>? ?? const {},
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

class DrowsinessReviewSummary {
  const DrowsinessReviewSummary({
    required this.totalEvents,
    required this.newEvents,
    required this.confirmed,
    required this.falseAlarm,
    required this.followUpRequired,
    required this.followedUp,
    required this.reviewedTotal,
    required this.reviewCompletionRate,
    required this.falseAlarmRate,
    required this.closureRate,
  });

  final int totalEvents;
  final int newEvents;
  final int confirmed;
  final int falseAlarm;
  final int followUpRequired;
  final int followedUp;
  final int reviewedTotal;
  final double reviewCompletionRate;
  final double falseAlarmRate;
  final double closureRate;

  factory DrowsinessReviewSummary.fromJson(Map<String, dynamic> json) {
    return DrowsinessReviewSummary(
      totalEvents: _toInt(json['total_events']),
      newEvents: _toInt(json['new']),
      confirmed: _toInt(json['confirmed']),
      falseAlarm: _toInt(json['false_alarm']),
      followUpRequired: _toInt(json['follow_up_required']),
      followedUp: _toInt(json['followed_up']),
      reviewedTotal: _toInt(json['reviewed_total']),
      reviewCompletionRate: _toDouble(json['review_completion_rate']) ?? 0,
      falseAlarmRate: _toDouble(json['false_alarm_rate']) ?? 0,
      closureRate: _toDouble(json['closure_rate']) ?? 0,
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
    this.reviewStatus = 'new',
    this.reviewNote,
    this.reviewedBy,
    this.reviewedAt,
    this.followUpNote,
    this.followedUpAt,
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
  final String reviewStatus;
  final String? reviewNote;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? followUpNote;
  final DateTime? followedUpAt;

  String get driverLabel => userId > 0 ? 'User #$userId' : 'Unknown';
  bool get hasSpeedContext => speedAtEvent != null;
  bool get isReviewed => reviewStatus != 'new';
  bool get isConfirmed => reviewStatus == 'confirmed';
  bool get isFalseAlarm => reviewStatus == 'false_alarm';
  bool get isFollowUpRequired => reviewStatus == 'follow_up_required';
  bool get isFollowedUp => reviewStatus == 'followed_up';
  String? get formattedSpeed =>
      speedAtEvent == null ? null : '${speedAtEvent!.toStringAsFixed(0)} km/h';
  String? get formattedTelemetryTime =>
      telemetryTimestamp == null
          ? null
          : telemetryTimestamp!.toLocal().toIso8601String();
  String? get formattedReviewedAt => _formatDisplayDate(reviewedAt);
  String? get formattedFollowedUpAt => _formatDisplayDate(followedUpAt);

  DrowsinessEvent copyWith({
    int? id,
    String? vehicleId,
    int? userId,
    DateTime? time,
    String? status,
    String? riskLevel,
    String? behaviorType,
    String? imageUrl,
    String? previewBase64,
    String? location,
    double? latitude,
    double? longitude,
    double? speedAtEvent,
    DateTime? telemetryTimestamp,
    int? tripId,
    int? telemetryStatusId,
    String? speedSource,
    String? reviewStatus,
    String? reviewNote,
    bool clearReviewNote = false,
    String? reviewedBy,
    bool clearReviewedBy = false,
    DateTime? reviewedAt,
    bool clearReviewedAt = false,
    String? followUpNote,
    bool clearFollowUpNote = false,
    DateTime? followedUpAt,
    bool clearFollowedUpAt = false,
  }) {
    return DrowsinessEvent(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      userId: userId ?? this.userId,
      time: time ?? this.time,
      status: status ?? this.status,
      riskLevel: riskLevel ?? this.riskLevel,
      behaviorType: behaviorType ?? this.behaviorType,
      imageUrl: imageUrl ?? this.imageUrl,
      previewBase64: previewBase64 ?? this.previewBase64,
      location: location ?? this.location,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speedAtEvent: speedAtEvent ?? this.speedAtEvent,
      telemetryTimestamp: telemetryTimestamp ?? this.telemetryTimestamp,
      tripId: tripId ?? this.tripId,
      telemetryStatusId: telemetryStatusId ?? this.telemetryStatusId,
      speedSource: speedSource ?? this.speedSource,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewNote: clearReviewNote ? null : (reviewNote ?? this.reviewNote),
      reviewedBy: clearReviewedBy ? null : (reviewedBy ?? this.reviewedBy),
      reviewedAt: clearReviewedAt ? null : (reviewedAt ?? this.reviewedAt),
      followUpNote: clearFollowUpNote
          ? null
          : (followUpNote ?? this.followUpNote),
      followedUpAt: clearFollowedUpAt
          ? null
          : (followedUpAt ?? this.followedUpAt),
    );
  }

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
      reviewStatus: _reviewStatus(json['review_status']),
      reviewNote: _optionalString(json['review_note']),
      reviewedBy: _optionalString(json['reviewed_by']),
      reviewedAt: _parseDate(json['reviewed_at']),
      followUpNote: _optionalString(json['follow_up_note']),
      followedUpAt: _parseDate(json['followed_up_at']),
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

String _reviewStatus(dynamic value) {
  final normalized = value?.toString().trim().toLowerCase();
  if (normalized == null || normalized.isEmpty) {
    return 'new';
  }
  return normalized;
}

String? _formatDisplayDate(DateTime? value) {
  if (value == null) {
    return null;
  }

  return DateFormat('MMM d, yyyy hh:mm:ss a').format(value);
}
