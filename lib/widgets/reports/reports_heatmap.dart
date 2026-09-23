import '../../models/drowsiness_report.dart';

/// Events counted per weekday and hour, ready to draw as a grid.
class ReportsHeatmapData {
  const ReportsHeatmapData({
    required this.weekdays,
    required this.hours,
    required this.counts,
    required this.busiest,
  });

  static const ReportsHeatmapData empty = ReportsHeatmapData(
    weekdays: [],
    hours: [],
    counts: {},
    busiest: 0,
  );

  /// Rows, as `DateTime.monday`..`DateTime.sunday` values.
  final List<int> weekdays;

  /// Columns, in ascending hour-of-day order.
  final List<int> hours;

  /// Event count keyed by `weekday * 100 + hour`; a missing key means zero.
  final Map<int, int> counts;

  /// Highest count in the grid, which sets the top of the colour scale.
  final int busiest;

  bool get isEmpty => weekdays.isEmpty || hours.isEmpty;

  int countAt(int weekday, int hour) => counts[weekday * 100 + hour] ?? 0;
}

/// Buckets [events] into a weekday x hour grid.
///
/// Only hours that actually carry events become columns: a fleet that never
/// runs at 03:00 should not spend a third of the card on empty night columns.
/// Rows always cover Monday to Friday so the working week keeps its familiar
/// shape, and extend into the weekend only when there are weekend events —
/// dropping those rows outright would hide real detections.
ReportsHeatmapData buildReportsHeatmap(List<DrowsinessEvent> events) {
  if (events.isEmpty) return ReportsHeatmapData.empty;

  final counts = <int, int>{};
  final hours = <int>{};
  final weekdays = <int>{
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
  };

  var busiest = 0;

  for (final event in events) {
    final at = event.time.toLocal();
    final key = at.weekday * 100 + at.hour;
    final next = (counts[key] ?? 0) + 1;

    counts[key] = next;
    hours.add(at.hour);
    weekdays.add(at.weekday);
    if (next > busiest) busiest = next;
  }

  return ReportsHeatmapData(
    weekdays: weekdays.toList()..sort(),
    hours: hours.toList()..sort(),
    counts: counts,
    busiest: busiest,
  );
}
