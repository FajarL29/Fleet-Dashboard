import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Split of events by risk level.
class ReportsSeverityDonutCard extends StatefulWidget {
  const ReportsSeverityDonutCard({
    super.key,
    required this.critical,
    required this.medium,
    required this.low,
    required this.emptyMessage,
    this.height = 240,
    this.fill = false,
  });

  final int critical;
  final int medium;
  final int low;
  final String emptyMessage;

  /// Height of the chart area when [fill] is false.
  final double height;

  /// Take whatever height the parent gives instead, so the page can size
  /// the card to fit one screen.
  final bool fill;

  @override
  State<ReportsSeverityDonutCard> createState() =>
      _ReportsSeverityDonutCardState();
}

class _ReportsSeverityDonutCardState extends State<ReportsSeverityDonutCard> {
  /// --- Ring size knobs. The donut scales with these three, nothing else. ---
  /// Hole in the middle; also sets how thick the ring reads.
  static const double _holeRadius = 30;

  /// Thickness of a slice at rest, and while the pointer is on it.
  static const double _sliceRadius = 34;
  static const double _sliceRadiusHovered = 41;

  /// Index of the slice under the pointer, or -1 when the cursor is away.
  int _hovered = -1;

  int get _total => widget.critical + widget.medium + widget.low;

  @override
  Widget build(BuildContext context) {
    final slices = [
      _Slice('Critical', widget.critical, AppColors.red),
      _Slice('Medium', widget.medium, AppColors.amber),
      _Slice('Low', widget.low, AppColors.green),
    ];
    // Only non-empty slices are drawn, so chart indices need their own list.
    final drawn = slices.where((slice) => slice.value > 0).toList();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: widget.fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          const Text(
            'Drowsiness Severity Distribution',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          // Expanded when the page sizes the card; a fixed box otherwise.
          _ChartArea(
            fill: widget.fill,
            height: widget.height,
            child: _total == 0
                ? Center(
                    child: Text(
                      widget.emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            PieChart(
                              PieChartData(
                                sectionsSpace: 0,
                                centerSpaceRadius: _holeRadius,
                                startDegreeOffset: -90,
                                pieTouchData: PieTouchData(
                                  enabled: true,
                                  touchCallback: (event, response) {
                                    final index = response
                                        ?.touchedSection
                                        ?.touchedSectionIndex;
                                    final next =
                                        (event.isInterestedForInteractions &&
                                            index != null)
                                        ? index
                                        : -1;
                                    if (next != _hovered) {
                                      setState(() => _hovered = next);
                                    }
                                  },
                                ),
                                sections: [
                                  for (var i = 0; i < drawn.length; i++)
                                    PieChartSectionData(
                                      value: drawn[i].value.toDouble(),
                                      color: drawn[i].color,
                                      // Grows under the pointer so the hovered
                                      // slice is obvious.
                                      radius: i == _hovered
                                          ? _sliceRadiusHovered
                                          : _sliceRadius,
                                      showTitle: false,
                                    ),
                                ],
                              ),
                            ),
                            IgnorePointer(
                              // Same guard as the legend: the readout is a
                              // fixed-height Column, so a short card would
                              // otherwise overflow the donut's centre.
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _CentreReadout(
                                  slice:
                                      (_hovered >= 0 && _hovered < drawn.length)
                                      ? drawn[_hovered]
                                      : null,
                                  total: _total,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 4,
                        // scaleDown only ever shrinks, never grows, so the
                        // legend still sits at its natural size whenever
                        // there's room and only compresses when the card is
                        // squeezed shorter than usual — the actual guard
                        // against overflow, the smaller constants above just
                        // raise the bar before it kicks in.
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (final slice in slices) ...[
                                _LegendRow(
                                  slice: slice,
                                  total: _total,
                                  hovered:
                                      _hovered >= 0 &&
                                      _hovered < drawn.length &&
                                      drawn[_hovered].label == slice.label,
                                  onHover: (entered) {
                                    final index = drawn.indexWhere(
                                      (item) => item.label == slice.label,
                                    );
                                    setState(
                                      () => _hovered = entered ? index : -1,
                                    );
                                  },
                                ),
                                if (slice != slices.last)
                                  const SizedBox(height: 10),
                              ],
                            ],
                          ),
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

class _Slice {
  const _Slice(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;
}

/// Count shown inside the donut, named by whichever slice is hovered. Falls
/// back to the fleet total when nothing is, so the hole is never empty space.
class _CentreReadout extends StatelessWidget {
  const _CentreReadout({required this.slice, required this.total});

  final _Slice? slice;
  final int total;

  @override
  Widget build(BuildContext context) {
    final hovered = slice;
    final value = hovered?.value ?? total;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: hovered?.color ?? AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          hovered?.label ?? 'Total',
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 10,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.slice,
    required this.total,
    required this.hovered,
    required this.onHover,
  });

  final _Slice slice;
  final int total;
  final bool hovered;
  final ValueChanged<bool> onHover;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: hovered ? AppColors.tileBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: slice.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            // Fixed rather than Expanded: this Row sits inside a FittedBox,
            // which measures children unconstrained — a flex child there
            // throws. The width just keeps the three values lined up.
            SizedBox(
              width: 68,
              child: Text(
                slice.label,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${slice.value}',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
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
