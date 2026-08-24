import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';
import 'floating_status_card.dart';

class FleetIllustration extends StatelessWidget {
  const FleetIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: CustomPaint(painter: _FleetRoutePainter())),
        const Positioned(
          top: 5,
          right: 80,
          child: FloatingStatusCard(
            icon: Icons.location_on_rounded,
            title: 'Live Tracking',
            value: '124 Vehicles',
            subtitle: 'On the road',
          ),
        ),
        const Positioned(
          left: 20,
          top: 210,
          child: FloatingStatusCard(
            icon: Icons.shield_outlined,
            title: 'Safety Events',
            value: '3 Alerts Today',
            subtitle: '2 High Risk',
            subtitleColor: AuthColors.danger,
          ),
        ),
        const Positioned(
          right: 35,
          bottom: 105,
          child: FloatingStatusCard(
            icon: Icons.check_circle_rounded,
            title: 'Fleet Healthy',
            value: 'All systems',
            subtitle: 'operating normally',
            iconColor: AuthColors.success,
          ),
        ),
        const Positioned(
          left: 155,
          bottom: 165,
          child: Icon(
            Icons.local_shipping_rounded,
            color: AuthColors.brandBlueDark,
            size: 44,
          ),
        ),
        const Positioned(
          right: 190,
          top: 150,
          child: Icon(
            Icons.directions_car_filled_rounded,
            color: AuthColors.textSecondary,
            size: 32,
          ),
        ),
        const Positioned(
          right: 225,
          top: 275,
          child: Icon(
            Icons.directions_car_filled_rounded,
            color: AuthColors.textSecondary,
            size: 39,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 80,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AuthColors.brandBlue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x332563EB),
                      blurRadius: 28,
                      spreadRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              Container(
                width: 52,
                height: 9,
                margin: const EdgeInsets.only(top: 7),
                decoration: BoxDecoration(
                  color: AuthColors.brandBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FleetRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AuthColors.mapGrid.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    final routePaint = Paint()
      ..color = AuthColors.route.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var x = 0.0; x < size.width; x += 34) {
      canvas.drawLine(Offset(x, 0), Offset(x - 160, size.height), gridPaint);
    }
    for (var y = 20.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y - 80), gridPaint);
    }

    final route = Path()
      ..moveTo(size.width * 0.05, size.height * 0.72)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.28,
        size.width * 0.48,
        size.height * 0.82,
        size.width * 0.72,
        size.height * 0.35,
      )
      ..cubicTo(
        size.width * 0.82,
        size.height * 0.16,
        size.width * 0.9,
        size.height * 0.28,
        size.width,
        size.height * 0.1,
      );
    canvas.drawPath(route, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
