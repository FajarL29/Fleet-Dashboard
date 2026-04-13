import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart'; // Wajib untuk controller
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Controller ini ditaruh di sini agar bisa diakses oleh BlocListener
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkNavy,
      body: BlocListener<DashboardBloc, DashboardState>(
        // Fokus Listener: Gerakkan kamera peta jika posisi kendaraan terpilih berubah
        listenWhen: (prev, curr) =>
            prev.selectedVehicle?.position != curr.selectedVehicle?.position,
        listener: (context, state) {
          if (state.selectedVehicle != null) {
            _mapController.move(state.selectedVehicle!.position, 15.0);
          }
        },
        child: ResponsiveLayout(
          child: SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Row(
              children: [
                // 1. SIDEBAR SECTION
                _buildSidebar(),

                // 2. MAIN CONTENT SECTION
                Expanded(
                  child: Padding(
                    padding: ResponsiveBreakpoints.screenPadding(context),
                    child: Column(
                      children: [
                        const Header(),
                        SizedBox(height: ResponsiveBreakpoints.contentSpacing(context)),
                        
                        // 3. MIDDLE SECTION (MAP & MONITORING)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildMapArea(context),
                              SizedBox(width: ResponsiveBreakpoints.contentSpacing(context)),
                              _buildDriverMonitoringArea(),
                            ],
                          ),
                        ),
                        
                        SizedBox(height: ResponsiveBreakpoints.contentSpacing(context)),

                        // 4. BOTTOM SECTION (STATISTICS)
                        _buildStatisticsArea(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS (Untuk menjaga kode tetap bersih/clean) ---

  Widget _buildSidebar() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (prev, curr) => prev.selectedMenuIndex != curr.selectedMenuIndex,
      builder: (context, state) => Sidebar(
        selectedIndex: state.selectedMenuIndex,
        onItemSelected: (index) =>
            context.read<DashboardBloc>().add(MenuItemSelected(index)),
      ),
    );
  }

  Widget _buildMapArea(BuildContext context) {
    return Expanded(
      flex: ResponsiveBreakpoints.isLarge(context) ? 3 : 2,
      child: BlocBuilder<DashboardBloc, DashboardState>(
        // Rebuild peta hanya jika list kendaraan berubah (misal: GPS baru masuk)
        buildWhen: (prev, curr) => prev.vehicles != curr.vehicles,
        builder: (context, state) => MapSection(
          mapController: _mapController, // Inject controller ke dalam MapSection
          vehicles: state.vehicles,
          onVehicleSelected: (vehicle) =>
              context.read<DashboardBloc>().add(VehicleSelected(vehicle)),
        ),
      ),
    );
  }

  Widget _buildDriverMonitoringArea() {
    return Expanded(
      flex: 2,
      child: BlocBuilder<DashboardBloc, DashboardState>(
        // Gunakan identitas objek untuk pengecekan cepat
        buildWhen: (prev, curr) =>
            prev.driversHealth != curr.driversHealth ||
            prev.driverAlerts != curr.driverAlerts,
        builder: (context, state) {
          return DriverMonitoring(
            drivers: state.driversHealth,
            driverAlerts: state.driverAlerts,
          );
        },
      ),
    );
  }

  Widget _buildStatisticsArea() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (prev, curr) =>
          prev.aqiData != curr.aqiData ||
          prev.onlineDrivers != curr.onlineDrivers ||
          prev.highRiskAlerts != curr.highRiskAlerts ||
          prev.alertLog != curr.alertLog,
      builder: (context, state) => StatisticsCards(
        aqiData: state.aqiData,
        onlineDrivers: state.onlineDrivers,
        highRiskAlerts: state.highRiskAlerts,
        alertLog: state.alertLog,
      ),
    );
  }
}