import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_driver_option.dart';
import 'report_styles.dart';

class ReportFilterBar extends StatelessWidget {
  const ReportFilterBar({
    super.key,
    required this.label,
    required this.driverOptions,
    required this.selectedDriver,
    required this.isLoadingDrivers,
    required this.onDateRangeTap,
    required this.onDriverChanged,
    required this.onRefresh,
  });

  final String label;
  final List<DrowsinessDriverOption> driverOptions;
  final DrowsinessDriverOption? selectedDriver;
  final bool isLoadingDrivers;
  final VoidCallback onDateRangeTap;
  final ValueChanged<DrowsinessDriverOption?> onDriverChanged;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 980;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: isNarrow ? 0 : 296,
                maxWidth: isNarrow ? constraints.maxWidth : 360,
              ),
              child: _DateRangeButton(
                label: label,
                onTap: onDateRangeTap,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: isNarrow ? 0 : 248,
                maxWidth: isNarrow ? constraints.maxWidth : 310,
              ),
              child: _DriverDropdown(
                options: driverOptions,
                selectedDriver: selectedDriver,
                isLoading: isLoadingDrivers,
                onChanged: onDriverChanged,
              ),
            ),
            SizedBox(
              width: isNarrow
                  ? constraints.maxWidth
                  : constraints.maxWidth - 690,
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ToolbarButton(
                      icon: Icons.refresh_rounded,
                      label: 'Refresh',
                      onTap: onRefresh,
                    ),
                    const _ToolbarButton(
                      icon: Icons.picture_as_pdf_outlined,
                      label: 'Export PDF',
                    ),
                    const _ToolbarButton(
                      icon: Icons.download_rounded,
                      label: 'Export CSV',
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ReportStyles.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ReportStyles.border),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: ReportStyles.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
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
    );
  }
}

class _DriverDropdown extends StatelessWidget {
  const _DriverDropdown({
    required this.options,
    required this.selectedDriver,
    required this.isLoading,
    required this.onChanged,
  });

  final List<DrowsinessDriverOption> options;
  final DrowsinessDriverOption? selectedDriver;
  final bool isLoading;
  final ValueChanged<DrowsinessDriverOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedValue = selectedDriver ??
        (options.isNotEmpty ? options.first : DrowsinessDriverOption.allDrivers());

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.person_rounded,
            size: 16,
            color: ReportStyles.textSecondary,
          ),
          const SizedBox(width: 8),
          const Text(
            'Driver',
            style: TextStyle(
              color: ReportStyles.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DrowsinessDriverOption>(
                value: options.any((item) => item.userId == selectedValue.userId)
                    ? options.firstWhere(
                        (item) => item.userId == selectedValue.userId,
                      )
                    : options.isNotEmpty
                        ? options.first
                        : selectedValue,
                isExpanded: true,
                icon: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: ReportStyles.textSecondary,
                      ),
                dropdownColor: ReportStyles.surfaceBackgroundSoft,
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                onChanged: isLoading || options.isEmpty ? null : onChanged,
                items: options
                    .map(
                      (option) => DropdownMenuItem<DrowsinessDriverOption>(
                        value: option,
                        child: Text(
                          _driverOptionLabel(option),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ReportStyles.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _driverOptionLabel(DrowsinessDriverOption option) {
    if (option.isAllDrivers) {
      return option.driverName;
    }
    return '${option.driverName} — ${_formatCount(option.totalEvents)} events';
  }

  String _formatCount(int value) {
    return NumberFormat.decimalPattern().format(value);
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
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: ReportStyles.cardBackground,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ReportStyles.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: ReportStyles.textPrimary),
            const SizedBox(width: 7),
            Text(
              label,
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
