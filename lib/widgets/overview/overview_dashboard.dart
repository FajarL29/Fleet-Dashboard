import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';

import '../../models/driver_behavior_summary.dart';
import '../../models/drowsiness_report.dart';
import '../../models/driver_health.dart';
import '../../models/vehicle.dart';
import '../../theme/app_theme.dart';
import '../map_section.dart';
import 'device_status_panel.dart';
import 'high_risk_drivers_panel.dart';
import 'latest_safety_alerts_panel.dart';
import 'overview_kpi_card.dart';
import 'recent_events_preview_panel.dart';

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
    required this.onVehicleSelected,
    required this.onClearSelection,
    required this.onFollowModeChanged,
    required this.onOpenMapFullscreen,
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
  final ValueChanged<Vehicle> onVehicleSelected;
  final VoidCallback onClearSelection;
  final ValueChanged<bool> onFollowModeChanged;
  final VoidCallback onOpenMapFullscreen;

  @override
  Widget build(BuildContext context) {
    final overviewData = _buildOverviewData();
    final kpiCards = _buildKpiCards(overviewData);
    final eventSourceLabel = _eventSourceLabel();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth = constraints.maxWidth;
          final isDesktop = contentWidth >= 1280;
          final useDesktopKpiRow = contentWidth >= 1200;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 14),
              const _OverviewHeading(),
              const SizedBox(height: 2),
              Text(
                'Recent events from $eventSourceLabel',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 14),
              if (useDesktopKpiRow)
                SizedBox(
                  height: 112,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < kpiCards.length; i++) ...[
                        Expanded(
                          child: SizedBox(
                            height: 112,
                            child: kpiCards[i],
                          ),
                        ),
                        if (i != kpiCards.length - 1) const SizedBox(width: 14),
                      ],
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: kpiCards
                      .map(
                        (card) => SizedBox(
                          width: contentWidth >= 760
                              ? (contentWidth - 14) / 2
                              : contentWidth,
                          height: 112,
                          child: card,
                        ),
                      )
                      .toList(),
                ),
              const SizedBox(height: 14),
              if (isDesktop)
                SizedBox(
                  height: 318,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _OverviewMapCard(
                          map: _buildMapSection(),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        flex: 2,
                        child: LatestSafetyAlertsPanel(
                          alerts: overviewData.latestAlerts,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                SizedBox(
                  height: 318,
                  child: _OverviewMapCard(
                    map: _buildMapSection(),
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 320,
                  child: LatestSafetyAlertsPanel(
                    alerts: overviewData.latestAlerts,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (isDesktop)
                SizedBox(
                  height: 228,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: HighRiskDriversPanel(
                          drivers: overviewData.highRiskDrivers,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: DeviceStatusPanel(
                          totalDevices: overviewData.totalDevices,
                          onlineDevices: overviewData.onlineDevices,
                          warningDevices: overviewData.warningDevices,
                          errorDevices: overviewData.errorDevices,
                          healthPercentage: overviewData.deviceHealthPercentage,
                          lastUpdatedLabel: overviewData.lastUpdatedLabel,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: RecentEventsPreviewPanel(
                          events: overviewData.recentEvents,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                SizedBox(
                  height: 228,
                  child: HighRiskDriversPanel(
                    drivers: overviewData.highRiskDrivers,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 228,
                  child: DeviceStatusPanel(
                    totalDevices: overviewData.totalDevices,
                    onlineDevices: overviewData.onlineDevices,
                    warningDevices: overviewData.warningDevices,
                    errorDevices: overviewData.errorDevices,
                    healthPercentage: overviewData.deviceHealthPercentage,
                    lastUpdatedLabel: overviewData.lastUpdatedLabel,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 228,
                  child: RecentEventsPreviewPanel(
                    events: overviewData.recentEvents,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildMapSection() {
    return MapSection(
      mapController: mapController,
      vehicles: vehicles,
      onVehicleSelected: onVehicleSelected,
      isFullScreen: false,
      onFullScreenToggle: onOpenMapFullscreen,
      showVehicleList: false,
      selectedVehicleId: selectedVehicle?.id,
      onClearSelection: onClearSelection,
      onFollowModeChanged: onFollowModeChanged,
    );
  }

  List<Widget> _buildKpiCards(_OverviewData data) {
    return [
      OverviewKpiCard(
        title: 'Online Vehicles',
        value: '${data.onlineVehicles}',
        subtitle: 'of ${data.totalVehicles} vehicles',
        trendText: '${data.onlineVehiclePercentage.toStringAsFixed(1)}%',
        trendColor: AppTheme.success,
        icon: Icons.local_shipping_rounded,
        accentColor: AppTheme.success,
      ),
      OverviewKpiCard(
        title: 'Drowsy Events Today',
        value: '${data.drowsyEventsToday}',
        subtitle: 'Safety monitoring feed',
        trendText: '${data.drowsyEventsDeltaLabel} vs baseline',
        trendColor: AppTheme.warning,
        icon: Icons.nightlight_round,
        accentColor: const Color(0xFF8B5CF6),
      ),
      OverviewKpiCard(
        // TODO: Replace with real review queue count when backend provides review status.
        title: 'Recent Events',
        value: '${data.eventsNeedReview}',
        subtitle: 'Recent vehicle activity',
        trendText: data.eventsNeedReviewTrendLabel,
        trendColor: AppTheme.error,
        icon: Icons.warning_amber_rounded,
        accentColor: const Color(0xFFF59E0B),
      ),
      // TODO: Replace this proxy with real driver risk data when the backend exposes it.
      OverviewKpiCard(
        title: 'High-Risk Drivers',
        value: '${data.highRiskDriverCount}',
        subtitle: data.highRiskDriversSubtitle,
        trendText: data.highRiskDriversTrendLabel,
        trendColor: AppTheme.error,
        icon: Icons.groups_rounded,
        accentColor: const Color(0xFFEF4444),
      ),
      // TODO: Replace this proxy with real device health data when the backend exposes it.
      OverviewKpiCard(
        title: 'Device Health',
        value: '${data.deviceHealthPercentage}%',
        subtitle: 'Fleet telemetry availability',
        trendText: '${data.onlineDevices}/${data.totalDevices} online',
        trendColor: AppTheme.success,
        icon: Icons.memory_rounded,
        accentColor: AppTheme.accentBlue,
      ),
    ];
  }

  _OverviewData _buildOverviewData() {
    final onlineVehicles =
        vehicles.where((vehicle) => vehicle.status == VehicleStatus.active).length;
    final warningVehicles =
        vehicles.where((vehicle) => vehicle.status == VehicleStatus.warning).length;
    final errorVehicles =
        vehicles.where((vehicle) => vehicle.status == VehicleStatus.error).length;

    final latestAlerts = _buildLatestAlerts();
    final recentEvents = _buildRecentEvents();
    final highRiskDrivers = _buildHighRiskDrivers();
    final realHighRiskDrivers = _buildRealHighRiskDrivers();
    final drowsyEventsToday = recentDrowsinessEvents
        .where(_isTodayEvent)
        .length;
    final eventBasedRecentCount = recentDrowsinessEvents
        .where((event) => _severityFromRisk(event.riskLevel) != 'Low')
        .length;
    final aggregateReport = currentDrowsinessReport;
    final reportSummary = aggregateReport?.summary;
    final recentEventsKpiValue = reportSummary?.totalEvents ??
        (eventBasedRecentCount == 0 ? latestAlerts.length : eventBasedRecentCount);
    final highRiskEventCount = reportSummary?.highRiskEvents ?? 0;
    final peakHourLabel = _peakHourLabel(reportSummary?.peakHour);
    final realHighRiskDriverCount = driverBehaviorSummaries
        .where((summary) => summary.userId != null)
        .where((summary) => summary.riskLevel == 'High')
        .where((summary) => summary.totalEvents >= 20 || summary.priorityScore >= 50)
        .length;

    return _OverviewData(
      totalVehicles: vehicles.length,
      onlineVehicles: onlineVehicles,
      onlineVehiclePercentage: vehicles.isEmpty
          ? 0
          : (onlineVehicles / vehicles.length) * 100,
      drowsyEventsToday: drowsyEventsToday,
      eventsNeedReview: recentEventsKpiValue,
      // TODO: Handle unassigned behavior events separately.
      highRiskDriverCount: realHighRiskDrivers.isNotEmpty
          ? realHighRiskDriverCount
          : highRiskDrivers
              .where((driver) => (driver['riskScore'] as int) >= 55)
              .length,
      totalDevices: vehicles.length,
      onlineDevices: onlineVehicles,
      warningDevices: warningVehicles,
      errorDevices: errorVehicles,
      deviceHealthPercentage: vehicles.isEmpty
          ? 0
          : ((onlineVehicles / vehicles.length) * 100).round(),
      drowsyEventsDeltaLabel: drowsyEventsToday == 0 ? '0' : '+$drowsyEventsToday',
      eventsNeedReviewDeltaLabel:
          recentEventsKpiValue == 0 ? '0' : '+$recentEventsKpiValue',
      eventsNeedReviewTrendLabel: peakHourLabel != null
          ? 'Peak hour: $peakHourLabel'
          : '${recentEventsKpiValue == 0 ? '0' : '+$recentEventsKpiValue'} recent items',
      highRiskDriversSubtitle: realHighRiskDrivers.isNotEmpty
          ? 'Based on driver behavior'
          : 'Warning or alert status',
      highRiskDriversDeltaLabel: realHighRiskDrivers.isNotEmpty
          ? '${realHighRiskDrivers.length}'
          : highRiskDrivers.isEmpty
              ? (highRiskEventCount == 0 ? '0' : '$highRiskEventCount')
              : '${highRiskDrivers.length}',
      highRiskDriversTrendLabel: realHighRiskDrivers.isNotEmpty
          ? 'Top ${realHighRiskDrivers.length} shown'
          : '${highRiskDrivers.isEmpty ? (highRiskEventCount == 0 ? '0' : highRiskEventCount) : highRiskDrivers.length} monitored',
      latestAlerts: latestAlerts,
      highRiskDrivers:
          realHighRiskDrivers.isNotEmpty ? realHighRiskDrivers : highRiskDrivers,
      recentEvents: recentEvents,
      lastUpdatedLabel: _lastUpdatedLabel(latestAlerts),
    );
  }

  List<Map<String, dynamic>> _buildLatestAlerts() {
    final events = List<DrowsinessEvent>.from(recentDrowsinessEvents)
      ..sort((a, b) => b.time.compareTo(a.time));

    return events.take(3).map(_mapEventForOverview).toList();
  }

  List<Map<String, dynamic>> _buildHighRiskDrivers() {
    final items = driversHealth.asMap().entries.map((entry) {
      final index = entry.key;
      final driver = entry.value;
      final vehicle = _vehicleForDriver(driver, null);
      final driverId = int.tryParse(driver.driverId);
      final hasActiveAlert = driverId != null && driverAlerts.containsKey(driverId);

      var riskScore = switch (driver.status) {
        HealthStatus.alert => 72,
        HealthStatus.warning => 58,
        HealthStatus.normal => 34,
      };

      if (hasActiveAlert) {
        riskScore += 18;
      }
      if (driver.heartRate > 95) {
        riskScore += 6;
      }
      if (driver.temperature >= 37.5) {
        riskScore += 4;
      }

      riskScore = riskScore.clamp(24, 96);

      return {
        'name': driver.name,
        'initials': _initials(driver.name),
        'vehicleLabel': vehicle?.plateNumber ?? _fallbackPlate(index),
        'riskScore': riskScore,
        'statusText': hasActiveAlert ? 'Active alert' : driver.getStatusText(),
      };
    }).toList();

    items.sort(
      (a, b) => (b['riskScore'] as int).compareTo(a['riskScore'] as int),
    );

    return items.take(5).toList();
  }

  List<Map<String, dynamic>> _buildRealHighRiskDrivers() {
    final rankedDrivers = driverBehaviorSummaries
        .where((summary) => summary.userId != null)
        .where((summary) => summary.priorityScore > 0)
        .toList()
      ..sort((a, b) {
        final priorityCompare = b.priorityScore.compareTo(a.priorityScore);
        if (priorityCompare != 0) return priorityCompare;
        final scoreCompare = b.interventionScore.compareTo(a.interventionScore);
        if (scoreCompare != 0) return scoreCompare;
        return b.totalEvents.compareTo(a.totalEvents);
      });

    return rankedDrivers.take(3).map((summary) {
      final linkedDriver = _driverForBehavior(summary);
      final linkedVehicle = _vehicleForBehavior(summary);
      final score = summary.priorityScore;

      return {
        'name': linkedDriver?.name ?? summary.driverLabel,
        'initials': _initials(linkedDriver?.name ?? summary.driverLabel),
        'vehicleLabel': summary.vehicleId ??
            linkedVehicle?.plateNumber ??
            linkedVehicle?.apiVehicleId ??
            '-',
        'riskScore': score,
        'statusText':
            '${summary.riskLevel} · ${summary.dominantBehavior} · ${summary.totalEvents} events',
      };
    }).toList();
  }

  List<Map<String, dynamic>> _buildRecentEvents() {
    final events = List<DrowsinessEvent>.from(recentDrowsinessEvents)
      ..sort((a, b) => b.time.compareTo(a.time));

    return events.take(3).map(_mapEventForOverview).toList();
  }

  Vehicle? _vehicleForDriver(DriverHealth? driver, String? vehicleId) {
    if (vehicleId != null && vehicleId.isNotEmpty) {
      for (final vehicle in vehicles) {
        if (vehicle.id == vehicleId ||
            vehicle.plateNumber == vehicleId ||
            vehicle.apiVehicleId == vehicleId) {
          return vehicle;
        }
      }
    }

    if (driver != null) {
      for (final vehicle in vehicles) {
        if (vehicle.driverName.toLowerCase() == driver.name.toLowerCase()) {
          return vehicle;
        }
      }
    }

    return vehicles.isEmpty ? null : vehicles.first;
  }

  String _formatEventType(String? rawType) {
    if (rawType == null || rawType.isEmpty) {
      return 'Drowsiness Detected';
    }

    final normalized = rawType.replaceAll('_', ' ').trim();
    final lower = normalized.toLowerCase();

    if (lower.contains('drows')) return 'Drowsiness Detected';
    if (lower.contains('speed')) return 'Overspeed';
    if (lower.contains('brake')) return 'Hard Braking';

    return normalized
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  String _severityFromRisk(String? riskLevel) {
    final lower = riskLevel?.toLowerCase().trim() ?? '';
    if (lower == 'high') return 'High';
    if (lower == 'medium') return 'Medium';
    if (lower == 'low') return 'Low';
    return 'Medium';
  }

  bool _isTodayEvent(DrowsinessEvent event) {
    final now = DateTime.now();
    return event.time.year == now.year &&
        event.time.month == now.month &&
        event.time.day == now.day;
  }

  Map<String, dynamic> _mapEventForOverview(DrowsinessEvent event) {
    final vehicle = _vehicleForEvent(event);
    final driver = _driverForEvent(event);

    return {
      'driverName': driver?.name ?? event.driverLabel,
      'vehicleLabel': event.vehicleId.isNotEmpty
          ? event.vehicleId
          : (vehicle?.plateNumber ?? '-'),
      'location': _eventLocationLabel(event, vehicle),
      'time': event.time,
      'eventType': _eventTitle(event),
      'severity': _severityFromRisk(event.riskLevel),
      'speedLabel':
          vehicle == null ? '-' : '${vehicle.speed.toStringAsFixed(0)} km/h',
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

  DriverHealth? _driverForBehavior(DriverBehaviorSummary summary) {
    if (summary.userId == null) return null;

    for (final driver in driversHealth) {
      if (driver.driverId == summary.userId.toString()) {
        return driver;
      }
    }

    return null;
  }

  Vehicle? _vehicleForBehavior(DriverBehaviorSummary summary) {
    final vehicleId = summary.vehicleId?.trim();
    if (vehicleId == null || vehicleId.isEmpty) {
      return null;
    }

    for (final vehicle in vehicles) {
      if (vehicle.id == vehicleId ||
          vehicle.plateNumber == vehicleId ||
          vehicle.apiVehicleId == vehicleId) {
        return vehicle;
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

  String _eventTitle(DrowsinessEvent event) {
    if (event.status.trim().isNotEmpty) {
      return _formatEventType(event.status);
    }
    if ((event.behaviorType ?? '').trim().isNotEmpty) {
      return _formatEventType(event.behaviorType);
    }
    return 'Drowsiness Detected';
  }

  String _eventLocationLabel(DrowsinessEvent event, Vehicle? vehicle) {
    if (event.location != null && event.location!.trim().isNotEmpty) {
      return event.location!;
    }
    if (event.latitude != null && event.longitude != null) {
      return '${event.latitude!.toStringAsFixed(5)}, ${event.longitude!.toStringAsFixed(5)}';
    }
    return _locationForVehicle(vehicle, 'Unknown location');
  }

  String _locationForVehicle(Vehicle? vehicle, String fallback) {
    if (vehicle == null) return fallback;

    switch (vehicle.id) {
      case '1210':
        return 'Sunter, Jakarta Utara';
      case '999':
        return 'Cikarang, Bekasi';
      case '1234':
        return 'Karawang, Jawa Barat';
      default:
        return fallback;
    }
  }

  DateTime _normalizeDateTime(dynamic value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value)?.toLocal() ?? DateTime.now();
    }
    return DateTime.now();
  }

  String _lastUpdatedLabel(List<Map<String, dynamic>> alerts) {
    final formatter = DateFormat('HH:mm');
    if (alerts.isEmpty) {
      return '${formatter.format(DateTime.now())} WIB';
    }
    return '${formatter.format(_normalizeDateTime(alerts.first['time']))} WIB';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _fallbackPlate(int index) {
    const plates = [
      'B 7041 UDB',
      'B 9999 XYZ',
      'B 1234 ABC',
      'B 1111 UOB',
      'B 5678 DEF',
    ];
    return plates[index % plates.length];
  }

  String _eventSourceLabel() {
    final selectedApiId = selectedVehicle?.apiVehicleId?.trim();
    if (selectedApiId != null && selectedApiId.isNotEmpty) {
      return selectedApiId;
    }

    for (final vehicle in vehicles) {
      final apiId = vehicle.apiVehicleId?.trim();
      if (apiId != null && apiId.isNotEmpty) {
        return apiId;
      }
    }

    return 'VIN-0001';
  }

  String? _peakHourLabel(int? peakHour) {
    if (peakHour == null || peakHour < 0 || peakHour > 23) {
      return null;
    }

    final time = DateTime(2026, 1, 1, peakHour);
    return DateFormat('HH:mm').format(time);
  }

}

class _OverviewHeading extends StatelessWidget {
  const _OverviewHeading();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Driver Safety & Telematics',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Overview of fleet health, live tracking, and safety monitoring.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Live overview · recent data',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _OverviewHeadingWithSource extends StatelessWidget {
  const _OverviewHeadingWithSource({
    required this.eventSourceLabel,
  });

  final String eventSourceLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Driver Safety & Telematics',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Overview of fleet health, live tracking, and safety monitoring.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 3),
        const Text(
          'Live overview · recent data',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Recent events from $eventSourceLabel',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _OverviewMapCard extends StatelessWidget {
  const _OverviewMapCard({
    required this.map,
  });

  final Widget map;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.slateGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox.expand(
                child: map,
              ),
            ),
          ),
          Positioned(
            left: 18,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.24),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Live Map',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Real-time vehicle locations',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 18,
            bottom: 18,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.34),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendRow(color: AppTheme.success, label: 'Moving'),
                  SizedBox(height: 8),
                  _LegendRow(color: AppTheme.warning, label: 'Warning'),
                  SizedBox(height: 8),
                  _LegendRow(color: AppTheme.error, label: 'Alert'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _OverviewData {
  const _OverviewData({
    required this.totalVehicles,
    required this.onlineVehicles,
    required this.onlineVehiclePercentage,
    required this.drowsyEventsToday,
    required this.eventsNeedReview,
    required this.highRiskDriverCount,
    required this.totalDevices,
    required this.onlineDevices,
    required this.warningDevices,
    required this.errorDevices,
    required this.deviceHealthPercentage,
    required this.drowsyEventsDeltaLabel,
    required this.eventsNeedReviewDeltaLabel,
    required this.eventsNeedReviewTrendLabel,
    required this.highRiskDriversSubtitle,
    required this.highRiskDriversDeltaLabel,
    required this.highRiskDriversTrendLabel,
    required this.latestAlerts,
    required this.highRiskDrivers,
    required this.recentEvents,
    required this.lastUpdatedLabel,
  });

  final int totalVehicles;
  final int onlineVehicles;
  final double onlineVehiclePercentage;
  final int drowsyEventsToday;
  final int eventsNeedReview;
  final int highRiskDriverCount;
  final int totalDevices;
  final int onlineDevices;
  final int warningDevices;
  final int errorDevices;
  final int deviceHealthPercentage;
  final String drowsyEventsDeltaLabel;
  final String eventsNeedReviewDeltaLabel;
  final String eventsNeedReviewTrendLabel;
  final String highRiskDriversSubtitle;
  final String highRiskDriversDeltaLabel;
  final String highRiskDriversTrendLabel;
  final List<Map<String, dynamic>> latestAlerts;
  final List<Map<String, dynamic>> highRiskDrivers;
  final List<Map<String, dynamic>> recentEvents;
  final String lastUpdatedLabel;
}
