import 'package:flutter/material.dart';

import 'report_styles.dart';

class ReportFilterBar extends StatelessWidget {
  const ReportFilterBar({
    super.key,
    required this.label,
    required this.onDateRangeTap,
    required this.onRefresh,
  });

  final String label;
  final VoidCallback onDateRangeTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: onDateRangeTap,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: ReportStyles.surfaceBackground,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: ReportStyles.border),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    size: 18,
                    color: ReportStyles.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    label,
                    style: const TextStyle(
                      color: ReportStyles.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: ReportStyles.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          _ToolbarButton(
            icon: Icons.refresh_rounded,
            label: 'Refresh',
            onTap: onRefresh,
          ),
          const SizedBox(width: 10),
          const _ToolbarButton(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Export PDF',
          ),
          const SizedBox(width: 10),
          const _ToolbarButton(
            icon: Icons.download_rounded,
            label: 'Export CSV',
          ),
        ],
      ),
    );
  }
}

class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _ToolbarButton(
      icon: icon,
      label: label,
      onTap: onTap,
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ReportStyles.surfaceBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ReportStyles.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: ReportStyles.textPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
