class DrowsinessDriverOption {
  const DrowsinessDriverOption({
    required this.userId,
    required this.driverName,
    required this.totalEvents,
    required this.highRiskEvents,
    required this.lastEventTime,
  });

  final int? userId;
  final String driverName;
  final int totalEvents;
  final int highRiskEvents;
  final DateTime? lastEventTime;

  bool get isAllDrivers => userId == null;

  factory DrowsinessDriverOption.allDrivers() {
    return const DrowsinessDriverOption(
      userId: null,
      driverName: 'All Drivers',
      totalEvents: 0,
      highRiskEvents: 0,
      lastEventTime: null,
    );
  }

  factory DrowsinessDriverOption.fromJson(Map<String, dynamic> json) {
    final userId = _toNullableInt(json['user_id']);
    if (userId == null) {
      throw const FormatException('Missing user_id');
    }

    return DrowsinessDriverOption(
      userId: userId,
      driverName: _driverName(json['driver_name'], userId),
      totalEvents: _toInt(json['total_events']),
      highRiskEvents: _toInt(json['high_risk_events']),
      lastEventTime: _parseDate(json['last_event_time']),
    );
  }
}

String _driverName(dynamic value, int userId) {
  final name = value?.toString().trim();
  if (name == null || name.isEmpty) {
    return 'User #$userId';
  }
  return name;
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

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString())?.toLocal();
}
