import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportExecutiveRiskSummaryCard extends StatelessWidget {
  const ReportExecutiveRiskSummaryCard({
    super.key,
    required this.riskSummary,
  });

  final ReportRiskSummary riskSummary;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForRisk(riskSummary.riskLevel);
    final visibleActions = riskSummary.recommendedActions.take(2).toList();
    final visibleFlags = riskSummary.flags.take(2).toList();

    return ReportCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 860;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isNarrow)
                _NarrowHeader(
                  riskSummary: riskSummary,
                  accent: palette.accent,
                )
              else
                _WideHeader(
                  riskSummary: riskSummary,
                  accent: palette.accent,
                ),
              const SizedBox(height: 12),
              if (visibleFlags.isNotEmpty)
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
              if (visibleFlags.isNotEmpty) const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1180;
                  final insightWidth = isWide
                      ? (constraints.maxWidth - 24) / 3
                      : constraints.maxWidth >= 820
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth;

                  return Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      SizedBox(
                        width: insightWidth,
                        child: _InsightBlock(
                          title: 'Peak Risk Day',
                          value: _primaryValue(riskSummary),
                          subtitle: _primarySubtitle(riskSummary),
                          accent: palette.accent,
                          icon: Icons.calendar_month_rounded,
                        ),
                      ),
                      SizedBox(
                        width: insightWidth,
                        child: _InsightBlock(
                          title: 'Main Contributor',
                          value: _contributorValue(riskSummary),
                          subtitle: _contributorSubtitle(riskSummary),
                          accent: ReportStyles.orange,
                          icon: Icons.person_outline_rounded,
                        ),
                      ),
                      SizedBox(
                        width: insightWidth,
                        child: _InsightBlock(
                          title: 'Review Backlog',
                          value: _backlogValue(riskSummary),
                          subtitle: _backlogSubtitle(riskSummary),
                          accent: ReportStyles.blue,
                          icon: Icons.assignment_late_outlined,
                        ),
                      ),
                    ],
                  );
                },
              ),
              if (!riskSummary.isNoData && visibleActions.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
                  decoration: BoxDecoration(
                    color: ReportStyles.surfaceBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: ReportStyles.border),
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final actionWidth = constraints.maxWidth >= 900
                          ? (constraints.maxWidth - 10) / 2
                          : constraints.maxWidth;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Action Required',
                            style: TextStyle(
                              color: ReportStyles.textPrimary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: visibleActions
                                .map(
                                  (action) => SizedBox(
                                    width: actionWidth,
                                    child: _RecommendedActionTile(action: action),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NarrowHeader extends StatelessWidget {
  const _NarrowHeader({
    required this.riskSummary,
    required this.accent,
  });

  final ReportRiskSummary riskSummary;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
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
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _summaryText(riskSummary),
          style: const TextStyle(
            color: ReportStyles.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 12),
        _RiskScorePill(
          score: riskSummary.riskScore,
          accent: accent,
        ),
      ],
    );
  }
}

class _WideHeader extends StatelessWidget {
  const _WideHeader({
    required this.riskSummary,
    required this.accent,
  });

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
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _summaryText(riskSummary),
                style: const TextStyle(
                  color: ReportStyles.textSecondary,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _RiskScorePill(
          score: riskSummary.riskScore,
          accent: accent,
        ),
      ],
    );
  }
}

class _RiskBadge extends StatelessWidget {
  const _RiskBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.34)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _RiskScorePill extends StatelessWidget {
  const _RiskScorePill({
    required this.score,
    required this.accent,
  });

  final int score;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(14),
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
          const SizedBox(height: 5),
          Text(
            '$score/100',
            style: TextStyle(
              color: accent,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1,
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
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: accent, size: 16),
          ),
          const SizedBox(width: 10),
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
                const SizedBox(height: 4),
                FittedBox(
                  alignment: Alignment.centerLeft,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      color: ReportStyles.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 10,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendedActionTile extends StatelessWidget {
  const _RecommendedActionTile({
    required this.action,
  });

  final ReportRecommendedAction action;

  @override
  Widget build(BuildContext context) {
    final accent = _paletteForRisk(_prioritySeverity(action.priority)).accent;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: accent.withOpacity(0.14),
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            action.priority.isEmpty ? '!' : action.priority[0].toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RichText(
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
            ],
          ),
        ),
      ],
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
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
    return summary.replaceAll(', ', ' · ');
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
  return '${_formatInteger(contributor.totalEvents)} events · ${_formatPercent(contributor.percentage)}';
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
