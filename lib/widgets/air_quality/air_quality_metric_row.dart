import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import '../common/subscript_label.dart';
import 'air_quality_reading.dart';

/// CO2 / CO / O2 / Temperature / Humidity cards for the latest reading.
class AirQualityMetricRow extends StatelessWidget {
  const AirQualityMetricRow({
    super.key,
    required this.latest,
    required this.isWide,
  });

  /// Most recent sample, or null when nothing has been reported.
  final AirQualityReading? latest;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetricCard(
        title: 'CO',
        titleSubscript: '2',
        value: _decimal(latest?.co2Ppm, unit: 'ppm', fractionDigits: 0),
        icon: Icons.co2_rounded,
      ),
      _MetricCard(
        title: 'CO',
        value: _decimal(latest?.coPpm, unit: 'ppm'),
        icon: Icons.cloud_outlined,
      ),
      _MetricCard(
        title: 'O',
        titleSubscript: '2',
        value: _decimal(latest?.o2Percent, unit: '%'),
        icon: Icons.air_rounded,
      ),
      _MetricCard(
        title: 'Temperature',
        value: _decimal(latest?.temperatureCelsius, unit: '°C'),
        icon: Icons.thermostat_rounded,
      ),
      _MetricCard(
        title: 'Humidity',
        value: _decimal(latest?.humidityPercent, unit: '%', fractionDigits: 0),
        icon: Icons.water_drop_outlined,
      ),
    ];

    if (!isWide) {
      return Column(
        children: [
          for (final card in cards) ...[card, const SizedBox(height: 12)],
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }

  /// Formats a measurement, or a dash when the sensor reported nothing.
  static String _decimal(
    double? value, {
    required String unit,
    int fractionDigits = 1,
  }) {
    if (value == null) return '-';
    return '${value.toStringAsFixed(fractionDigits)} $unit';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    this.titleSubscript,
  });

  final String title;
  final String? titleSubscript;
  final String value;
  final IconData icon;

  static const TextStyle _titleStyle = TextStyle(
    color: AppColors.textPrimary,
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: titleSubscript == null
                    ? Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _titleStyle,
                      )
                    : SubscriptLabel(
                        text: title,
                        subscript: titleSubscript!,
                        style: _titleStyle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(width: 6),
              Icon(icon, size: 18, color: AppColors.blue),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: AppColors.blue,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: -0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
