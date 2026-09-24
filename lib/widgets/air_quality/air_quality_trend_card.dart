import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import 'air_quality_reading.dart';

/// AQI over time for the selected range.
class AirQualityTrendCard extends StatelessWidget {
  const AirQualityTrendCard({
    super.key,
    required this.readings,
    required this.emptyMessage,
    required this.rangeLabel,
  });

  /// Samples inside the range, oldest first.
  final List<AirQualityReading> readings;
  final String emptyMessage;

  /// The window the chart is showing, e.g. "10 Aug - 31 Aug". The page's date
  /// picker is the only thing that sets it, so this is a label rather than a
  /// control — two widgets deciding one window is how they end up disagreeing.
  final String rangeLabel;

  static const Color _line = Color(0xFF8B7BF0);
  static const double _chartHeight = 210;

  /// Daily average AQI, oldest first.
  ///
  /// The devices sample many times a day, which draws a spiky line nobody can
  /// read across a month. Averaging per day answers the question the card
  /// actually asks — was the air worse today than yesterday.
  List<_DailyAqi> get _dailyAverages {
    final totals = <DateTime, ({int sum, int count})>{};

    for (final reading in readings) {
      final aqi = reading.aqi;
      if (aqi == null) continue;

      final day = DateUtils.dateOnly(reading.recordedAt);
      final running = totals[day];
      totals[day] = running == null
          ? (sum: aqi, count: 1)
          : (sum: running.sum + aqi, count: running.count + 1);
    }

    final days = totals.keys.toList()..sort();
    return [
      for (final day in days)
        _DailyAqi(day, totals[day]!.sum / totals[day]!.count),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final plotted = _dailyAverages;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Air Quality Trend',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              _RangeLabel(text: rangeLabel),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: _chartHeight,
            child: plotted.isEmpty
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
                : LineChart(_chartData(plotted)),
          ),
        ],
      ),
    );
  }

  /// Plots against the day index rather than the timestamp, so labels land
  /// exactly on data points and never collide near the right edge.
  LineChartData _chartData(List<_DailyAqi> plotted) {
    final points = [
      for (var i = 0; i < plotted.length; i++)
        FlSpot(i.toDouble(), plotted[i].averageAqi),
    ];

    final maxY = points.map((point) => point.y).reduce(math.max);
    // Round the top up to a clean 20 so the gridlines land on round numbers.
    final topY = ((maxY / 20).ceil() * 20).toDouble().clamp(20.0, 1e9);

    // Aim for about six labels regardless of how many days arrived.
    final step = math.max(1, (plotted.length / 6).ceil()).toDouble();

    // A lone day has no neighbour to draw a line to, so the chart came out
    // blank — axes and gridlines, no data. It gets a dot and an axis centred
    // on it instead.
    final isSingleDay = plotted.length == 1;

    return LineChartData(
      minX: isSingleDay ? -1 : 0,
      maxX: isSingleDay ? 1 : (plotted.length - 1).toDouble(),
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
            reservedSize: 34,
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
              if (index < 0 || index >= plotted.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  DateFormat('d MMM').format(plotted[index].day),
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
          getTooltipItems: (spots) => spots.map((spot) {
            final day = plotted[spot.x.round()].day;
            return LineTooltipItem(
              '${DateFormat('d MMM').format(day)}\n'
              'AQI ${spot.y.round()}',
              const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            );
          }).toList(),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: points,
          isCurved: true,
          curveSmoothness: 0.25,
          preventCurveOverShooting: true,
          color: _line,
          barWidth: 2.5,
          // One dot per day turned a month into a row of circles; the line
          // carries the shape on its own, and the tooltip still gives exact
          // numbers on hover. A single day has no line, so it keeps its dot.
          dotData: FlDotData(show: isSingleDay),
          belowBarData: BarAreaData(
            show: true,
            color: _line.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

/// One day's mean AQI.
class _DailyAqi {
  const _DailyAqi(this.day, this.averageAqi);

  final DateTime day;
  final double averageAqi;
}

/// Shows which window the chart covers. Read-only on purpose: the header's
/// date picker owns the range.
class _RangeLabel extends StatelessWidget {
  const _RangeLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.tileBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.tileBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 12,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
