import 'package:flutter/material.dart';

import '../../models/vehicle_status.dart';
import 'live_tracking_status.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import '../common/app_pagination.dart';

/// Vehicle list beside the map: status filter chips, one paginated page of
/// vehicles, and the pager.
class LiveTrackingVehicleDetailPanel extends StatelessWidget {
  const LiveTrackingVehicleDetailPanel({
    super.key,
    required this.pageVehicles,
    required this.counts,
    required this.totalCount,
    required this.activeFilter,
    required this.onFilterChanged,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    required this.selectedVehicleKey,
    required this.onVehicleTap,
    required this.vehicleTypes,
    required this.emptyMessage,
  });

  /// Vehicles on the current page, already filtered and searched.
  final List<VehicleStatusItem> pageVehicles;

  /// How many vehicles fall into each bucket, across the whole fleet.
  final Map<LiveTrackingStatus, int> counts;
  final int totalCount;

  /// Active chip, or null for "All".
  final LiveTrackingStatus? activeFilter;
  final ValueChanged<LiveTrackingStatus?> onFilterChanged;

  /// Zero-based page index.
  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  final String? selectedVehicleKey;
  final ValueChanged<VehicleStatusItem> onVehicleTap;

  /// Vehicle type per vehicle key, joined in from the vehicle registry.
  final Map<String, String> vehicleTypes;

  final String emptyMessage;

  static const List<LiveTrackingStatus> _chipOrder = [
    LiveTrackingStatus.moving,
    LiveTrackingStatus.idle,
    LiveTrackingStatus.emergency,
    LiveTrackingStatus.offline,
  ];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Vehicle Detail',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 3,
            runSpacing: 6,
            children: [
              _FilterChip(
                label: 'All ($totalCount)',
                selected: activeFilter == null,
                onTap: () => onFilterChanged(null),
              ),
              for (final status in _chipOrder)
                _FilterChip(
                  label: '${status.label} (${counts[status] ?? 0})',
                  selected: activeFilter == status,
                  onTap: () => onFilterChanged(status),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: pageVehicles.isEmpty
                ? Center(
                    child: Text(
                      emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: pageVehicles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = pageVehicles[index];
                      final key = liveTrackingVehicleKey(item);
                      return _VehicleTile(
                        plate: liveTrackingPlateLabel(item),
                        type: vehicleTypes[key] ?? '-',
                        status: liveTrackingStatusOf(item),
                        selected: key.isNotEmpty && key == selectedVehicleKey,
                        onTap: () => onVehicleTap(item),
                      );
                    },
                  ),
          ),
          if (pageCount > 1) ...[
            const SizedBox(height: 12),
            AppPagination(
              page: page,
              pageCount: pageCount,
              onPageChanged: onPageChanged,
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.navy : AppColors.tileBackground,
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.tileBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _VehicleTile extends StatelessWidget {
  const _VehicleTile({
    required this.plate,
    required this.type,
    required this.status,
    required this.selected,
    required this.onTap,
  });

  final String plate;
  final String type;
  final LiveTrackingStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: AppColors.tileBackground,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? AppColors.blue : AppColors.cardBorder,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      plate,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      type,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              _StatusPill(status: status),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final LiveTrackingStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 26,
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: status.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            status.label,
            style: TextStyle(
              color: status.textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
