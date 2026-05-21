class DriverBehaviorSummary {
  const DriverBehaviorSummary({
    required this.userId,
    required this.vehicleId,
    required this.internalVehicleId,
    required this.totalEvents,
    required this.latestEventTime,
    required this.behaviors,
    required this.riskSummary,
  });

  final int? userId;
  final String? vehicleId;
  final String? internalVehicleId;
  final int totalEvents;
  final DateTime? latestEventTime;
  final DriverBehaviorCounts behaviors;
  final DriverBehaviorRiskSummary riskSummary;

  String get driverLabel =>
      userId != null ? 'User #$userId' : 'Unassigned Driver';

  int get highRiskCount => riskSummary.high;
  int get mediumRiskCount => riskSummary.medium;
  int get lowRiskCount => riskSummary.low;

  double get highRiskRatio => totalEvents <= 0 ? 0 : highRiskCount / totalEvents;

  double get riskRatioScore {
    final weighted =
        (highRiskCount * 3) + (mediumRiskCount * 2) + lowRiskCount;
    final denominator = totalEvents <= 0 ? 1 : totalEvents * 3;
    return (weighted / denominator) * 100;
  }

  int get priorityScore =>
      (highRiskCount * 3) + (mediumRiskCount * 2) + lowRiskCount;

  double get volumeFactor {
    if (totalEvents <= 0) return 0;
    final factor = totalEvents / 100;
    return factor > 1 ? 1 : factor;
  }

  double get interventionScore => riskRatioScore * volumeFactor;

  String get riskLevel {
    final score = riskRatioScore;
    if (score >= 70) return 'High';
    if (score >= 40) return 'Medium';
    return 'Low';
  }

  String get dominantBehavior {
    final entries = <MapEntry<String, int>>[
      MapEntry('Drowsiness Episode', behaviors.drowsinessEpisode),
      MapEntry('Distraction', behaviors.distraction),
      MapEntry('Yawn', behaviors.yawn),
      MapEntry('Drowsy', behaviors.drowsy),
      MapEntry('Drowsy Score On', behaviors.drowsyScoreOn),
    ];

    entries.sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty || entries.first.value <= 0) {
      return 'No dominant behavior';
    }
    return entries.first.key;
  }

  factory DriverBehaviorSummary.fromJson(Map<String, dynamic> json) {
    return DriverBehaviorSummary(
      userId: _toNullableInt(json['user_id']),
      vehicleId: _optionalString(json['vehicle_id']),
      internalVehicleId: _optionalString(json['internal_vehicle_id']),
      totalEvents: _toInt(json['total_events']),
      latestEventTime: _parseDate(json['latest_event_time']),
      behaviors: DriverBehaviorCounts.fromJson(
        json['behaviors'] as Map<String, dynamic>? ?? const {},
      ),
      riskSummary: DriverBehaviorRiskSummary.fromJson(
        json['risk_summary'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class DriverBehaviorCounts {
  const DriverBehaviorCounts({
    required this.drowsinessEpisode,
    required this.distraction,
    required this.yawn,
    required this.drowsy,
    required this.drowsyScoreOn,
  });

  final int drowsinessEpisode;
  final int distraction;
  final int yawn;
  final int drowsy;
  final int drowsyScoreOn;

  factory DriverBehaviorCounts.fromJson(Map<String, dynamic> json) {
    return DriverBehaviorCounts(
      drowsinessEpisode: _toInt(json['drowsiness_episode']),
      distraction: _toInt(json['distraction']),
      yawn: _toInt(json['yawn']),
      drowsy: _toInt(json['drowsy']),
      drowsyScoreOn: _toInt(json['drowsy_score_on']),
    );
  }
}

class DriverBehaviorRiskSummary {
  const DriverBehaviorRiskSummary({
    required this.high,
    required this.medium,
    required this.low,
  });

  final int high;
  final int medium;
  final int low;

  factory DriverBehaviorRiskSummary.fromJson(Map<String, dynamic> json) {
    return DriverBehaviorRiskSummary(
      high: _toInt(json['high']),
      medium: _toInt(json['medium']),
      low: _toInt(json['low']),
    );
  }
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
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
    return null;
  }
  return text;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
