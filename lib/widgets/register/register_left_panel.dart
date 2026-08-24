import 'package:fleet_dashboard/theme/app_theme.dart';
import 'package:fleet_dashboard/widgets/auth/auth_brand.dart';
import 'package:flutter/material.dart';

import 'register_feature_card.dart';

class RegisterLeftPanel extends StatelessWidget {
  const RegisterLeftPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AuthTheme.leftGradient),
      child: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(painter: _RegisterBackgroundPainter()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 42, 48, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AuthBrand(),
                const SizedBox(height: 48),

                const Text(
                  'Create your account\nand get started',
                  style: TextStyle(
                    color: AuthTheme.darkBlue,
                    fontSize: 34,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 18),

                const SizedBox(
                  width: 450,
                  child: Text(
                    'Join FleetSafe to monitor your fleet in real-time, '
                    'improve driver safety, and make smarter decisions.',
                    style: TextStyle(
                      color: AuthTheme.textSecondary,
                      fontSize: 15,
                      height: 1.55,
                    ),
                  ),
                ),

                const SizedBox(height: 42),

                const Expanded(child: _FeatureIllustration()),

                const SizedBox(height: 20),

                const Row(
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      size: 15,
                      color: Color(0xFF7085A6),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Secured and encrypted connection',
                      style: TextStyle(
                        color: Color(0xFF7085A6),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureIllustration extends StatelessWidget {
  const _FeatureIllustration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned(
          left: 20,
          top: 30,
          child: RegisterFeatureCard(
            icon: Icons.shield_outlined,
            title: 'Driver Safety',
            description:
                'Monitor drowsiness,\ndistraction, and\nrisky behavior.',
          ),
        ),
        const Positioned(
          right: 35,
          top: 0,
          child: RegisterFeatureCard(
            icon: Icons.location_on_outlined,
            title: 'Live Tracking',
            description:
                'Track vehicles\nin real-time with\naccurate location.',
          ),
        ),
        const Positioned(
          left: 5,
          bottom: 45,
          child: RegisterFeatureCard(
            icon: Icons.insights_outlined,
            title: 'Insights & Reports',
            description:
                'Get actionable insights\nto improve fleet\nperformance.',
          ),
        ),
        const Positioned(
          right: 0,
          bottom: 75,
          child: RegisterFeatureCard(
            icon: Icons.cloud_outlined,
            title: 'Connected Platform',
            description:
                'All your fleet data in one\nsecure and intelligent\nplatform.',
          ),
        ),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AuthTheme.primaryBlue,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x332563EB),
                  blurRadius: 30,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const Icon(Icons.location_on, color: Colors.white, size: 52),
          ),
        ),
      ],
    );
  }
}

class _RegisterBackgroundPainter extends CustomPainter {
  const _RegisterBackgroundPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0x0C2563EB)
      ..strokeWidth = 1;

    const spacing = 34.0;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = size.height * 0.35; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.1, gridPaint);
      }
    }

    final routePaint = Paint()
      ..color = const Color(0xDB2563EB)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.14, size.height * 0.79)
      ..cubicTo(
        size.width * 0.30,
        size.height * 0.78,
        size.width * 0.34,
        size.height * 0.82,
        size.width * 0.42,
        size.height * 0.70,
      )
      ..cubicTo(
        size.width * 0.50,
        size.height * 0.60,
        size.width * 0.35,
        size.height * 0.53,
        size.width * 0.40,
        size.height * 0.44,
      )
      ..cubicTo(
        size.width * 0.45,
        size.height * 0.37,
        size.width * 0.58,
        size.height * 0.38,
        size.width * 0.60,
        size.height * 0.31,
      );

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
