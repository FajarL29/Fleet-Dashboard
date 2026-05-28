import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_driver_option.dart';
import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportWeeklyBehaviorTrendSection extends StatefulWidget {
  const ReportWeeklyBehaviorTrendSection({
    super.key,
    required this.weekdaySummaries,
    this.isDriverFiltered = false,
    this.selectedDriver,
    this.reviewCompletionRate = 0,
  });

  final List<WeekdayBehaviorSummary> weekdaySummaries;
  final bool isDriverFiltered;
  final DrowsinessDriverOption? selectedDriver;
  final double reviewCompletionRate;

  @override
  State<ReportWeeklyBehaviorTrendSection> createState() =>
      _ReportWeeklyBehaviorTrendSectionState();
}

class _ReportWeeklyBehaviorTrendSectionState
    extends State<ReportWeeklyBehaviorTrendSection> {
  int? _selectedWeekdayIndex;

  @override
  void initState() {
    super.initState();
    _selectedWeekdayIndex = _defaultWeekdayIndex(widget.weekdaySummaries);
  }

  @override
  void didUpdateWidget(covariant ReportWeeklyBehaviorTrendSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    final dataChanged = !_sameWeekdayData(
      oldWidget.weekdaySummaries,
      widget.weekdaySummaries,
    );
    final driverChanged =
        oldWidget.selectedDriver?.userId != widget.selectedDriver?.userId;

    if (dataChanged || driverChanged) {
      _selectedWeekdayIndex = _defaultWeekdayIndex(widget.weekdaySummaries);
      return;
    }

    final availableIndexes = widget.weekdaySummaries
        .map((entry) => entry.weekdayIndex)
        .where((index) => index >= 1 && index <= 5)
        .toSet();

    if (_selectedWeekdayIndex == null ||
        !availableIndexes.contains(_selectedWeekdayIndex)) {
      _selectedWeekdayIndex = _defaultWeekdayIndex(widget.weekdaySummaries);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.weekdaySummaries.isEmpty) {
      return _WeeklyBehaviorEmptyState(
        message: widget.isDriverFiltered
            ? 'No weekly behavior data for selected driver in this period.'
            : 'No weekly behavior data available for selected period.',
      );
    }

    final normalized = _normalizeWeekdaySummaries(widget.weekdaySummaries);
    final selected = normalized.firstWhere(
      (entry) => entry.weekdayIndex == _selectedWeekdayIndex,
      orElse: () => normalized.first,
    );
    final peakDay = normalized.reduce(
      (best, current) => current.totalEvents > best.totalEvents ? current : best,
    );
    final topContributor = _visibleContributors(selected).isNotEmpty
        ? _visibleContributors(selected).first
        : null;

    return ReportCard(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Behavior Trend',
            style: TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.isDriverFiltered
                ? 'Driver-filtered view of weekday behavior and contribution.'
                : 'Understand behavior mix and top contributors by weekday.',
            style: const TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _InsightChip(
                label: 'Peak Day',
                value: peakDay.weekdayLabel,
                color: ReportStyles.blue,
              ),
              _InsightChip(
                label: 'Dominant',
                value: _behaviorLabel(selected.dominantBehavior),
                color: ReportStyles.orange,
              ),
              _InsightChip(
                label: widget.isDriverFiltered ? 'Driver' : 'Top Contributor',
                value: widget.isDriverFiltered
                    ? (widget.selectedDriver?.driverName ?? 'Selected driver')
                    : topContributor == null
                        ? 'None'
                        : _driverName(topContributor),
                color: ReportStyles.green,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1140;

              if (isWide) {
                return SizedBox(
                  height: 248,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 52,
                        child: _WeeklyBehaviorChartPanel(
                          summaries: normalized,
                          selectedWeekdayIndex: selected.weekdayIndex,
                          onWeekdaySelected: _onWeekdaySelected,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 48,
                        child: _TopDriverContributorsPanel(
                          selectedSummary: selected,
                          isDriverFiltered: widget.isDriverFiltered,
                          selectedDriver: widget.selectedDriver,
                          reviewCompletionRate: widget.reviewCompletionRate,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: [
                  SizedBox(
                    height: 242,
                    child: _WeeklyBehaviorChartPanel(
                      summaries: normalized,
                      selectedWeekdayIndex: selected.weekdayIndex,
                      onWeekdaySelected: _onWeekdaySelected,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 214,
                    child: _TopDriverContributorsPanel(
                      selectedSummary: selected,
                      isDriverFiltered: widget.isDriverFiltered,
                      selectedDriver: widget.selectedDriver,
                      reviewCompletionRate: widget.reviewCompletionRate,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _onWeekdaySelected(int weekdayIndex) {
    if (_selectedWeekdayIndex == weekdayIndex) return;
    setState(() {
      _selectedWeekdayIndex = weekdayIndex;
    });
  }
}

class _WeeklyBehaviorChartPanel extends StatelessWidget {
  const _WeeklyBehaviorChartPanel({
    required this.summaries,
    required this.selectedWeekdayIndex,
    required this.onWeekdaySelected,
  });

  final List<_WeekdayBarSummary> summaries;
  final int selectedWeekdayIndex;
  final ValueChanged<int> onWeekdaySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackgroundSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.stacked_bar_chart_rounded,
                color: ReportStyles.blue,
                size: 16,
              ),
              SizedBox(width: 8),
              Text(
                'Behavior Mix by Weekday',
                style: TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      minY: 0,
                      maxY: _maxY(summaries),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _gridInterval(summaries),
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: ReportStyles.border.withValues(alpha: 0.6),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= summaries.length) {
                                return const SizedBox.shrink();
                              }

                              final total = summaries[index].totalEvents;
                              return Text(
                                total == 0 ? '' : _integerFormat(total),
                                style: const TextStyle(
                                  color: ReportStyles.textSecondary,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= summaries.length) {
                                return const SizedBox.shrink();
                              }

                              final item = summaries[index];
                              final isSelected =
                                  item.weekdayIndex == selectedWeekdayIndex;

                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  item.shortLabel,
                                  style: TextStyle(
                                    color: isSelected
                                        ? ReportStyles.textPrimary
                                        : ReportStyles.textMuted,
                                    fontSize: 9.5,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          tooltipRoundedRadius: 10,
                          tooltipPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          tooltipBgColor: const Color(0xEE11161E),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final summary = summaries[group.x.toInt()];
                            return BarTooltipItem(
                              '${summary.weekdayLabel}\n${_integerFormat(summary.totalEvents)} events',
                              const TextStyle(
                                color: ReportStyles.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          },
                        ),
                        touchCallback: (event, response) {
                          final index = response?.spot?.touchedBarGroupIndex;
                          if (index == null ||
                              index < 0 ||
                              index >= summaries.length ||
                              !event.isInterestedForInteractions) {
                            return;
                          }

                          onWeekdaySelected(summaries[index].weekdayIndex);
                        },
                      ),
                      barGroups: summaries
                          .asMap()
                          .entries
                          .map(
                            (entry) => _buildBarGroup(
                              x: entry.key,
                              summary: entry.value,
                              isSelected:
                                  entry.value.weekdayIndex == selectedWeekdayIndex,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 138,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        _behaviorSeries.map(_BehaviorLegendRow.new).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _gridInterval(List<_WeekdayBarSummary> summaries) {
    final maxValue = summaries.fold<int>(
      0,
      (best, item) => math.max(best, item.totalEvents),
    );

    if (maxValue <= 100) return 25;
    if (maxValue <= 500) return 100;
    if (maxValue <= 1200) return 200;
    return (maxValue / 4).ceilToDouble();
  }

  double _maxY(List<_WeekdayBarSummary> summaries) {
    final maxValue = summaries.fold<int>(
      0,
      (best, item) => math.max(best, item.totalEvents),
    );

    if (maxValue == 0) {
      return 1;
    }

    return maxValue * 1.16;
  }

  BarChartGroupData _buildBarGroup({
    required int x,
    required _WeekdayBarSummary summary,
    required bool isSelected,
  }) {
    final counts = summary.behaviors;
    final segments = <BarChartRodStackItem>[];
    var start = 0.0;

    for (final series in _behaviorSeries) {
      final value = series.valueOf(counts).toDouble();
      if (value <= 0) continue;
      segments.add(
        BarChartRodStackItem(start, start + value, series.color),
      );
      start += value;
    }

    return BarChartGroupData(
      x: x,
      barsSpace: 0,
      barRods: [
        BarChartRodData(
          toY: math.max(summary.totalEvents.toDouble(), 0.0),
          width: isSelected ? 30 : 24,
          borderRadius: BorderRadius.circular(8),
          borderSide: isSelected
              ? const BorderSide(color: Colors.white, width: 1.4)
              : BorderSide.none,
          rodStackItems: segments,
          color: ReportStyles.border,
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: _maxY(summaries),
            color:
                Colors.white.withValues(alpha: isSelected ? 0.06 : 0.03),
          ),
        ),
      ],
      showingTooltipIndicators: isSelected ? const [0] : const [],
    );
  }
}

class _TopDriverContributorsPanel extends StatelessWidget {
  const _TopDriverContributorsPanel({
    required this.selectedSummary,
    required this.isDriverFiltered,
    required this.selectedDriver,
    required this.reviewCompletionRate,
  });

  final _WeekdayBarSummary selectedSummary;
  final bool isDriverFiltered;
  final DrowsinessDriverOption? selectedDriver;
  final double reviewCompletionRate;

  @override
  Widget build(BuildContext context) {
    final contributors = _visibleContributors(selectedSummary);
    final driverName = selectedDriver?.driverName ?? 'Selected driver';

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackgroundSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isDriverFiltered
                ? 'Driver Focus Summary'
                : 'Top Driver Contributors',
            style: const TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            isDriverFiltered
                ? 'Report is scoped to $driverName'
                : 'Selected: ${selectedSummary.weekdayLabel}',
            style: const TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 10),
          if (isDriverFiltered)
            Expanded(
              child: _DriverFocusSummary(
                driverName: driverName,
                selectedSummary: selectedSummary,
                reviewCompletionRate: reviewCompletionRate,
              ),
            )
          else if (contributors.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No contributor data for selected day.',
                  style: TextStyle(
                    color: ReportStyles.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.zero,
                itemCount: contributors.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  return _ContributorRow(
                    rank: index + 1,
                    contributor: contributors[index],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ContributorRow extends StatelessWidget {
  const _ContributorRow({
    required this.rank,
    required this.contributor,
  });

  final int rank;
  final DriverContributor contributor;

  @override
  Widget build(BuildContext context) {
    final percentage = contributor.percentage.clamp(0, 100).toDouble();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: ReportStyles.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                alignment: Alignment.center,
                child: Text(
                  '#$rank',
                  style: const TextStyle(
                    color: ReportStyles.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _driverName(contributor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatPercent(contributor.percentage),
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${_integerFormat(contributor.totalEvents)} events',
            style: const TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: percentage / 100,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: const AlwaysStoppedAnimation<Color>(ReportStyles.blue),
            ),
          ),
        ],
      ),
    );
  }
}

class _BehaviorLegendRow extends StatelessWidget {
  const _BehaviorLegendRow(this.series);

  final _BehaviorSeries series;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: series.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              series.label,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: const TextStyle(
            color: ReportStyles.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyBehaviorEmptyState extends StatelessWidget {
  const _WeeklyBehaviorEmptyState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Behavior Trend',
            style: TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: ReportStyles.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverFocusSummary extends StatelessWidget {
  const _DriverFocusSummary({
    required this.driverName,
    required this.selectedSummary,
    required this.reviewCompletionRate,
  });

  final String driverName;
  final _WeekdayBarSummary selectedSummary;
  final double reviewCompletionRate;

  @override
  Widget build(BuildContext context) {
    final totalEvents = selectedSummary.totalEvents;
    final dominantBehavior = _behaviorLabel(selectedSummary.dominantBehavior);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              driverName,
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            _InlineDividerLabel(
              label: '${_integerFormat(totalEvents)} events',
            ),
            _InlineDividerLabel(
              label: 'Review ${_formatPercent(reviewCompletionRate)}',
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SummaryChip(
              label: 'Peak Day',
              value: selectedSummary.weekdayLabel,
              color: ReportStyles.blue,
            ),
            _SummaryChip(
              label: 'Dominant',
              value: dominantBehavior,
              color: ReportStyles.orange,
            ),
            _SummaryChip(
              label: 'Review',
              value: _formatPercent(reviewCompletionRate),
              color: ReportStyles.green,
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text(
          'Driver-filtered view',
          style: TextStyle(
            color: ReportStyles.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Contributor breakdown is hidden because this report is already scoped to a single driver.',
          style: TextStyle(
            color: ReportStyles.textMuted,
            fontSize: 10,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _InlineDividerLabel extends StatelessWidget {
  const _InlineDividerLabel({
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: ReportStyles.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: RichText(
        text: TextSpan(
          text: '$label: ',
          style: const TextStyle(
            color: ReportStyles.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          children: [
            TextSpan(
              text: value,
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayBarSummary {
  const _WeekdayBarSummary({
    required this.weekdayIndex,
    required this.weekdayLabel,
    required this.shortLabel,
    required this.totalEvents,
    required this.behaviors,
    required this.dominantBehavior,
    required this.topDrivers,
  });

  final int weekdayIndex;
  final String weekdayLabel;
  final String shortLabel;
  final int totalEvents;
  final WeekdayBehaviorCounts behaviors;
  final String dominantBehavior;
  final List<DriverContributor> topDrivers;
}

class _BehaviorSeries {
  const _BehaviorSeries({
    required this.label,
    required this.color,
    required this.valueOf,
  });

  final String label;
  final Color color;
  final int Function(WeekdayBehaviorCounts counts) valueOf;
}

const List<_BehaviorSeries> _behaviorSeries = [
  _BehaviorSeries(
    label: 'Drowsiness',
    color: ReportStyles.red,
    valueOf: _drowsinessValue,
  ),
  _BehaviorSeries(
    label: 'Yawn',
    color: ReportStyles.yellow,
    valueOf: _yawnValue,
  ),
  _BehaviorSeries(
    label: 'Drowsy Score On',
    color: ReportStyles.blue,
    valueOf: _drowsyScoreOnValue,
  ),
  _BehaviorSeries(
    label: 'Distraction',
    color: ReportStyles.purple,
    valueOf: _distractionValue,
  ),
  _BehaviorSeries(
    label: 'Other',
    color: ReportStyles.green,
    valueOf: _otherValue,
  ),
];

int _drowsinessValue(WeekdayBehaviorCounts counts) => counts.drowsiness;
int _yawnValue(WeekdayBehaviorCounts counts) => counts.yawn;
int _drowsyScoreOnValue(WeekdayBehaviorCounts counts) => counts.drowsyScoreOn;
int _distractionValue(WeekdayBehaviorCounts counts) => counts.distraction;
int _otherValue(WeekdayBehaviorCounts counts) => counts.other;

List<_WeekdayBarSummary> _normalizeWeekdaySummaries(
  List<WeekdayBehaviorSummary> summaries,
) {
  final byIndex = <int, WeekdayBehaviorSummary>{
    for (final item in summaries)
      if (item.weekdayIndex >= 1 && item.weekdayIndex <= 5) item.weekdayIndex: item,
  };

  return List<_WeekdayBarSummary>.generate(5, (index) {
    final weekdayIndex = index + 1;
    final item = byIndex[weekdayIndex];

    return _WeekdayBarSummary(
      weekdayIndex: weekdayIndex,
      weekdayLabel: item?.weekday.isNotEmpty == true
          ? item!.weekday
          : _weekdayName(weekdayIndex),
      shortLabel: _weekdayShortLabel(weekdayIndex),
      totalEvents: item?.totalEvents ?? 0,
      behaviors: item?.behaviors ??
          const WeekdayBehaviorCounts(
            drowsiness: 0,
            yawn: 0,
            drowsyScoreOn: 0,
            distraction: 0,
            other: 0,
          ),
      dominantBehavior: item?.dominantBehavior ?? '',
      topDrivers: item?.topDrivers ?? const [],
    );
  });
}

int _defaultWeekdayIndex(List<WeekdayBehaviorSummary> summaries) {
  if (summaries.isEmpty) {
    return 1;
  }

  final normalized = _normalizeWeekdaySummaries(summaries);
  final nonZeroEntries = normalized.where((entry) => entry.totalEvents > 0);

  if (nonZeroEntries.isEmpty) {
    return 1;
  }

  return nonZeroEntries
      .reduce(
        (best, current) =>
            current.totalEvents > best.totalEvents ? current : best,
      )
      .weekdayIndex;
}

bool _sameWeekdayData(
  List<WeekdayBehaviorSummary> a,
  List<WeekdayBehaviorSummary> b,
) {
  if (a.length != b.length) {
    return false;
  }

  for (var i = 0; i < a.length; i++) {
    final left = a[i];
    final right = b[i];
    if (left.weekdayIndex != right.weekdayIndex ||
        left.totalEvents != right.totalEvents ||
        left.dominantBehavior != right.dominantBehavior) {
      return false;
    }
  }

  return true;
}

List<DriverContributor> _visibleContributors(_WeekdayBarSummary summary) {
  if (summary.topDrivers.isEmpty) {
    return const [];
  }

  final nonZero = summary.topDrivers
      .where((driver) => driver.totalEvents > 0)
      .toList(growable: false);

  if (nonZero.isNotEmpty) {
    return nonZero;
  }

  return summary.topDrivers;
}

String _weekdayName(int weekdayIndex) {
  switch (weekdayIndex) {
    case 1:
      return 'Monday';
    case 2:
      return 'Tuesday';
    case 3:
      return 'Wednesday';
    case 4:
      return 'Thursday';
    case 5:
      return 'Friday';
    default:
      return 'Day $weekdayIndex';
  }
}

String _weekdayShortLabel(int weekdayIndex) {
  switch (weekdayIndex) {
    case 1:
      return 'Mon';
    case 2:
      return 'Tue';
    case 3:
      return 'Wed';
    case 4:
      return 'Thu';
    case 5:
      return 'Fri';
    default:
      return 'Day';
  }
}

String _behaviorLabel(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'drowsiness':
      return 'Drowsiness';
    case 'yawn':
      return 'Yawn';
    case 'drowsy_score_on':
    case 'drowsyscoreon':
    case 'drowsy score on':
      return 'Drowsy Score On';
    case 'distraction':
      return 'Distraction';
    case 'other':
      return 'Other';
    default:
      return raw.isEmpty ? 'Unknown' : raw;
  }
}

String _driverName(DriverContributor contributor) {
  final name = contributor.driverName.trim();
  if (name.isEmpty) {
    return contributor.userId == null ? 'Unassigned' : 'User #${contributor.userId}';
  }
  return name;
}

String _formatPercent(double value) {
  final isWhole = value == value.roundToDouble();
  if (isWhole) {
    return '${value.toStringAsFixed(0)}%';
  }
  return '${value.toStringAsFixed(1)}%';
}

String _integerFormat(int value) => NumberFormat.decimalPattern().format(value);
