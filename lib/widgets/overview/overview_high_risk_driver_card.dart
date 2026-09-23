import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/vehicle_status.dart';
import '../common/sortable_header.dart';
import 'overview_table_card.dart';
import '../../utils/app_navigation.dart';

/// "High-Risk Driver" table: the vehicles most in need of attention, ranked by
/// safety status, then display status, then how recently they reported.
class OverviewHighRiskDriverCard extends StatefulWidget {
  const OverviewHighRiskDriverCard({
    super.key,
    required this.vehicleStatusData,
    this.maxRows = 5,
  });

  final VehicleStatusData? vehicleStatusData;
  final int maxRows;

  static const List<int> _flex = [0, 3, 3, 3, 3];

  @override
  State<OverviewHighRiskDriverCard> createState() =>
      _OverviewHighRiskDriverCardState();
}

class _OverviewHighRiskDriverCardState
    extends State<OverviewHighRiskDriverCard> {
  /// Column index of Risk Level in the `headers` list below.
  static const int _riskColumn = 2;

  /// Null means "the page's own ranking": alert first, then status, then how
  /// recently the vehicle reported. Clicking the column takes over from it.
  ColumnSort<int>? _sort;

  @override
  Widget build(BuildContext context) {
    final rows = _buildRows();

    return OverviewTableCard(
      title: 'High-Risk Driver',
      onViewAll: () => openAppRoute(context, '/safety'),
      headers: const [
        OverviewTableColumn('No'),
        OverviewTableColumn('Vehicle'),
        OverviewTableColumn(
          'Risk Level',
          sortable: true,
          firstDirection: SortDirection.descending,
        ),
        OverviewTableColumn('Issue Summary'),
        OverviewTableColumn('Last Telemetry'),
      ],
      flex: OverviewHighRiskDriverCard._flex,
      sort: _sort,
      onSort: (next) => setState(() => _sort = next),
      emptyMessage: 'No driver risk data available',
      rowCount: rows.length,
      rowBuilder: (context, index) {
        final row = rows[index];
        return [
          OverviewTableText('${index + 1}', emphasis: true),
          OverviewTableText(row.vehicle, emphasis: true),
          Align(
            alignment: Alignment.centerLeft,
            child: OverviewSeverityPill(label: row.riskLevel),
          ),
          OverviewTableText(row.issue),
          OverviewTableText(row.lastTelemetry),
        ];
      },
    );
  }

  List<_Row> _buildRows() {
    final items =
        widget.vehicleStatusData?.vehicles ?? const <VehicleStatusItem>[];
    if (items.isEmpty) return const [];

    final ranked = List<VehicleStatusItem>.from(items)
      ..sort((a, b) {
        final alertCompare = _isAlert(b).compareTo(_isAlert(a));
        if (alertCompare != 0) return alertCompare;

        final statusCompare = _statusPriority(
          b.displayStatus,
        ).compareTo(_statusPriority(a.displayStatus));
        if (statusCompare != 0) return statusCompare;

        final seenCompare = (a.lastSeenMinutes ?? 1 << 30).compareTo(
          b.lastSeenMinutes ?? 1 << 30,
        );
        if (seenCompare != 0) return seenCompare;

        return a.driverName.compareTo(b.driverName);
      });

    // An explicit column sort overrides the default ranking entirely, so the
    // arrow means what it says rather than re-ordering within it.
    final sort = _sort;
    if (sort != null && sort.column == _riskColumn) {
      ranked.sort((a, b) {
        final comparison = _riskRank(a).compareTo(_riskRank(b));
        final result = sort.order(comparison);
        return result != 0 ? result : a.driverName.compareTo(b.driverName);
      });
    }

    return ranked.take(widget.maxRows).map((item) {
      final vehicleLabel = item.plateNumber.isNotEmpty
          ? item.plateNumber
          : (item.vehicleIdentificationNumber.isNotEmpty
                ? item.vehicleIdentificationNumber
                : item.vehicleId);

      return _Row(
        vehicle: vehicleLabel.isNotEmpty ? vehicleLabel : '-',
        riskLevel: _riskLabel(item),
        issue: item.statusReason.isNotEmpty
            ? item.statusReason
            : 'No issues detected',
        lastTelemetry: _lastSeenLabel(item),
      );
    }).toList();
  }

  int _isAlert(VehicleStatusItem item) =>
      item.safetyStatus.trim().toLowerCase() == 'alert' ? 1 : 0;

  int _statusPriority(String status) {
    switch (status.trim().toLowerCase()) {
      case 'alert':
        return 5;
      case 'warning':
        return 4;
      case 'moving':
      case 'idle':
      case 'online':
        return 3;
      case 'offline':
        return 1;
      default:
        return 2;
    }
  }

  int _riskRank(VehicleStatusItem item) {
    switch (_riskLabel(item)) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      default:
        return 1;
    }
  }

  String _riskLabel(VehicleStatusItem item) {
    final safetyStatus = item.safetyStatus.trim().toLowerCase();
    final displayStatus = item.displayStatus.trim().toLowerCase();

    if (safetyStatus == 'alert' || displayStatus == 'alert') return 'High';
    if (displayStatus == 'warning') return 'Medium';
    return 'Low';
  }

  String _lastSeenLabel(VehicleStatusItem item) {
    final minutes = item.lastSeenMinutes;
    if (minutes == null) {
      final time = item.lastTelemetryTime;
      return time == null ? '-' : DateFormat('HH.mm').format(time);
    }
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '$minutes min ago';
    final hours = minutes ~/ 60;
    if (hours < 24) return '$hours hr ago';
    return '${hours ~/ 24} d ago';
  }
}

class _Row {
  const _Row({
    required this.vehicle,
    required this.riskLevel,
    required this.issue,
    required this.lastTelemetry,
  });

  final String vehicle;
  final String riskLevel;
  final String issue;
  final String lastTelemetry;
}
