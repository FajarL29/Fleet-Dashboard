import 'package:fleet_dashboard/theme/app_theme.dart';
import 'package:flutter/material.dart';

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final logoSize = compact ? 48.0 : 58.0;
    final titleSize = compact ? 23.0 : 28.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: logoSize,
          height: logoSize,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(compact ? 14 : 18),
            border: Border.all(color: AuthTheme.primaryBlue, width: 3),
          ),
          child: Icon(
            Icons.directions_car_rounded,
            color: AuthTheme.primaryBlue,
            size: compact ? 27 : 31,
          ),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(
                    text: 'FLEET ',
                    style: TextStyle(
                      color: AuthTheme.darkBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const TextSpan(
                    text: 'SAFE',
                    style: TextStyle(
                      color: AuthTheme.primaryBlue,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              style: TextStyle(fontSize: titleSize),
            ),
            const Text(
              'Monitor Today, Safer Tomorrow',
              style: TextStyle(
                color: AuthTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
