import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../models/driver_behavior_summary.dart';
import '../../models/driver_health.dart';
import '../../models/drowsiness_report.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_status.dart';
import 'overview_skeleton_loading.dart';
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
    required this.driversHealth,
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
  final List<DriverHealth> driversHealth;
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
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final useWideHeader = width >= 960;
            final kpiPerRow = width >= 1200
                ? 4
                : width >= 900
                ? 2
                : 1;
            final useTwoColumns = width >= 1180;

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
                const SizedBox(height: 16),
                _KpiGrid(
                  perRow: kpiPerRow,
                  children: _buildKpiCards(overviewData),
                ),
                const SizedBox(height: 16),
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
                            child: _HighRiskRankingCard(
                              drivers: overviewData.highRiskDrivers,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _SafetySnapshotCard(data: overviewData),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _RecentLogCard(
                              recentLog: overviewData.recentLog,
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
                      const SizedBox(height: 16),
                      _HighRiskRankingCard(
                        drivers: overviewData.highRiskDrivers,
                      ),
                      const SizedBox(height: 16),
                      _SafetySnapshotCard(data: overviewData),
                      const SizedBox(height: 16),
                      _RecentLogCard(recentLog: overviewData.recentLog),
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
        onVehicleSelected: onVehicleSelected,
        isFullScreen: false,
        onFullScreenToggle: onOpenMapFullscreen,
        showVehicleList: false,
        selectedVehicleId: selectedVehicle?.id,
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
        title: 'Online Vehicles',
        value: data.hasVehicleStatus
            ? '${data.onlineVehicles} / $totalVehicles'
            : 'Unavailable',
        subtitle: data.hasVehicleStatus
            ? (totalVehicles == 0 ? 'No vehicles available' : 'Live status')
            : (data.vehicleStatusMessage ?? 'Vehicle status unavailable'),
        icon: Icons.local_shipping_rounded,
        accentColor: ReportStyles.green,
        trailing: _RingPercent(
          percent: data.hasVehicleStatus ? onlinePercent : 0,
          color: ReportStyles.green,
        ),
      ),
      _CompactKpiCard(
        title: 'Drowsy Events Today',
        value: '${data.drowsyCount}',
        subtitle: 'Today only',
        icon: Icons.mood_bad_rounded,
        accentColor: ReportStyles.blue,
        footer: _StatusPill(
          label: data.drowsyCount == 0 ? 'Clear' : 'Alert',
          color: data.drowsyCount == 0
              ? ReportStyles.green
              : ReportStyles.orange,
        ),
      ),
      _CompactKpiCard(
        title: 'Distraction Today',
        value: '${data.distractionCount}',
        subtitle: 'Today only',
        icon: Icons.phonelink_lock_rounded,
        accentColor: ReportStyles.blue,
        footer: _StatusPill(
          label: data.distractionCount == 0 ? 'Clear' : 'Alert',
          color: data.distractionCount == 0
              ? ReportStyles.green
              : ReportStyles.orange,
        ),
      ),
      _CompactKpiCard(
        title: 'High-Risk Drivers',
        value: data.hasVehicleStatus
            ? '${data.highRiskDriverCount}'
            : 'Unavailable',
        subtitle: data.highRiskSubtitle,
        icon: Icons.person_rounded,
        accentColor: ReportStyles.purple,
        footer: const _StatusPill(
          label: 'LIVE',
          color: ReportStyles.purple,
          withDot: true,
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
    final highRiskDrivers = _buildHighRiskDrivers();
    final recentLog = todayEvents.take(5).map(_mapRecentLog).toList();
    final totalVehicles = summary?.totalVehicles ?? vehicleItems.length;
    final onlineVehicles = summary?.onlineVehicles ?? 0;
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
    final hasVehicleStatus = vehicleStatusData != null;
    final highRiskSubtitle = !hasVehicleStatus
        ? (vehicleStatusError ?? 'Awaiting vehicle status')
        : highRiskDriverCount == 0
        ? 'No high-risk drivers today'
        : '$highRiskDriverCount vehicle${highRiskDriverCount == 1 ? '' : 's'} need attention';
    final mapStateMessage = vehicleStatusError != null && !hasVehicleStatus
        ? vehicleStatusError!
        : vehicleItems.isEmpty
        ? 'Vehicle status data unavailable'
        : vehicles.isEmpty
        ? 'No vehicle coordinates available'
        : null;
    final fleetHealthLabel = highRiskDriverCount > 0
        ? 'ATTENTION REQUIRED'
        : warningCount > 0
        ? 'WARNING - CHECK DEVICE STATUS'
        : 'GREEN - FLEET HEALTHY';
    final fleetHealthColor = highRiskDriverCount > 0
        ? ReportStyles.red
        : warningCount > 0
        ? ReportStyles.yellow
        : ReportStyles.green;
    final fleetHealthIcon = highRiskDriverCount > 0 || warningCount > 0
        ? Icons.warning_rounded
        : Icons.check_rounded;

    return _OverviewData(
      totalVehicles: totalVehicles,
      onlineVehicles: onlineVehicles,
      drowsyCount: behaviorByName['drowsy'] ?? 0,
      distractionCount: behaviorByName['distraction'] ?? 0,
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
      highRiskDrivers: highRiskDrivers,
      highRiskSubtitle: highRiskSubtitle,
      recentLog: recentLog,
      mapStateMessage: mapStateMessage,
      fleetHealthLabel: fleetHealthLabel,
      fleetHealthColor: fleetHealthColor,
      fleetHealthIcon: fleetHealthIcon,
      lastUpdatedLabel: '${_twoDigits(now.hour)}:${_twoDigits(now.minute)} WIB',
    );
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

  List<Map<String, String>> _buildHighRiskDrivers() {
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

    return ranked.take(5).map((item) {
      final driverName = item.driverName.isNotEmpty
          ? item.driverName
          : 'Unknown Driver';
      final vehicleLabel = item.plateNumber.isNotEmpty
          ? item.plateNumber
          : (item.vehicleIdentificationNumber.isNotEmpty
                ? item.vehicleIdentificationNumber
                : item.vehicleId);

      return {
        'driver': driverName,
        'vehicle': vehicleLabel.isNotEmpty ? vehicleLabel : '-',
        'risk': _vehicleRiskLabel(item),
        'issue': item.statusReason.isNotEmpty
            ? item.statusReason
            : 'No issues detected',
        'initials': _initials(driverName),
      };
    }).toList();
  }

  Map<String, String> _mapRecentLog(DrowsinessEvent event) {
    final driver = _driverForEvent(event);
    final vehicle = _vehicleForEvent(event);
    return {
      'time': '${_twoDigits(event.time.hour)}:${_twoDigits(event.time.minute)}',
      'type': _eventLabel(event),
      'driver': driver?.name ?? event.driverLabel,
      'vehicle': vehicle?.plateNumber ?? event.vehicleId,
      'severity': _severityLabel(event.riskLevel),
    };
  }

  DriverHealth? _driverForEvent(DrowsinessEvent event) {
    for (final driver in driversHealth) {
      if (driver.driverId == event.userId.toString()) {
        return driver;
      }
    }
    return null;
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

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Driver Safety & Telematics Overview',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Today live monitoring for driver condition, vehicle position, and safety events.',
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
          'Driver Safety & Telematics Overview',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Today live monitoring for driver condition, vehicle position, and safety events.',
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
      height: 96,
      padding: const EdgeInsets.all(14),
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
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accentColor.withValues(alpha: 0.12),
              border: Border.all(color: accentColor.withValues(alpha: 0.32)),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 6),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
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
      height: 320,
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
                    horizontal: 12,
                    vertical: 8,
                  ),
                  textStyle: const TextStyle(fontSize: 12),
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
          const SizedBox(height: 10),
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

class _HighRiskRankingCard extends StatelessWidget {
  const _HighRiskRankingCard({required this.drivers});

  final List<Map<String, String>> drivers;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: 320,
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
                  'High-Risk Driver Ranking Today',
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
          const SizedBox(height: 10),
          Expanded(
            child: drivers.isEmpty
                ? const _CenteredEmptyState(
                    title: 'No driver risk data available',
                    subtitle:
                        'Driver ranking will appear when risk data is received.',
                  )
                : Column(
                    children: [
                      _RankingHeader(),
                      Expanded(
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          itemCount: drivers.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.white.withValues(alpha: 0.08),
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final item = drivers[index];
                            return _RankingRow(
                              rank: index + 1,
                              driver: item['driver'] ?? '-',
                              vehicle: item['vehicle'] ?? '-',
                              risk: item['risk'] ?? 'Low',
                              issue: item['issue'] ?? '-',
                              initials: item['initials'] ?? '?',
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Showing top ${drivers.length} drivers',
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
      height: 232,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              _TitleIcon(icon: Icons.shield_outlined, color: ReportStyles.blue),
              SizedBox(width: 8),
              Text(
                "Today's Safety Snapshot",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: data.snapshotRows.map((row) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
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

class _RecentLogCard extends StatelessWidget {
  const _RecentLogCard({required this.recentLog});

  final List<Map<String, String>> recentLog;

  @override
  Widget build(BuildContext context) {
    return _DashboardCard(
      height: 232,
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
                  'Recent Log',
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
          const SizedBox(height: 8),
          Expanded(
            child: recentLog.isEmpty
                ? const _CenteredEmptyState(
                    title: 'All clear!',
                    subtitle: 'No recent safety events to display.',
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
                        padding: const EdgeInsets.symmetric(vertical: 8),
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
                                    '${item['driver'] ?? '-'} - ${item['vehicle'] ?? '-'}',
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
      padding: const EdgeInsets.all(14),
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
            child: Text('Driver', style: _TableHeaderStyle.text),
          ),
          Expanded(
            flex: 2,
            child: Text('Vehicle', style: _TableHeaderStyle.text),
          ),
          Expanded(flex: 2, child: Text('Risk', style: _TableHeaderStyle.text)),
          Expanded(
            flex: 3,
            child: Text('Issue Summary', style: _TableHeaderStyle.text),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.rank,
    required this.driver,
    required this.vehicle,
    required this.risk,
    required this.issue,
    required this.initials,
  });

  final int rank;
  final String driver;
  final String vehicle;
  final String risk;
  final String issue;
  final String initials;

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
            child: Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: ReportStyles.blue.withValues(alpha: 0.7),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    driver,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
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
            width: 72,
            height: 72,
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
              size: 34,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
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
    required this.drowsyCount,
    required this.distractionCount,
    required this.snapshotRows,
    required this.hasVehicleStatus,
    required this.vehicleStatusMessage,
    required this.highRiskDriverCount,
    required this.highRiskDrivers,
    required this.highRiskSubtitle,
    required this.recentLog,
    required this.mapStateMessage,
    required this.fleetHealthLabel,
    required this.fleetHealthColor,
    required this.fleetHealthIcon,
    required this.lastUpdatedLabel,
  });

  final int totalVehicles;
  final int onlineVehicles;
  final int drowsyCount;
  final int distractionCount;
  final List<_SnapshotRowData> snapshotRows;
  final bool hasVehicleStatus;
  final String? vehicleStatusMessage;
  final int highRiskDriverCount;
  final List<Map<String, String>> highRiskDrivers;
  final String highRiskSubtitle;
  final List<Map<String, String>> recentLog;
  final String? mapStateMessage;
  final String fleetHealthLabel;
  final Color fleetHealthColor;
  final IconData fleetHealthIcon;
  final String lastUpdatedLabel;
}
