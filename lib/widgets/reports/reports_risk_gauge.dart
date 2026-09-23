import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Half-circle gauge for the fleet's overall risk score.
///
/// The filled sweep is the risk itself, so a high score paints more red; the
/// remainder stays green.
class ReportsRiskGauge extends StatefulWidget {
  const ReportsRiskGauge({
    super.key,
    required this.score,
    this.maxScore = 100,
    this.width = 132,
  });

  /// Null renders an empty track and a dash instead of a made-up score.
  final int? score;
  final int maxScore;

  /// Fixed on purpose: a LayoutBuilder here cannot report intrinsic
  /// dimensions, which the KPI row's IntrinsicHeight needs.
  ///
  /// This is also what sets the height of the whole KPI row: the row is an
  /// IntrinsicHeight and the gauge card is its tallest member, so the two
  /// count cards beside it follow whatever this arc measures.
  final double width;

  @override
  State<ReportsRiskGauge> createState() => _ReportsRiskGaugeState();
}

/// Which part of the arc the pointer is over.
enum _GaugeBand { none, risk, safe }

class _ReportsRiskGaugeState extends State<ReportsRiskGauge> {
  _GaugeBand _hovered = _GaugeBand.none;

  double get _fraction {
    final value = widget.score;
    if (value == null) return 0;
    return (value / widget.maxScore).clamp(0.0, 1.0).toDouble();
  }

  /// Maps a pointer position onto the arc, or null when it is off the ring.
  _GaugeBand _bandAt(Offset local) {
    final width = widget.width;
    final centre = Offset(width / 2, width / 2);
    // Matches the painter's grown stroke, so the whole visible ring is
    // hoverable rather than a band narrower than what is drawn.
    final stroke = width * 0.14 * 1.25;
    final outer = width / 2;
    final inner = outer - stroke;

    final delta = local - centre;
    final distance = delta.distance;
    if (distance < inner || distance > outer) return _GaugeBand.none;
    // Only the top half is drawn.
    if (delta.dy > 0) return _GaugeBand.none;

    // 0 at the left end of the arc, 1 at the right end.
    final angle = math.atan2(-delta.dy, delta.dx);
    final progress = 1 - (angle / math.pi);
    if (progress < 0 || progress > 1) return _GaugeBand.none;

    return progress <= _fraction ? _GaugeBand.risk : _GaugeBand.safe;
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.score;
    final riskValue = value ?? 0;
    final safeValue = widget.maxScore - riskValue;

    // Same readout shape as the severity donut: the number stays big and
    // takes the hovered band's colour, and the word under it names what the
    // number is. Before this the gauge swapped in a small grey sentence, so
    // the two cards behaved differently on the same gesture.
    final (readout, caption, colour) = switch (_hovered) {
      _GaugeBand.risk => ('$riskValue', 'Risk', AppColors.red),
      _GaugeBand.safe => ('$safeValue', 'Headroom', AppColors.green),
      _GaugeBand.none => (
        value == null ? '-' : '$value/${widget.maxScore}',
        value == null ? 'No data' : 'Risk score',
        AppColors.textPrimary,
      ),
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MouseRegion(
          onHover: (event) {
            final band = value == null
                ? _GaugeBand.none
                : _bandAt(event.localPosition);
            if (band != _hovered) setState(() => _hovered = band);
          },
          onExit: (_) {
            if (_hovered != _GaugeBand.none) {
              setState(() => _hovered = _GaugeBand.none);
            }
          },
          child: SizedBox(
            width: widget.width,
            height: widget.width / 2,
            child: CustomPaint(
              painter: _GaugePainter(fraction: _fraction, hovered: _hovered),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Reserved so the card does not jump as the caption changes.
        SizedBox(
          height: 34,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                readout,
                style: TextStyle(
                  color: colour,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                caption,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GaugePainter extends CustomPainter {
  const _GaugePainter({required this.fraction, required this.hovered});

  final double fraction;
  final _GaugeBand hovered;

  /// Gap between the risk arc and the remainder arc, in radians.
  static const double _gap = 0.05;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.14;
    // The hovered band thickens the way the hovered donut slice grows, so
    // the same gesture reads the same way on both cards.
    final hoveredStroke = stroke * 1.25;
    final rect = Rect.fromLTWH(
      hoveredStroke / 2,
      hoveredStroke / 2,
      size.width - hoveredStroke,
      size.width - hoveredStroke,
    );

    Paint arc(Color color, {bool grown = false}) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = grown ? hoveredStroke : stroke
      ..strokeCap = StrokeCap.butt;

    const start = math.pi;
    const sweep = math.pi;
    final risky = sweep * fraction;

    if (fraction <= 0) {
      canvas.drawArc(rect, start, sweep, false, arc(AppColors.tileBackground));
      return;
    }

    canvas.drawArc(
      rect,
      start,
      risky,
      false,
      arc(
        hovered == _GaugeBand.risk
            ? AppColors.red
            : AppColors.red.withValues(alpha: 0.85),
        grown: hovered == _GaugeBand.risk,
      ),
    );

    final remaining = sweep - risky - _gap;
    if (remaining > 0) {
      canvas.drawArc(
        rect,
        start + risky + _gap,
        remaining,
        false,
        arc(
          hovered == _GaugeBand.safe
              ? AppColors.green
              : AppColors.green.withValues(alpha: 0.85),
          grown: hovered == _GaugeBand.safe,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.hovered != hovered;
}
