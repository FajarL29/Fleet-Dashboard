import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ReportStyles {
  static const Color pageBackground = AppTheme.darkNavy;
  static const Color cardBackground = Color(0xFF0F1824);
  static const Color surfaceBackground = Color(0xFF151F2D);
  static const Color surfaceBackgroundSoft = Color(0xFF1A2534);
  static const Color border = Color(0xFF27354A);
  static const Color borderStrong = Color(0xFF32455E);
  static const Color textPrimary = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color textMuted = Color(0xFF8E95A4);
  static const Color textFaint = Color(0xFF667284);
  static const Color blue = AppTheme.accentBlue;
  static const Color green = AppTheme.success;
  static const Color yellow = Color(0xFFFFC64D);
  static const Color orange = AppTheme.warning;
  static const Color red = AppTheme.error;
  static const Color redSoft = Color(0xFFF87171);
  static const Color redDeep = Color(0xFFB42318);
  static const Color purple = Color(0xFF8F6BFF);

  static LinearGradient get cardGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF121C2A),
          Color(0xFF0C1420),
        ],
      );

  static List<BoxShadow> get cardShadow => const [
        BoxShadow(
          color: Color(0x2A020711),
          blurRadius: 24,
          offset: Offset(0, 12),
        ),
      ];
}

class ReportCard extends StatelessWidget {
  const ReportCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.72)),
        boxShadow: ReportStyles.cardShadow,
      ),
      child: child,
    );
  }
}
