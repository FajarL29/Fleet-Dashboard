import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../models/aqi_data.dart';
import '../../models/driver_behavior_summary.dart';
import '../../models/driver_health.dart';
import '../../models/drowsiness_report.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_status.dart';
import '../common/app_page_body.dart';
import '../../theme/app_theme.dart';
import '../common/app_page_surface.dart';
import '../common/fleet_loader.dart';
import 'overview_air_quality_card.dart';
import 'overview_high_risk_driver_card.dart';
import 'overview_kpi_row.dart';
import 'overview_map_card.dart';
import 'overview_page_header.dart';
import 'overview_vital_sign_card.dart';

/// Telematics Overview page: composes the sections and hands each one the raw
/// models it needs. Data itself comes from `DashboardBloc` via
/// `DashboardScreen`.
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
    this.aqiData = const AQIData(index: 0, pm25: 0, co2: 0, no2: 0),
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
  final AQIData aqiData;
  final ValueChanged<Vehicle> onVehicleSelected;
  final VoidCallback onClearSelection;
  final ValueChanged<bool> onFollowModeChanged;
  final VoidCallback onOpenMapFullscreen;
  final bool isLoading;

  /// Layouts below this width stack the sections into one column.
  static const double _wideBreakpoint = 940;

  /// Smallest the map / tables row may be before the page starts scrolling
  /// instead of stretching.
  static const double _minBottomRowHeight = 320;

  /// Below this the panel cannot hold the whole page, so it scrolls rather
  /// than squeezing the map into a letterbox.
  static const double _minFillHeight = 620;

  static const EdgeInsets _pagePadding = EdgeInsets.fromLTRB(26, 24, 26, 26);

  static const String _loadingMessage = 'Loading fleet overview...';

  @override
  Widget build(BuildContext context) {
    final hasOverviewData =
        vehicleStatusData != null ||
        currentDrowsinessReport != null ||
        recentDrowsinessEvents.isNotEmpty ||
        driverBehaviorSummaries.isNotEmpty;

    if (isLoading && !hasOverviewData) {
      return const AppPageSurface(
        child: Center(child: FleetLoader(message: _loadingMessage)),
      );
    }

    final dashboard = AppPageSurface(
      child: AppPageBody(
        wideBreakpoint: _wideBreakpoint,
        // The map / high-risk row grows to take up whatever height is left,
        // so this page can be pinned to the bottom of the panel.
        canFill: true,
        minFillHeight: _minFillHeight,
        padding: _pagePadding,
        builder: (context, {required isWide, required fills}) =>
            _buildSections(isWide: isWide, fills: fills),
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
        // On a card so it stays legible over the dimmed page behind it.
        Center(
          child: IgnorePointer(
            child: Container(
              padding: const EdgeInsets.fromLTRB(28, 22, 28, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1A0F1D3D),
                    blurRadius: 24,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const FleetLoader(message: _loadingMessage),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSections({required bool isWide, required bool fills}) {
    final todayEvents = _todayEvents();

    final kpiRow = OverviewKpiRow(
      vehicleStatusData: vehicleStatusData,
      todayEvents: todayEvents,
      report: currentDrowsinessReport,
      isWide: isWide,
    );

    final vitalSign = OverviewVitalSignCard(driversHealth: driversHealth);
    final airQuality = OverviewAirQualityCard(
      aqiData: aqiData,
      vehicleStatusData: vehicleStatusData,
      vehicles: vehicles,
    );

    final map = OverviewMapCard(
      mapController: mapController,
      vehicles: vehicles,
      selectedVehicleId: selectedVehicle?.id,
      vehicleStatusData: vehicleStatusData,
      vehicleStatusError: vehicleStatusError,
      onFollowModeChanged: onFollowModeChanged,
      onOpenFullscreen: onOpenMapFullscreen,
    );
    final highRisk = OverviewHighRiskDriverCard(
      vehicleStatusData: vehicleStatusData,
    );

    final bottomRow = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 385, child: map),
        const SizedBox(width: 12),
        Expanded(flex: 412, child: highRisk),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OverviewPageHeader(
          lastUpdated: DateTime.now(),
          vehicleStatusData: vehicleStatusData,
          isWide: isWide,
        ),
        const SizedBox(height: 22),
        kpiRow,
        const SizedBox(height: 14),
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 19, child: vitalSign),
                const SizedBox(width: 12),
                Expanded(flex: 20, child: airQuality),
              ],
            ),
          )
        else ...[
          vitalSign,
          const SizedBox(height: 12),
          airQuality,
        ],
        const SizedBox(height: 14),
        if (fills)
          // Takes whatever height is left, which is what makes the page reach
          // the bottom of the panel on every window size.
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _minBottomRowHeight),
              child: bottomRow,
            ),
          )
        else if (isWide)
          SizedBox(height: _minBottomRowHeight, child: bottomRow)
        else ...[
          SizedBox(height: 280, child: map),
          const SizedBox(height: 12),
          SizedBox(height: 340, child: highRisk),
        ],
      ],
    );
  }

  /// Today's safety events, newest first.
  List<DrowsinessEvent> _todayEvents() {
    final now = DateTime.now();
    return recentDrowsinessEvents
        .where(
          (event) =>
              event.time.year == now.year &&
              event.time.month == now.month &&
              event.time.day == now.day,
        )
        .toList()
      ..sort((a, b) => b.time.compareTo(a.time));
  }
}
