import 'package:flutter/material.dart';

import '../../models/vehicle_management.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import '../common/app_pagination.dart';
import '../common/sortable_header.dart';
import 'vehicle_list_sort.dart';
import 'vehicle_status_pill.dart';

/// Paginated fleet table. Tapping a row drives the detail panel beside it.
class VehicleListCard extends StatelessWidget {
  const VehicleListCard({
    super.key,
    required this.pageVehicles,
    required this.shownCount,
    required this.totalCount,
    required this.selectedVehicleId,
    required this.onVehicleTap,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    required this.emptyMessage,
    required this.sort,
    required this.onSort,
  });

  final List<ManagedVehicle> pageVehicles;

  /// How many vehicles the current filter matches, out of the whole fleet.
  final int shownCount;
  final int totalCount;

  final String? selectedVehicleId;
  final ValueChanged<ManagedVehicle> onVehicleTap;

  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final String emptyMessage;

  /// Sort applied to every matching vehicle, not just the page on screen.
  final ColumnSort<VehicleListColumn> sort;
  final SortChanged<VehicleListColumn> onSort;

  static const List<int> _flex = [4, 3, 3, 3];

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Vehicle List',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              Text(
                '$shownCount of $totalCount vehicles',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _HeaderRow(flex: _flex, sort: sort, onSort: onSort),
          if (pageVehicles.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            for (final vehicle in pageVehicles)
              _VehicleRow(
                vehicle: vehicle,
                selected: vehicle.vehicleId == selectedVehicleId,
                onTap: () => onVehicleTap(vehicle),
              ),
          if (pageCount > 1) ...[
            const SizedBox(height: 14),
            AppPagination(
              page: page,
              pageCount: pageCount,
              onPageChanged: onPageChanged,
              alignment: MainAxisAlignment.start,
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.flex,
    required this.sort,
    required this.onSort,
  });

  final List<int> flex;
  final ColumnSort<VehicleListColumn> sort;
  final SortChanged<VehicleListColumn> onSort;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.tileBackground,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          for (var i = 0; i < VehicleListColumn.values.length; i++)
            Expanded(
              flex: flex[i],
              child: VehicleListColumn.values[i].sortable
                  ? SortableHeader<VehicleListColumn>(
                      label: VehicleListColumn.values[i].label,
                      column: VehicleListColumn.values[i],
                      sort: sort,
                      onSort: onSort,
                      firstDirection:
                          VehicleListColumn.values[i].firstDirection,
                    )
                  : Text(
                      VehicleListColumn.values[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

class _VehicleRow extends StatelessWidget {
  const _VehicleRow({
    required this.vehicle,
    required this.selected,
    required this.onTap,
  });

  final ManagedVehicle vehicle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.blueSoft : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: AppColors.tileBackground,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: VehicleListCard._flex[0],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      vehicle.plateNumber.isEmpty ? '-' : vehicle.plateNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vehicle.vehicleType.isEmpty ? '-' : vehicle.vehicleType,
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
              Expanded(
                flex: VehicleListCard._flex[1],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: VehicleStatusPill(vehicle: vehicle),
                ),
              ),
              Expanded(
                flex: VehicleListCard._flex[2],
                child: Text(
                  vehicle.vin.isEmpty ? '-' : vehicle.vin,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
              Expanded(
                flex: VehicleListCard._flex[3],
                child: Text(
                  vehicle.lastSeenLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
