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
    return ReportCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 1140;
          final controlWidth = isCompact ? constraints.maxWidth : 230.0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: 0,
                      maxWidth: isCompact ? constraints.maxWidth : 420,
                    ),
                    child: _HeaderBlock(title: title),
                  ),
                  SizedBox(
                    width: isCompact
                        ? constraints.maxWidth
                        : constraints.maxWidth - 456,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.end,
                        children: [
                          SizedBox(
                            width: controlWidth,
                            child: _DriverDropdown(
                              options: driverOptions,
                              selectedDriver: selectedDriver,
                              isLoading: isLoadingDrivers,
                              onChanged: onDriverChanged,
                            ),
                          ),
                          _ToolbarButton(
                            icon: Icons.refresh_rounded,
                            label: 'Refresh',
                            onTap: onRefresh,
                          ),
                          _ToolbarButton(
                            icon: Icons.picture_as_pdf_outlined,
                            label: 'Export PDF',
                            onTap: isExportingPdf ? null : onExportPdf,
                            isLoading: isExportingPdf,
                          ),
                          _ToolbarButton(
                            icon: Icons.download_rounded,
                            label: 'Export CSV',
                            onTap: isExportingCsv ? null : onExportCsv,
                            isLoading: isExportingCsv,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: controlWidth,
                    child: _DateRangeButton(
                      label: label,
                      onTap: onDateRangeTap,
                    ),
                  ),
                  _ContextChip(
                    icon: Icons.route_rounded,
                    label: 'Vehicle',
                    value: 'VIN-0001',
                  ),
                  _ContextChip(
                    icon: Icons.person_pin_circle_outlined,
                    label: 'Focus',
                    value: selectedDriver?.driverName ?? 'All Drivers',
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderBlock extends StatelessWidget {
  const _HeaderBlock({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'EXECUTIVE OVERVIEW',
          style: TextStyle(
            color: ReportStyles.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: ReportStyles.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Operational risk snapshot with behavior trend, contributor ranking, and hour-of-day exposure.',
          style: TextStyle(
            color: ReportStyles.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
      ],
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
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: ReportStyles.surfaceBackgroundSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ReportStyles.borderStrong.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ReportStyles.blue.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: ReportStyles.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      color: ReportStyles.textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ReportStyles.textPrimary,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
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
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackgroundSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ReportStyles.borderStrong.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ReportStyles.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons.person_rounded,
              size: 16,
              color: ReportStyles.redSoft,
            ),
          ),
          const SizedBox(width: 12),
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

class _ContextChip extends StatelessWidget {
  const _ContextChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: ReportStyles.textMuted),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              color: ReportStyles.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
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
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return _ToolbarButton(
      icon: icon,
      label: label,
      onTap: onTap,
      isLoading: isLoading,
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: ReportStyles.surfaceBackgroundSoft,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ReportStyles.borderStrong.withValues(alpha: 0.7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: ReportStyles.textPrimary),
            const SizedBox(width: 8),
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Text(
                label,
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
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
