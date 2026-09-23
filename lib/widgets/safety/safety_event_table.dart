import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import '../../models/vehicle_status.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import '../common/app_pagination.dart';
import '../common/sortable_header.dart';
import 'safety_event_sort.dart';
import 'safety_severity_pill.dart';

/// Paginated safety events. Tapping a row drives the detail panel beside it.
class SafetyEventTable extends StatefulWidget {
  const SafetyEventTable({
    super.key,
    required this.pageEvents,
    required this.vehicles,
    required this.selectedEventId,
    this.vehicleTypes = const {},
    required this.onEventTap,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    required this.emptyMessage,
    required this.sort,
    required this.onSort,
  });

  final List<DrowsinessEvent> pageEvents;

  /// Used to resolve a plate from the event's VIN.
  final List<VehicleStatusItem> vehicles;

  /// Vehicle type per VIN, joined in from the registry when it is reachable.
  final Map<String, String> vehicleTypes;

  final int? selectedEventId;
  final ValueChanged<DrowsinessEvent> onEventTap;

  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final String emptyMessage;

  /// Sort applied to the whole filtered list, not just [pageEvents] — sorting
  /// one page at a time would only shuffle the rows you can already see.
  final ColumnSort<SafetyEventColumn> sort;
  final SortChanged<SafetyEventColumn> onSort;

  /// Time, Vehicle, VIN, Event Type, Severity, Speed, Location.
  static const List<int> _flex = [4, 4, 3, 4, 3, 3, 4];

  /// Below this the columns are cramped, so the table scrolls sideways
  /// instead of squeezing text into ellipses.
  static const double _minTableWidth = 900;

  @override
  State<SafetyEventTable> createState() => _SafetyEventTableState();
}

class _SafetyEventTableState extends State<SafetyEventTable> {
  final ScrollController _horizontalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Event List',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const minWidth = SafetyEventTable._minTableWidth;
              final width = constraints.maxWidth < minWidth
                  ? minWidth
                  : constraints.maxWidth;

              final table = SizedBox(
                width: width,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeaderRow(sort: widget.sort, onSort: widget.onSort),
                    if (widget.pageEvents.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 44),
                        child: Center(
                          child: Text(
                            widget.emptyMessage,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                    else
                      for (final event in widget.pageEvents)
                        _EventRow(
                          event: event,
                          vehicle: _vehicleFor(event),
                          vehicleType:
                              widget.vehicleTypes[event.vehicleId] ?? '-',
                          selected: event.id == widget.selectedEventId,
                          onTap: () => widget.onEventTap(event),
                        ),
                  ],
                ),
              );

              if (constraints.maxWidth >= SafetyEventTable._minTableWidth) {
                return table;
              }
              // Always-visible thumb: without it there is no hint that the
              // Location column is off to the right.
              return Scrollbar(
                controller: _horizontalController,
                thumbVisibility: true,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SingleChildScrollView(
                    controller: _horizontalController,
                    scrollDirection: Axis.horizontal,
                    child: table,
                  ),
                ),
              );
            },
          ),
          if (widget.pageCount > 1) ...[
            const SizedBox(height: 14),
            AppPagination(
              page: widget.page,
              pageCount: widget.pageCount,
              onPageChanged: widget.onPageChanged,
              alignment: MainAxisAlignment.start,
            ),
          ],
        ],
      ),
    );
  }

  VehicleStatusItem? _vehicleFor(DrowsinessEvent event) {
    for (final vehicle in widget.vehicles) {
      if (vehicle.vehicleIdentificationNumber == event.vehicleId ||
          vehicle.vehicleId == event.vehicleId ||
          vehicle.plateNumber == event.vehicleId) {
        return vehicle;
      }
    }
    return null;
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.sort, required this.onSort});

  final ColumnSort<SafetyEventColumn> sort;
  final SortChanged<SafetyEventColumn> onSort;

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
          for (var i = 0; i < SafetyEventColumn.values.length; i++)
            Expanded(
              flex: SafetyEventTable._flex[i],
              child: SafetyEventColumn.values[i].sortable
                  ? SortableHeader<SafetyEventColumn>(
                      label: SafetyEventColumn.values[i].label,
                      column: SafetyEventColumn.values[i],
                      sort: sort,
                      onSort: onSort,
                      firstDirection:
                          SafetyEventColumn.values[i].firstDirection,
                    )
                  : Text(
                      SafetyEventColumn.values[i].label,
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

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
    required this.vehicle,
    required this.vehicleType,
    required this.selected,
    required this.onTap,
  });

  final DrowsinessEvent event;
  final VehicleStatusItem? vehicle;
  final String vehicleType;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final local = event.time.toLocal();

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
              _StackedCell(
                flex: 0,
                title: DateFormat('MMM d, yyyy').format(local),
                subtitle: DateFormat('hh:mm:ss a').format(local),
              ),
              _StackedCell(
                flex: 1,
                title: (vehicle?.plateNumber.isNotEmpty ?? false)
                    ? vehicle!.plateNumber
                    : '-',
                subtitle: vehicleType,
              ),
              _TextCell(flex: 2, value: event.vehicleId),
              _TextCell(flex: 3, value: safetyEventTypeLabel(event)),
              Expanded(
                flex: SafetyEventTable._flex[4],
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SafetySeverityPill(riskLevel: event.riskLevel),
                ),
              ),
              _TextCell(flex: 5, value: safetySpeedLabel(event)),
              _TextCell(flex: 6, value: safetyLocationLabel(event)),
            ],
          ),
        ),
      ),
    );
  }
}

class _StackedCell extends StatelessWidget {
  const _StackedCell({
    required this.flex,
    required this.title,
    required this.subtitle,
  });

  final int flex;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: SafetyEventTable._flex[flex],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _TextCell extends StatelessWidget {
  const _TextCell({required this.flex, required this.value});

  final int flex;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: SafetyEventTable._flex[flex],
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
      ),
    );
  }
}

/// "one_hand_off_wheel" -> "One Hand Off Wheel".
String safetyEventTypeLabel(DrowsinessEvent event) {
  final raw = (event.behaviorType?.trim().isNotEmpty ?? false)
      ? event.behaviorType!
      : event.status;
  if (raw.trim().isEmpty) return '-';

  return raw
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map(
        (part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String safetySpeedLabel(DrowsinessEvent event) {
  final speed = event.speedAtEvent;
  if (speed == null) return '-';
  return '${speed.toStringAsFixed(0)} km/h';
}

String safetyLocationLabel(DrowsinessEvent event) {
  final latitude = event.latitude;
  final longitude = event.longitude;
  if (latitude == null || longitude == null) {
    final location = event.location?.trim();
    return (location == null || location.isEmpty) ? '-' : location;
  }
  return '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';
}
