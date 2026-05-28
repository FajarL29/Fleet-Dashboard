import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ReportStyles {
  static const Color pageBackground = AppTheme.darkNavy;
  static const Color cardBackground = Color(0xFF101826);
  static const Color surfaceBackground = Color(0xFF162131);
  static const Color surfaceBackgroundSoft = Color(0xFF1A2535);
  static const Color border = Color(0xFF253246);
  static const Color textPrimary = AppTheme.textPrimary;
  static const Color textSecondary = AppTheme.textSecondary;
  static const Color textMuted = Color(0xFF8E95A4);
  static const Color blue = AppTheme.accentBlue;
  static const Color green = AppTheme.success;
  static const Color yellow = Color(0xFFFFC64D);
  static const Color orange = AppTheme.warning;
  static const Color red = AppTheme.error;
  static const Color purple = Color(0xFF8F6BFF);
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.65)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33040A14),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
