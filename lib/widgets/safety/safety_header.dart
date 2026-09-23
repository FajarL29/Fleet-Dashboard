import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/app_action_button.dart';
import '../common/app_date_range_picker.dart';
import '../common/app_search_field.dart';
import '../common/last_updated_label.dart';

/// One entry in the vehicle filter.
///
/// The API keys events by VIN, but a VIN means nothing to whoever is reading
/// the page, so the label carries the plate and the value stays the VIN.
class VehicleFilterOption {
  const VehicleFilterOption({required this.vin, required this.label});

  final String vin;
  final String label;
}

/// Page title, last-updated line, search and the page actions.
class SafetyHeader extends StatelessWidget {
  const SafetyHeader({
    super.key,
    required this.lastUpdated,
    required this.searchController,
    required this.dateRange,
    required this.onDateRangeChanged,
    required this.vehicleOptions,
    required this.selectedVin,
    required this.onVehicleChanged,
    required this.isWide,
  });

  final DateTime lastUpdated;
  final TextEditingController searchController;

  final DateTimeRange? dateRange;
  final ValueChanged<DateTimeRange?> onDateRangeChanged;

  final List<VehicleFilterOption> vehicleOptions;

  /// Null means every vehicle.
  final String? selectedVin;
  final ValueChanged<String?> onVehicleChanged;

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Safety Monitoring',
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
      _VehicleFilterButton(
        options: vehicleOptions,
        selected: selectedVin,
        onChanged: onVehicleChanged,
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
        SizedBox(width: 240, child: search),
        for (final action in actions) ...[const SizedBox(width: 8), action],
      ],
    );
  }
}

class _VehicleFilterButton extends StatelessWidget {
  const _VehicleFilterButton({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final List<VehicleFilterOption> options;
  final String? selected;
  final ValueChanged<String?> onChanged;

  /// Falls back to the raw VIN if the picked vehicle has dropped out of the
  /// list, rather than silently reading "All Vehicle" while a filter is on.
  String get _selectedLabel {
    final vin = selected;
    if (vin == null) return 'All Vehicle';
    for (final option in options) {
      if (option.vin == vin) return option.label;
    }
    return vin;
  }

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
        _MenuItem(
          label: 'All Vehicle',
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        for (final option in options)
          _MenuItem(
            label: option.label,
            selected: selected == option.vin,
            onTap: () => onChanged(option.vin),
          ),
      ],
      builder: (context, controller, child) => AppActionButton(
        icon: Icons.local_shipping_outlined,
        label: _selectedLabel,
        trailingIcon: Icons.keyboard_arrow_down_rounded,
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
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
