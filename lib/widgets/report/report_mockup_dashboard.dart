import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_driver_option.dart';
import '../../models/drowsiness_report.dart';
import 'report_skeleton_loading.dart';
import 'report_styles.dart';

class ReportMockupDashboard extends StatelessWidget {
  const ReportMockupDashboard({
    super.key,
    required this.report,
    required this.events,
    required this.selectedDriver,
    required this.dateRangeLabel,
    this.isRefreshing = false,
  });

  final DrowsinessReport report;
  final List<DrowsinessEvent> events;
  final DrowsinessDriverOption? selectedDriver;
  final String dateRangeLabel;
  final bool isRefreshing;

  @override
  Widget build(BuildContext context) {
    final weeklyData = _WeeklyDataset.from(report.weekdayBehaviorSummary);
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

    final dashboard = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ResponsiveGrid(
          minItemWidth: 220,
          spacing: 12,
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
              accent: ReportStyles.blue,
              secondaryAccent: ReportStyles.redSoft,
              icon: Icons.assignment_outlined,
            ),
            _MetricCard(
              title: 'Unreviewed Events',
              value: _formatCount(backlogCount),
              subtitle: backlogCount > 0
                  ? '${_formatPercent(backlogRate)} Backlog'
                  : 'No review backlog',
              accent: ReportStyles.purple,
              secondaryAccent: ReportStyles.purple,
              icon: Icons.feed_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ResponsiveColumns(
          spacing: 12,
          leftFlex: 55,
          rightFlex: 45,
          left: _WeeklyBehaviorCard(
            dataset: weeklyData,
            selectedDriver: selectedDriver,
          ),
          right: _DriverContributionCard(
            contributors: contributors,
            isDriverFiltered: isDriverFiltered,
          ),
        ),
        const SizedBox(height: 12),
        _ResponsiveColumns(
          spacing: 12,
          leftFlex: 45,
          rightFlex: 55,
          left: _TrendBehaviorCard(dataset: weeklyData),
          right: _HourlyHeatmapCard(
            report: report,
            events: events,
            dateRangeLabel: dateRangeLabel,
          ),
        ),
      ],
    );

    if (!isRefreshing) {
      return dashboard;
    }

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: true,
          child: AnimatedOpacity(
            opacity: 0.62,
            duration: const Duration(milliseconds: 180),
            child: dashboard,
          ),
        ),
        const IgnorePointer(child: ReportDashboardSkeleton(overlay: true)),
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
        final columns = constraints.maxWidth >= 1200
            ? 4
            : math.max(
                1,
                math.min(
                  children.length,
                  ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                      .floor(),
                ),
              );
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

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
        if (constraints.maxWidth < 1100) {
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

class _ReportPanel extends StatelessWidget {
  const _ReportPanel({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: SizedBox(height: height, child: child),
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

    return _ReportPanel(
      height: 126,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardEyebrow('Risk Score'),
          const SizedBox(height: 4),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final gaugeWidth = constraints.maxWidth.clamp(220.0, 280.0);
                final gaugeHeight = constraints.maxHeight.clamp(84.0, 94.0);

                return Center(
                  child: SizedBox(
                    width: gaugeWidth,
                    height: gaugeHeight,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _GaugePainter(
                              progress: score.clamp(0, 100) / 100,
                              color: color,
                            ),
                          ),
                        ),
                        Positioned(
                          top: gaugeHeight * 0.42,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$score',
                                      style: const TextStyle(
                                        color: ReportStyles.textPrimary,
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '/100',
                                      style: TextStyle(
                                        color: ReportStyles.textSecondary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _displayRiskLevel(riskLevel).toUpperCase(),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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

    return _ReportPanel(
      height: 126,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _CardEyebrow('Risk Level'),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(Icons.gpp_bad_outlined, color: color, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  _displayRiskLevel(riskLevel),
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
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
    required this.secondaryAccent,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color accent;
  final Color secondaryAccent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      height: 126,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CardEyebrow(title),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.12),
                  border: Border.all(color: accent.withValues(alpha: 0.18)),
                ),
                child: Icon(icon, color: accent, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        color: ReportStyles.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: secondaryAccent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
        ],
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
    return _ReportPanel(
      height: 255,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Weekly Behavior Trend',
                style: TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
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
          const Row(
            children: [
              _LegendDot(color: ReportStyles.redSoft, label: 'Drowsiness'),
              SizedBox(width: 16),
              _LegendDot(color: Color(0xFFB8BEC8), label: 'Other Behavior'),
            ],
          ),
          const SizedBox(height: 12),
          if (dataset.rows.isEmpty)
            const Expanded(
              child: _CardEmptyState('No weekly behavior data available'),
            )
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    _ChartYAxis(maxTotal: dataset.maxTotal),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          const Positioned.fill(child: _ChartGridLines()),
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: dataset.rows
                                    .map(
                                      (row) => Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 5,
                                          ),
                                          child: _WeekdayStackBar(
                                            label: row.shortLabel,
                                            drowsiness: row.drowsiness
                                                .toDouble(),
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
    return _ReportPanel(
      height: 255,
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
          const SizedBox(height: 14),
          Expanded(
            child: contributors.isEmpty
                ? _CardEmptyState(
                    isDriverFiltered
                        ? 'No contributor data available for selected driver.'
                        : 'No contributor data available',
                  )
                : Column(
                    children: contributors.take(3).toList().asMap().entries.map(
                      (entry) {
                        final index = entry.key;
                        final contributor = entry.value;
                        return Padding(
                          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 14),
                          child: _ContributorRow(
                            rank: index + 1,
                            contributor: contributor,
                          ),
                        );
                      },
                    ).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TrendBehaviorCard extends StatelessWidget {
  const _TrendBehaviorCard({required this.dataset});

  final _WeeklyDataset dataset;

  @override
  Widget build(BuildContext context) {
    return _ReportPanel(
      height: 255,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trend & Perilaku',
            style: TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            children: [
              _LegendBar(color: ReportStyles.blue, label: 'Total Events'),
              SizedBox(width: 20),
              _LegendLine(
                color: Color(0xFF28E2C3),
                label: '7-Day Moving Average',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: dataset.rows.isEmpty
                ? const _CardEmptyState('No weekly trend data available')
                : CustomPaint(
                    painter: _TrendPainter(rows: dataset.rows),
                    child: const SizedBox.expand(),
                  ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: dataset.rows
                .map(
                  (row) => Text(
                    row.shortLabel,
                    style: const TextStyle(
                      color: ReportStyles.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
                .toList(),
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

    return _ReportPanel(
      height: 255,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Drowsiness Events by Hour - Heatmap',
                  style: TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _heatmapDateLabel(dateRangeLabel),
                style: const TextStyle(
                  color: ReportStyles.textMuted,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'jam berapa aja sih dia ngantuk',
            style: TextStyle(color: ReportStyles.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: maxValue == 0
                ? const _CardEmptyState('No hourly heatmap data available')
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 42, bottom: 6),
                        child: Row(
                          children: List.generate(24, (hour) {
                            return Expanded(
                              child: Center(
                                child: Text(
                                  hour.toString().padLeft(2, '0'),
                                  style: const TextStyle(
                                    color: ReportStyles.textMuted,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }),
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
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: List.generate(24, (hour) {
                                          return Expanded(
                                            child: Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 1.5,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: _heatColor(
                                                  matrix[row][hour],
                                                  maxValue,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(3),
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

class _LegendBar extends StatelessWidget {
  const _LegendBar({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
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
    const chartColumnHeight = 136.0;
    final fullHeight = ((total / safeMax) * chartColumnHeight)
        .clamp(8, chartColumnHeight)
        .toDouble();
    final drowsinessHeight = total <= 0
        ? 0.0
        : fullHeight * (drowsiness / total);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          _formatCount(total.round()),
          style: const TextStyle(
            color: ReportStyles.textPrimary,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: chartColumnHeight,
          alignment: Alignment.bottomCenter,
          child: Container(
            width: 34,
            height: fullHeight,
            decoration: BoxDecoration(
              color: const Color(0xFFB8BEC8),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: drowsinessHeight.clamp(0.0, fullHeight).toDouble(),
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: ReportStyles.redSoft,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(8),
                    top: Radius.circular(6),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
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
            _DriverAvatar(name: contributor.label, color: rankColor),
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
                    '${_formatCount(contributor.totalEvents)} events',
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
              style: TextStyle(
                color: rankColor,
                fontSize: 14,
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
            minHeight: 8,
            backgroundColor: ReportStyles.surfaceBackgroundSoft,
            valueColor: AlwaysStoppedAnimation<Color>(rankColor),
          ),
        ),
      ],
    );
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.name, required this.color});

  final String name;
  final Color color;

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
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.55)],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
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
    final strokeWidth = 16.0;
    final gaugeHeight = size.height * 1.7;
    final rect = Rect.fromLTWH(
      strokeWidth,
      strokeWidth * 0.95,
      size.width - (strokeWidth * 2),
      gaugeHeight - (strokeWidth * 2),
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
        colors: [const Color(0xFFFF7A1A), color],
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
            Color(0xFF3547A8),
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
    final chartHeight = size.height - 22;
    final chartWidth = size.width;
    final barWidth = rows.isEmpty ? 0.0 : chartWidth / (rows.length * 1.4);
    final dx = rows.length == 1 ? 0.0 : chartWidth / (rows.length - 1);

    final gridPaint = Paint()
      ..color = ReportStyles.border.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (var i = 1; i <= 4; i++) {
      final y = chartHeight * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    final linePoints = <Offset>[];
    final barPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF5A87FF), Color(0xFF2E4FAE)],
      ).createShader(Rect.fromLTWH(0, 0, chartWidth, chartHeight));

    final labelPainter = TextPainter(textDirection: ui.TextDirection.ltr);

    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final x = rows.length == 1 ? chartWidth / 2 : dx * i;
      final barHeight = ((row.total / safeMax) * (chartHeight - 24))
          .clamp(6, chartHeight - 24)
          .toDouble();
      final left = x - (barWidth / 2);
      final top = chartHeight - barHeight;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, barWidth, barHeight),
        const Radius.circular(8),
      );
      canvas.drawRRect(rect, barPaint);

      final lineY =
          chartHeight - (((row.total * 0.62) / safeMax) * chartHeight);
      linePoints.add(Offset(x, lineY));

      labelPainter.text = TextSpan(
        text: _formatCount(row.total),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(x - (labelPainter.width / 2), top - 18),
      );
    }

    final linePaint = Paint()
      ..color = const Color(0xFF28E2C3)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pointPaint = Paint()..color = const Color(0xFF28E2C3);

    final path = Path()..moveTo(linePoints.first.dx, linePoints.first.dy);
    for (var i = 1; i < linePoints.length; i++) {
      final previous = linePoints[i - 1];
      final current = linePoints[i];
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

    canvas.drawPath(path, linePaint);
    for (final point in linePoints) {
      canvas.drawCircle(point, 4, pointPaint);
    }
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

  factory _WeeklyDataset.from(List<WeekdayBehaviorSummary> summaries) {
    final normalized =
        summaries
            .where((entry) => entry.weekdayIndex > 0 && entry.weekdayIndex <= 7)
            .toList()
          ..sort((a, b) => a.weekdayIndex.compareTo(b.weekdayIndex));

    final rows = normalized
        .map(
          (entry) => _WeeklyRow(
            shortLabel: _shortWeekday(entry.weekday),
            total: entry.totalEvents,
            drowsiness: entry.behaviors.drowsiness,
            others: math.max(0, entry.totalEvents - entry.behaviors.drowsiness),
          ),
        )
        .toList();

    final peakDay = normalized.isEmpty
        ? null
        : normalized.reduce(
            (best, current) =>
                current.totalEvents > best.totalEvents ? current : best,
          );
    final topContributor = peakDay == null || peakDay.topDrivers.isEmpty
        ? null
        : peakDay.topDrivers.reduce(
            (best, current) =>
                current.totalEvents > best.totalEvents ? current : best,
          );

    return _WeeklyDataset(
      rows: rows,
      maxTotal: rows.fold<int>(0, (best, row) => math.max(best, row.total)),
      topContributorLabel: topContributor == null
          ? ''
          : _driverLabel(topContributor),
    );
  }
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
  final matrix = List.generate(7, (_) => List.filled(24, 0));

  if (events.isNotEmpty) {
    for (final event in events) {
      final row = event.time.weekday - 1;
      if (row >= 0 && row < 7) {
        matrix[row][event.time.hour] = matrix[row][event.time.hour] + 1;
      }
    }
    return matrix;
  }

  for (final hour in report.eventsByHour) {
    final eventHour = hour.hour.clamp(0, 23);
    for (var row = 0; row < matrix.length; row++) {
      matrix[row][eventHour] = hour.totalEvents;
    }
  }

  return matrix;
}

Color _heatColor(int value, int maxValue) {
  if (maxValue <= 0 || value <= 0) {
    return ReportStyles.surfaceBackgroundSoft;
  }

  final ratio = value / maxValue;
  if (ratio >= 0.8) return const Color(0xFFF97316);
  if (ratio >= 0.6) return const Color(0xFFEF4444);
  if (ratio >= 0.4) return const Color(0xFF7C3AED);
  if (ratio >= 0.2) return const Color(0xFF3547A8);
  return const Color(0xFF31203A);
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

String _shortWeekday(String weekday) {
  if (weekday.trim().isEmpty) {
    return '-';
  }
  return weekday.trim().substring(0, math.min(3, weekday.trim().length));
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
  'Sat',
  'Sun',
];
