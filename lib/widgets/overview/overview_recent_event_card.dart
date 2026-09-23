import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import '../../models/vehicle.dart';
import '../common/sortable_header.dart';
import 'overview_table_card.dart';
import '../../utils/app_navigation.dart';

/// "Recent Event" table: the latest safety events of the day.
class OverviewRecentEventCard extends StatefulWidget {
  const OverviewRecentEventCard({
    super.key,
    required this.events,
    required this.vehicles,
    this.maxRows = 5,
  });

  /// Safety events recorded today, newest first.
  final List<DrowsinessEvent> events;
  final List<Vehicle> vehicles;
  final int maxRows;

  static const List<int> _flex = [2, 3, 3, 2];

  @override
  State<OverviewRecentEventCard> createState() =>
      _OverviewRecentEventCardState();
}

class _OverviewRecentEventCardState extends State<OverviewRecentEventCard> {
  /// Column indices that can be sorted, matching the `headers` list below.
  static const int _timeColumn = 0;
  static const int _severityColumn = 3;

  ColumnSort<int> _sort = const ColumnSort(
    _timeColumn,
    SortDirection.descending,
  );

  @override
  Widget build(BuildContext context) {
    // Sort the events, then take the top rows: trimming first would sort only
    // whichever five happened to arrive most recently.
    final ordered = _sorted(widget.events);
    final rows = ordered.take(widget.maxRows).map(_mapRow).toList();

    return OverviewTableCard(
      title: 'Recent Event',
      onViewAll: () => openAppRoute(context, '/safety'),
      headers: const [
        OverviewTableColumn(
          'Time',
          sortable: true,
          firstDirection: SortDirection.descending,
        ),
        OverviewTableColumn('Vehicle'),
        OverviewTableColumn('Event'),
        OverviewTableColumn(
          'Severity',
          sortable: true,
          firstDirection: SortDirection.descending,
        ),
      ],
      flex: OverviewRecentEventCard._flex,
      sort: _sort,
      onSort: (next) => setState(() => _sort = next),
      emptyMessage: 'No safety events recorded today',
      rowCount: rows.length,
      rowBuilder: (context, index) {
        final row = rows[index];
        return [
          OverviewTableText(row.time, emphasis: true),
          OverviewTableText(row.vehicle, emphasis: true),
          OverviewTableText(row.event, emphasis: true),
          Align(
            alignment: Alignment.centerLeft,
            child: OverviewSeverityPill(label: row.severity),
          ),
        ];
      },
    );
  }

  _Row _mapRow(DrowsinessEvent event) {
    return _Row(
      time: DateFormat('HH.mm').format(event.time),
      vehicle: _vehicleFor(event)?.plateNumber ?? event.vehicleId,
      event: _eventLabel(event),
      severity: _severityLabel(event.riskLevel),
    );
  }

  /// Ranks severity by danger; a text sort would put "high" after "low".
  static int _severityRank(String risk) {
    switch (risk.trim().toLowerCase()) {
      case 'high':
      case 'critical':
        return 3;
      case 'medium':
        return 2;
      default:
        return 1;
    }
  }

  List<DrowsinessEvent> _sorted(List<DrowsinessEvent> events) {
    final sorted = List<DrowsinessEvent>.from(events);
    sorted.sort((a, b) {
      final comparison = _sort.column == _severityColumn
          ? _severityRank(a.riskLevel).compareTo(_severityRank(b.riskLevel))
          : a.time.compareTo(b.time);
      final result = _sort.order(comparison);
      return result != 0 ? result : b.time.compareTo(a.time);
    });
    return sorted;
  }

  Vehicle? _vehicleFor(DrowsinessEvent event) {
    for (final vehicle in widget.vehicles) {
      if (vehicle.id == event.vehicleId ||
          vehicle.plateNumber == event.vehicleId ||
          vehicle.apiVehicleId == event.vehicleId) {
        return vehicle;
      }
    }
    return null;
  }

  String _eventLabel(DrowsinessEvent event) {
    final raw = (event.behaviorType?.isNotEmpty ?? false)
        ? event.behaviorType!
        : event.status;
    if (raw.trim().isEmpty) return 'Safety Event';

    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _severityLabel(String risk) {
    final normalized = risk.trim().toLowerCase();
    if (normalized == 'high') return 'High';
    if (normalized == 'medium') return 'Medium';
    return 'Low';
  }
}

class _Row {
  const _Row({
    required this.time,
    required this.vehicle,
    required this.event,
    required this.severity,
  });

  final String time;
  final String vehicle;
  final String event;
  final String severity;
}
