import 'package:flutter/material.dart';
import '../../theme/auth_colors.dart';

class FleetSafeLogo extends StatelessWidget {
  const FleetSafeLogo({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 48.0 : 64.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: compact ? 52 : 68,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            border: Border.all(
              color: AuthColors.brandBlue,
              width: compact ? 3 : 4,
            ),
            borderRadius: BorderRadius.circular(compact ? 13 : 17),
          ),
          child: Icon(
            Icons.directions_car_filled_rounded,
            color: AuthColors.brandBlue,
            size: compact ? 25 : 34,
          ),
        ),
        SizedBox(width: compact ? 13 : 18),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: compact ? 22 : 30,
                  fontWeight: FontWeight.w800,
                ),
                children: const [
                  TextSpan(
                    text: 'FLEET ',
                    style: TextStyle(color: AuthColors.textPrimary),
                  ),
                  TextSpan(
                    text: 'SAFE',
                    style: TextStyle(color: AuthColors.brandBlue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Monitor Today, Safer Tomorrow',
              style: TextStyle(
                color: AuthColors.textSecondary,
                fontSize: compact ? 11 : 14,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
