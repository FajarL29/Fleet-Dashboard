import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/app_action_button.dart';
import '../common/app_search_field.dart';
import '../common/last_updated_label.dart';

/// Page title, last-updated line, fleet search and the page actions.
class LiveTrackingHeader extends StatelessWidget {
  const LiveTrackingHeader({
    super.key,
    required this.lastUpdated,
    required this.searchController,
    required this.vehiclePlates,
    required this.selectedVehicle,
    required this.onVehicleChanged,
    required this.isWide,
  });

  final DateTime lastUpdated;
  final TextEditingController searchController;
  final List<String> vehiclePlates;
  final String? selectedVehicle;
  final ValueChanged<String?> onVehicleChanged;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Live Tracking',
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
      _VehicleFilterButton(
        plates: vehiclePlates,
        selected: selectedVehicle,
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
        SizedBox(width: 245, child: search),
        for (final action in actions) ...[const SizedBox(width: 8), action],
      ],
    );
  }
}

class _VehicleFilterButton extends StatelessWidget {
  const _VehicleFilterButton({
    required this.plates,
    required this.selected,
    required this.onChanged,
  });

  final List<String> plates;
  final String? selected;
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
        _MenuItem(
          label: 'All Vehicles',
          selected: selected == null,
          onTap: () => onChanged(null),
        ),
        for (final plate in plates)
          _MenuItem(
            label: plate,
            selected: selected == plate,
            onTap: () => onChanged(plate),
          ),
      ],
      builder: (context, controller, child) => AppActionButton(
        icon: Icons.local_shipping_outlined,
        label: selected ?? 'Vehicle',
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
