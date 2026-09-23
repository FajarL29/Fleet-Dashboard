import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Daily drowsiness event counts across the reporting period.
class ReportsEventsOverTimeCard extends StatelessWidget {
  const ReportsEventsOverTimeCard({
    super.key,
    required this.eventsByDay,
    required this.emptyMessage,
    this.height = 260,
    this.fill = false,
  });

  /// Buckets from the report API, any order.
  final List<DrowsinessEventsByDay> eventsByDay;
  final String emptyMessage;

  /// Height of the chart area when [fill] is false.
  final double height;

  /// Take whatever height the parent gives instead, so the page can size
  /// the card to fit one screen.
  final bool fill;

  static const Color _line = AppColors.blue;

  @override
  Widget build(BuildContext context) {
    final days = List<DrowsinessEventsByDay>.from(eventsByDay)
      ..sort((a, b) => a.date.compareTo(b.date));

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const Text(
            'Drowsiness Event Overtime',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 18),
          // Expanded when the page sizes the card; a fixed box otherwise.
          _ChartArea(
            fill: fill,
            height: height,
            child: days.isEmpty
                ? Center(
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : LineChart(_chartData(days)),
          ),
        ],
      ),
    );
  }

  LineChartData _chartData(List<DrowsinessEventsByDay> days) {
    final points = [
      for (var i = 0; i < days.length; i++)
        FlSpot(i.toDouble(), days[i].totalEvents.toDouble()),
    ];

    final maxY = points.map((point) => point.y).reduce(math.max);
    final topY = maxY <= 0
        ? 10.0
        : ((maxY / 5).ceil() * 5).toDouble().clamp(5.0, 1e9);
    // Aim for about six date labels regardless of the period length.
    final step = math.max(1, (days.length / 6).ceil()).toDouble();

    return LineChartData(
      minX: 0,
      maxX: (days.length - 1).toDouble().clamp(1.0, 1e9),
      minY: 0,
      maxY: topY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: topY / 5,
        getDrawingHorizontalLine: (value) =>
            const FlLine(color: AppColors.divider, strokeWidth: 1),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: topY / 5,
            getTitlesWidget: (value, meta) => Text(
              value.toInt().toString(),
              style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: step,
            getTitlesWidget: (value, meta) {
              final index = value.round();
              if (index < 0 || index >= days.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('d MMM').format(days[index].date),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: AppColors.textPrimary,
          getTooltipItems: (spots) => spots
              .map(
                (spot) => LineTooltipItem(
                  '${spot.y.round()} events',
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: points,
          isCurved: true,
          curveSmoothness: 0.3,
          preventCurveOverShooting: true,
          color: _line,
          barWidth: 2.5,
          dotData: FlDotData(
            show: days.length <= 20,
            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
              radius: 3,
              color: AppColors.surface,
              strokeWidth: 2,
              strokeColor: _line,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            color: _line.withValues(alpha: 0.10),
          ),
        ),
      ],
    );
  }
}

/// Gives the chart either the height it was told, or whatever is left in the
/// card, depending on how the page laid this card out.
class _ChartArea extends StatelessWidget {
  const _ChartArea({
    required this.fill,
    required this.height,
    required this.child,
  });

  final bool fill;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (fill) return Expanded(child: child);
    return SizedBox(height: height, child: child);
  }
}
