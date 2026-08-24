import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../models/driver_behavior_summary.dart';
import '../../models/drowsiness_report.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_status.dart';
import 'overview_skeleton_loading.dart';
import 'overview_monitoring_summary.dart';
import '../map_section.dart';
import '../report/report_styles.dart';

class OverviewDashboard extends StatelessWidget {
  const OverviewDashboard({
    super.key,
    required this.mapController,
    required this.vehicles,
    required this.selectedVehicle,
    required this.driverAlerts,
    required this.alertLog,
    required this.recentDrowsinessEvents,
    required this.currentDrowsinessReport,
    required this.driverBehaviorSummaries,
    required this.vehicleStatusData,
    required this.vehicleStatusError,
    required this.onVehicleSelected,
    required this.onClearSelection,
    required this.onFollowModeChanged,
    required this.onOpenMapFullscreen,
    this.isLoading = false,
  });

  final MapController mapController;
  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final Map<int, Map<String, dynamic>> driverAlerts;
  final List<String> alertLog;
  final List<DrowsinessEvent> recentDrowsinessEvents;
  final DrowsinessReport? currentDrowsinessReport;
  final List<DriverBehaviorSummary> driverBehaviorSummaries;
  final VehicleStatusData? vehicleStatusData;
  final String? vehicleStatusError;
  final ValueChanged<Vehicle> onVehicleSelected;
  final VoidCallback onClearSelection;
  final ValueChanged<bool> onFollowModeChanged;
  final VoidCallback onOpenMapFullscreen;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasOverviewData =
        vehicleStatusData != null ||
        currentDrowsinessReport != null ||
        recentDrowsinessEvents.isNotEmpty ||
        driverBehaviorSummaries.isNotEmpty;

    if (isLoading && !hasOverviewData) {
      return const OverviewDashboardSkeleton();
    }

    final overviewData = _buildOverviewData();

    final dashboard = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF05111F), Color(0xFF071427)],
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final useWideHeader = width >= 960;
            final kpiPerRow = width >= 1000
                ? 4
                : width >= 700
                ? 2
                : 1;
            final useTwoColumns = width >= 1000;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OverviewHeader(
                  lastUpdatedLabel: overviewData.lastUpdatedLabel,
                  healthLabel: overviewData.fleetHealthLabel,
                  healthColor: overviewData.fleetHealthColor,
                  healthIcon: overviewData.fleetHealthIcon,
                  useWideLayout: useWideHeader,
                ),
                const SizedBox(height: 10),
                const _SectionLabel('FLEET SUMMARY'),
                const SizedBox(height: 6),
                _KpiGrid(
                  perRow: kpiPerRow,
                  children: _buildKpiCards(overviewData),
                ),
                const SizedBox(height: 10),
                _SelectedVehicleHeader(
                  vehicles: vehicles,
                  selectedVehicle: selectedVehicle,
                  onVehicleSelected: (vehicle) {
                    debugPrint(
                      '[OverviewSelection] source=selector vehicle_id=${vehicle.id}',
                    );
                    onVehicleSelected(vehicle);
                  },
                ),
                const SizedBox(height: 10),
                _SelectedVehicleCards(
                  vehicle: selectedVehicle,
                  data: overviewData,
                ),
                const SizedBox(height: 30),
                if (useTwoColumns)
                  Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 11,
                            child: _LiveMapCard(
                              map: _buildMapContent(),
                              hasVehicleData: vehicles.isNotEmpty,
                              mapStateMessage: overviewData.mapStateMessage,
                              onViewFullMap: onOpenMapFullscreen,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 10,
                            child: _VehicleRiskRankingCard(
                              vehicles: overviewData.rankedVehicles,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SafetySnapshotCard(data: overviewData),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RecentEventsCard(
                              recentLog: overviewData.recentLog,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _RecentStatusLogCard(
                              entries: overviewData.statusLog,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                else
                  Column(
                    children: [
                      _LiveMapCard(
                        map: _buildMapContent(),
                        hasVehicleData: vehicles.isNotEmpty,
                        mapStateMessage: overviewData.mapStateMessage,
                        onViewFullMap: onOpenMapFullscreen,
                      ),
                      const SizedBox(height: 8),
                      _VehicleRiskRankingCard(
                        vehicles: overviewData.rankedVehicles,
                      ),
                      const SizedBox(height: 16),
                      _SafetySnapshotCard(data: overviewData),
                      const SizedBox(height: 16),
                      _RecentEventsCard(recentLog: overviewData.recentLog),
                      const SizedBox(height: 8),
                      _RecentStatusLogCard(entries: overviewData.statusLog),
                    ],
                  ),
              ],
            );
          },
        ),
      ),
    );

    if (!isLoading) {
      return dashboard;
    }

    return Stack(
      children: [
        AbsorbPointer(
          absorbing: true,
          child: AnimatedOpacity(
            opacity: 0.62,
            duration: const Duration(milliseconds: 180),
            child: dashboard,
          ),
        ),
        const IgnorePointer(child: OverviewDashboardSkeleton(overlay: true)),
      ],
    );
  }

  Widget _buildMapContent() {
    if (vehicles.isEmpty) {
      return const _MapUnavailableState();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: MapSection(
        mapController: mapController,
        vehicles: vehicles,
        isFullScreen: false,
        onFullScreenToggle: onOpenMapFullscreen,
        showVehicleList: false,
        selectedVehicleId: selectedVehicle?.id,
        onVehicleSelected: (vehicle) {
          debugPrint('[OverviewSelection] source=map vehicle_id=${vehicle.id}');
          onVehicleSelected(vehicle);
        },
        onClearSelection: onClearSelection,
        onFollowModeChanged: onFollowModeChanged,
      ),
    );
  }

  List<Widget> _buildKpiCards(_OverviewData data) {
    final totalVehicles = data.totalVehicles;
    final onlinePercent = totalVehicles == 0
        ? 0
        : ((data.onlineVehicles / totalVehicles) * 100).round();

    return [
      _CompactKpiCard(
        title: 'Fleet Online',
        value: data.hasVehicleStatus
            ? '${data.onlineVehicles} / $totalVehicles'
            : 'Unavailable',
        subtitle: data.hasVehicleStatus
            ? (totalVehicles == 0
                  ? 'No vehicles available'
                  : '$onlinePercent% available')
            : (data.vehicleStatusMessage ?? 'Vehicle status unavailable'),
        icon: Icons.local_shipping_rounded,
        accentColor: ReportStyles.green,
        trailing: _RingPercent(
          percent: data.hasVehicleStatus ? onlinePercent : 0,
          color: ReportStyles.green,
        ),
      ),
      _CompactKpiCard(
        title: 'Offline Vehicles',
        value: data.hasVehicleStatus
            ? '${data.offlineVehicles}'
            : 'Unavailable',
        subtitle: data.offlineVehicles > 0
            ? 'No live telemetry'
            : 'All vehicles reporting',
        icon: Icons.cloud_off_outlined,
        accentColor: ReportStyles.textMuted,
      ),
      _CompactKpiCard(
        title: 'Safety Events Today',
        value: '${data.safetyEventCount}',
        subtitle: 'Total events',
        icon: Icons.shield_outlined,
        accentColor: ReportStyles.orange,
        trailing: _SafetyEventBreakdown(data: data),
      ),
      _CompactKpiCard(
        title: 'Vehicles at Risk',
        value: data.hasVehicleStatus
            ? '${data.highRiskDriverCount}'
            : 'Unavailable',
        subtitle: data.riskSubtitle,
        icon: Icons.local_shipping_outlined,
        accentColor: ReportStyles.purple,
        footer: _StatusPill(
          label: data.highRiskDriverCount > 0 ? 'Need attention' : 'No flags',
          color: data.highRiskDriverCount > 0
              ? ReportStyles.red
              : ReportStyles.textMuted,
        ),
      ),
    ];
  }

  _OverviewData _buildOverviewData() {
    final now = DateTime.now();
    final vehicleItems =
        vehicleStatusData?.vehicles ?? const <VehicleStatusItem>[];
    final summary = vehicleStatusData?.summary;
    final todayEvents =
        recentDrowsinessEvents
            .where((event) => _isSameDay(event.time, now))
            .toList()
          ..sort((a, b) => b.time.compareTo(a.time));

    final behaviorByName = _buildBehaviorCountMap(todayEvents);
    final rankedVehicles = _buildRankedVehicles();
    final recentLog = todayEvents.take(3).map(_mapRecentLog).toList();
    final totalVehicles = summary?.totalVehicles ?? vehicleItems.length;
    final onlineVehicles = summary?.onlineVehicles ?? 0;
    final offlineVehicles =
        summary?.offline ??
        vehicleItems
            .where((item) => item.displayStatus.toLowerCase() == 'offline')
            .length;
    final highRiskDriverCount =
        summary?.alert ??
        vehicleItems
            .where((item) => item.safetyStatus.trim().toLowerCase() == 'alert')
            .length;
    final warningCount =
        summary?.warning ??
        vehicleItems
            .where(
              (item) => item.displayStatus.trim().toLowerCase() == 'warning',
            )
            .length;
    final snapshotMax = [
      behaviorByName['drowsy'] ?? 0,
      behaviorByName['yawn'] ?? 0,
      behaviorByName['distraction'] ?? 0,
      behaviorByName['one_hand_off_wheel'] ?? 0,
    ].fold<int>(0, math.max);
    final safetyEventCount = behaviorByName.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );
    final hasVehicleStatus = vehicleStatusData != null;
    final riskSubtitle = !hasVehicleStatus
        ? (vehicleStatusError ?? 'Awaiting vehicle status')
        : highRiskDriverCount == 0
        ? 'No vehicles currently flagged'
        : '$highRiskDriverCount vehicle${highRiskDriverCount == 1 ? '' : 's'} need attention';
    final mapStateMessage = vehicleStatusError != null && !hasVehicleStatus
        ? vehicleStatusError!
        : vehicleItems.isEmpty
        ? 'Vehicle status data unavailable'
        : vehicles.isEmpty
        ? 'No vehicle coordinates available'
        : null;
    final fleetHealthLabel =
        highRiskDriverCount > 0 || warningCount > 0 || safetyEventCount > 0
        ? 'ATTENTION REQUIRED'
        : !hasVehicleStatus || totalVehicles == 0 || offlineVehicles > 0
        ? 'LIVE DATA LIMITED'
        : 'NORMAL';
    final fleetHealthColor = highRiskDriverCount > 0 || safetyEventCount > 0
        ? ReportStyles.red
        : warningCount > 0
        ? ReportStyles.yellow
        : !hasVehicleStatus || totalVehicles == 0 || offlineVehicles > 0
        ? ReportStyles.textMuted
        : ReportStyles.green;
    final fleetHealthIcon =
        highRiskDriverCount > 0 || warningCount > 0 || safetyEventCount > 0
        ? Icons.warning_rounded
        : !hasVehicleStatus || totalVehicles == 0 || offlineVehicles > 0
        ? Icons.cloud_off_outlined
        : Icons.check_rounded;

    return _OverviewData(
      totalVehicles: totalVehicles,
      onlineVehicles: onlineVehicles,
      offlineVehicles: offlineVehicles,
      drowsyCount: behaviorByName['drowsy'] ?? 0,
      yawnCount: behaviorByName['yawn'] ?? 0,
      distractionCount: behaviorByName['distraction'] ?? 0,
      safetyEventCount: safetyEventCount,
      snapshotRows: [
        _SnapshotRowData(
          icon: Icons.mood_bad_rounded,
          label: 'Drowsy',
          count: behaviorByName['drowsy'] ?? 0,
          progress: _snapshotProgress(
            behaviorByName['drowsy'] ?? 0,
            snapshotMax,
          ),
        ),
        _SnapshotRowData(
          icon: Icons.sentiment_dissatisfied_rounded,
          label: 'Yawn',
          count: behaviorByName['yawn'] ?? 0,
          progress: _snapshotProgress(behaviorByName['yawn'] ?? 0, snapshotMax),
        ),
        _SnapshotRowData(
          icon: Icons.phonelink_lock_rounded,
          label: 'Distraction',
          count: behaviorByName['distraction'] ?? 0,
          progress: _snapshotProgress(
            behaviorByName['distraction'] ?? 0,
            snapshotMax,
          ),
        ),
        _SnapshotRowData(
          icon: Icons.pan_tool_rounded,
          label: 'One Hand Off Wheel',
          count: behaviorByName['one_hand_off_wheel'] ?? 0,
          progress: _snapshotProgress(
            behaviorByName['one_hand_off_wheel'] ?? 0,
            snapshotMax,
          ),
        ),
      ],
      hasVehicleStatus: hasVehicleStatus,
      vehicleStatusMessage: vehicleStatusError,
      highRiskDriverCount: highRiskDriverCount,
      rankedVehicles: rankedVehicles,
      riskSubtitle: riskSubtitle,
      recentLog: recentLog,
      statusLog: _buildStatusLog(
        totalVehicles,
        onlineVehicles,
        offlineVehicles,
      ),
      mapStateMessage: mapStateMessage,
      fleetHealthLabel: fleetHealthLabel,
      fleetHealthColor: fleetHealthColor,
      fleetHealthIcon: fleetHealthIcon,
      lastUpdatedLabel: _wibTime(now),
    );
  }

  List<String> _buildStatusLog(int total, int online, int offline) {
    if (vehicleStatusData == null) {
      return [vehicleStatusError ?? 'Fleet status data unavailable'];
    }
    return [
      '$total fleet vehicles loaded',
      '$online reporting live telemetry',
      if (offline > 0) '$offline vehicles currently offline',
    ];
  }

  Map<String, int> _buildBehaviorCountMap(List<DrowsinessEvent> events) {
    final counts = <String, int>{
      'drowsy': 0,
      'yawn': 0,
      'distraction': 0,
      'one_hand_off_wheel': 0,
    };

    for (final event in events) {
      final behavior = _normalizeBehavior(event);
      if (behavior == null) {
        continue;
      }
      counts[behavior] = (counts[behavior] ?? 0) + 1;
    }

    final report = currentDrowsinessReport;
    if (report != null) {
      for (final summary in report.weekdayBehaviorSummary) {
        if (summary.weekdayIndex != DateTime.now().weekday) {
          continue;
        }

        counts['drowsy'] = math.max(
          counts['drowsy'] ?? 0,
          summary.behaviors.drowsiness,
        );
        counts['yawn'] = math.max(counts['yawn'] ?? 0, summary.behaviors.yawn);
        counts['distraction'] = math.max(
          counts['distraction'] ?? 0,
          summary.behaviors.distraction,
        );
        counts['one_hand_off_wheel'] = math.max(
          counts['one_hand_off_wheel'] ?? 0,
          summary.behaviors.other,
        );
      }
    }

    return counts;
  }

  String? _normalizeBehavior(DrowsinessEvent event) {
    final raw = '${event.behaviorType ?? ''} ${event.status}'.toLowerCase();
    if (raw.contains('drows')) return 'drowsy';
    if (raw.contains('yawn')) return 'yawn';
    if (raw.contains('distraction')) return 'distraction';
    if (raw.contains('one_hand_off_wheel') ||
        raw.contains('one hand off wheel') ||
        raw.contains('hands_off') ||
        raw.contains('hand off wheel')) {
      return 'one_hand_off_wheel';
    }
    return null;
  }

  List<Map<String, String>> _buildRankedVehicles() {
    final items = vehicleStatusData?.vehicles ?? const <VehicleStatusItem>[];
    if (items.isEmpty) {
      return const [];
    }

    final ranked = List<VehicleStatusItem>.from(items)
      ..sort((a, b) {
        final alertCompare = _isAlertVehicle(b).compareTo(_isAlertVehicle(a));
        if (alertCompare != 0) {
          return alertCompare;
        }

        final statusCompare = _vehicleStatusPriority(
          b.displayStatus,
        ).compareTo(_vehicleStatusPriority(a.displayStatus));
        if (statusCompare != 0) {
          return statusCompare;
        }

        final seenCompare = (a.lastSeenMinutes ?? 1 << 30).compareTo(
          b.lastSeenMinutes ?? 1 << 30,
        );
        if (seenCompare != 0) {
          return seenCompare;
        }

        return a.driverName.compareTo(b.driverName);
      });

    return ranked.take(3).map((item) {
      final vehicleLabel = item.plateNumber.isNotEmpty
          ? item.plateNumber
          : (item.vehicleIdentificationNumber.isNotEmpty
                ? item.vehicleIdentificationNumber
                : item.vehicleId);

      return {
        'vehicle': vehicleLabel.isNotEmpty ? vehicleLabel : '-',
        'risk': _vehicleRiskLabel(item),
        'issue': _vehicleIssue(item),
        'telemetry': _telemetryAge(item.lastSeenMinutes),
      };
    }).toList();
  }

  Map<String, String> _mapRecentLog(DrowsinessEvent event) {
    final vehicle = _vehicleForEvent(event);
    return {
      'time': _wibTime(event.time),
      'type': _eventLabel(event),
      'description': _eventDescription(event),
      'vehicle': vehicle?.plateNumber ?? event.vehicleId,
      'severity': _severityLabel(event.riskLevel),
    };
  }

  String _eventDescription(DrowsinessEvent event) {
    final label = _eventLabel(event).toLowerCase();
    return label == 'safety event'
        ? 'Safety event received'
        : '$label detected';
  }

  String _vehicleIssue(VehicleStatusItem item) {
    if (item.lastSeenMinutes == null) return 'No Live Data';
    if (item.lastSeenMinutes! > 15) return 'Stale Telemetry';
    if (item.safetyStatus.trim().toLowerCase() == 'alert')
      return 'Safety Alert';
    return item.statusReason.trim().isEmpty
        ? 'No issue reported'
        : item.statusReason;
  }

  String _telemetryAge(int? minutes) {
    if (minutes == null) return 'No data';
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '$minutes min ago';
    if (minutes < 1440) return '${minutes ~/ 60} hr ago';
    return '${minutes ~/ 1440} days ago';
  }

  Vehicle? _vehicleForEvent(DrowsinessEvent event) {
    for (final vehicle in vehicles) {
      if (vehicle.id == event.vehicleId ||
          vehicle.plateNumber == event.vehicleId ||
          vehicle.apiVehicleId == event.vehicleId) {
        return vehicle;
      }
    }
    return null;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }

  String _severityLabel(String risk) {
    final normalized = risk.trim().toLowerCase();
    if (normalized == 'high') return 'High';
    if (normalized == 'medium') return 'Medium';
    return 'Low';
  }

  String _eventLabel(DrowsinessEvent event) {
    final raw = (event.behaviorType?.isNotEmpty ?? false)
        ? event.behaviorType!
        : event.status;
    if (raw.trim().isEmpty) {
      return 'Safety Event';
    }

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

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  String _wibTime(DateTime value) {
    final wib = value.toUtc().add(const Duration(hours: 7));
    return '${_twoDigits(wib.hour)}:${_twoDigits(wib.minute)} WIB';
  }

  int _isAlertVehicle(VehicleStatusItem item) {
    return item.safetyStatus.trim().toLowerCase() == 'alert' ? 1 : 0;
  }

  int _vehicleStatusPriority(String status) {
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

  String _vehicleRiskLabel(VehicleStatusItem item) {
    final safetyStatus = item.safetyStatus.trim().toLowerCase();
    final displayStatus = item.displayStatus.trim().toLowerCase();

    if (safetyStatus == 'alert' || displayStatus == 'alert') {
      return 'High';
    }

    if (displayStatus == 'warning') {
      return 'Medium';
    }

    if (displayStatus == 'offline') return 'Unavailable';

    return 'Low';
  }

  double _snapshotProgress(int count, int maxCount) {
    if (count <= 0 || maxCount <= 0) {
      return 0;
    }
    return (count / maxCount).clamp(0, 1).toDouble();
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader({
    required this.lastUpdatedLabel,
    required this.healthLabel,
    required this.healthColor,
    required this.healthIcon,
    required this.useWideLayout,
  });

  final String lastUpdatedLabel;
  final String healthLabel;
  final Color healthColor;
  final IconData healthIcon;
  final bool useWideLayout;

  @override
  Widget build(BuildContext context) {
    final statusCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: healthColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: healthColor.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: healthColor),
            ),
            child: Icon(healthIcon, color: healthColor, size: 18),
          ),
          const SizedBox(width: 10),
          Text(
            healthLabel,
            style: TextStyle(
              color: healthColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final timestamp = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.access_time_rounded,
          color: ReportStyles.textMuted,
          size: 16,
        ),
        const SizedBox(width: 6),
        Text(
          'Last updated: $lastUpdatedLabel',
          style: const TextStyle(
            color: ReportStyles.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );

    if (useWideLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fleet Management Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Real-time visibility of fleet safety, vehicle status, and driver wellbeing.',
                  style: TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [statusCard, const SizedBox(height: 8), timestamp],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fleet Management Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Real-time visibility of fleet safety, vehicle status, and driver wellbeing.',
          style: TextStyle(color: ReportStyles.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        statusCard,
        const SizedBox(height: 8),
        timestamp,
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: ReportStyles.textMuted,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );
}

class _SelectedVehicleHeader extends StatelessWidget {
  const _SelectedVehicleHeader({
    required this.vehicles,
    required this.selectedVehicle,
    required this.onVehicleSelected,
  });

  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final ValueChanged<Vehicle> onVehicleSelected;

  @override
  Widget build(BuildContext context) {
    final index = selectedVehicle == null
        ? -1
        : vehicles.indexWhere((vehicle) => vehicle.id == selectedVehicle!.id);
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.borderStrong),
      ),
      child: Row(
        children: [
          const _SectionLabel('SELECTED VEHICLE'),
          const SizedBox(width: 10),
          Expanded(
            child: _OverviewVehicleSelector(
              vehicles: vehicles,
              selectedVehicle: selectedVehicle,
              onSelected: onVehicleSelected,
            ),
          ),
          if (index >= 0) ...[
            const SizedBox(width: 14),
            Text(
              'Mapped Vehicle ${index + 1} of ${vehicles.length}',
              style: const TextStyle(
                color: ReportStyles.textMuted,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 7),
            _VehicleNavButton(
              icon: Icons.chevron_left_rounded,
              enabled: vehicles.length > 1,
              onPressed: () => onVehicleSelected(
                vehicles[(index - 1 + vehicles.length) % vehicles.length],
              ),
            ),
            const SizedBox(width: 5),
            _VehicleNavButton(
              icon: Icons.chevron_right_rounded,
              enabled: vehicles.length > 1,
              onPressed: () =>
                  onVehicleSelected(vehicles[(index + 1) % vehicles.length]),
            ),
          ],
        ],
      ),
    );
  }
}

class _VehicleNavButton extends StatelessWidget {
  const _VehicleNavButton({
    required this.icon,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 28,
    height: 28,
    child: IconButton(
      padding: EdgeInsets.zero,
      onPressed: enabled ? onPressed : null,
      icon: Icon(icon, size: 18),
      color: Colors.white,
      disabledColor: ReportStyles.textFaint,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.04),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
      ),
    ),
  );
}

class _SelectedVehicleCards extends StatelessWidget {
  const _SelectedVehicleCards({required this.vehicle, required this.data});

  final Vehicle? vehicle;
  final _OverviewData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final first = _VehicleStatusCard(vehicle: vehicle);
        final second = _DriverSafetyCard(data: data);
        final monitoring = OverviewMonitoringSummary(vehicle: vehicle);
        if (constraints.maxWidth >= 1000) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              const SizedBox(width: 12),
              Expanded(child: second),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: monitoring),
            ],
          );
        }
        return Column(
          children: [
            Row(
              children: [
                Expanded(child: first),
                const SizedBox(width: 12),
                Expanded(child: second),
              ],
            ),
            const SizedBox(height: 12),
            monitoring,
          ],
        );
      },
    );
  }
}

class _VehicleStatusCard extends StatelessWidget {
  const _VehicleStatusCard({required this.vehicle});

  final Vehicle? vehicle;

  @override
  Widget build(BuildContext context) {
    final item = vehicle;
    if (item == null)
      return const _SelectedDataCard(
        title: 'Vehicle Status',
        icon: Icons.bar_chart_rounded,
        child: Text(
          'No vehicle selected',
          style: TextStyle(color: ReportStyles.textMuted),
        ),
      );
    final stale =
        item.statusLabel.toLowerCase() == 'offline' ||
        item.lastSeenMinutes == null ||
        item.lastSeenMinutes! > 15;
    return _SelectedDataCard(
      title: 'Vehicle Status',
      icon: Icons.bar_chart_rounded,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: (stale ? ReportStyles.textMuted : ReportStyles.green)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color:
                          (stale ? ReportStyles.textMuted : ReportStyles.green)
                              .withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    item.statusLabel.toUpperCase(),
                    style: TextStyle(
                      color: stale
                          ? ReportStyles.textSecondary
                          : ReportStyles.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                _StatusDetail(
                  label: 'Last telemetry',
                  value: _freshness(item.lastSeenMinutes),
                ),
                _StatusDetail(
                  label: stale ? 'Last recorded speed' : 'Current speed',
                  value: '${item.speed.toStringAsFixed(0)} km/h',
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 120,
            height: 120,
            child: Image.asset(
              'assets/images/generic_fleet_van.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.medium,
              semanticLabel: 'Generic fleet vehicle illustration',
            ),
          ),
        ],
      ),
    );
  }

  String _freshness(int? minutes) {
    if (minutes == null) return 'No live data';
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return '$minutes min ago';
    if (minutes < 1440) return '${minutes ~/ 60} hr ago';
    return '${minutes ~/ 1440} days ago';
  }
}

class _StatusDetail extends StatelessWidget {
  const _StatusDetail({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: ReportStyles.textMuted, fontSize: 12),
        ),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _DriverSafetyCard extends StatelessWidget {
  const _DriverSafetyCard({required this.data});

  final _OverviewData data;

  @override
  Widget build(BuildContext context) => _SelectedDataCard(
    title: 'Driver Safety',
    icon: Icons.shield_outlined,
    context: 'Today',
    child: Column(
      children: data.snapshotRows
          .map(
            (row) => _MetricLine(
              label: row.label,
              count: row.count,
              progress: row.progress,
              value: '${row.count}',
              valueColor: _metricColor(row.label),
            ),
          )
          .toList(),
    ),
  );

  Color _metricColor(String label) {
    switch (label) {
      case 'Drowsy':
        return ReportStyles.red;
      case 'Yawn':
        return ReportStyles.yellow;
      case 'Distraction':
        return ReportStyles.orange;
      default:
        return ReportStyles.blue;
    }
  }
}

class _SelectedDataCard extends StatelessWidget {
  const _SelectedDataCard({
    required this.title,
    required this.icon,
    required this.child,
    this.context,
  });
  final String title;
  final IconData icon;
  final String? context;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: 160,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
    decoration: BoxDecoration(
      color: ReportStyles.cardBackground,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: ReportStyles.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: ReportStyles.blue, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (this.context != null)
              Text(
                '(${this.context!})',
                style: const TextStyle(
                  color: ReportStyles.textMuted,
                  fontSize: 10,
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(child: child),
      ],
    ),
  );
}

class _MetricLine extends StatelessWidget {
  const _MetricLine({
    required this.label,
    required this.value,
    this.valueColor,
    required int count,
    required double progress,
  });
  final String label;
  final String value;
  final Color? valueColor;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: ReportStyles.textMuted, fontSize: 12),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _OverviewVehicleSelector extends StatelessWidget {
  const _OverviewVehicleSelector({
    required this.vehicles,
    required this.selectedVehicle,
    required this.onSelected,
  });

  final List<Vehicle> vehicles;
  final Vehicle? selectedVehicle;
  final ValueChanged<Vehicle> onSelected;

  @override
  Widget build(BuildContext context) {
    final selectedId =
        selectedVehicle != null &&
            vehicles.any((vehicle) => vehicle.id == selectedVehicle!.id)
        ? selectedVehicle!.id
        : null;

    return Container(
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ReportStyles.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isExpanded: true,
          dropdownColor: ReportStyles.surfaceBackground,
          hint: const Text(
            'Select Fleet vehicle',
            style: TextStyle(color: ReportStyles.textMuted, fontSize: 12),
          ),
          iconEnabledColor: ReportStyles.textSecondary,
          items: vehicles
              .map(
                (vehicle) => DropdownMenuItem<String>(
                  value: vehicle.id,
                  child: Text(
                    _vehicleSelectorLabel(vehicle),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              )
              .toList(),
          onChanged: vehicles.isEmpty
              ? null
              : (id) {
                  if (id == null) return;
                  for (final vehicle in vehicles) {
                    if (vehicle.id == id) {
                      onSelected(vehicle);
                      return;
                    }
                  }
                },
        ),
      ),
    );
  }

  String _vehicleSelectorLabel(Vehicle vehicle) {
    final plate = vehicle.plateNumber.trim();
    final type = vehicle.type.trim();
    const statusValues = {'moving', 'idle', 'online', 'offline', 'unknown'};
    final vin = vehicle.vin;
    final primary = plate.isNotEmpty ? plate : vehicle.id;
    final typeSuffix = type.isEmpty || statusValues.contains(type.toLowerCase())
        ? ''
        : ' - $type';
    final vinSuffix = vin.isEmpty || vin == primary ? '' : ' · $vin';
    return '$primary$typeSuffix$vinSuffix';
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.children, required this.perRow});

  final List<Widget> children;
  final int perRow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final width = constraints.maxWidth;
        final itemWidth = perRow <= 1
            ? width
            : (width - (spacing * (perRow - 1))) / perRow;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _CompactKpiCard extends StatelessWidget {
  const _CompactKpiCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.trailing,
    this.footer,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget? trailing;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.9)),
        boxShadow: ReportStyles.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
              border: Border.all(color: accentColor.withValues(alpha: 0.32)),
            ),
            child: Icon(icon, color: accentColor, size: 19),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReportStyles.textMuted,
                    fontSize: 11,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
          if (footer != null) ...[const SizedBox(width: 10), footer!],
        ],
      ),
    );
  }
}

class _SafetyEventBreakdown extends StatelessWidget {
  const _SafetyEventBreakdown({required this.data});

  final _OverviewData data;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _BreakdownLine(
        label: 'Drowsy',
        value: data.drowsyCount,
        color: ReportStyles.red,
      ),
      _BreakdownLine(
        label: 'Yawn',
        value: data.yawnCount,
        color: ReportStyles.yellow,
      ),
      _BreakdownLine(
        label: 'Distraction',
        value: data.distractionCount,
        color: ReportStyles.orange,
      ),
    ],
  );
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 82,
    height: 15,
    child: Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: ReportStyles.textMuted, fontSize: 8),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _LiveMapCard extends StatelessWidget {
  const _LiveMapCard({
    required this.map,
    required this.hasVehicleData,
    required this.mapStateMessage,
    required this.onViewFullMap,
  });

  final Widget map;
  final bool hasVehicleData;
  final String? mapStateMessage;
  final VoidCallback onViewFullMap;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: 218,
      child: Column(
        children: [
          Row(
            children: [
              const _TitleIcon(icon: Icons.circle, color: ReportStyles.green),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Live Map',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: hasVehicleData ? onViewFullMap : null,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  textStyle: const TextStyle(fontSize: 11),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                child: const Text('View Full Map'),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  Positioned.fill(child: map),
                  Positioned(
                    left: 14,
                    bottom: 14,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xCC0B1625),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LegendRow(
                            color: ReportStyles.green,
                            label: 'Moving',
                          ),
                          SizedBox(height: 6),
                          _LegendRow(color: ReportStyles.blue, label: 'Idle'),
                          SizedBox(height: 6),
                          _LegendRow(
                            color: ReportStyles.yellow,
                            label: 'Warning',
                          ),
                          SizedBox(height: 6),
                          _LegendRow(color: ReportStyles.red, label: 'Alert'),
                          SizedBox(height: 6),
                          _LegendRow(
                            color: ReportStyles.textMuted,
                            label: 'Offline',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (mapStateMessage != null)
                    Positioned(
                      right: 14,
                      bottom: 14,
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 220),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC0B1625),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Text(
                          mapStateMessage!,
                          style: const TextStyle(
                            color: ReportStyles.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleRiskRankingCard extends StatelessWidget {
  const _VehicleRiskRankingCard({required this.vehicles});

  final List<Map<String, String>> vehicles;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: 218,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TitleIcon(
                icon: Icons.bar_chart_rounded,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Vehicle Risk Ranking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/drivers'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Expanded(
            child: vehicles.isEmpty
                ? const _CenteredEmptyState(
                    title: 'No vehicle risk data available',
                    subtitle:
                        'Vehicle ranking will appear when fleet status is received.',
                  )
                : Column(
                    children: [
                      _RankingHeader(),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: vehicles.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.white.withValues(alpha: 0.08),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final item = vehicles[index];
                            return _RankingRow(
                              rank: index + 1,
                              vehicle: item['vehicle'] ?? '-',
                              risk: item['risk'] ?? 'Low',
                              issue: item['issue'] ?? '-',
                              telemetry: item['telemetry'] ?? '-',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Showing top ${vehicles.length} vehicles',
                        style: const TextStyle(
                          color: ReportStyles.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SafetySnapshotCard extends StatelessWidget {
  const _SafetySnapshotCard({required this.data});

  final _OverviewData data;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _TitleIcon(icon: Icons.shield_outlined, color: ReportStyles.blue),
              SizedBox(width: 8),
              Text(
                'Safety Events Breakdown',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Column(
              children: data.snapshotRows.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: _SnapshotRow(row: row),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentEventsCard extends StatelessWidget {
  const _RecentEventsCard({required this.recentLog});

  final List<Map<String, String>> recentLog;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: 148,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _TitleIcon(
                icon: Icons.fact_check_outlined,
                color: ReportStyles.blue,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Recent Events',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pushNamed('/safety'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: const Text('View All Logs'),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Expanded(
            child: recentLog.isEmpty
                ? const _CenteredEmptyState(
                    title: 'No recent live events',
                    subtitle: 'No recent telemetry or safety events received.',
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: recentLog.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final item = recentLog[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 48,
                              child: Text(
                                item['time'] ?? '--:--',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['type'] ?? 'Safety Event',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['description'] ??
                                        'Safety event received',
                                    style: const TextStyle(
                                      color: ReportStyles.textSecondary,
                                      fontSize: 11,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _RiskChip(label: item['severity'] ?? 'Low'),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.85)),
        boxShadow: ReportStyles.cardShadow,
      ),
      child: child,
    );
  }
}

class _RecentStatusLogCard extends StatelessWidget {
  const _RecentStatusLogCard({required this.entries});

  final List<String> entries;

  @override
  Widget build(BuildContext context) => _DashboardCard(
    height: 148,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            _TitleIcon(
              icon: Icons.receipt_long_outlined,
              color: ReportStyles.blue,
            ),
            SizedBox(width: 7),
            Text(
              'Recent Log',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Expanded(
          child: entries.isEmpty
              ? const Text(
                  'No recent live-data updates.',
                  style: TextStyle(color: ReportStyles.textMuted, fontSize: 11),
                )
              : Column(
                  children: entries
                      .take(3)
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: ReportStyles.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: ReportStyles.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    ),
  );
}

class _RingPercent extends StatelessWidget {
  const _RingPercent({required this.percent, required this.color});

  final int percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0, 100) / 100;

    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: clamped.toDouble(),
              strokeWidth: 6,
              backgroundColor: color.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    this.withDot = false,
  });

  final String label;
  final Color color;
  final bool withDot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withDot) ...[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}

class _RankingHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 34,
            child: Text('Rank', style: _TableHeaderStyle.text),
          ),
          Expanded(
            flex: 3,
            child: Text('Vehicle', style: _TableHeaderStyle.text),
          ),
          Expanded(flex: 2, child: Text('Risk', style: _TableHeaderStyle.text)),
          Expanded(
            flex: 3,
            child: Text('Main Issue', style: _TableHeaderStyle.text),
          ),
          Expanded(
            flex: 2,
            child: Text('Last Telemetry', style: _TableHeaderStyle.text),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.rank,
    required this.vehicle,
    required this.risk,
    required this.issue,
    required this.telemetry,
  });

  final int rank;
  final String vehicle;
  final String risk;
  final String issue;
  final String telemetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '$rank',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              vehicle,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _RiskChip(label: '$risk Risk'),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              issue,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              telemetry,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiskChip extends StatelessWidget {
  const _RiskChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final color = lower.contains('high')
        ? ReportStyles.red
        : lower.contains('medium')
        ? ReportStyles.orange
        : lower.contains('unavailable')
        ? ReportStyles.textMuted
        : ReportStyles.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({required this.row});

  final _SnapshotRowData row;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 144,
          child: Row(
            children: [
              Icon(row.icon, color: ReportStyles.blue, size: 18),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  row.label,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: row.progress,
              backgroundColor: const Color(0xFF1C2B43),
              valueColor: const AlwaysStoppedAnimation<Color>(
                ReportStyles.blue,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 52,
          child: Text(
            '${row.count}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _CenteredEmptyState extends StatelessWidget {
  const _CenteredEmptyState({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.02),
                ],
              ),
            ),
            child: const Icon(
              Icons.assignment_turned_in_outlined,
              color: ReportStyles.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 3),
          Text(
            subtitle,
            style: const TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MapUnavailableState extends StatelessWidget {
  const _MapUnavailableState();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A1524),
      alignment: Alignment.center,
      child: const Text(
        'Vehicle location data unavailable',
        style: TextStyle(color: ReportStyles.textSecondary, fontSize: 14),
      ),
    );
  }
}

class _TitleIcon extends StatelessWidget {
  const _TitleIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, color: color, size: 16);
  }
}

class _TableHeaderStyle {
  static const text = TextStyle(
    color: ReportStyles.textSecondary,
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );
}

class _SnapshotRowData {
  const _SnapshotRowData({
    required this.icon,
    required this.label,
    required this.count,
    required this.progress,
  });

  final IconData icon;
  final String label;
  final int count;
  final double progress;
}

class _OverviewData {
  const _OverviewData({
    required this.totalVehicles,
    required this.onlineVehicles,
    required this.offlineVehicles,
    required this.drowsyCount,
    required this.yawnCount,
    required this.distractionCount,
    required this.safetyEventCount,
    required this.snapshotRows,
    required this.hasVehicleStatus,
    required this.vehicleStatusMessage,
    required this.highRiskDriverCount,
    required this.rankedVehicles,
    required this.riskSubtitle,
    required this.recentLog,
    required this.statusLog,
    required this.mapStateMessage,
    required this.fleetHealthLabel,
    required this.fleetHealthColor,
    required this.fleetHealthIcon,
    required this.lastUpdatedLabel,
  });

  final int totalVehicles;
  final int onlineVehicles;
  final int offlineVehicles;
  final int drowsyCount;
  final int yawnCount;
  final int distractionCount;
  final int safetyEventCount;
  final List<_SnapshotRowData> snapshotRows;
  final bool hasVehicleStatus;
  final String? vehicleStatusMessage;
  final int highRiskDriverCount;
  final List<Map<String, String>> rankedVehicles;
  final String riskSubtitle;
  final List<Map<String, String>> recentLog;
  final List<String> statusLog;
  final String? mapStateMessage;
  final String fleetHealthLabel;
  final Color fleetHealthColor;
  final IconData fleetHealthIcon;
  final String lastUpdatedLabel;
}
