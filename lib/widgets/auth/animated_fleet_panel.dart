import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';

/// The left half of the sign-in and sign-up pages: a looping scene of vehicles
/// driving a tracked route, under the product's name and pitch.
///
/// It is deliberately the *same widget instance* on both pages — see
/// [AuthShell] — so switching between login and register changes only the
/// words on the right. If this rebuilt, the cars would jump back to the start
/// on every toggle and the seam would be obvious.
class AnimatedFleetPanel extends StatefulWidget {
  const AnimatedFleetPanel({super.key});

  @override
  State<AnimatedFleetPanel> createState() => _AnimatedFleetPanelState();
}

class _AnimatedFleetPanelState extends State<AnimatedFleetPanel>
    with TickerProviderStateMixin {
  /// Drives the vehicles along the route. Long and linear, so the loop reads
  /// as steady traffic rather than a repeating gesture.
  late final AnimationController _drive = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();

  /// Drives the pin pulse and the sky's slow drift, on its own clock so the
  /// two cycles do not visibly line up.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat();

  @override
  void dispose() {
    _drive.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: ColoredBox(
        color: AuthColors.skyHigh,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // The scene repaints every frame; everything above it does not.
            RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_drive, _pulse]),
                builder: (context, _) => CustomPaint(
                  painter: _FleetScenePainter(
                    drive: _drive.value,
                    pulse: _pulse.value,
                  ),
                ),
              ),
            ),
            const _PanelCopy(),
          ],
        ),
      ),
    );
  }
}

/// The wordmark and pitch that sit over the scene.
class _PanelCopy extends StatelessWidget {
  const _PanelCopy();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 38, 40, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monitor Today,\nSafer Tomorrow',
            style: TextStyle(
              color: AuthColors.textPrimary,
              fontSize: 30,
              height: 1.25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          // maxWidth, not a fixed width: at the panel's narrowest — right at
          // the two-column breakpoint — a fixed 380 would overflow.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: const Text(
              'An intelligent platform to help you monitor, manage, and '
              'optimize your fleet for a safer and more efficient future.',
              style: TextStyle(
                color: AuthColors.textSecondary,
                fontSize: 15,
                height: 1.55,
              ),
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  size: 15,
                  color: AuthColors.brandBlueDark,
                ),
              ),
              const SizedBox(width: 10),
              // Flexible so the line shrinks rather than overflowing right at
              // the two-column breakpoint, where the panel is at its
              // narrowest.
              Flexible(
                child: Text(
                  'Secured and encrypted connection',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AuthColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One vehicle's place in the loop.
class _Traveller {
  const _Traveller({
    required this.icon,
    required this.offset,
    required this.color,
  });

  final IconData icon;

  /// Where this vehicle sits in the loop, 0..1, so they are spread out along
  /// the road instead of leaving in convoy.
  final double offset;
  final Color color;
}

/// How a building's roofline is finished.
enum _RoofStyle { flat, stepped, spire, pyramid }

/// One building's shape and position, expressed as fractions so the skyline
/// redraws correctly at any panel size.
class _Building {
  const _Building({
    required this.x,
    required this.width,
    required this.height,
    this.roof = _RoofStyle.flat,
    this.tone = 1,
  });

  /// Left edge, as a fraction of the panel's width.
  final double x;

  /// As a fraction of the panel's width.
  final double width;

  /// As a fraction of the height scale the caller passes in — see
  /// [_FleetScenePainter._paintBuilding]. Far buildings scale off the panel's
  /// width (so they stay skyline-sized on a tall narrow panel); near ones
  /// scale off its height (so they read as a fixed "hero" size instead of
  /// stretching with how wide the window happens to be).
  final double height;

  final _RoofStyle roof;

  /// Index into the tone palette. 0 is the darkest/closest tone, 2 the
  /// haziest — used to sell depth between buildings at the same baseline.
  final int tone;
}

class _FleetScenePainter extends CustomPainter {
  const _FleetScenePainter({required this.drive, required this.pulse});

  /// 0..1, one full trip down the road.
  final double drive;

  /// 0..1, one full pin pulse.
  final double pulse;

  static const List<_Traveller> _fleet = [
    _Traveller(
      icon: Icons.local_shipping_rounded,
      offset: 0.06,
      color: AuthColors.brandBlueDark,
    ),
    _Traveller(
      icon: Icons.airport_shuttle_rounded,
      offset: 0.42,
      color: AuthColors.brandBlue,
    ),
    _Traveller(
      icon: Icons.directions_car_filled_rounded,
      offset: 0.68,
      color: AuthColors.routeDeep,
    ),
    _Traveller(
      icon: Icons.directions_car_filled_rounded,
      offset: 0.88,
      color: AuthColors.brandBlueDark,
    ),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);

    _paintSky(canvas, size);
    _paintSkyline(canvas, size);
    _paintClouds(canvas, size);

    final road = _roadPath(size);
    _paintRoad(canvas, size, road);

    final metric = road.computeMetrics().first;
    for (final traveller in _fleet) {
      _paintTraveller(canvas, size, metric, traveller);
    }
  }

  // ------------------------------------------------------------------ sky

  void _paintSky(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AuthColors.skyHigh, AuthColors.skyLow, AuthColors.groundFar],
          stops: [0.0, 0.46, 1.0],
        ).createShader(rect),
    );

    // Sun glow, low and soft, anchored behind the skyline.
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.30),
      size.width * 0.34,
      Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.white.withValues(alpha: 0.85),
                Colors.white.withValues(alpha: 0.0),
              ],
            ).createShader(
              Rect.fromCircle(
                center: Offset(size.width * 0.78, size.height * 0.30),
                radius: size.width * 0.34,
              ),
            ),
    );
  }

  /// Where the ground meets the sky. Everything is positioned off this.
  static const double _horizon = 0.60;

  /// The distant skyline: many slim towers, deliberately understated so the
  /// nearer row below reads as the foreground.
  static const List<_Building> _farBuildings = [
    _Building(x: 0.00, width: 0.050, height: 0.30, tone: 2),
    _Building(x: 0.045, width: 0.038, height: 0.18, tone: 2),
    _Building(
      x: 0.095,
      width: 0.044,
      height: 0.34,
      roof: _RoofStyle.spire,
      tone: 1,
    ),
    _Building(x: 0.15, width: 0.036, height: 0.22, tone: 2),
    _Building(
      x: 0.20,
      width: 0.050,
      height: 0.28,
      roof: _RoofStyle.stepped,
      tone: 1,
    ),
    _Building(x: 0.265, width: 0.034, height: 0.15, tone: 2),
    _Building(x: 0.31, width: 0.046, height: 0.32, tone: 1),
    _Building(x: 0.37, width: 0.040, height: 0.19, tone: 2),
    _Building(
      x: 0.425,
      width: 0.054,
      height: 0.36,
      roof: _RoofStyle.pyramid,
      tone: 1,
    ),
    _Building(x: 0.49, width: 0.036, height: 0.16, tone: 2),
    _Building(
      x: 0.535,
      width: 0.046,
      height: 0.26,
      roof: _RoofStyle.stepped,
      tone: 1,
    ),
    _Building(x: 0.595, width: 0.038, height: 0.14, tone: 2),
    _Building(
      x: 0.645,
      width: 0.046,
      height: 0.31,
      roof: _RoofStyle.spire,
      tone: 1,
    ),
    _Building(x: 0.705, width: 0.036, height: 0.20, tone: 2),
    _Building(x: 0.755, width: 0.050, height: 0.29, tone: 1),
    _Building(x: 0.82, width: 0.036, height: 0.17, tone: 2),
    _Building(x: 0.87, width: 0.046, height: 0.24, tone: 2),
    _Building(x: 0.93, width: 0.040, height: 0.13, tone: 2),
  ];

  /// The three "hero" towers close enough to show real detail: bigger
  /// silhouettes, bigger window panes, laid on top of the far row so they
  /// read as standing in front of it.
  static const List<_Building> _nearBuildings = [
    _Building(
      x: 0.015,
      width: 0.155,
      height: 0.17,
      roof: _RoofStyle.flat,
      tone: 0,
    ),
    _Building(
      x: 0.395,
      width: 0.185,
      height: 0.195,
      roof: _RoofStyle.pyramid,
      tone: 1,
    ),
    _Building(
      x: 0.79,
      width: 0.16,
      height: 0.135,
      roof: _RoofStyle.stepped,
      tone: 0,
    ),
  ];

  /// A skyline with real depth: a hazy distant row, then a nearer row of
  /// bigger towers with their own windows and rooflines, standing in front of
  /// it. Both rows are deterministic, so the city never reshuffles itself
  /// between frames.
  void _paintSkyline(Canvas canvas, Size size) {
    final horizon = size.height * _horizon;

    // Off the panel's *width*, not its height: on a tall narrow panel a
    // height-based skyline grows into a wall of towers that reads as a bar
    // chart rather than a distant city.
    final farScale = size.width * 0.22;

    for (var i = 0; i < _farBuildings.length; i++) {
      _paintBuilding(
        canvas,
        building: _farBuildings[i],
        index: i,
        size: size,
        horizon: horizon,
        heightScale: farScale,
        layerOpacity: 0.5,
      );
    }

    // Haze that fades the distant row into the horizon, painted before the
    // near towers so it never dulls them.
    final hazeRect = Rect.fromLTWH(0, horizon - farScale, size.width, farScale);
    canvas.drawRect(
      hazeRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AuthColors.skyLow.withValues(alpha: 0.5),
            AuthColors.skyLow.withValues(alpha: 0.0),
          ],
        ).createShader(hazeRect),
    );

    // Off the panel's *height* this time: these are meant to hold a fixed
    // "standing right in front of you" size, not balloon on a wide window.
    for (var i = 0; i < _nearBuildings.length; i++) {
      _paintBuilding(
        canvas,
        building: _nearBuildings[i],
        index: i + 100,
        size: size,
        horizon: horizon,
        heightScale: size.height,
        layerOpacity: 1.0,
      );
    }
  }

  /// Paints one building: its silhouette, a side-lit sheen suggesting glass
  /// catching the sun, and a grid of window panes.
  void _paintBuilding(
    Canvas canvas, {
    required _Building building,
    required int index,
    required Size size,
    required double horizon,
    required double heightScale,
    required double layerOpacity,
  }) {
    final width = building.width * size.width;
    final height = building.height * heightScale;
    final rect = Rect.fromLTWH(
      building.x * size.width,
      horizon - height,
      width,
      height,
    );
    if (rect.width <= 0 || rect.height <= 0) return;

    const palette = [
      AuthColors.brandBlueDark,
      AuthColors.skyline,
      AuthColors.skyline,
    ];
    final baseAlpha = switch (building.tone) {
      0 => 0.34,
      1 => 0.24,
      _ => 0.15,
    };
    final base = palette[building.tone].withValues(
      alpha: baseAlpha * layerOpacity,
    );

    _paintBuildingSilhouette(
      canvas,
      rect: rect,
      roof: building.roof,
      base: base,
    );

    // A soft light-to-shadow sweep across the face, as if the sun were low
    // and off to the left — without it every tower reads as a flat cutout.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.16 * layerOpacity),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(rect),
    );

    if (rect.width >= 10 && rect.height >= 14) {
      _paintWindowGrid(canvas, rect, seed: index, opacity: layerOpacity);
    }
  }

  /// Draws one building's outline, including its roofline.
  void _paintBuildingSilhouette(
    Canvas canvas, {
    required Rect rect,
    required _RoofStyle roof,
    required Color base,
  }) {
    final paint = Paint()..color = base;

    switch (roof) {
      case _RoofStyle.flat:
        canvas.drawRect(rect, paint);
      case _RoofStyle.stepped:
        final tierWidth = rect.width * 0.58;
        final tierHeight = rect.height * 0.16;
        canvas.drawRect(rect, paint);
        canvas.drawRect(
          Rect.fromLTWH(
            rect.left + (rect.width - tierWidth) / 2,
            rect.top - tierHeight,
            tierWidth,
            tierHeight,
          ),
          paint,
        );
      case _RoofStyle.pyramid:
        canvas.drawRect(rect, paint);
        canvas.drawPath(
          Path()..addPolygon(<Offset>[
            rect.topLeft,
            rect.topRight,
            Offset(rect.center.dx, rect.top - rect.width * 0.42),
          ], true),
          paint,
        );
      case _RoofStyle.spire:
        canvas.drawRect(rect, paint);
        final tip = Offset(rect.center.dx, rect.top - rect.width * 0.55);
        canvas.drawLine(
          rect.topCenter,
          tip,
          paint..strokeWidth = math.max(1.2, rect.width * 0.05),
        );
        canvas.drawCircle(tip, math.max(1.0, rect.width * 0.07), paint);
    }
  }

  /// A deterministic pseudo-random value in [0, 1) for ([a], [b]).
  ///
  /// Window tones need to look scattered but must never actually change
  /// between frames — a `Random` reseeded every paint would flicker, and one
  /// held as state would need somewhere to live outside this stateless
  /// painter. A hash sidesteps both problems.
  static double _hash(int a, int b) {
    var n = a * 928371 + b * 128981 + 17;
    n = (n ^ (n >> 13)) & 0x7FFFFFFF;
    return (n % 1000) / 1000;
  }

  /// Draws a grid of window panes inside [rect].
  ///
  /// Panes read as glass, not lit windows — most a cool translucent tint,
  /// a few brighter where they catch the sky, a few darker in shadow — since
  /// the scene is a bright afternoon, not a night skyline.
  void _paintWindowGrid(
    Canvas canvas,
    Rect rect, {
    required int seed,
    required double opacity,
    double pitch = 7,
    double margin = 3,
  }) {
    final inner = rect.deflate(margin);
    if (inner.width < pitch || inner.height < pitch) return;

    final cols = (inner.width / pitch).floor();
    final rows = (inner.height / pitch).floor();
    if (cols < 1 || rows < 1) return;

    final colGap = inner.width / cols;
    final rowGap = inner.height / rows;
    final paneWidth = colGap * 0.55;
    final paneHeight = rowGap * 0.6;

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final h = _hash(seed, r * 131 + c);
        final Color tone;
        if (h > 0.90) {
          tone = Colors.white.withValues(alpha: 0.55 * opacity);
        } else if (h < 0.18) {
          tone = AuthColors.asphalt.withValues(alpha: 0.30 * opacity);
        } else {
          tone = Colors.white.withValues(alpha: 0.22 * opacity);
        }

        canvas.drawRect(
          Rect.fromLTWH(
            inner.left + c * colGap + (colGap - paneWidth) / 2,
            inner.top + r * rowGap + (rowGap - paneHeight) / 2,
            paneWidth,
            paneHeight,
          ),
          Paint()..color = tone,
        );
      }
    }
  }

  void _paintClouds(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.72);
    // Each cloud drifts at its own pace and wraps around the full width plus
    // its own size, so it never pops in mid-air.
    const clouds = <({double y, double scale, double speed})>[
      (y: 0.10, scale: 1.0, speed: 0.6),
      (y: 0.20, scale: 0.7, speed: 1.0),
      (y: 0.07, scale: 0.5, speed: 1.5),
      (y: 0.34, scale: 0.85, speed: 0.8),
      (y: 0.44, scale: 0.55, speed: 1.25),
      (y: 0.28, scale: 0.42, speed: 1.9),
    ];

    for (final cloud in clouds) {
      final span = size.width + 260;
      final x = ((drive * cloud.speed) % 1.0) * span - 130;
      final y = size.height * cloud.y;
      final r = 26 * cloud.scale;
      canvas.drawCircle(Offset(x, y), r, paint);
      canvas.drawCircle(Offset(x + r * 0.95, y + r * 0.22), r * 0.78, paint);
      canvas.drawCircle(Offset(x - r * 0.95, y + r * 0.28), r * 0.66, paint);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y + r * 0.55),
          width: r * 3.6,
          height: r * 1.1,
        ),
        paint,
      );
    }
  }

  // ----------------------------------------------------------------- road

  /// The route the fleet drives, from the horizon down into the foreground.
  Path _roadPath(Size size) {
    final w = size.width;
    final h = size.height;
    return Path()
      ..moveTo(w * 0.54, h * _horizon)
      ..cubicTo(w * 0.54, h * 0.68, w * 0.16, h * 0.68, w * 0.20, h * 0.79)
      ..cubicTo(w * 0.24, h * 0.90, w * 0.86, h * 0.84, w * 0.80, h * 0.95)
      ..cubicTo(w * 0.76, h * 1.01, w * 0.52, h * 1.00, w * 0.42, h * 1.06);
  }

  void _paintRoad(Canvas canvas, Size size, Path road) {
    // Ground the road sits on.
    final groundTop = size.height * _horizon;
    final groundRect = Rect.fromLTWH(
      0,
      groundTop,
      size.width,
      size.height - groundTop,
    );
    canvas.drawRect(
      groundRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AuthColors.groundFar, AuthColors.groundNear],
        ).createShader(groundRect),
    );

    // The road widens toward the viewer, which a single stroke cannot do, so
    // it is drawn as three passes of decreasing width and increasing opacity.
    for (final pass in const [
      (width: 44.0, alpha: 0.10),
      (width: 36.0, alpha: 0.20),
      (width: 30.0, alpha: 1.0),
    ]) {
      canvas.drawPath(
        road,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = pass.width
          ..color = AuthColors.asphalt.withValues(alpha: pass.alpha),
      );
    }

    // Centre line, dashed by walking the path and drawing every other stretch.
    final metric = road.computeMetrics().first;
    const dash = 16.0;
    const gap = 13.0;
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.75);

    // Shift the dashes along with the traffic, so the road reads as moving.
    var distance = -((drive * (dash + gap) * 6) % (dash + gap));
    while (distance < metric.length) {
      final start = math.max(0.0, distance);
      final end = math.min(distance + dash, metric.length);
      if (end > start) {
        canvas.drawPath(metric.extractPath(start, end), dashPaint);
      }
      distance += dash + gap;
    }
  }

  // ------------------------------------------------------------- vehicles

  void _paintTraveller(
    Canvas canvas,
    Size size,
    PathMetric metric,
    _Traveller traveller,
  ) {
    final progress = (drive + traveller.offset) % 1.0;
    final tangent = metric.getTangentForOffset(progress * metric.length);
    if (tangent == null) return;

    // Perspective: a vehicle at the horizon is small and grows as it comes
    // toward the viewer. Squared so the growth accelerates the way it looks
    // from a fixed viewpoint.
    final scale = 0.58 + 0.42 * (progress * progress);
    final length = 62.0 * scale;

    // Fade in over the first stretch so nothing appears out of thin air at the
    // horizon, and out again as it leaves the frame.
    final opacity = (progress < 0.08)
        ? progress / 0.08
        : (progress > 0.94 ? (1 - progress) / 0.06 : 1.0);
    if (opacity <= 0) return;

    final angle = math.atan2(tangent.vector.dy, tangent.vector.dx);
    _paintVehicle(
      canvas,
      center: tangent.position,
      angle: angle,
      length: length,
      body: traveller.color,
      opacity: opacity,
    );

    _paintPin(canvas, tangent.position, length, opacity);
  }

  /// Draws one vehicle seen from above, nose pointing along [angle].
  ///
  /// Drawn rather than stamped from the icon font: an icon is a side-on
  /// silhouette, which reads as lying on its side once it is sitting on a
  /// top-down road, and it cannot turn to follow the bends.
  void _paintVehicle(
    Canvas canvas, {
    required Offset center,
    required double angle,
    required double length,
    required Color body,
    required double opacity,
  }) {
    final width = length * 0.44;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    // Contact shadow, offset slightly so the vehicle reads as above the road.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, width * 0.16),
          width: length * 1.02,
          height: width * 1.04,
        ),
        Radius.circular(width * 0.4),
      ),
      Paint()
        ..color = AuthColors.asphalt.withValues(alpha: 0.30 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, length * 0.09),
    );

    // Tyres: four dark stubs peeking out past the body's long sides.
    final tyre = Paint()
      ..color = const Color(0xFF1B2534).withValues(alpha: 0.85 * opacity);
    for (final dx in [length * 0.27, -length * 0.26]) {
      for (final dy in [width * 0.5, -width * 0.5]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(dx, dy),
              width: length * 0.22,
              height: width * 0.20,
            ),
            Radius.circular(width * 0.07),
          ),
          tyre,
        );
      }
    }

    // Body.
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: length, height: width),
      Radius.circular(width * 0.30),
    );
    canvas.drawRRect(
      bodyRect,
      Paint()..color = body.withValues(alpha: opacity),
    );

    // A lighter sheen down the length, so the roof does not read as flat.
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.22 * opacity),
            Colors.white.withValues(alpha: 0.0),
          ],
        ).createShader(bodyRect.outerRect),
    );

    // Cabin glass: a darker panel toward the nose, plus the rear window.
    final glass = Paint()
      ..color = const Color(0xFF16233A).withValues(alpha: 0.55 * opacity);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(length * 0.12, 0),
          width: length * 0.26,
          height: width * 0.66,
        ),
        Radius.circular(width * 0.12),
      ),
      glass,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(-length * 0.28, 0),
          width: length * 0.16,
          height: width * 0.60,
        ),
        Radius.circular(width * 0.1),
      ),
      glass,
    );

    // Headlights at the nose and tail lights at the back.
    final head = Paint()
      ..color = const Color(0xFFFFF4D2).withValues(alpha: opacity);
    for (final dy in [width * 0.28, -width * 0.28]) {
      canvas.drawCircle(Offset(length * 0.44, dy), width * 0.09, head);
    }
    final tail = Paint()
      ..color = const Color(0xFFE2574C).withValues(alpha: 0.9 * opacity);
    for (final dy in [width * 0.26, -width * 0.26]) {
      canvas.drawCircle(Offset(-length * 0.45, dy), width * 0.075, tail);
    }

    canvas.restore();
  }

  /// The tracking pin hovering over a vehicle, with a ring that grows and
  /// fades — the visual shorthand for "this one is being tracked live".
  void _paintPin(Canvas canvas, Offset vehicle, double length, double opacity) {
    final anchor = vehicle.translate(0, -length * 0.60);
    final ringRadius = length * (0.13 + 0.20 * pulse);

    canvas.drawCircle(
      anchor,
      ringRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = AuthColors.brandBlue.withValues(
          alpha: (1 - pulse) * 0.55 * opacity,
        ),
    );

    _paintIcon(
      canvas,
      icon: Icons.location_on,
      center: anchor,
      size: length * 0.34,
      color: AuthColors.brandBlue.withValues(alpha: opacity),
    );
  }

  /// Draws a Material icon onto the canvas.
  ///
  /// Icons are a font, so they can be laid out like text — which keeps the
  /// vehicles in the same coordinate space as the road instead of needing
  /// positioned widgets tracking the path from outside.
  void _paintIcon(
    Canvas canvas, {
    required IconData icon,
    required Offset center,
    required double size,
    required Color color,
  }) {
    final painter = TextPainter(
      textDirection: TextDirection.ltr,
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      ),
    )..layout();

    painter.paint(
      canvas,
      center.translate(-painter.width / 2, -painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _FleetScenePainter oldDelegate) {
    return oldDelegate.drive != drive || oldDelegate.pulse != pulse;
  }
}
