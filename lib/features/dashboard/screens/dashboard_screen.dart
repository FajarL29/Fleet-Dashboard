import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/dashboard_bloc.dart';
import '../bloc/dashboard_state.dart';
import '../bloc/dashboard_event.dart';
import '../widgets/sidebar.dart';
import '../widgets/header.dart';
import '../widgets/map_section.dart';
import '../widgets/driver_monitoring.dart';
import '../widgets/statistics_cards.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/responsive_layout.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DashboardBloc, DashboardState>(
      builder: (context, mainState) {
        // 1. Cek jika state belum siap
        if (mainState is! DashboardLoaded) {
          return const Scaffold(
            backgroundColor: AppTheme.darkNavy,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. Jika siap, tampilkan UI utama menggunakan mainState
        return Scaffold(
          backgroundColor: AppTheme.darkNavy,
          body: ResponsiveLayout(
            child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: Row(
                children: [
                  // SIDEBAR
                  Sidebar(
                    selectedIndex: mainState.selectedMenuIndex,
                    onItemSelected: (index) {
                      context.read<DashboardBloc>().add(ChangeMenuIndex(index));
                    },
                  ),

                  // MAIN CONTENT
                  Expanded(
                    child: Padding(
                      padding: ResponsiveBreakpoints.screenPadding(context),
                      child: Column(
                        children: [
                          const Header(),
                          SizedBox(height: ResponsiveBreakpoints.contentSpacing(context)),

                          // MAP & MONITORING SECTION
                          Expanded(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // MAP (Hanya rebuild jika data kendaraan berubah)
                                Expanded(
  flex: ResponsiveBreakpoints.isLarge(context) ? 3 : 2,
  child: BlocBuilder<DashboardBloc, DashboardState>(
    // HANYA rebuild MapSection jika jumlah kendaraan berubah 
    // atau jika state baru pertama kali loaded.
    buildWhen: (p, c) {
      if (p is! DashboardLoaded && c is DashboardLoaded) return true;
      if (p is DashboardLoaded && c is DashboardLoaded) {
        // Jangan rebuild jika cuma koordinat yang berubah (GPS update)
        return p.vehicles.length != c.vehicles.length;
      }
      return false;
    },
    builder: (context, state) {
      if (state is DashboardLoaded) {
        return MapSection(
          key: const PageStorageKey('dashboard_map'), // Kunci agar state tetap terjaga
          vehicles: state.vehicles,
          onVehicleSelected: (vehicle) {
            // Trigger tracking ke BLoC
            context.read<DashboardBloc>().add(StartGpsTracking(vehicle.id));
            // Pergerakan kamera ditangani INTERNAL di dalam MapSection lewat MapController
          },
        );
      }
      return const Center(child: CircularProgressIndicator());
    },
  ),
),
                                
                                SizedBox(width: ResponsiveBreakpoints.contentSpacing(context)),

                                // DRIVER MONITORING (Menggunakan mainState)
                                Expanded(
                                  flex: 2,
                                  child: DriverMonitoring(
                                    drivers: mainState.drivers, // Data driver sekarang muncul
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          SizedBox(height: ResponsiveBreakpoints.contentSpacing(context)),

                          // STATISTICS CARDS
                          StatisticsCards(
                            aqiData: mainState.aqiData,
                            onlineDrivers: mainState.onlineDrivers,
                            highRiskAlerts: mainState.highRiskAlerts,
                            alertLog: mainState.alertLog,
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
      },
    );
  }
}