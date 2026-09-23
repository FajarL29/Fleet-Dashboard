import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/app_action_button.dart';
import '../common/app_date_range_picker.dart';
import '../common/app_search_field.dart';
import '../common/last_updated_label.dart';

/// Page title, last-updated line, driver search and the page actions.
class VitalSignHeader extends StatelessWidget {
  const VitalSignHeader({
    super.key,
    required this.lastUpdated,
    required this.searchController,
    required this.dateRange,
    required this.onDateRangeChanged,
    required this.driverNames,
    required this.selectedDriver,
    required this.onDriverChanged,
    required this.isWide,
  });

  final DateTime lastUpdated;
  final TextEditingController searchController;

  /// Active telemetry date filter, or null for "all time".
  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;

  final List<String> driverNames;

  /// Null means "All Driver".
  final String? selectedDriver;
  final ValueChanged<String?> onDriverChanged;

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Vital Sign Monitoring',
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

    final search = AppSearchField(
      controller: searchController,
      hintText: 'Search by plate, VIN, or device',
    );

    final actions = [
      AppDateRangePicker(value: dateRange, onChanged: onDateRangeChanged),
      _DriverFilterButton(
        driverNames: driverNames,
        selectedDriver: selectedDriver,
        onChanged: onDriverChanged,
      ),
    ];

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title,
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: search),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        SizedBox(width: 245, child: search),
        for (final action in actions) ...[const SizedBox(width: 8), action],
      ],
    );
  }
}

/// "All Driver" action that opens the driver filter.
class _DriverFilterButton extends StatelessWidget {
  const _DriverFilterButton({
    required this.driverNames,
    required this.selectedDriver,
    required this.onChanged,
  });

  final List<String> driverNames;
  final String? selectedDriver;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(AppColors.menuShadow),
        elevation: const WidgetStatePropertyAll(9),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      menuChildren: [
        _DriverMenuItem(
          label: 'All Driver',
          selected: selectedDriver == null,
          onTap: () => onChanged(null),
        ),
        for (final name in driverNames)
          _DriverMenuItem(
            label: name,
            selected: selectedDriver == name,
            onTap: () => onChanged(name),
          ),
      ],
      builder: (context, controller, child) {
        return AppActionButton(
          icon: Icons.person_search_outlined,
          label: selectedDriver ?? 'All Driver',
          trailingIcon: Icons.keyboard_arrow_down_rounded,
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}

class _DriverMenuItem extends StatelessWidget {
  const _DriverMenuItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: onTap,
      leadingIcon: Icon(
        selected ? Icons.check_rounded : Icons.remove,
        size: 16,
        color: selected ? AppColors.blue : Colors.transparent,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 13,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
