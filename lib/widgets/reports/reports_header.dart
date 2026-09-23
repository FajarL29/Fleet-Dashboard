import 'package:flutter/material.dart';

import '../../services/drowsiness_report_service.dart';

import '../../theme/app_theme.dart';
import '../common/app_action_button.dart';
import '../common/last_updated_label.dart';
import '../common/app_date_range_picker.dart';

/// Page title, last-updated line and the page actions.
///
/// No search box: the report rolls every vehicle up into one set of figures,
/// so there is nothing on the page for a per-vehicle search to narrow.
class ReportsHeader extends StatelessWidget {
  const ReportsHeader({
    super.key,
    required this.lastUpdated,
    required this.isExporting,
    required this.exportTargets,
    required this.onExport,
    required this.isWide,
    required this.dateRange,
    required this.onDateRangeChanged,
  });

  final DateTime lastUpdated;

  final bool isExporting;

  /// Vehicles the export can be narrowed to. Empty disables the button.
  final List<ReportExportTarget> exportTargets;

  /// Called with the vehicle to export, or null for the whole fleet.
  final ValueChanged<ReportExportTarget?>? onExport;

  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Reports',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        LastUpdatedLabel(timestamp: lastUpdated),
      ],
    );

    final actions = [
      AppDateRangePicker(value: dateRange, onChanged: onDateRangeChanged),
      _ExportMenuButton(
        isExporting: isExporting,
        targets: exportTargets,
        onExport: onExport,
      ),
    ];

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 14),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          actions[i],
        ],
      ],
    );
  }
}

/// The Export button, which asks what to export rather than guessing.
///
/// It used to export whichever vehicle happened to be first in the list, with
/// nothing on screen saying so — the page showed fleet-wide figures and the
/// file held one arbitrary vehicle.
class _ExportMenuButton extends StatelessWidget {
  const _ExportMenuButton({
    required this.isExporting,
    required this.targets,
    required this.onExport,
  });

  final bool isExporting;
  final List<ReportExportTarget> targets;
  final ValueChanged<ReportExportTarget?>? onExport;

  @override
  Widget build(BuildContext context) {
    final enabled = !isExporting && onExport != null && targets.isNotEmpty;

    return PopupMenuButton<ReportExportTarget?>(
      enabled: enabled,
      tooltip: targets.isEmpty
          ? 'Nothing to export yet'
          : 'Choose what to export',
      position: PopupMenuPosition.under,
      onSelected: (target) => onExport?.call(target),
      itemBuilder: (context) => [
        PopupMenuItem<ReportExportTarget?>(
          value: null,
          child: Row(
            children: [
              const Icon(Icons.dns_outlined, size: 18),
              const SizedBox(width: 10),
              Text('All vehicles (${targets.length})'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        for (final target in targets)
          PopupMenuItem<ReportExportTarget?>(
            value: target,
            child: Row(
              children: [
                const Icon(Icons.directions_bus_outlined, size: 18),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(target.label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
      ],
      child: AbsorbPointer(
        child: AppActionButton(
          icon: Icons.file_download_outlined,
          label: isExporting ? 'Exporting...' : 'Export CSV',
          onPressed: enabled ? () {} : null,
        ),
      ),
    );
  }
}
