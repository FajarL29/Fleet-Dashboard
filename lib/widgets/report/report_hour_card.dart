import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportHourCard extends StatelessWidget {
  const ReportHourCard({
    super.key,
    this.report,
    required this.events,
  });

  final DrowsinessReport? report;
  final List<DrowsinessEvent> events;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ReportStyles.green.withValues(alpha: 0.16),
                ),
                child: const Icon(
                  Icons.speed_rounded,
                  color: ReportStyles.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'Drowsy Events by Hour',
                style: TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Row(
                children: const [
                  Text(
                    'Low',
                    style: TextStyle(
                      color: ReportStyles.textMuted,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(width: 8),
                  _LegendCell(color: Color(0xFF335F33)),
                  _LegendCell(color: Color(0xFF5D8A34)),
                  _LegendCell(color: Color(0xFF99BE32)),
                  _LegendCell(color: Color(0xFFF0C533)),
                  _LegendCell(color: Color(0xFFFF9C3D)),
                  SizedBox(width: 4),
                  Text(
                    'High',
                    style: TextStyle(
                      color: ReportStyles.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _HourHeatmap(
              report: report,
              events: events,
            ),
          ),
          const SizedBox(height: 6),
          const Divider(height: 1, color: ReportStyles.border),
          const SizedBox(height: 6),
          const Row(
            children: [
              Icon(
                Icons.schedule_rounded,
                size: 14,
                color: ReportStyles.textMuted,
              ),
              SizedBox(width: 6),
              Text(
                'All times shown in local time',
                style: TextStyle(
                  color: ReportStyles.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendCell extends StatelessWidget {
  const _LegendCell({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _HourHeatmap extends StatelessWidget {
  const _HourHeatmap({
    this.report,
    required this.events,
  });

  final DrowsinessReport? report;
  final List<DrowsinessEvent> events;

  Color _cellColor(double value) {
    if (value > 0.85) return const Color(0xFFFF9C3D);
    if (value > 0.70) return const Color(0xFFF0C533);
    if (value > 0.55) return const Color(0xFF99BE32);
    if (value > 0.35) return const Color(0xFF5D8A34);
    return const Color(0xFF335F33);
  }

  @override
  Widget build(BuildContext context) {
    final reportHourlyData = report?.eventsByHour ?? const [];
    if (reportHourlyData.isNotEmpty) {
      final values = _aggregateHourlyValues(reportHourlyData);
      return _AggregateHourHeatmap(values: values);
    }

    // TODO: Remove this fallback after the backend provides day-by-hour report aggregation.
    final values = _eventDerivedHourlyValues();

    return Column(
      children: [
        Expanded(
          child: Column(
            children: List.generate(_DerivedHourHeatmap.days.length, (row) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 40,
                        child: Text(
                          _DerivedHourHeatmap.days[row],
                          style: const TextStyle(
                            color: ReportStyles.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: List.generate(24, (hour) {
                            final value = values[row][hour];

                            return Expanded(
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: _cellColor(value),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Row(
                children: List.generate(24, (hour) {
                  return Expanded(
                    child: Center(
                      child: hour % 3 == 0
                          ? Text(
                              hour.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                color: ReportStyles.textMuted,
                                fontSize: 10,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Hour of Day',
          style: TextStyle(
            color: ReportStyles.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  List<List<double>> _eventDerivedHourlyValues() {
    final counts = List.generate(
      _DerivedHourHeatmap.days.length,
      (_) => List.filled(24, 0),
    );
    var maxCount = 0;

    for (final event in events) {
      final weekdayIndex = event.time.weekday - 1;
      if (weekdayIndex < 0 ||
          weekdayIndex >= _DerivedHourHeatmap.days.length) {
        continue;
      }

      counts[weekdayIndex][event.time.hour]++;
      maxCount = math.max(maxCount, counts[weekdayIndex][event.time.hour]);
    }

    if (maxCount == 0) {
      return List.generate(
        _DerivedHourHeatmap.days.length,
        (_) => List.filled(24, 0.0),
      );
    }

    return counts
        .map((row) => row.map((count) => count / maxCount).toList())
        .toList();
  }

  List<double> _aggregateHourlyValues(List<DrowsinessEventsByHour> hours) {
    final counts = List<int>.filled(24, 0);
    var maxCount = 0;

    for (final entry in hours) {
      if (entry.hour < 0 || entry.hour > 23) continue;
      counts[entry.hour] = entry.totalEvents;
      maxCount = math.max(maxCount, entry.totalEvents);
    }

    if (maxCount == 0) {
      return List<double>.filled(24, 0.0);
    }

    return counts.map((count) => count / maxCount).toList();
  }
}

class _DerivedHourHeatmap {
  static const List<String> days = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
  ];
}

class _AggregateHourHeatmap extends StatelessWidget {
  const _AggregateHourHeatmap({
    required this.values,
  });

  final List<double> values;

  Color _cellColor(double value) {
    if (value > 0.85) return const Color(0xFFFF9C3D);
    if (value > 0.70) return const Color(0xFFF0C533);
    if (value > 0.55) return const Color(0xFF99BE32);
    if (value > 0.35) return const Color(0xFF5D8A34);
    return const Color(0xFF335F33);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const SizedBox(
                    width: 40,
                    child: Text(
                      'All',
                      style: TextStyle(
                        color: ReportStyles.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: List.generate(24, (hour) {
                        return Expanded(
                          child: Container(
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: _cellColor(values[hour]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'Using aggregate report events_by_hour',
                style: TextStyle(
                  color: ReportStyles.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const SizedBox(width: 40),
            Expanded(
              child: Row(
                children: List.generate(24, (hour) {
                  return Expanded(
                    child: Center(
                      child: hour % 3 == 0
                          ? Text(
                              hour.toString().padLeft(2, '0'),
                              style: const TextStyle(
                                color: ReportStyles.textMuted,
                                fontSize: 10,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Hour of Day',
          style: TextStyle(
            color: ReportStyles.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
