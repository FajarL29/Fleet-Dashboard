import 'package:intl/intl.dart';

class DrowsinessReport {
  const DrowsinessReport({
    required this.summary,
    required this.reviewSummary,
    required this.riskSummary,
    required this.eventsByDay,
    required this.eventsByHour,
    required this.weekdayBehaviorSummary,
  });

  final DrowsinessReportSummary summary;
  final DrowsinessReviewSummary reviewSummary;
  final ReportRiskSummary riskSummary;
  final List<DrowsinessEventsByDay> eventsByDay;
  final List<DrowsinessEventsByHour> eventsByHour;
  final List<WeekdayBehaviorSummary> weekdayBehaviorSummary;

  factory DrowsinessReport.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final days = data['events_by_day'] as List<dynamic>? ?? const [];
    final hours = data['events_by_hour'] as List<dynamic>? ?? const [];
    final weekdaySummary =
        data['weekday_behavior_summary'] as List<dynamic>? ?? const [];
    final parsedSummary = DrowsinessReportSummary.fromJson(
      data['summary'] as Map<String, dynamic>? ?? const {},
    );
    final parsedReviewSummary = DrowsinessReviewSummary.fromJson(
      data['review_summary'] as Map<String, dynamic>? ?? const {},
    );
    final parsedWeekdaySummary = weekdaySummary
        .whereType<Map<String, dynamic>>()
        .map(WeekdayBehaviorSummary.fromJson)
        .toList();

    return DrowsinessReport(
      summary: parsedSummary,
      reviewSummary: parsedReviewSummary,
      riskSummary: ReportRiskSummary.fromJson(
        data['risk_summary'] as Map<String, dynamic>? ?? const {},
        summary: parsedSummary,
        reviewSummary: parsedReviewSummary,
        weekdayBehaviorSummary: parsedWeekdaySummary,
      ),
      eventsByDay:
          days.whereType<Map<String, dynamic>>().map(DrowsinessEventsByDay.fromJson).toList(),
      eventsByHour: hours
          .whereType<Map<String, dynamic>>()
          .map(DrowsinessEventsByHour.fromJson)
          .toList(),
      weekdayBehaviorSummary: parsedWeekdaySummary,
    );
  }
}

class ReportRiskSummary {
  const ReportRiskSummary({
    required this.riskLevel,
    required this.riskScore,
    required this.headline,
    required this.shortSummary,
    required this.primaryFinding,
    required this.mainContributor,
    required this.dominantBehavior,
    required this.reviewBacklog,
    required this.recommendedActions,
    required this.flags,
  });

  final String riskLevel;
  final int riskScore;
  final String headline;
  final String shortSummary;
  final ReportPrimaryFinding primaryFinding;
  final ReportMainContributor mainContributor;
  final ReportDominantBehavior dominantBehavior;
  final ReportReviewBacklog reviewBacklog;
  final List<ReportRecommendedAction> recommendedActions;
  final List<ReportRiskFlag> flags;

  bool get isNoData => riskLevel == 'no_data';

  factory ReportRiskSummary.fromJson(
    Map<String, dynamic> json, {
    required DrowsinessReportSummary summary,
    required DrowsinessReviewSummary reviewSummary,
    required List<WeekdayBehaviorSummary> weekdayBehaviorSummary,
  }) {
    if (json.isEmpty) {
      return _fallbackRiskSummary(
        summary: summary,
        reviewSummary: reviewSummary,
        weekdayBehaviorSummary: weekdayBehaviorSummary,
      );
    }

    final actions = json['recommended_actions'] as List<dynamic>? ?? const [];
    final flags = json['flags'] as List<dynamic>? ?? const [];

    return ReportRiskSummary(
      riskLevel: _optionalString(json['risk_level']) ?? 'no_data',
      riskScore: _toInt(json['risk_score']),
      headline: _optionalString(json['headline']) ??
          _fallbackRiskSummary(
            summary: summary,
            reviewSummary: reviewSummary,
            weekdayBehaviorSummary: weekdayBehaviorSummary,
          ).headline,
      shortSummary: _optionalString(json['short_summary']) ?? '',
      primaryFinding: ReportPrimaryFinding.fromJson(
        json['primary_finding'] as Map<String, dynamic>? ?? const {},
      ),
      mainContributor: ReportMainContributor.fromJson(
        json['main_contributor'] as Map<String, dynamic>? ?? const {},
      ),
      dominantBehavior: ReportDominantBehavior.fromJson(
        json['dominant_behavior'] as Map<String, dynamic>? ?? const {},
      ),
      reviewBacklog: ReportReviewBacklog.fromJson(
        json['review_backlog'] as Map<String, dynamic>? ?? const {},
      ),
      recommendedActions: actions
          .whereType<Map<String, dynamic>>()
          .map(ReportRecommendedAction.fromJson)
          .toList(),
      flags: flags
          .whereType<Map<String, dynamic>>()
          .map(ReportRiskFlag.fromJson)
          .toList(),
    );
  }
}

class ReportPrimaryFinding {
  const ReportPrimaryFinding({
    required this.title,
    required this.value,
    required this.description,
  });

  final String title;
  final String value;
  final String description;

  factory ReportPrimaryFinding.fromJson(Map<String, dynamic> json) {
    return ReportPrimaryFinding(
      title: _optionalString(json['title']) ?? '',
      value: _optionalString(json['value']) ?? '',
      description: _optionalString(json['description']) ?? '',
    );
  }
}

class ReportMainContributor {
  const ReportMainContributor({
    required this.userId,
    required this.driverName,
    required this.totalEvents,
    required this.percentage,
    required this.description,
  });

  final int? userId;
  final String driverName;
  final int totalEvents;
  final double percentage;
  final String description;

  bool get hasData =>
      totalEvents > 0 || driverName.isNotEmpty || (userId != null && userId! > 0);

  factory ReportMainContributor.fromJson(Map<String, dynamic> json) {
    return ReportMainContributor(
      userId: _toNullableInt(json['user_id']),
      driverName: _optionalString(json['driver_name']) ?? '',
      totalEvents: _toInt(json['total_events']),
      percentage: _toDouble(json['percentage']) ?? 0,
      description: _optionalString(json['description']) ?? '',
    );
  }
}

class ReportDominantBehavior {
  const ReportDominantBehavior({
    required this.key,
    required this.label,
    required this.description,
  });

  final String key;
  final String label;
  final String description;

  factory ReportDominantBehavior.fromJson(Map<String, dynamic> json) {
    return ReportDominantBehavior(
      key: _optionalString(json['key']) ?? '',
      label: _optionalString(json['label']) ?? '',
      description: _optionalString(json['description']) ?? '',
    );
  }
}

class ReportReviewBacklog {
  const ReportReviewBacklog({
    required this.newEvents,
    required this.reviewCompletionRate,
    required this.description,
  });

  final int newEvents;
  final double reviewCompletionRate;
  final String description;

  factory ReportReviewBacklog.fromJson(Map<String, dynamic> json) {
    return ReportReviewBacklog(
      newEvents: _toInt(json['new_events']),
      reviewCompletionRate: _toDouble(json['review_completion_rate']) ?? 0,
      description: _optionalString(json['description']) ?? '',
    );
  }
}

class ReportRecommendedAction {
  const ReportRecommendedAction({
    required this.priority,
    required this.title,
    required this.description,
  });

  final String priority;
  final String title;
  final String description;

  factory ReportRecommendedAction.fromJson(Map<String, dynamic> json) {
    return ReportRecommendedAction(
      priority: _optionalString(json['priority']) ?? '',
      title: _optionalString(json['title']) ?? '',
      description: _optionalString(json['description']) ?? '',
    );
  }
}

class ReportRiskFlag {
  const ReportRiskFlag({
    required this.type,
    required this.severity,
    required this.label,
  });

  final String type;
  final String severity;
  final String label;

  factory ReportRiskFlag.fromJson(Map<String, dynamic> json) {
    return ReportRiskFlag(
      type: _optionalString(json['type']) ?? '',
      severity: _optionalString(json['severity']) ?? '',
      label: _optionalString(json['label']) ?? '',
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

class WeekdayBehaviorSummary {
  const WeekdayBehaviorSummary({
    required this.weekday,
    required this.weekdayIndex,
    required this.totalEvents,
    required this.behaviors,
    required this.dominantBehavior,
    required this.topDrivers,
  });

  final String weekday;
  final int weekdayIndex;
  final int totalEvents;
  final WeekdayBehaviorCounts behaviors;
  final String dominantBehavior;
  final List<DriverContributor> topDrivers;

  factory WeekdayBehaviorSummary.fromJson(Map<String, dynamic> json) {
    final topDrivers = json['top_drivers'] as List<dynamic>? ?? const [];

    return WeekdayBehaviorSummary(
      weekday: (json['weekday'] ?? '').toString(),
      weekdayIndex: _toInt(json['weekday_index']),
      totalEvents: _toInt(json['total_events']),
      behaviors: WeekdayBehaviorCounts.fromJson(
        json['behaviors'] as Map<String, dynamic>? ?? const {},
      ),
      dominantBehavior: (json['dominant_behavior'] ?? '').toString(),
      topDrivers: topDrivers
          .whereType<Map<String, dynamic>>()
          .map(DriverContributor.fromJson)
          .toList(),
    );
  }
}

class WeekdayBehaviorCounts {
  const WeekdayBehaviorCounts({
    required this.drowsiness,
    required this.yawn,
    required this.drowsyScoreOn,
    required this.distraction,
    required this.other,
  });

  final int drowsiness;
  final int yawn;
  final int drowsyScoreOn;
  final int distraction;
  final int other;

  int get total =>
      drowsiness + yawn + drowsyScoreOn + distraction + other;

  factory WeekdayBehaviorCounts.fromJson(Map<String, dynamic> json) {
    return WeekdayBehaviorCounts(
      drowsiness: _toInt(json['drowsiness']),
      yawn: _toInt(json['yawn']),
      drowsyScoreOn: _toInt(json['drowsy_score_on'] ?? json['drowsyScoreOn']),
      distraction: _toInt(json['distraction']),
      other: _toInt(json['other']),
    );
  }
}

class DriverContributor {
  const DriverContributor({
    required this.userId,
    required this.driverName,
    required this.totalEvents,
    required this.percentage,
  });

  final int? userId;
  final String driverName;
  final int totalEvents;
  final double percentage;

  factory DriverContributor.fromJson(Map<String, dynamic> json) {
    return DriverContributor(
      userId: _toNullableInt(json['user_id']),
      driverName: (json['driver_name'] ?? '').toString(),
      totalEvents: _toInt(json['total_events']),
      percentage: _toDouble(json['percentage']) ?? 0,
    );
  }
}

ReportRiskSummary _fallbackRiskSummary({
  required DrowsinessReportSummary summary,
  required DrowsinessReviewSummary reviewSummary,
  required List<WeekdayBehaviorSummary> weekdayBehaviorSummary,
}) {
  final totalEvents = summary.totalEvents > 0
      ? summary.totalEvents
      : reviewSummary.totalEvents;

  if (totalEvents <= 0) {
    return const ReportRiskSummary(
      riskLevel: 'no_data',
      riskScore: 0,
      headline: 'No drowsiness events detected',
      shortSummary: 'No drowsiness events were detected for the selected period.',
      primaryFinding: ReportPrimaryFinding(
        title: 'Peak risk day',
        value: '-',
        description: 'No weekday trend is available for the selected period.',
      ),
      mainContributor: ReportMainContributor(
        userId: null,
        driverName: '',
        totalEvents: 0,
        percentage: 0,
        description: 'No driver contribution data is available.',
      ),
      dominantBehavior: ReportDominantBehavior(
        key: '',
        label: 'No dominant behavior',
        description: 'No dominant behavior is available for the selected period.',
      ),
      reviewBacklog: ReportReviewBacklog(
        newEvents: 0,
        reviewCompletionRate: 0.0,
        description: 'There is no review backlog for the selected period.',
      ),
      recommendedActions: [],
      flags: [],
    );
  }

  final highSeverityRate = totalEvents == 0
      ? 0.0
      : (summary.highRiskEvents / totalEvents) * 100;
  final peakDay = weekdayBehaviorSummary.isEmpty
      ? null
      : weekdayBehaviorSummary.reduce(
          (best, current) =>
              current.totalEvents > best.totalEvents ? current : best,
        );
  final peakShare = peakDay == null || totalEvents == 0
      ? 0.0
      : (peakDay.totalEvents / totalEvents) * 100;
  final topContributor = _topContributor(peakDay);
  final dominantBehaviorKey = peakDay?.dominantBehavior.isNotEmpty == true
      ? peakDay!.dominantBehavior
      : _dominantBehaviorFromCounts(peakDay?.behaviors);
  final dominantBehaviorLabel = _riskBehaviorLabel(dominantBehaviorKey);
  final backlogRate = reviewSummary.reviewCompletionRate;

  final rawScore =
      (highSeverityRate * 0.55) + ((100 - backlogRate) * 0.25) + (peakShare * 0.2);
  final riskScore = rawScore.round().clamp(0, 100);
  final riskLevel = _riskLevelFromScore(riskScore);

  final primaryDescription = peakDay == null
      ? 'No weekday distribution is available for the selected period.'
      : '${peakDay.weekday} has the highest concentration with '
          '${_formatInteger(peakDay.totalEvents)} events, representing '
          '${_formatPercent(peakShare)} of total events.';
  final mainContributorDescription = topContributor == null
      ? 'No single driver contributor is available for the peak day.'
      : '${_driverLabel(topContributor)} is the largest contributor on '
          '${peakDay?.weekday ?? 'the peak day'}.';
  final reviewBacklogDescription = backlogRate < 1
      ? 'Review backlog is critical. Most events are still unreviewed.'
      : backlogRate < 10
          ? 'Review backlog is high and should be prioritized.'
          : 'Review completion is improving but still requires attention.';

  final actions = <ReportRecommendedAction>[
    ReportRecommendedAction(
      priority: 'immediate',
      title: 'Review high-severity backlog',
      description: 'Prioritize unreviewed high-severity drowsiness events.',
    ),
    if (topContributor != null)
      ReportRecommendedAction(
        priority: 'high',
        title: 'Investigate ${_driverLabel(topContributor)}',
        description:
            '${_driverLabel(topContributor)} contributes ${_formatPercent(topContributor.percentage)} of ${peakDay?.weekday ?? 'peak day'} events.',
      ),
    if (peakDay != null)
      ReportRecommendedAction(
        priority: 'medium',
        title: 'Evaluate ${peakDay.weekday} operation pattern',
        description:
            '${peakDay.weekday} has the highest event concentration and may require schedule or route review.',
      ),
  ];

  final flags = <ReportRiskFlag>[
    if (highSeverityRate >= 75)
      const ReportRiskFlag(
        type: 'high_severity_rate',
        severity: 'critical',
        label: 'High severity dominates total events',
      ),
    if (backlogRate <= 5)
      const ReportRiskFlag(
        type: 'review_backlog',
        severity: 'critical',
        label: 'Review completion is critically low',
      ),
    if (peakShare >= 30)
      const ReportRiskFlag(
        type: 'peak_day_concentration',
        severity: 'high',
        label: 'A single weekday dominates event concentration',
      ),
    if (topContributor != null && topContributor.percentage >= 60)
      const ReportRiskFlag(
        type: 'driver_concentration',
        severity: 'high',
        label: 'A single driver dominates the peak-day contribution',
      ),
  ];

  return ReportRiskSummary(
    riskLevel: riskLevel,
    riskScore: riskScore,
    headline: _riskHeadline(riskLevel),
    shortSummary:
        '${_formatInteger(totalEvents)} events detected, ${_formatPercent(highSeverityRate)} high severity, only ${_formatPercent(backlogRate)} reviewed.',
    primaryFinding: ReportPrimaryFinding(
      title: 'Peak risk day',
      value: peakDay?.weekday ?? '-',
      description: primaryDescription,
    ),
    mainContributor: ReportMainContributor(
      userId: topContributor?.userId,
      driverName: topContributor?.driverName ?? '',
      totalEvents: topContributor?.totalEvents ?? 0,
      percentage: topContributor?.percentage ?? 0,
      description: mainContributorDescription,
    ),
    dominantBehavior: ReportDominantBehavior(
      key: dominantBehaviorKey,
      label: dominantBehaviorLabel,
      description: peakDay == null
          ? 'No dominant behavior is available for the selected period.'
          : '$dominantBehaviorLabel is the dominant behavior on the peak risk day.',
    ),
    reviewBacklog: ReportReviewBacklog(
      newEvents: reviewSummary.newEvents,
      reviewCompletionRate: reviewSummary.reviewCompletionRate,
      description: reviewBacklogDescription,
    ),
    recommendedActions: actions,
    flags: flags,
  );
}

DriverContributor? _topContributor(WeekdayBehaviorSummary? summary) {
  if (summary == null || summary.topDrivers.isEmpty) {
    return null;
  }

  final nonZero = summary.topDrivers.where((item) => item.totalEvents > 0);
  if (nonZero.isEmpty) {
    return null;
  }

  return nonZero.reduce(
    (best, current) => current.totalEvents > best.totalEvents ? current : best,
  );
}

String _dominantBehaviorFromCounts(WeekdayBehaviorCounts? counts) {
  if (counts == null) return '';

  final map = <String, int>{
    'drowsiness': counts.drowsiness,
    'yawn': counts.yawn,
    'drowsy_score_on': counts.drowsyScoreOn,
    'distraction': counts.distraction,
    'other': counts.other,
  };

  return map.entries.reduce((best, current) {
    return current.value > best.value ? current : best;
  }).key;
}

String _riskBehaviorLabel(String value) {
  switch (value.trim().toLowerCase()) {
    case 'drowsiness':
      return 'Drowsiness';
    case 'yawn':
      return 'Yawn';
    case 'drowsy_score_on':
    case 'drowsy score on':
      return 'Drowsy Score On';
    case 'distraction':
      return 'Distraction';
    case 'other':
      return 'Other';
    default:
      return value.isEmpty ? 'Unknown' : value;
  }
}

String _riskLevelFromScore(int score) {
  if (score >= 75) return 'critical';
  if (score >= 55) return 'high';
  if (score >= 30) return 'medium';
  return 'low';
}

String _riskHeadline(String riskLevel) {
  switch (riskLevel) {
    case 'critical':
      return 'Critical drowsiness risk requires immediate action';
    case 'high':
      return 'High drowsiness risk needs operator attention';
    case 'medium':
      return 'Moderate drowsiness risk should be monitored';
    case 'low':
      return 'Drowsiness risk is currently contained';
    default:
      return 'No drowsiness events detected';
  }
}

String _formatInteger(int value) => NumberFormat.decimalPattern().format(value);

String _formatPercent(double value) {
  final isWhole = value == value.roundToDouble();
  if (isWhole) {
    return '${value.toStringAsFixed(0)}%';
  }
  return '${value.toStringAsFixed(1)}%';
}

String _driverLabel(DriverContributor contributor) {
  final name = contributor.driverName.trim();
  if (name.isNotEmpty) {
    return name;
  }
  if (contributor.userId != null) {
    return 'User #${contributor.userId}';
  }
  return 'Unassigned';
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
      telemetryTimestamp?.toLocal().toIso8601String();
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
