import 'package:flutter/material.dart';

import '../../models/aqi_data.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_status.dart';
import 'overview_metric_group.dart';
import 'overview_metric_tile.dart';

/// "Cabin Air Quality" card: vehicles monitored, average CO2, highest CO2.
class OverviewAirQualityCard extends StatelessWidget {
  const OverviewAirQualityCard({
    super.key,
    required this.aqiData,
    required this.vehicleStatusData,
    required this.vehicles,
  });

  final AQIData aqiData;
  final VehicleStatusData? vehicleStatusData;
  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    final monitored =
        vehicleStatusData?.summary.onlineVehicles ?? vehicles.length;

    return OverviewMetricGroup(
      title: 'Cabin Air Quality',
      tiles: [
        OverviewMetricTileData(value: '$monitored', label: 'Vehicle Monitored'),
        OverviewMetricTileData(
          value: _formatNumber(aqiData.co2),
          unit: 'PPM',
          label: 'Average CO',
          labelSubscript: '2',
        ),
        // AQIData carries a single current reading, so there is no fleet peak
        // to show until the API exposes one.
        const OverviewMetricTileData(
          value: '-',
          unit: 'PPM',
          label: 'Highest CO',
          labelSubscript: '2',
        ),
      ],
    );
  }

  /// Indonesian grouping (1120 -> 1.120), matching the design. Returns a dash
  /// when there is no reading, rather than a misleading zero.
  static String _formatNumber(double value) {
    if (value <= 0) return '-';
    final rounded = value.round();
    final digits = rounded.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    return '${rounded < 0 ? '-' : ''}$buffer';
  }
}
