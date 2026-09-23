import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import 'reports_heatmap.dart';

/// When drowsiness happens: a weekday x hour grid, darkest where events pile up.
class ReportsHeatmapCard extends StatelessWidget {
  const ReportsHeatmapCard({
    super.key,
    required this.data,
    required this.emptyMessage,
    this.height = 240,
    this.fill = false,
  });

  final ReportsHeatmapData data;
  final String emptyMessage;

  /// Height of the grid area when [fill] is false.
  final double height;

  /// Take whatever height the parent gives instead, so the page can size
  /// the card to fit one screen.
  final bool fill;

  /// Cells sit on this when nothing happened in that slot — a pale blue reads
  /// as "quiet" rather than "no data", which an empty gap would.
  static const Color _quiet = AppColors.blueSoft;

  static const List<String> _weekdayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Drowsiness Heatmap',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              if (!data.isEmpty) _Scale(busiest: data.busiest),
            ],
          ),
          const SizedBox(height: 16),
          _ChartArea(
            fill: fill,
            height: height,
            child: data.isEmpty
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
                : _Grid(data: data, quiet: _quiet),
          ),
        ],
      ),
    );
  }

  static String weekdayLabel(int weekday) => _weekdayLabels[weekday - 1];
}

/// The grid itself: an hour header, then one row per weekday.
///
/// Rows and columns both flex, so the card fills whatever the page gives it
/// instead of clipping or overflowing at an awkward size.
class _Grid extends StatelessWidget {
  const _Grid({required this.data, required this.quiet});

  final ReportsHeatmapData data;
  final Color quiet;

  /// Width of the weekday gutter on the left.
  static const double _gutter = 38;
  static const double _gap = 5;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hour header.
        SizedBox(
          height: 18,
          child: Row(
            children: [
              const SizedBox(width: _gutter),
              for (final hour in data.hours)
                Expanded(
                  child: Center(
                    child: Text(
                      hour.toString().padLeft(2, '0'),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: _gap),
        for (final weekday in data.weekdays)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: _gap),
              child: Row(
                children: [
                  SizedBox(
                    width: _gutter,
                    child: Text(
                      ReportsHeatmapCard.weekdayLabel(weekday),
                      style: const TextStyle(
                        color: AppColors.navy,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  for (final hour in data.hours)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: _Cell(
                          count: data.countAt(weekday, hour),
                          busiest: data.busiest,
                          quiet: quiet,
                          weekday: weekday,
                          hour: hour,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.count,
    required this.busiest,
    required this.quiet,
    required this.weekday,
    required this.hour,
  });

  final int count;
  final int busiest;
  final Color quiet;
  final int weekday;
  final int hour;

  @override
  Widget build(BuildContext context) {
    final label = ReportsHeatmapCard.weekdayLabel(weekday);
    final slot = '${hour.toString().padLeft(2, '0')}:00';

    return Tooltip(
      message: count == 0
          ? '$label $slot — no events'
          : '$label $slot — $count event${count == 1 ? '' : 's'}',
      waitDuration: const Duration(milliseconds: 250),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _colour,
          borderRadius: BorderRadius.circular(6),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }

  /// Quiet slots stay blue; anything with events runs from the palest red up
  /// to full red at the busiest slot in the grid.
  Color get _colour {
    if (count <= 0 || busiest <= 0) return quiet;
    final intensity = (count / busiest).clamp(0.0, 1.0).toDouble();
    return Color.lerp(AppColors.redSoft, AppColors.red, intensity)!;
  }
}

/// Reads the colour ramp back for the user, so a shade means something.
class _Scale extends StatelessWidget {
  const _Scale({required this.busiest});

  final int busiest;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Quiet',
          style: TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
        const SizedBox(width: 6),
        for (final colour in [
          AppColors.blueSoft,
          AppColors.redSoft,
          Color.lerp(AppColors.redSoft, AppColors.red, 0.5)!,
          AppColors.red,
        ]) ...[
          Container(
            width: 14,
            height: 10,
            margin: const EdgeInsets.only(right: 3),
            decoration: BoxDecoration(
              color: colour,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
        const SizedBox(width: 3),
        Text(
          '$busiest',
          style: const TextStyle(color: AppColors.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

/// Gives the grid either the height it was told, or whatever is left in the
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
