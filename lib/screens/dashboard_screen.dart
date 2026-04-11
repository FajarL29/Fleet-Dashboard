import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_event.dart';
import '../bloc/dashboard/dashboard_state.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/map_section.dart';
import '../widgets/driver_monitoring.dart';
import '../widgets/statistics_cards.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: ResponsiveLayout(
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Row(
            children: [
              // Sidebar
              BlocBuilder<DashboardBloc, DashboardState>(
                buildWhen: (previous, current) =>
                    previous.selectedMenuIndex != current.selectedMenuIndex,
                builder: (context, state) => Sidebar(
                  selectedIndex: state.selectedMenuIndex,
                  onItemSelected: (index) {
                    context.read<DashboardBloc>().add(MenuItemSelected(index));
                  },
                ),
              ),

              // Main Content
              Expanded(
                child: Padding(
                  padding: ResponsiveBreakpoints.screenPadding(context),
                  child: Column(
                    children: [
                      // Header
                      const Header(),
                      SizedBox(height: ResponsiveBreakpoints.contentSpacing(context)),

                      // Main Content Area
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left Section (Map)
                            Expanded(
                              flex: ResponsiveBreakpoints.isLarge(context) ? 3 : 2,
                              child: BlocBuilder<DashboardBloc, DashboardState>(
                                buildWhen: (previous, current) =>
                                    previous.vehicles != current.vehicles,
                                builder: (context, state) => MapSection(
                                  vehicles: state.vehicles,
                                  onVehicleSelected: (vehicle) {
                                    context.read<DashboardBloc>().add(VehicleSelected(vehicle));
                                  },
                                ),
                              ),
                            ),
                            SizedBox(width: ResponsiveBreakpoints.contentSpacing(context)),

                            // Right Section (Driver Monitoring)
                            Expanded(
                              flex: 2,
                              child: BlocBuilder<DashboardBloc, DashboardState>(
                                buildWhen: (previous, current) {
                                  // Cek apakah driversHealth berubah
                                  if (previous.driversHealth != current.driversHealth) {
                                    debugPrint("🔄 Rebuild: driversHealth berubah");
                                    return true;
                                  }
                                  // Cek apakah driverAlerts berubah (deep comparison)
                                  if (previous.driverAlerts.length != current.driverAlerts.length) {
                                    debugPrint("🔄 Rebuild: driverAlerts length berubah dari ${previous.driverAlerts.length} ke ${current.driverAlerts.length}");
                                    return true;
                                  }
                                  for (final key in previous.driverAlerts.keys) {
                                    if (!current.driverAlerts.containsKey(key)) {
                                      debugPrint("🔄 Rebuild: driverAlerts key $key tidak ditemukan di current");
                                      return true;
                                    }
                                    if (previous.driverAlerts[key]!.toString() != current.driverAlerts[key]!.toString()) {
                                      debugPrint("🔄 Rebuild: driverAlerts[$key] berubah");
                                      debugPrint("   Previous: ${previous.driverAlerts[key]}");
                                      debugPrint("   Current: ${current.driverAlerts[key]}");
                                      return true;
                                    }
                                  }
                                  debugPrint("🔄 Tidak perlu rebuild");
                                  return false;
                                },
                                builder: (context, state) {
                                  debugPrint("🔄 DriverMonitoring rebuild dengan driverAlerts: ${state.driverAlerts}");
                                  return DriverMonitoring(
                                    drivers: state.driversHealth,
                                    driverAlerts: state.driverAlerts,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveBreakpoints.contentSpacing(context)),

                      // Bottom Statistics Cards
                      BlocBuilder<DashboardBloc, DashboardState>(
                        buildWhen: (previous, current) =>
                            previous.aqiData != current.aqiData ||
                            previous.onlineDrivers != current.onlineDrivers ||
                            previous.highRiskAlerts != current.highRiskAlerts ||
                            previous.alertLog != current.alertLog,
                        builder: (context, state) => StatisticsCards(
                          aqiData: state.aqiData,
                          onlineDrivers: state.onlineDrivers,
                          highRiskAlerts: state.highRiskAlerts,
                          alertLog: state.alertLog,
                        ),
                      ),
                    ],
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