import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import '../common/subscript_label.dart';
import 'vital_sign_reading.dart';

/// Active Drivers / Average Heart Rate / Average SpO2 cards.
class VitalSignKpiRow extends StatelessWidget {
  const VitalSignKpiRow({
    super.key,
    required this.readings,
    required this.isWide,
    this.heartRateTrend,
    this.spo2Trend,
  });

  final List<VitalSignReading> readings;
  final bool isWide;

  /// Percentage change against the previous period. Null hides the badge —
  /// there is no historical series to compute it from yet.
  final int? heartRateTrend;
  final int? spo2Trend;

  @override
  Widget build(BuildContext context) {
    final activeCount = readings.where((item) => item.isActive).length;
    final total = readings.length;

    final cards = [
      _KpiCard(
        title: 'Active Drivers',
        value: '$activeCount',
        caption: total == 0
            ? 'No drivers reporting'
            : '${((activeCount / total) * 100).round()}% of total driver',
      ),
      _KpiCard(
        title: 'Average Heart Rate',
        value: _average((item) => item.heartRate)?.toString() ?? '-',
        unit: 'BPM',
        trend: heartRateTrend,
      ),
      _KpiCard(
        title: 'Average SpO',
        titleSubscript: '2',
        value: _formatPercent(_average((item) => item.spo2)),
        trend: spo2Trend,
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
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }

  int? _average(int? Function(VitalSignReading) selector) {
    final values = readings.map(selector).whereType<int>().toList();
    if (values.isEmpty) return null;
    return (values.reduce((a, b) => a + b) / values.length).round();
  }

  static String _formatPercent(int? value) => value == null ? '-' : '$value%';
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    this.titleSubscript,
    this.unit,
    this.caption,
    this.trend,
  });

  final String title;
  final String? titleSubscript;
  final String value;
  final String? unit;
  final String? caption;
  final int? trend;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (titleSubscript == null)
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle,
            )
          else
            SubscriptLabel(
              text: title,
              subscript: titleSubscript!,
              style: _titleStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -0.8,
                  ),
                ),
              ),
              if (unit != null) ...[
                const SizedBox(width: 5),
                Text(
                  unit!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
              if (trend != null) ...[
                const SizedBox(width: 12),
                _TrendBadge(percent: trend!),
              ],
            ],
          ),
          if (caption != null) ...[
            const SizedBox(height: 7),
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 9,
                height: 1.2,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

const _titleStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 18,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    final rising = percent >= 0;
    final color = rising ? AppColors.greenText : AppColors.redText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: rising ? AppColors.greenSoft : AppColors.redSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            rising ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            '${percent.abs()}%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
