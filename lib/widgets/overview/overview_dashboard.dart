import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';

import '../../models/driver_health.dart';
import '../../models/vehicle.dart';
import '../../theme/app_theme.dart';
import '../header.dart';
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
  final ValueChanged<Vehicle> onVehicleSelected;
  final VoidCallback onClearSelection;
  final ValueChanged<bool> onFollowModeChanged;
  final VoidCallback onOpenMapFullscreen;

  @override
  Widget build(BuildContext context) {
    final overviewData = _buildOverviewData();
    final kpiCards = _buildKpiCards(overviewData);
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
              const Header(),
              const SizedBox(height: 14),
              const _OverviewHeading(),
              const SizedBox(height: 16),
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
        title: 'Events Need Review',
        value: '${data.eventsNeedReview}',
        subtitle: 'Pending safety follow-up',
        trendText: '${data.eventsNeedReviewDeltaLabel} review queue',
        trendColor: AppTheme.error,
        icon: Icons.warning_amber_rounded,
        accentColor: const Color(0xFFF59E0B),
      ),
      OverviewKpiCard(
        title: 'High-Risk Drivers',
        value: '${data.highRiskDriverCount}',
        subtitle: 'Warning or alert status',
        trendText: '${data.highRiskDriversDeltaLabel} monitored',
        trendColor: AppTheme.error,
        icon: Icons.groups_rounded,
        accentColor: const Color(0xFFEF4444),
      ),
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

  double _kpiWidth(double contentWidth) {
    if (contentWidth >= 1720) {
      return (contentWidth - 64) / 5;
    }
    if (contentWidth >= 1440) {
      return (contentWidth - 48) / 3;
    }
    return contentWidth;
  }

  _OverviewData _buildOverviewData() {
    final onlineVehicles =
        vehicles.where((vehicle) => vehicle.status == VehicleStatus.active).length;
    final warningVehicles =
        vehicles.where((vehicle) => vehicle.status == VehicleStatus.warning).length;
    final errorVehicles =
        vehicles.where((vehicle) => vehicle.status == VehicleStatus.error).length;

    final latestAlerts = _buildLatestAlerts();
    final recentEvents = _buildRecentEvents(latestAlerts);
    final highRiskDrivers = _buildHighRiskDrivers();
    final drowsyEventsToday = latestAlerts
        .where((alert) => (alert['eventType'] as String).contains('Drowsiness'))
        .length;
    final eventsNeedReview = latestAlerts
        .where((alert) => alert['severity'] != 'Low')
        .length;

    return _OverviewData(
      totalVehicles: vehicles.length,
      onlineVehicles: onlineVehicles,
      onlineVehiclePercentage: vehicles.isEmpty
          ? 0
          : (onlineVehicles / vehicles.length) * 100,
      drowsyEventsToday: drowsyEventsToday,
      eventsNeedReview: eventsNeedReview == 0 ? latestAlerts.length : eventsNeedReview,
      highRiskDriverCount: highRiskDrivers
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
          eventsNeedReview == 0 ? '0' : '+$eventsNeedReview',
      highRiskDriversDeltaLabel: highRiskDrivers.isEmpty
          ? '0'
          : '${highRiskDrivers.length}',
      latestAlerts: latestAlerts,
      highRiskDrivers: highRiskDrivers,
      recentEvents: recentEvents,
      lastUpdatedLabel: _lastUpdatedLabel(latestAlerts),
    );
  }

  List<Map<String, dynamic>> _buildLatestAlerts() {
    final alerts = <Map<String, dynamic>>[];
    final fallbackLocations = ['Sunter, Jakarta Utara', 'Bekasi', 'Karawang'];

    driverAlerts.forEach((driverId, alert) {
      final driver = _driverById(driverId);
      final vehicle = _vehicleForDriver(driver, alert['vehicle_id']?.toString());
      final eventType = _formatEventType(alert['type']?.toString());
      final severity = _severityFromType(eventType);

      alerts.add({
        'driverName': driver?.name ?? 'Unknown Driver',
        'vehicleLabel': vehicle?.plateNumber ?? alert['vehicle_id']?.toString() ?? '-',
        'location': _locationForVehicle(vehicle, fallbackLocations[alerts.length % 3]),
        'time': _normalizeDateTime(alert['time']),
        'eventType': eventType,
        'severity': severity,
        'speedLabel':
            vehicle == null ? '-' : '${vehicle.speed.toStringAsFixed(0)} km/h',
      });
    });

    for (var i = 0; i < alertLog.length && alerts.length < 5; i++) {
      final driver = driversHealth.isEmpty
          ? null
          : driversHealth[i % driversHealth.length];
      final vehicle = vehicles.isEmpty ? null : vehicles[i % vehicles.length];
      final message = alertLog[i];
      final eventType = _eventTypeFromLog(message);
      final severity = _severityFromType(eventType);

      alerts.add({
        'driverName': driver?.name ?? _fallbackDriver(i),
        'vehicleLabel': vehicle?.plateNumber ?? _fallbackPlate(i),
        'location': _fallbackLocation(i),
        'time': DateTime.now().subtract(Duration(minutes: 14 * (i + 1))),
        'eventType': eventType,
        'severity': severity,
        'speedLabel':
            vehicle == null ? '${42 + (i * 5)} km/h' : '${vehicle.speed.toStringAsFixed(0)} km/h',
      });
    }

    alerts.sort(
      (a, b) => (_normalizeDateTime(b['time']))
          .compareTo(_normalizeDateTime(a['time'])),
    );

    return alerts.take(6).toList();
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

  List<Map<String, dynamic>> _buildRecentEvents(
    List<Map<String, dynamic>> latestAlerts,
  ) {
    if (latestAlerts.isNotEmpty) {
      return latestAlerts
          .map(
            (alert) => {
              'time': alert['time'],
              'eventType': alert['eventType'],
              'driverName': alert['driverName'],
              'vehicleLabel': alert['vehicleLabel'],
              'location': alert['location'],
              'severity': alert['severity'],
              'speedLabel': alert['speedLabel'],
            },
          )
          .toList();
    }

    return List.generate(5, (index) {
      return {
        'time': DateTime.now().subtract(Duration(minutes: 12 * (index + 1))),
        'eventType': index.isEven ? 'Drowsiness Detected' : 'Overspeed',
        'driverName': _fallbackDriver(index),
        'vehicleLabel': _fallbackPlate(index),
        'location': _fallbackLocation(index),
        'severity': index.isEven ? 'High' : 'Medium',
        'speedLabel': '${48 + (index * 6)} km/h',
      };
    });
  }

  DriverHealth? _driverById(int driverId) {
    for (final driver in driversHealth) {
      if (int.tryParse(driver.driverId) == driverId) {
        return driver;
      }
    }
    return null;
  }

  Vehicle? _vehicleForDriver(DriverHealth? driver, String? vehicleId) {
    if (vehicleId != null && vehicleId.isNotEmpty) {
      for (final vehicle in vehicles) {
        if (vehicle.id == vehicleId || vehicle.plateNumber == vehicleId) {
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

  String _eventTypeFromLog(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('drows')) return 'Drowsiness Detected';
    if (lower.contains('speed')) return 'Overspeed';
    if (lower.contains('co2')) return 'Device Warning';
    return 'Safety Alert';
  }

  String _severityFromType(String eventType) {
    final lower = eventType.toLowerCase();
    if (lower.contains('drows') || lower.contains('alert')) return 'High';
    if (lower.contains('braking') || lower.contains('speed')) return 'Medium';
    return 'Low';
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

  String _fallbackDriver(int index) {
    const names = [
      'Ahmad Fauzi',
      'Dimas Putra',
      'Rizky Pratama',
      'Hendra Wijaya',
      'Yudi Kurniawan',
    ];
    return names[index % names.length];
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

  String _fallbackLocation(int index) {
    const locations = [
      'Sunter, Jakarta Utara',
      'Bekasi, Jawa Barat',
      'Karawang, Jawa Barat',
      'Tambun, Bekasi',
      'Cikarang, Bekasi',
    ];
    return locations[index % locations.length];
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
    required this.highRiskDriversDeltaLabel,
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
  final String highRiskDriversDeltaLabel;
  final List<Map<String, dynamic>> latestAlerts;
  final List<Map<String, dynamic>> highRiskDrivers;
  final List<Map<String, dynamic>> recentEvents;
  final String lastUpdatedLabel;
}
