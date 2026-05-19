import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class ReportStyles {
  static const Color pageBackground = AppTheme.darkNavy;
  static const Color cardBackground = AppTheme.slateGrey;
  static const Color surfaceBackground = Color(0xFF202531);
  static const Color border = Color(0xFF363C48);
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withOpacity(0.65)),
      ),
      child: child,
    );
  }
}
