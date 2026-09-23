import 'package:flutter/material.dart';

import '../../models/driver_health.dart';
import 'overview_metric_group.dart';
import 'overview_metric_tile.dart';

/// "Driver Vital Sign" card: drivers monitored, average heart rate, average
/// SpO2.
class OverviewVitalSignCard extends StatelessWidget {
  const OverviewVitalSignCard({super.key, required this.driversHealth});

  final List<DriverHealth> driversHealth;

  @override
  Widget build(BuildContext context) {
    return OverviewMetricGroup(
      title: 'Driver Vital Sign',
      tiles: [
        OverviewMetricTileData(
          value: '${driversHealth.length}',
          label: 'Drivers Monitored',
        ),
        OverviewMetricTileData(
          value: _averageHeartRate()?.toString() ?? '-',
          unit: 'BPM',
          label: 'Average Heart Rate',
        ),
        OverviewMetricTileData(
          value: _formatPercent(_averageSpo2()),
          label: 'Average SpO',
          labelSubscript: '2',
        ),
      ],
    );
  }

  /// Null when no driver is reporting a usable reading, so the tile can show
  /// a dash rather than a made-up number.
  int? _averageHeartRate() =>
      _average(driversHealth.map((driver) => driver.heartRate));

  int? _averageSpo2() => _average(driversHealth.map((driver) => driver.spo2));

  static String _formatPercent(int? value) => value == null ? '-' : '$value%';

  static int? _average(Iterable<int?> values) {
    final usable = values.whereType<int>().where((value) => value > 0).toList();
    if (usable.isEmpty) return null;
    return (usable.reduce((a, b) => a + b) / usable.length).round();
  }
}
