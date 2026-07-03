import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_driver_option.dart';
import '../../models/drowsiness_report.dart';
import 'report_map_card.dart';
import 'report_styles.dart';

class ReportExecutiveDashboard extends StatelessWidget {
  const ReportExecutiveDashboard({
    super.key,
    required this.report,
    required this.events,
    required this.selectedDriver,
    required this.dateRangeLabel,
  });

  final DrowsinessReport report;
  final List<DrowsinessEvent> events;
  final DrowsinessDriverOption? selectedDriver;
  final String dateRangeLabel;

  @override
  Widget build(BuildContext context) {
    final weeklyData = _WeeklyDataset.fromEvents(
      events,
      selectedDriver: selectedDriver,
    );
    final totalEvents = _resolveTotalEvents(report);
    final isDriverFiltered = selectedDriver?.isAllDrivers == false;
    final contributors = _contributorsForScope(
      summaries: report.weekdayBehaviorSummary,
      selectedDriver: selectedDriver,
      totalEvents: totalEvents,
    );
    final highSeverityEvents = report.summary.highRiskEvents;
    final highSeverityRate = totalEvents == 0
        ? 0.0
        : (highSeverityEvents / totalEvents) * 100;
    final backlogCount = report.reviewSummary.newEvents > 0
        ? report.reviewSummary.newEvents
        : report.riskSummary.reviewBacklog.newEvents;
    final backlogRate = totalEvents == 0
        ? 0.0
        : (backlogCount / totalEvents) * 100;
    if (kDebugMode) {
      debugPrint(
        '[Report] Executive dashboard render userId=${selectedDriver?.userId ?? 'all'} '
        'totalEvents=$totalEvents weeklyRows=${weeklyData.rows.length} '
        'contributors=${contributors.length} eventSamples=${events.length}',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          minItemWidth: 210,
          spacing: 14,
          children: [
            _RiskScoreCard(
              score: report.riskSummary.riskScore,
              riskLevel: report.riskSummary.riskLevel,
            ),
            _RiskLevelCard(riskLevel: report.riskSummary.riskLevel),
            _MetricCard(
              title: 'Total Events',
              value: _formatCount(totalEvents),
              subtitle: highSeverityEvents > 0
                  ? '${_formatPercent(highSeverityRate)} High Severity'
                  : 'No high severity events',
              accent: ReportStyles.redSoft,
              icon: Icons.warning_amber_rounded,
            ),
            _MetricCard(
              title: 'Unreviewed Events',
              value: _formatCount(backlogCount),
              subtitle: backlogCount > 0
                  ? '${_formatPercent(backlogRate)} Backlog'
                  : 'No review backlog',
              accent: ReportStyles.blue,
              icon: Icons.inventory_2_outlined,
            ),
          ],
        ),
        const SizedBox(height: 14),
        _ResponsiveColumns(
          spacing: 14,
          leftFlex: 55,
          rightFlex: 45,
          left: ReportMapCard(events: events),
          right: _DriverContributionCard(
            contributors: contributors,
            isDriverFiltered: isDriverFiltered,
          ),
        ),
        const SizedBox(height: 14),
        _ResponsiveColumns(
          spacing: 14,
          leftFlex: 55,
          rightFlex: 45,
          left: _WeeklyBehaviorCard(
            dataset: weeklyData,
            selectedDriver: selectedDriver,
          ),
          right: _HourlyHeatmapCard(
            report: report,
            events: events,
            dateRangeLabel: dateRangeLabel,
          ),
        ),
      ],
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.minItemWidth,
    required this.spacing,
    required this.children,
  });

  final double minItemWidth;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final forcedDesktopColumns = constraints.maxWidth >= 1200 ? 4 : null;
        final columns = math.max(
          1,
          math.min(
            children.length,
            forcedDesktopColumns ??
                ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                    .floor(),
          ),
        );
        final availableWidth =
            (constraints.maxWidth - (spacing * (columns - 1))).clamp(
              0.0,
              double.infinity,
            );
        final itemWidth = (availableWidth / columns).toDouble();

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _ResponsiveColumns extends StatelessWidget {
  const _ResponsiveColumns({
    required this.spacing,
    required this.leftFlex,
    required this.rightFlex,
    required this.left,
    required this.right,
  });

  final double spacing;
  final int leftFlex;
  final int rightFlex;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1080) {
          return Column(
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: spacing),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }
}

class _RiskScoreCard extends StatelessWidget {
  const _RiskScoreCard({required this.score, required this.riskLevel});

  final int score;
  final String riskLevel;

  @override
  Widget build(BuildContext context) {
    final color = _riskAccent(riskLevel);

    return ReportCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: SizedBox(
        height: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardEyebrow('Risk Score'),
            const SizedBox(height: 8),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CustomPaint(
                      painter: _GaugePainter(
                        progress: score.clamp(0, 100) / 100,
                        color: color,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$score/100',
                        style: const TextStyle(
                          color: ReportStyles.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _displayRiskLevel(riskLevel).toUpperCase(),
                        style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskLevelCard extends StatelessWidget {
  const _RiskLevelCard({required this.riskLevel});

  final String riskLevel;

  @override
  Widget build(BuildContext context) {
    final color = _riskAccent(riskLevel);

    return ReportCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: SizedBox(
        height: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _CardEyebrow('Risk Level'),
            const Spacer(),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(color: color.withValues(alpha: 0.24)),
                  ),
                  child: Icon(Icons.shield_outlined, color: color, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    _displayRiskLevel(riskLevel),
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: color.withValues(alpha: 0.18)),
                ),
                child: Text(
                  'Fleet risk posture',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.95),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
    return ReportCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: SizedBox(
        height: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardEyebrow(title),
            const SizedBox(height: 10),
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBehaviorCard extends StatelessWidget {
  const _WeeklyBehaviorCard({
    required this.dataset,
    required this.selectedDriver,
  });

  final _WeeklyDataset dataset;
  final DrowsinessDriverOption? selectedDriver;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Behavior Trend',
                      style: TextStyle(
                        color: ReportStyles.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Working days - 07:00-18:00',
                      style: TextStyle(
                        color: ReportStyles.textMuted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (dataset.topContributorLabel.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: ReportStyles.border.withValues(alpha: 0.8),
                    ),
                  ),
                  child: Text(
                    'Top Contributor: ${selectedDriver?.isAllDrivers == false ? selectedDriver!.driverName : dataset.topContributorLabel}',
                    style: const TextStyle(
                      color: ReportStyles.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 252,
            child: Column(
              children: [
                const Row(
                  children: [
                    _LegendDot(
                      color: ReportStyles.redSoft,
                      label: 'Drowsiness',
                    ),
                    SizedBox(width: 16),
                    _LegendDot(
                      color: Color(0xFFB8BEC8),
                      label: 'Other Behavior',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Row(
                    children: [
                      _ChartYAxis(maxTotal: dataset.maxTotal),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Stack(
                          children: [
                            const Positioned.fill(child: _ChartGridLines()),
                            Positioned.fill(
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: dataset.rows
                                    .map(
                                      (row) => Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                          ),
                                          child: _WeekdayStackBar(
                                            label: row.shortLabel,
                                            drowsiness: row.drowsiness.toDouble(),
                                            others: row.others.toDouble(),
                                            maxTotal: dataset.maxTotal
                                                .toDouble(),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _DriverContributionCard extends StatelessWidget {
  const _DriverContributionCard({
    required this.contributors,
    required this.isDriverFiltered,
  });

  final List<_ContributorEntry> contributors;
  final bool isDriverFiltered;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DRIVERS WITH HIGHEST RISK CONTRIBUTION',
            style: TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          if (contributors.isEmpty)
            _CardEmptyState(
              isDriverFiltered
                  ? 'No contributor data available for selected driver.'
                  : 'No contributor data available',
            )
          else
            Column(
              children: contributors.take(3).toList().asMap().entries.map((
                entry,
              ) {
                final index = entry.key;
                final contributor = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
                  child: _ContributorRow(
                    rank: index + 1,
                    contributor: contributor,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _HourlyHeatmapCard extends StatelessWidget {
  const _HourlyHeatmapCard({
    required this.report,
    required this.events,
    required this.dateRangeLabel,
  });

  final DrowsinessReport report;
  final List<DrowsinessEvent> events;
  final String dateRangeLabel;

  @override
  Widget build(BuildContext context) {
    final matrix = _buildHeatmap(report, events);
    final maxValue = matrix.expand((row) => row).fold<int>(0, math.max);

    return ReportCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Drowsiness Events by Hour - Heatmap',
                      style: TextStyle(
                        color: ReportStyles.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Working-hour drowsiness exposure',
                      style: TextStyle(
                        color: ReportStyles.textSecondary,
                        fontSize: 11.5,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Working days only - 07:00-18:00',
                      style: TextStyle(
                        color: ReportStyles.textMuted,
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _heatmapDateLabel(dateRangeLabel),
                style: const TextStyle(
                  color: ReportStyles.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 252,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 42, bottom: 6),
                  child: Row(
                    children: _workingHours
                        .map(
                          (hour) => Expanded(
                            child: Center(
                              child: Text(
                                hour.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  color: ReportStyles.textMuted,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: _weekdayLabels
                            .map(
                              (label) => Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    label,
                                    style: const TextStyle(
                                      color: ReportStyles.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          children: List.generate(matrix.length, (row) {
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 3),
                                child: Row(
                                  children: List.generate(_workingHours.length, (
                                    hour,
                                  ) {
                                    return Expanded(
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _heatColor(
                                            matrix[row][hour],
                                            maxValue,
                                          ),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (maxValue == 0)
                  const Text(
                    'No working-hour events in this period',
                    style: TextStyle(
                      color: ReportStyles.textMuted,
                      fontSize: 10.5,
                    ),
                  ),
                if (maxValue == 0) const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Low',
                      style: TextStyle(
                        color: ReportStyles.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 12),
                    _HeatLegendBar(),
                    SizedBox(width: 12),
                    Text(
                      'High',
                      style: TextStyle(
                        color: ReportStyles.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CardEyebrow extends StatelessWidget {
  const _CardEyebrow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: ReportStyles.textMuted,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _CardEmptyState extends StatelessWidget {
  const _CardEmptyState(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: ReportStyles.textSecondary,
          fontSize: 11.5,
          height: 1.4,
        ),
      ),
    );
  }
}

class _WeekdayStackBar extends StatelessWidget {
  const _WeekdayStackBar({
    required this.label,
    required this.drowsiness,
    required this.others,
    required this.maxTotal,
  });

  final String label;
  final double drowsiness;
  final double others;
  final double maxTotal;

  @override
  Widget build(BuildContext context) {
    final total = drowsiness + others;
    final safeMax = maxTotal <= 0 ? 1.0 : maxTotal;
    final fullHeight = total <= 0
        ? 0.0
        : ((total / safeMax) * 150).clamp(8, 150).toDouble();
    final drowsinessHeight = total <= 0
        ? 0.0
        : fullHeight * (drowsiness / total);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _formatCount(total.round()),
          style: const TextStyle(
            color: ReportStyles.textSecondary,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 150,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 34,
            height: fullHeight,
            decoration: BoxDecoration(
              color: const Color(0xFF55606F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: drowsinessHeight.clamp(0.0, fullHeight).toDouble(),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: ReportStyles.redSoft,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(10),
                    top: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: ReportStyles.textMuted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: ReportStyles.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ChartYAxis extends StatelessWidget {
  const _ChartYAxis({required this.maxTotal});

  final int maxTotal;

  @override
  Widget build(BuildContext context) {
    final safeMax = maxTotal <= 0 ? 4 : maxTotal;
    final values = List.generate(5, (index) {
      final step = (safeMax / 4) * (4 - index);
      return step.round();
    });

    return SizedBox(
      width: 34,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: values
            .map(
              (value) => Text(
                _formatCount(value),
                style: const TextStyle(
                  color: ReportStyles.textMuted,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _ChartGridLines extends StatelessWidget {
  const _ChartGridLines();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(
        5,
        (index) => Container(
          height: 1,
          color: ReportStyles.border.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: ReportStyles.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ContributorRow extends StatelessWidget {
  const _ContributorRow({required this.rank, required this.contributor});

  final int rank;
  final _ContributorEntry contributor;

  @override
  Widget build(BuildContext context) {
    final percentage = contributor.percentage;
    final rankColor = switch (rank) {
      1 => ReportStyles.redSoft,
      2 => ReportStyles.orange,
      _ => ReportStyles.yellow,
    };

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: rankColor.withValues(alpha: 0.16),
                border: Border.all(color: rankColor.withValues(alpha: 0.45)),
              ),
              alignment: Alignment.center,
              child: Text(
                '#$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            _DriverAvatar(name: contributor.label),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contributor.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ReportStyles.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_formatCount(contributor.totalEvents)} event${contributor.totalEvents == 1 ? '' : 's'} (${_formatPercent(percentage)})',
                    style: const TextStyle(
                      color: ReportStyles.textSecondary,
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatPercent(percentage),
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: ReportStyles.surfaceBackgroundSoft,
            valueColor: AlwaysStoppedAnimation<Color>(rankColor),
          ),
        ),
      ],
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().isEmpty
        ? '?'
        : name
              .trim()
              .split(RegExp(r'\s+'))
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ReportStyles.surfaceBackgroundSoft,
        border: Border.all(
          color: ReportStyles.borderStrong.withValues(alpha: 0.7),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: ReportStyles.textPrimary,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 12.0;
    final rect = Rect.fromLTWH(
      strokeWidth,
      strokeWidth,
      size.width - (strokeWidth * 2),
      size.height - (strokeWidth * 2),
    );
    final startAngle = math.pi;
    const sweepAngle = math.pi;
    final basePaint = Paint()
      ..color = ReportStyles.surfaceBackgroundSoft
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;
    final valuePaint = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.7), color],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(rect, startAngle, sweepAngle, false, basePaint);
    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle * progress.clamp(0.0, 1.0),
      false,
      valuePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

class _HeatLegendBar extends StatelessWidget {
  const _HeatLegendBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 10,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF31203A),
            Color(0xFF4B1A1A),
            Color(0xFFB91C1C),
            Color(0xFFFFC64D),
          ],
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({required this.rows});

  final List<_WeeklyRow> rows;

  @override
  void paint(Canvas canvas, Size size) {
    if (rows.isEmpty) {
      return;
    }

    final maxTotal = rows.fold<int>(
      0,
      (best, row) => math.max(best, row.total),
    );
    final safeMax = maxTotal <= 0 ? 1 : maxTotal;
    final chartHeight = size.height - 24;
    final chartWidth = size.width;
    final dx = rows.length == 1 ? 0.0 : chartWidth / (rows.length - 1);

    final gridPaint = Paint()
      ..color = ReportStyles.border.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final drowsinessPoints = <Offset>[];
    final othersPoints = <Offset>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final x = rows.length == 1 ? chartWidth / 2 : dx * i;
      final drowsinessY =
          chartHeight - ((row.drowsiness / safeMax) * chartHeight);
      final othersY = chartHeight - ((row.others / safeMax) * chartHeight);
      drowsinessPoints.add(Offset(x, drowsinessY));
      othersPoints.add(Offset(x, othersY));
    }

    final areaPath = Path()..moveTo(drowsinessPoints.first.dx, chartHeight);
    for (final point in drowsinessPoints) {
      areaPath.lineTo(point.dx, point.dy);
    }
    areaPath.lineTo(drowsinessPoints.last.dx, chartHeight);
    areaPath.close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          ReportStyles.redSoft.withValues(alpha: 0.32),
          ReportStyles.redSoft.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight))
      ..style = PaintingStyle.fill;

    final drowsinessPaint = Paint()
      ..color = ReportStyles.redSoft
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final othersPaint = Paint()
      ..color = ReportStyles.blue.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(areaPath, areaPaint);
    canvas.drawPath(_smoothPath(drowsinessPoints), drowsinessPaint);
    canvas.drawPath(_smoothPath(othersPoints), othersPaint);

    final pointPaint = Paint()..color = ReportStyles.redSoft;
    for (final point in drowsinessPoints) {
      canvas.drawCircle(point, 4, pointPaint);
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    return path;
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.rows != rows;
}

class _WeeklyDataset {
  const _WeeklyDataset({
    required this.rows,
    required this.maxTotal,
    required this.topContributorLabel,
  });

  final List<_WeeklyRow> rows;
  final int maxTotal;
  final String topContributorLabel;

  factory _WeeklyDataset.fromEvents(
    List<DrowsinessEvent> events, {
    required DrowsinessDriverOption? selectedDriver,
  }) {
    final buckets = List.generate(
      _weekdayLabels.length,
      (index) => _WorkingWeekBucket(shortLabel: _weekdayLabels[index]),
    );
    final contributorCounts = <int, int>{};

    for (final event in events) {
      if (!_isWorkingScopeEvent(event.time)) {
        continue;
      }

      final row = event.time.weekday - 1;
      final bucket = buckets[row];
      final isDrowsinessEvent = _isDrowsinessBehavior(event);
      bucket.total += 1;
      if (isDrowsinessEvent) {
        bucket.drowsiness += 1;
      }

      if (event.userId > 0) {
        contributorCounts[event.userId] =
            (contributorCounts[event.userId] ?? 0) + 1;
      }
    }

    final rows = buckets
        .map(
          (bucket) => _WeeklyRow(
            shortLabel: bucket.shortLabel,
            total: bucket.total,
            drowsiness: bucket.drowsiness,
            others: math.max(0, bucket.total - bucket.drowsiness),
          ),
        )
        .toList();

    return _WeeklyDataset(
      rows: rows,
      maxTotal: rows.fold<int>(0, (best, row) => math.max(best, row.total)),
      topContributorLabel: _weeklyTopContributorLabel(
        contributorCounts,
        selectedDriver: selectedDriver,
      ),
    );
  }
}

class _WorkingWeekBucket {
  _WorkingWeekBucket({required this.shortLabel});

  final String shortLabel;
  int total = 0;
  int drowsiness = 0;
}

class _WeeklyRow {
  const _WeeklyRow({
    required this.shortLabel,
    required this.total,
    required this.drowsiness,
    required this.others,
  });

  final String shortLabel;
  final int total;
  final int drowsiness;
  final int others;
}

class _ContributorEntry {
  const _ContributorEntry({
    required this.userId,
    required this.label,
    required this.totalEvents,
    required this.percentage,
  });

  final int? userId;
  final String label;
  final int totalEvents;
  final double percentage;
}

List<_ContributorEntry> _contributorsForScope({
  required List<WeekdayBehaviorSummary> summaries,
  required DrowsinessDriverOption? selectedDriver,
  required int totalEvents,
}) {
  if (selectedDriver?.isAllDrivers == false) {
    if (totalEvents <= 0) {
      return const [];
    }

    return [
      _ContributorEntry(
        userId: selectedDriver!.userId,
        label: selectedDriver.driverName,
        totalEvents: totalEvents,
        percentage: 100,
      ),
    ];
  }

  return _aggregateContributors(summaries);
}

List<_ContributorEntry> _aggregateContributors(
  List<WeekdayBehaviorSummary> summaries,
) {
  final totals = <String, _ContributorEntry>{};
  var grandTotal = 0;

  for (final summary in summaries) {
    for (final driver in summary.topDrivers) {
      final key = driver.userId?.toString() ?? driver.driverName;
      final existing = totals[key];
      final label = _driverLabel(driver);
      final nextTotal = (existing?.totalEvents ?? 0) + driver.totalEvents;
      totals[key] = _ContributorEntry(
        userId: driver.userId,
        label: label,
        totalEvents: nextTotal,
        percentage: 0,
      );
      grandTotal += driver.totalEvents;
    }
  }

  if (totals.isEmpty) {
    return const [];
  }

  final normalized =
      totals.values
          .map(
            (entry) => _ContributorEntry(
              userId: entry.userId,
              label: entry.label,
              totalEvents: entry.totalEvents,
              percentage: grandTotal == 0
                  ? 0
                  : (entry.totalEvents / grandTotal) * 100,
            ),
          )
          .toList()
        ..sort((a, b) => b.totalEvents.compareTo(a.totalEvents));

  return normalized;
}

int _resolveTotalEvents(DrowsinessReport report) {
  if (report.summary.totalEvents > 0) {
    return report.summary.totalEvents;
  }
  if (report.reviewSummary.totalEvents > 0) {
    return report.reviewSummary.totalEvents;
  }
  return report.eventsByDay.fold<int>(0, (sum, item) => sum + item.totalEvents);
}

List<List<int>> _buildHeatmap(
  DrowsinessReport report,
  List<DrowsinessEvent> events,
) {
  final matrix = List.generate(
    _weekdayLabels.length,
    (_) => List.filled(_workingHours.length, 0),
  );

  if (events.isNotEmpty) {
    for (final event in events) {
      final row = event.time.weekday - 1;
      final hour = event.time.hour;
      if (row >= 0 &&
          row < _weekdayLabels.length &&
          hour >= _workingHours.first &&
          hour <= _workingHours.last) {
        matrix[row][hour - _workingHours.first] =
            matrix[row][hour - _workingHours.first] + 1;
      }
    }
    return matrix;
  }

  for (final hour in report.eventsByHour) {
    final eventHour = hour.hour;
    if (eventHour < _workingHours.first || eventHour > _workingHours.last) {
      continue;
    }
    for (var row = 0; row < matrix.length; row++) {
      matrix[row][eventHour - _workingHours.first] = hour.totalEvents;
    }
  }

  return matrix;
}

Color _heatColor(int value, int maxValue) {
  if (maxValue <= 0 || value <= 0) {
    return ReportStyles.surfaceBackgroundSoft;
  }

  final ratio = value / maxValue;
  if (ratio >= 0.8) return const Color(0xFFEF4444);
  if (ratio >= 0.6) return const Color(0xFFDC2626);
  if (ratio >= 0.4) return const Color(0xFFB91C1C);
  if (ratio >= 0.2) return const Color(0xFF7F1D1D);
  return const Color(0xFF4B1A1A);
}

Color _riskAccent(String riskLevel) {
  switch (riskLevel.toLowerCase()) {
    case 'critical':
    case 'critical_risk':
      return const Color(0xFFFF5A5F);
    case 'high':
    case 'high_risk':
      return ReportStyles.redSoft;
    case 'medium':
    case 'medium_risk':
      return ReportStyles.yellow;
    case 'low':
    case 'low_risk':
      return ReportStyles.green;
    default:
      return ReportStyles.blue;
  }
}

String _displayRiskLevel(String riskLevel) {
  switch (riskLevel.toLowerCase()) {
    case 'critical':
    case 'critical_risk':
      return 'Critical Risk';
    case 'high':
    case 'high_risk':
      return 'High Risk';
    case 'medium':
    case 'medium_risk':
      return 'Medium Risk';
    case 'low':
    case 'low_risk':
      return 'Low Risk';
    default:
      return 'No Data';
  }
}

String _weeklyTopContributorLabel(
  Map<int, int> contributorCounts, {
  required DrowsinessDriverOption? selectedDriver,
}) {
  if (selectedDriver?.isAllDrivers == false) {
    return selectedDriver!.driverName;
  }
  if (contributorCounts.isEmpty) {
    return '';
  }

  final topContributor = contributorCounts.entries.reduce(
    (best, current) => current.value > best.value ? current : best,
  );
  return 'User #${topContributor.key}';
}

bool _isWorkingScopeEvent(DateTime time) {
  final weekdayIndex = time.weekday - 1;
  return weekdayIndex >= 0 &&
      weekdayIndex < _weekdayLabels.length &&
      time.hour >= _workingHours.first &&
      time.hour <= _workingHours.last;
}

bool _isDrowsinessBehavior(DrowsinessEvent event) {
  final behavior = event.behaviorType?.trim().toLowerCase();
  if (behavior != null && behavior.contains('drows')) {
    return true;
  }

  final status = event.status.trim().toLowerCase();
  return status.contains('drows');
}

String _driverLabel(DriverContributor contributor) {
  final name = contributor.driverName.trim();
  if (name.isNotEmpty) {
    return name;
  }
  if (contributor.userId != null) {
    return 'User #${contributor.userId}';
  }
  return 'Unknown';
}

String _formatCount(int value) => NumberFormat.decimalPattern().format(value);

String _formatPercent(double value) {
  if (value == value.roundToDouble()) {
    return '${value.toStringAsFixed(0)}%';
  }
  return '${value.toStringAsFixed(1)}%';
}

String _heatmapDateLabel(String label) {
  final parts = label.split(' - ');
  if (parts.length != 2) {
    return label;
  }

  try {
    final formatter = DateFormat('MMM d, yyyy');
    final start = formatter.parse(parts[0]);
    final end = formatter.parse(parts[1]);
    final shortFormatter = DateFormat('MMM d');
    return '${shortFormatter.format(start)} - ${shortFormatter.format(end)}';
  } catch (_) {
    return label;
  }
}

const List<String> _weekdayLabels = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
];

const List<int> _workingHours = [7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18];
