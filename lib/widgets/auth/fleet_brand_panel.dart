import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';
import 'fleet_illustration.dart';
import 'fleet_safe_logo.dart';

class FleetBrandPanel extends StatelessWidget {
  const FleetBrandPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        color: AuthColors.brandPanel,
        child: Stack(
          children: [
            Positioned(
              right: -210,
              top: -310,
              child: Container(
                width: 610,
                height: 610,
                decoration: const BoxDecoration(
                  color: Color(0xFFFAFCFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const Positioned(top: 72, left: 72, child: FleetSafeLogo()),
            Positioned(
              left: 72,
              top: 250,
              right: 110,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Real-time fleet safety,\ndriver monitoring and\nvehicle telematics.',
                    style: TextStyle(
                      color: AuthColors.textPrimary,
                      fontSize: 32,
                      height: 1.27,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'One intelligent platform to help you monitor,\nanalyze and improve your fleet performance.',
                    style: TextStyle(
                      color: AuthColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const Positioned.fill(
              top: 410,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 36),
                child: FleetIllustration(),
              ),
            ),
            const Positioned(
              left: 54,
              bottom: 34,
              child: Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    color: AuthColors.muted,
                    size: 18,
                  ),
                  SizedBox(width: 9),
                  Text(
                    'Secured and encrypted connection',
                    style: TextStyle(color: AuthColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
