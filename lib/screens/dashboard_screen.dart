import 'package:fleet_dashboard/screens/report_screen.dart';
import 'package:fleet_dashboard/screens/safety_screen.dart';
import 'package:fleet_dashboard/screens/vehicles_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_event.dart';
import '../bloc/dashboard/dashboard_state.dart';
import '../constants/menu_items.dart';
import '../widgets/driver_monitoring.dart';
import '../widgets/map_section.dart';
import '../widgets/overview/overview_dashboard.dart';
import '../widgets/sidebar.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MapController _mapController = MapController();
  bool _isMapFullScreen = false;
  bool _isMapFollowingVehicle = true;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  void _toggleMapFullScreen() {
    setState(() {
      _isMapFullScreen = !_isMapFullScreen;
    });
  }

  void _handleFollowModeChanged(bool isFollowing) {
    setState(() {
      _isMapFollowingVehicle = isFollowing;
    });
  }

  void _handleSidebarNavigation(int index) {
    final route = MenuItems.items[index].route;

    // Jika route adalah '/', kembali ke dashboard content
    if (route == '/') {
      _navigatorKey.currentState?.popUntil((route) => route.isFirst);
      return;
    }

    // Navigasi ke route lain menggunakan nested navigator
    _navigatorKey.currentState?.pushNamed(route);
  }

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
        listenWhen: (prev, curr) =>
            prev.selectedVehicle?.position != curr.selectedVehicle?.position,
        listener: (context, state) {
          if (state.selectedVehicle != null && _isMapFollowingVehicle) {
            _mapController.move(state.selectedVehicle!.position, 15.0);
          }
        },
        child: _isMapFullScreen
            ? _buildFullScreenOverlay(context)
            : _buildScrollableLayout(context),
      ),
    );
  }

  Widget _buildScrollableLayout(BuildContext context) {
    return ResponsiveLayout(child: _buildNormalLayout(context));
  }

  Widget _buildNormalLayout(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: MediaQuery.of(context).size.height,
      child: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Navigator(
              key: _navigatorKey,
              initialRoute: '/',
              onGenerateRoute: (settings) {
                switch (settings.name) {
                  case '/':
                    return MaterialPageRoute(
                      builder: (context) => _buildDashboardContent(),
                      settings: settings,
                    );
                  case '/reports':
                    return MaterialPageRoute(
                      builder: (context) => const ReportScreen(),
                      settings: settings,
                    );
                  case '/vehicles':
                    return MaterialPageRoute(
                      builder: (context) => const VehiclesScreen(),
                      settings: settings,
                    );
                  case '/drivers':
                    return MaterialPageRoute(
                      builder: (context) => _buildPlaceholderContent('Drivers'),
                      settings: settings,
                    );
                  case '/safety':
                    return MaterialPageRoute(
                      builder: (context) => const SafetyScreen(),
                      settings: settings,
                    );
                  case '/settings':
                    return MaterialPageRoute(
                      builder: (context) =>
                          _buildPlaceholderContent('Settings'),
                      settings: settings,
                    );
                  default:
                    return MaterialPageRoute(
                      builder: (context) => _buildPlaceholderContent('Unknown'),
                      settings: settings,
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (prev, curr) =>
          prev.vehicles != curr.vehicles ||
          prev.selectedVehicle != curr.selectedVehicle ||
          prev.driverAlerts != curr.driverAlerts ||
          prev.alertLog != curr.alertLog ||
          prev.driversHealth != curr.driversHealth ||
          prev.recentDrowsinessEvents != curr.recentDrowsinessEvents ||
          prev.currentDrowsinessReport != curr.currentDrowsinessReport ||
          prev.driverBehaviorSummaries != curr.driverBehaviorSummaries ||
          prev.isOverviewLoading != curr.isOverviewLoading ||
          prev.vehicleStatusData != curr.vehicleStatusData ||
          prev.vehicleStatusError != curr.vehicleStatusError,
      builder: (context, state) {
        return OverviewDashboard(
          mapController: _mapController,
          vehicles: state.vehicles,
          selectedVehicle: state.selectedVehicle,
          driverAlerts: state.driverAlerts,
          alertLog: state.alertLog,
          driversHealth: state.driversHealth,
          recentDrowsinessEvents: state.recentDrowsinessEvents,
          currentDrowsinessReport: state.currentDrowsinessReport,
          driverBehaviorSummaries: state.driverBehaviorSummaries,
          vehicleStatusData: state.vehicleStatusData,
          vehicleStatusError: state.vehicleStatusError,
          onVehicleSelected: (vehicle) =>
              context.read<DashboardBloc>().add(VehicleSelected(vehicle)),
          onClearSelection: () {
            context.read<DashboardBloc>().add(const SelectionCleared());
          },
          onFollowModeChanged: _handleFollowModeChanged,
          onOpenMapFullscreen: _toggleMapFullScreen,
          isLoading: state.isOverviewLoading,
        );
      },
    );
  }

  Widget _buildPlaceholderContent(String title) {
    return Center(
      child: Text(
        '$title Screen - Coming Soon',
        style: const TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }

  Widget _buildFullScreenOverlay(BuildContext context) {
    final state = context.watch<DashboardBloc>().state;
    return Stack(
      children: [
        // Full-screen map
        Positioned.fill(
          child: MapSection(
            mapController: _mapController,
            vehicles: state.vehicles,
            onVehicleSelected: (vehicle) =>
                context.read<DashboardBloc>().add(VehicleSelected(vehicle)),
            isFullScreen: true,
            showVehicleList: false,
            selectedVehicleId: state.selectedVehicle?.id,
            onClearSelection: () {
              context.read<DashboardBloc>().add(const SelectionCleared());
            },
            onFollowModeChanged: _handleFollowModeChanged,
          ),
        ),
        // Close button (top right)
        // Positioned(
        //   top: 40,
        //   right: 20,
        //   child: FloatingActionButton.small(
        //     backgroundColor: AppTheme.darkNavy,
        //     onPressed: _toggleMapFullScreen,
        //     child: const Icon(Icons.close, color: Colors.white),
        //   ),
        // ),
        // Driver monitoring panel (bottom)
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.slateGrey.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.darkNavy.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Driver 1',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _toggleMapFullScreen,
                        child: const Text(
                          'Exit Fullscreen',
                          style: TextStyle(color: AppTheme.accentBlue),
                        ),
                      ),
                    ],
                  ),
                ),
                // Scrollable driver monitoring content
                LayoutBuilder(
                  builder: (context, constraints) {
                    final maxHeight = MediaQuery.of(context).size.height * 0.5;
                    final panelHeight = constraints.maxWidth > 1200
                        ? 400.0
                        : 350.0;
                    final finalHeight = panelHeight.clamp(200.0, maxHeight);
                    return SizedBox(
                      height: finalHeight,
                      child: DriverMonitoring(
                        drivers: state.driversHealth,
                        driverAlerts: state.driverAlerts,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSidebar() {
    return BlocBuilder<DashboardBloc, DashboardState>(
      buildWhen: (prev, curr) =>
          prev.selectedMenuIndex != curr.selectedMenuIndex,
      builder: (context, state) => Sidebar(
        selectedIndex: state.selectedMenuIndex,
        onItemSelected: (index) =>
            context.read<DashboardBloc>().add(MenuItemSelected(index)),
        onItemTapped: _handleSidebarNavigation,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildMapArea(BuildContext context) {
    return Expanded(
      flex: ResponsiveBreakpoints.isLarge(context) ? 3 : 2,
      child: BlocBuilder<DashboardBloc, DashboardState>(
        buildWhen: (prev, curr) {
          final shouldRebuild =
              prev.vehicles != curr.vehicles ||
              prev.selectedVehicle != curr.selectedVehicle;
          if (shouldRebuild) {
            // ignore: avoid_print
            print(
              '🔄 BlocBuilder rebuild triggered: vehicles=${prev.vehicles.length != curr.vehicles.length}, selectedVehicle=${prev.selectedVehicle?.id} -> ${curr.selectedVehicle?.id}',
            );
          }
          return shouldRebuild;
        },
        builder: (context, state) {
          // ignore: avoid_print
          print(
            '🏗️ Building MapSection with selectedVehicleId: ${state.selectedVehicle?.id}',
          );
          return MapSection(
            mapController: _mapController,
            vehicles: state.vehicles,
            onVehicleSelected: (vehicle) =>
                context.read<DashboardBloc>().add(VehicleSelected(vehicle)),
            onFullScreenToggle: _toggleMapFullScreen,
            isFullScreen: _isMapFullScreen,
            selectedVehicleId: state.selectedVehicle?.id,
            onClearSelection: () {
              print('📤 Sending SelectionCleared event');
              context.read<DashboardBloc>().add(const SelectionCleared());
            },
            onFollowModeChanged: _handleFollowModeChanged,
          );
        },
      ),
    );
  }

  // Widget _buildDriverMonitoringArea() {
  //   return Expanded(
  //     flex: 2,
  //     child: BlocBuilder<DashboardBloc, DashboardState>(
  //       buildWhen: (prev, curr) =>
  //           prev.driversHealth != curr.driversHealth ||
  //           prev.driverAlerts != curr.driverAlerts,
  //       builder: (context, state) {
  //         return DriverMonitoring(
  //           drivers: state.driversHealth,
  //           driverAlerts: state.driverAlerts,
  //         );
  //       },
  //     ),
  //   );
  // }

  // Widget _buildStatisticsArea() {
  //   return BlocBuilder<DashboardBloc, DashboardState>(
  //     buildWhen: (prev, curr) =>
  //         prev.aqiData != curr.aqiData ||
  //         prev.onlineDrivers != curr.onlineDrivers ||
  //         prev.highRiskAlerts != curr.highRiskAlerts ||
  //         prev.alertLog != curr.alertLog,
  //     builder: (context, state) => StatisticsCards(
  //       aqiData: state.aqiData,
  //       onlineDrivers: state.onlineDrivers,
  //       highRiskAlerts: state.highRiskAlerts,
  //       alertLog: state.alertLog,
  //     ),
  //   );
  // }
}
