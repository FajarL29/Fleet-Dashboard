import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_driver_option.dart';
import 'report_styles.dart';

class ReportFilterBar extends StatelessWidget {
  const ReportFilterBar({
    super.key,
    required this.title,
    required this.label,
    required this.driverOptions,
    required this.selectedDriver,
    required this.isLoadingDrivers,
    required this.onDateRangeTap,
    required this.onDriverChanged,
    required this.onRefresh,
    required this.onExportPdf,
    required this.onExportCsv,
    this.isExportingPdf = false,
    this.isExportingCsv = false,
  });

  final String title;
  final String label;
  final List<DrowsinessDriverOption> driverOptions;
  final DrowsinessDriverOption? selectedDriver;
  final bool isLoadingDrivers;
  final VoidCallback onDateRangeTap;
  final ValueChanged<DrowsinessDriverOption?> onDriverChanged;
  final VoidCallback onRefresh;
  final VoidCallback onExportPdf;
  final VoidCallback onExportCsv;
  final bool isExportingPdf;
  final bool isExportingCsv;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 1180;
        final filterWidth = isCompact
            ? constraints.maxWidth
            : constraints.maxWidth * 0.22;

        final actions = Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.end,
          children: [
            _ToolbarButton(
              icon: Icons.refresh_rounded,
              label: 'Refresh',
              onTap: onRefresh,
              accentColor: ReportStyles.blue,
            ),
            _ToolbarButton(
              icon: Icons.picture_as_pdf_outlined,
              label: 'Export PDF',
              onTap: isExportingPdf ? null : onExportPdf,
              isLoading: isExportingPdf,
              accentColor: ReportStyles.blue,
            ),
            _ToolbarButton(
              icon: Icons.download_rounded,
              label: 'Export CSV',
              onTap: isExportingCsv ? null : onExportCsv,
              isLoading: isExportingCsv,
              accentColor: ReportStyles.green,
            ),
          ],
        );

        final filters = Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            SizedBox(
              width: filterWidth,
              child: _DateRangeButton(label: label, onTap: onDateRangeTap),
            ),
            SizedBox(
              width: filterWidth,
              child: _DriverDropdown(
                options: driverOptions,
                selectedDriver: selectedDriver,
                isLoading: isLoadingDrivers,
                onChanged: onDriverChanged,
              ),
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: ReportStyles.textPrimary,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isCompact) filters,
                    ],
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 16),
                  Flexible(
                    child: Align(alignment: Alignment.topRight, child: actions),
                  ),
                ],
              ],
            ),
            if (!isCompact) ...[
              const SizedBox(height: 12),
              Row(children: [Expanded(child: filters)]),
            ] else ...[
              const SizedBox(height: 10),
              Align(alignment: Alignment.centerRight, child: actions),
            ],
          ],
        );
      },
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  const _DateRangeButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ReportStyles.surfaceBackground.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ReportStyles.borderStrong.withValues(alpha: 0.82),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ReportStyles.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: ReportStyles.blue,
              ),
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
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
    final selectedValue =
        selectedDriver ??
        (options.isNotEmpty
            ? options.first
            : DrowsinessDriverOption.allDrivers());

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ReportStyles.borderStrong.withValues(alpha: 0.82),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 16,
              color: ReportStyles.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<DrowsinessDriverOption>(
                value:
                    options.any((item) => item.userId == selectedValue.userId)
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
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
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
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
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
    return '${option.driverName} - ${NumberFormat.decimalPattern().format(option.totalEvents)} events';
  }
}

class ToolbarButton extends StatelessWidget {
  const ToolbarButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.accentColor = ReportStyles.blue,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return _ToolbarButton(
      icon: icon,
      label: label,
      onTap: onTap,
      isLoading: isLoading,
      accentColor: accentColor,
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.accentColor = ReportStyles.blue,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accentColor.withValues(alpha: 0.55)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: accentColor),
            const SizedBox(width: 8),
            if (isLoading)
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
              )
            else
              Text(
                label,
                style: TextStyle(
                  color: accentColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
