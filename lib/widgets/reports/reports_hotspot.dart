import 'package:latlong2/latlong.dart';

import '../../models/drowsiness_report.dart';

/// A place where drowsiness events cluster.
class ReportsHotspot {
  const ReportsHotspot({
    required this.position,
    required this.eventCount,
    required this.highRiskCount,
    required this.label,
  });

  final LatLng position;
  final int eventCount;
  final int highRiskCount;

  /// Human-readable place when the event carried one, else the coordinates.
  final String label;
}

/// Groups located events into hotspots by rounding their coordinates.
///
/// [precision] is decimal places: 2 is roughly a kilometre, which keeps a city
/// trip from collapsing into a single blob or exploding into one dot per ping.
List<ReportsHotspot> buildReportsHotspots(
  List<DrowsinessEvent> events, {
  int precision = 2,
}) {
  final buckets = <String, List<DrowsinessEvent>>{};

  for (final event in events) {
    final latitude = event.latitude;
    final longitude = event.longitude;
    if (latitude == null || longitude == null) continue;

    final key =
        '${latitude.toStringAsFixed(precision)},'
        '${longitude.toStringAsFixed(precision)}';
    buckets.putIfAbsent(key, () => []).add(event);
  }

  final hotspots = buckets.values.map((grouped) {
    final latitude =
        grouped.map((event) => event.latitude!).reduce((a, b) => a + b) /
        grouped.length;
    final longitude =
        grouped.map((event) => event.longitude!).reduce((a, b) => a + b) /
        grouped.length;

    final named = grouped
        .map((event) => event.location?.trim() ?? '')
        .where((location) => location.isNotEmpty);

    return ReportsHotspot(
      position: LatLng(latitude, longitude),
      eventCount: grouped.length,
      highRiskCount: grouped
          .where((event) => event.riskLevel.toLowerCase() == 'high')
          .length,
      label: named.isNotEmpty
          ? named.first
          : '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}',
    );
  }).toList();

  hotspots.sort((a, b) => b.eventCount.compareTo(a.eventCount));
  return hotspots;
}
