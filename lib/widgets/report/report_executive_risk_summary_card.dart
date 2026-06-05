import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportExecutiveRiskSummaryCard extends StatelessWidget {
  const ReportExecutiveRiskSummaryCard({super.key, required this.riskSummary});

  final ReportRiskSummary riskSummary;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForRisk(riskSummary.riskLevel);
    final visibleActions = riskSummary.recommendedActions.take(2).toList();
    final visibleFlags = riskSummary.flags.take(2).toList();

    return ReportCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 900;
          final insightWidth = constraints.maxWidth >= 1200
              ? (constraints.maxWidth - 20) / 3
              : constraints.maxWidth >= 820
              ? (constraints.maxWidth - 10) / 2
              : constraints.maxWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow)
                _NarrowHeader(riskSummary: riskSummary, accent: palette.accent)
              else
                _WideHeader(riskSummary: riskSummary, accent: palette.accent),
              if (visibleFlags.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: visibleFlags
                      .map(
                        (flag) => _FlagChip(
                          label: flag.label,
                          color: _paletteForRisk(flag.severity).accent,
                        ),
                      )
                      .toList(),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  SizedBox(
                    width: insightWidth,
                    child: _InsightBlock(
                      title: 'Peak Risk Day',
                      value: _primaryValue(riskSummary),
                      subtitle: _primarySubtitle(riskSummary),
                      accent: palette.accent,
                      icon: Icons.calendar_today_rounded,
                      sparklineColor: palette.accent,
                      sparklineValues: const [
                        0.10,
                        0.22,
                        0.48,
                        0.40,
                        0.72,
                        0.58,
                        0.70,
                        0.66,
                      ],
                    ),
                  ),
                  SizedBox(
                    width: insightWidth,
                    child: _InsightBlock(
                      title: 'Main Contributor',
                      value: _contributorValue(riskSummary),
                      subtitle: _contributorSubtitle(riskSummary),
                      accent: ReportStyles.orange,
                      icon: Icons.person_rounded,
                      sparklineColor: ReportStyles.orange,
                      sparklineValues: const [
                        0.08,
                        0.12,
                        0.18,
                        0.30,
                        0.55,
                        0.42,
                        0.60,
                        0.50,
                      ],
                    ),
                  ),
                  SizedBox(
                    width: insightWidth,
                    child: _InsightBlock(
                      title: 'Review Backlog',
                      value: _backlogValue(riskSummary),
                      subtitle: _backlogSubtitle(riskSummary),
                      accent: ReportStyles.blue,
                      icon: Icons.event_note_rounded,
                      sparklineColor: ReportStyles.blue,
                      sparklineValues: const [
                        0.06,
                        0.10,
                        0.14,
                        0.34,
                        0.28,
                        0.50,
                        0.42,
                        0.56,
                      ],
                    ),
                  ),
                ],
              ),
              if (!riskSummary.isNoData && visibleActions.isNotEmpty) ...[
                const SizedBox(height: 8),
                _ActionStrip(actions: visibleActions),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NarrowHeader extends StatelessWidget {
  const _NarrowHeader({required this.riskSummary, required this.accent});

  final ReportRiskSummary riskSummary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _RiskBadge(label: _badgeLabel(riskSummary.riskLevel), color: accent),
        const SizedBox(height: 10),
        Text(
          riskSummary.headline,
          style: const TextStyle(
            color: ReportStyles.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _summaryText(riskSummary),
          style: const TextStyle(
            color: ReportStyles.textSecondary,
            fontSize: 11.5,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 10),
        _RiskScorePill(
          score: riskSummary.riskScore,
          riskLevel: riskSummary.riskLevel,
          accent: accent,
        ),
      ],
    );
  }
}

class _WideHeader extends StatelessWidget {
  const _WideHeader({required this.riskSummary, required this.accent});

  final ReportRiskSummary riskSummary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RiskBadge(
                label: _badgeLabel(riskSummary.riskLevel),
                color: accent,
              ),
              const SizedBox(height: 10),
              Text(
                riskSummary.headline,
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _summaryText(riskSummary),
                style: const TextStyle(
                  color: ReportStyles.textSecondary,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),
        _RiskScorePill(
          score: riskSummary.riskScore,
          riskLevel: riskSummary.riskLevel,
          accent: accent,
        ),
      ],
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 15),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskScorePill extends StatelessWidget {
  const _RiskScorePill({
    required this.score,
    required this.riskLevel,
    required this.accent,
  });

  final int score;
  final String riskLevel;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 154,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Risk Score',
            style: TextStyle(
              color: ReportStyles.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$score/100',
            style: TextStyle(
              color: accent,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _badgeLabel(riskLevel).replaceAll(' RISK', '').toLowerCase(),
            style: TextStyle(
              color: accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightBlock extends StatelessWidget {
  const _InsightBlock({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.sparklineColor,
    required this.sparklineValues,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final Color sparklineColor;
  final List<double> sparklineValues;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.18)),
            ),
            child: Icon(icon, color: accent, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ReportStyles.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 9.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 92,
            height: 40,
            child: _Sparkline(color: sparklineColor, values: sparklineValues),
          ),
        ],
      ),
    );
  }
}

class _ActionStrip extends StatelessWidget {
  const _ActionStrip({required this.actions});

  final List<ReportRecommendedAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackgroundSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ReportStyles.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return Wrap(
            children: [
              Container(
                width: isWide ? 176 : constraints.maxWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    right: isWide
                        ? BorderSide(color: ReportStyles.border)
                        : BorderSide.none,
                    bottom: !isWide
                        ? BorderSide(color: ReportStyles.border)
                        : BorderSide.none,
                  ),
                ),
                child: const Text(
                  'Action Required',
                  style: TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              ...actions.map(
                (action) => SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 176) / actions.length
                      : constraints.maxWidth,
                  child: _RecommendedActionTile(action: action),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _RecommendedActionTile extends StatelessWidget {
  const _RecommendedActionTile({required this.action});

  final ReportRecommendedAction action;

  @override
  Widget build(BuildContext context) {
    final accent = _paletteForRisk(_prioritySeverity(action.priority)).accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: ReportStyles.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              action.priority.isEmpty ? '!' : action.priority[0].toUpperCase(),
              style: TextStyle(
                color: accent,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                text: '${_priorityLabel(action.priority)}: ',
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                children: [
                  TextSpan(
                    text: action.title,
                    style: const TextStyle(
                      color: ReportStyles.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: ReportStyles.textSecondary,
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.color, required this.values});

  final Color color;
  final List<double> values;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(color: color, values: values),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  const _SparklinePainter({required this.color, required this.values});

  final Color color;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.30), color.withValues(alpha: 0.02)],
      ).createShader(Offset.zero & size);

    final linePath = Path();
    final fillPath = Path();

    for (var i = 0; i < values.length; i++) {
      final x = size.width * (i / (values.length - 1));
      final y = size.height - (size.height * values[i].clamp(0.0, 1.0));

      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.values != values;
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _RiskPalette {
  const _RiskPalette(this.accent);

  final Color accent;
}

_RiskPalette _paletteForRisk(String riskLevel) {
  switch (riskLevel.trim().toLowerCase()) {
    case 'critical':
      return const _RiskPalette(ReportStyles.red);
    case 'high':
      return const _RiskPalette(ReportStyles.orange);
    case 'medium':
      return const _RiskPalette(ReportStyles.yellow);
    case 'low':
      return const _RiskPalette(ReportStyles.green);
    default:
      return const _RiskPalette(ReportStyles.blue);
  }
}

String _prioritySeverity(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'immediate':
      return 'critical';
    case 'high':
      return 'high';
    case 'medium':
      return 'medium';
    default:
      return 'low';
  }
}

String _badgeLabel(String riskLevel) {
  switch (riskLevel.trim().toLowerCase()) {
    case 'critical':
      return 'CRITICAL RISK';
    case 'high':
      return 'HIGH RISK';
    case 'medium':
      return 'MEDIUM RISK';
    case 'low':
      return 'LOW RISK';
    default:
      return 'NO DATA';
  }
}

String _summaryText(ReportRiskSummary riskSummary) {
  final summary = riskSummary.shortSummary.trim();
  if (summary.isNotEmpty) {
    return summary.replaceAll(', ', ' • ');
  }
  return 'No drowsiness events were detected for the selected period.';
}

String _primaryValue(ReportRiskSummary riskSummary) {
  if (riskSummary.primaryFinding.value.trim().isNotEmpty) {
    return riskSummary.primaryFinding.value.trim();
  }
  return 'No data';
}

String _primarySubtitle(ReportRiskSummary riskSummary) {
  final description = riskSummary.primaryFinding.description.trim();
  if (description.isNotEmpty) {
    return description;
  }
  return 'No weekday concentration insight is available.';
}

String _contributorValue(ReportRiskSummary riskSummary) {
  if (!riskSummary.mainContributor.hasData) {
    return 'No contributor data';
  }

  return _driverName(
    riskSummary.mainContributor.driverName,
    riskSummary.mainContributor.userId,
  );
}

String _contributorSubtitle(ReportRiskSummary riskSummary) {
  if (!riskSummary.mainContributor.hasData) {
    return 'No driver concentration data is available.';
  }

  final contributor = riskSummary.mainContributor;
  return '${_formatInteger(contributor.totalEvents)} events (${_formatPercent(contributor.percentage)})';
}

String _backlogValue(ReportRiskSummary riskSummary) {
  return '${_formatInteger(riskSummary.reviewBacklog.newEvents)} unreviewed';
}

String _backlogSubtitle(ReportRiskSummary riskSummary) {
  return '${_formatPercent(riskSummary.reviewBacklog.reviewCompletionRate)} reviewed';
}

String _priorityLabel(String priority) {
  switch (priority.trim().toLowerCase()) {
    case 'immediate':
      return 'Immediate';
    case 'high':
      return 'High';
    case 'medium':
      return 'Medium';
    default:
      return 'Action';
  }
}

String _formatPercent(double value) {
  final isWhole = value == value.roundToDouble();
  if (isWhole) {
    return '${value.toStringAsFixed(0)}%';
  }
  return '${value.toStringAsFixed(1)}%';
}

String _formatInteger(int value) => NumberFormat.decimalPattern().format(value);

String _driverName(String driverName, int? userId) {
  final trimmed = driverName.trim();
  if (trimmed.isNotEmpty) {
    return trimmed;
  }
  if (userId != null) {
    return 'User #$userId';
  }
  return 'Unassigned';
}
