import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import 'reports_risk_gauge.dart';

/// Total events / overall risk score / high-critical events.
class ReportsKpiRow extends StatelessWidget {
  const ReportsKpiRow({
    super.key,
    required this.totalEvents,
    required this.riskScore,
    required this.highRiskEvents,
    required this.isWide,
    this.totalTrend,
    this.highRiskTrend,
  });

  /// Null renders a dash: the report has not loaded, or carries no figure.
  final int? totalEvents;
  final int? riskScore;
  final int? highRiskEvents;

  /// Percentage change against the previous period. Null hides the badge —
  /// the API returns no historical comparison yet.
  final double? totalTrend;
  final double? highRiskTrend;

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _CountCard(
        title: 'Total Drowsiness Events',
        value: totalEvents,
        trend: totalTrend,
      ),
      _GaugeCard(score: riskScore),
      _CountCard(
        title: 'High / Critical Event',
        value: highRiskEvents,
        trend: highRiskTrend,
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
}

/// Shared by all three cards, so the row stays visually consistent.
const TextStyle _cardTitleStyle = TextStyle(
  color: AppColors.textPrimary,
  fontSize: 15,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

class _CountCard extends StatelessWidget {
  const _CountCard({required this.title, required this.value, this.trend});

  /// Padding and the big figure: the two knobs that set how tall a count
  /// card wants to be. It only wins over the gauge if it grows past it.
  static const EdgeInsets _padding = EdgeInsets.fromLTRB(20, 14, 20, 14);
  static const double _valueSize = 26;

  final String title;
  final int? value;
  final double? trend;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _cardTitleStyle,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                value?.toString() ?? '-',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: _valueSize,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(width: 10),
              const Flexible(
                child: Text(
                  'Total\nEvents',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          if (trend != null) ...[
            const SizedBox(height: 16),
            _TrendBadge(percent: trend!),
          ],
        ],
      ),
    );
  }
}

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Overall Risk Score', style: _cardTitleStyle),
          const SizedBox(height: 4),
          Center(child: ReportsRiskGauge(score: score)),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.percent});

  final double percent;

  @override
  Widget build(BuildContext context) {
    // Fewer events is an improvement, so a drop reads green.
    final falling = percent <= 0;
    final color = falling ? AppColors.greenText : AppColors.redText;

    return Row(
      children: [
        Text(
          '${percent.abs().toStringAsFixed(1)}%',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: falling ? AppColors.greenSoft : AppColors.redSoft,
            shape: BoxShape.circle,
          ),
          child: Icon(
            falling ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 13,
            color: color,
          ),
        ),
      ],
    );
  }
}
