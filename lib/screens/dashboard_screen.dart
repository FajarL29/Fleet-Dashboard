import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/dashboard_provider.dart';
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
              Consumer<DashboardProvider>(
                builder: (context, provider, _) => Sidebar(
                  selectedIndex: provider.selectedMenuIndex,
                  onItemSelected: provider.selectMenuItem,
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
                              child: Consumer<DashboardProvider>(
                                builder: (context, provider, _) => MapSection(
                                  vehicles: provider.vehicles,
                                  onVehicleSelected: provider.selectVehicle,
                                ),
                              ),
                            ),
                            SizedBox(width: ResponsiveBreakpoints.contentSpacing(context)),

                            // Right Section (Driver Monitoring)
                            Expanded(
                              flex: 2,
                              child: Consumer<DashboardProvider>(
                                builder: (context, provider, _) => DriverMonitoring(
                                  drivers: provider.driversHealth,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveBreakpoints.contentSpacing(context)),

                      // Bottom Statistics Cards
                      Consumer<DashboardProvider>(
                        builder: (context, provider, _) => StatisticsCards(
                          aqiData: provider.aqiData,
                          onlineDrivers: provider.onlineDrivers,
                          highRiskAlerts: provider.highRiskAlerts,
                          alertLog: provider.alertLog,
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