import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// A truck driving along a scrolling road, shown while a page loads.
///
/// Drawn from an icon glyph and a painter rather than an image or Lottie file,
/// so it adds no asset weight and repaints only its own small box.
class FleetLoader extends StatefulWidget {
  const FleetLoader({
    super.key,
    this.message,
    this.icon = Icons.local_shipping_rounded,
  });

  final String? message;
  final IconData icon;

  @override
  State<FleetLoader> createState() => _FleetLoaderState();
}

class _FleetLoaderState extends State<FleetLoader>
    with SingleTickerProviderStateMixin {
  static const double _width = 180;
  static const double _height = 64;
  static const double _iconSize = 40;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Respect the OS "reduce motion" setting: the truck parks instead.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;

    return Semantics(
      label: message ?? 'Loading',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RepaintBoundary(
            child: SizedBox(
              width: _width,
              height: _height,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final t = _controller.value;
                  // Two small hops per cycle, like a truck on a rough road.
                  final hop = math.sin(t * math.pi * 2).abs() * 2;
                  return CustomPaint(
                    painter: _RoadPainter(progress: t),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Transform.translate(
                        offset: Offset(0, -hop),
                        child: child,
                      ),
                    ),
                  );
                },
                child: Icon(
                  widget.icon,
                  size: _iconSize,
                  color: AppColors.navy,
                ),
              ),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  _RoadPainter({required this.progress});

  final double progress;

  static const double _dash = 14;
  static const double _gap = 10;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    // The glyph leaves ~1/6 of its box empty under the wheels.
    final roadY = size.height - 6;

    // Dashes slide left, so the truck reads as driving right. Faded toward the
    // edges so the road has no hard ends.
    final period = _dash + _gap;
    final shift = -progress * period;
    final dashPaint = Paint()
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var x = shift; x < size.width; x += period) {
      final start = math.max(x, 0.0);
      final end = math.min(x + _dash, size.width);
      if (end <= start) continue;
      final mid = (start + end) / 2;
      final falloff = 1 - math.pow((mid - centerX).abs() / centerX, 2);
      dashPaint.color = AppColors.textMuted.withValues(
        alpha: 0.55 * falloff.clamp(0.0, 1.0),
      );
      canvas.drawLine(Offset(start, roadY), Offset(end, roadY), dashPaint);
    }

    // Speed lines trailing behind the truck.
    final tail = centerX - 24;
    final linePaint = Paint()
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    const rows = [(-26.0, 0.0), (-18.0, 0.33), (-10.0, 0.66)];
    for (final (dy, phase) in rows) {
      final wave = math.sin((progress + phase) * math.pi * 2) * 0.5 + 0.5;
      final length = 6 + wave * 10;
      linePaint.color = AppColors.blue.withValues(alpha: 0.25 + wave * 0.35);
      canvas.drawLine(
        Offset(tail - length, roadY + dy),
        Offset(tail, roadY + dy),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RoadPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
