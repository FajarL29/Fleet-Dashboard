import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Risk-level pill used in the event table and over the event media.
class SafetySeverityPill extends StatelessWidget {
  const SafetySeverityPill({
    super.key,
    required this.riskLevel,
    this.compact = true,
  });

  final String riskLevel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final label = _label(riskLevel);
    final (background, foreground) = _colorsFor(label);

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 12, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }

  static String _label(String riskLevel) {
    switch (riskLevel.trim().toLowerCase()) {
      case 'high':
        return 'High';
      case 'medium':
        return 'Medium';
      case 'low':
        return 'Low';
      default:
        return riskLevel.trim().isEmpty ? 'Unknown' : riskLevel.trim();
    }
  }

  static (Color, Color) _colorsFor(String label) {
    switch (label.toLowerCase()) {
      case 'high':
        return (AppColors.redSoft, AppColors.redText);
      case 'medium':
        return (AppColors.amberSoft, AppColors.amberText);
      case 'low':
        return (AppColors.greenSoft, AppColors.greenText);
      default:
        return (AppColors.tileBackground, AppColors.textSecondary);
    }
  }
}
