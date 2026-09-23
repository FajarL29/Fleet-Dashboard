import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../common/app_action_button.dart';
import '../common/app_search_field.dart';
import '../common/last_updated_label.dart';

/// Page title, last-updated line, fleet search and the page actions.
class VehicleManagementHeader extends StatelessWidget {
  const VehicleManagementHeader({
    super.key,
    required this.lastUpdated,
    required this.searchController,
    this.onAddVehicle,
    required this.isWide,
  });

  final DateTime lastUpdated;
  final TextEditingController searchController;

  /// Null hides the button: a read-only role should not see a control it
  /// cannot use.
  final VoidCallback? onAddVehicle;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Vehicle Management',
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
      if (onAddVehicle != null)
        AppActionButton(
          icon: Icons.add_rounded,
          label: 'Add Vehicle',
          onPressed: onAddVehicle,
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
