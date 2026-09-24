import 'package:fleet_dashboard/screens/air_quality_screen.dart';
import 'package:fleet_dashboard/screens/driver_screen.dart';
import 'package:fleet_dashboard/screens/live_tracking_screen.dart';
import 'package:fleet_dashboard/screens/report_screen.dart';
import 'package:fleet_dashboard/screens/safety_screen.dart';
import 'package:fleet_dashboard/screens/vehicles_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import '../bloc/auth/auth_cubit.dart';
import '../bloc/dashboard/dashboard_bloc.dart';
import '../bloc/dashboard/dashboard_event.dart';
import '../bloc/dashboard/dashboard_state.dart';
import '../constants/menu_items.dart';
import '../models/auth_user.dart';
import '../models/user_role.dart';
import '../widgets/common/app_page_surface.dart';
import '../widgets/auth/role_scope.dart';
import '../services/live_fix_merge.dart';
import '../widgets/common/app_top_bar.dart';
import '../widgets/driver_monitoring.dart';
import '../widgets/map_section.dart';
import '../widgets/overview/overview_dashboard.dart';
import '../widgets/sidebar.dart';
import '../theme/app_theme.dart';
import '../utils/responsive_layout.dart';

/// Reports the top route whenever the nested navigator's stack changes.
///
/// Tracks the stack itself rather than reading the callback arguments: a
/// `pushNamedAndRemoveUntil` removes routes from the middle of the stack, and
/// `didRemove` hands back the route *below* the removed one, which is not
/// where the user ended up.
class _RouteSyncObserver extends NavigatorObserver {
  _RouteSyncObserver({required this.onRouteChanged});

  final ValueChanged<String?> onRouteChanged;

  final List<Route<dynamic>> _stack = [];

  /// Deferred to the next frame: the observer fires during navigation, and
  /// dispatching a bloc event mid-build would rebuild the widget tree while
  /// it is already being laid out.
  void _report() {
    if (_stack.isEmpty) return;
    final name = _stack.last.settings.name;
    WidgetsBinding.instance.addPostFrameCallback((_) => onRouteChanged(name));
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _report();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _report();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _report();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (index >= 0 && newRoute != null) {
      _stack[index] = newRoute;
    } else if (newRoute != null) {
      _stack.add(newRoute);
    }
    _report();
  }
}

/// Sidebar pages swap in place; a slide animation only delays the content.
class _InstantRoute<T> extends MaterialPageRoute<T> {
  _InstantRoute({required super.builder, super.settings});

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // TODO: read these from the session once the app has an auth flow.
  /// Shown while the account bar has no session to read from — the sign-out
  /// frame between [AuthCubit] clearing the session and the gate swapping in
  /// the login page.
  static const String _fallbackUserName = 'Account';

  final MapController _mapController = MapController();
  bool _isMapFullScreen = false;
  bool _isMapFollowingVehicle = true;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  /// Keeps the sidebar highlight tied to the route that is actually on screen.
  ///
  /// The highlight used to be set only by the code that opened a route, so
  /// anything navigating another way — a "View All" link, a back gesture —
  /// left it pointing at the previous page.
  late final NavigatorObserver _routeObserver = _RouteSyncObserver(
    onRouteChanged: _syncSelectedMenu,
  );

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

  /// Clearing the session flips [AuthGate] back to the login page, which
  /// tears this screen down — so there is nothing to route to by hand.
  void _handleLogout() {
    context.read<AuthCubit>().logout();
  }

  /// What the signed-in person may do.
  UserRole get _role => RoleScope.of(context);

  /// The signed-in user, or null in the brief frame after signing out.
  AuthUser? get _sessionUser => context.watch<AuthCubit>().state.session?.user;

  /// Moves the sidebar highlight to whichever menu entry owns [route].
  ///
  /// Routes with no menu entry (e.g. /settings) leave the highlight alone
  /// rather than clearing it, so the sidebar never shows nothing selected.
  void _syncSelectedMenu(String? route) {
    if (route == null) return;
    final index = MenuItems.items.indexWhere((item) => item.route == route);
    if (index < 0) return;

    final bloc = context.read<DashboardBloc>();
    if (bloc.state.selectedMenuIndex == index) return;
    bloc.add(MenuItemSelected(index));
  }

  void _handleSidebarNavigation(int index) {
    _openRoute(MenuItems.items[index].route);
  }

  /// Navigates the nested navigator and keeps the sidebar highlight in sync,
  /// so routes opened from outside the sidebar (e.g. the account menu) behave
  /// the same as a sidebar tap.
  void _openRoute(String route) {
    // The observer syncs the highlight for us once the route settles, so this
    // only has to do the navigating.
    if (route == '/') {
      _navigatorKey.currentState?.popUntil((entry) => entry.isFirst);
      return;
    }

    // Replace rather than stack: pushNamed left every visited page mounted,
    // so their timers and loads kept firing in the background and a repeated
    // sidebar tap opened a second copy of the same page.
    _navigatorKey.currentState?.pushNamedAndRemoveUntil(
      route,
      (entry) => entry.isFirst,
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.shell,
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
            child: Column(
              children: [
                // Account bar sits in the shell so every route keeps it.
                AppTopBar(
                  userName: _sessionUser?.fullname.isNotEmpty == true
                      ? _sessionUser!.fullname
                      : _sessionUser?.username ?? _fallbackUserName,
                  userRole: _role.label,
                  // Null hides the menu entry, matching the sidebar.
                  onOpenSetting: _role.canOpenSettings
                      ? () => _openRoute('/settings')
                      : null,
                  onLogout: _handleLogout,
                ),
                Expanded(child: _buildPageNavigator()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNavigator() {
    return Navigator(
      key: _navigatorKey,
      initialRoute: '/',
      observers: [_routeObserver],
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return _InstantRoute(
              builder: (context) => _buildDashboardContent(),
              settings: settings,
            );
          case '/reports':
            return _InstantRoute(
              builder: (context) => const ReportScreen(),
              settings: settings,
            );
          case '/vehicles':
            return _InstantRoute(
              builder: (context) => const VehiclesScreen(),
              settings: settings,
            );
          case '/live-tracking':
            return _InstantRoute(
              builder: (context) => const LiveTrackingScreen(),
              settings: settings,
            );
          case '/air-quality':
            return _InstantRoute(
              builder: (context) => const AirQualityScreen(),
              settings: settings,
            );
          case '/vital-sign':
            return _InstantRoute(
              builder: (context) => const DriverScreen(),
              settings: settings,
            );
          case '/safety':
            return _InstantRoute(
              builder: (context) => const SafetyScreen(),
              settings: settings,
            );
          case '/settings':
            // Reached only if something navigates here directly. The entries
            // are already hidden, so this is the backstop rather than the
            // normal path.
            if (!_role.canOpenSettings) {
              return _InstantRoute(
                builder: (context) => const _NoAccessPage(),
                settings: settings,
              );
            }
            return _InstantRoute(
              builder: (context) => _buildPlaceholderContent('Settings'),
              settings: settings,
            );
          default:
            return _InstantRoute(
              builder: (context) => _buildPlaceholderContent('Unknown'),
              settings: settings,
            );
        }
      },
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
          prev.vehicleStatusError != curr.vehicleStatusError ||
          prev.liveFixes != curr.liveFixes ||
          prev.aqiData != curr.aqiData,
      builder: (context, state) {
        // The KPI row and the map read the same merged payload, so the
        // headline count cannot disagree with the markers underneath it.
        // The server's own summary is a snapshot from when it answered and
        // knows nothing about fixes that arrived since.
        final status = mergeVehicleStatus(
          state.vehicleStatusData,
          state.liveFixes,
          includeUnregistered: true,
          safetyEvents: state.recentDrowsinessEvents,
        );

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
          vehicleStatusData: state.vehicleStatusData == null ? null : status,
          vehicleStatusError: state.vehicleStatusError,
          aqiData: state.aqiData,
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
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 24),
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
            useLocalSelection: true,
            isFullScreen: true,
            showVehicleList: false,
            selectedVehicleId: state.selectedVehicle?.id,
            onFollowModeChanged: _handleFollowModeChanged,
            // Same basemap as the cards, so going fullscreen is not a jarring
            // switch from dark to light.
            tileUrlTemplate: AppMapStyle.tileUrl,
            tileSubdomains: AppMapStyle.tileSubdomains,
            tileMaxNativeZoom: AppMapStyle.tileMaxNativeZoom,
            tileAttribution: AppMapStyle.tileAttribution,
            tileOverlayColor: AppMapStyle.tint,
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
            debugPrint(
              '🔄 BlocBuilder rebuild triggered: vehicles=${prev.vehicles.length != curr.vehicles.length}, selectedVehicle=${prev.selectedVehicle?.id} -> ${curr.selectedVehicle?.id}',
            );
          }
          return shouldRebuild;
        },
        builder: (context, state) {
          debugPrint(
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
              debugPrint('📤 Sending SelectionCleared event');
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

/// Shown when a route is opened that this role may not see.
class _NoAccessPage extends StatelessWidget {
  const _NoAccessPage();

  @override
  Widget build(BuildContext context) {
    return AppPageSurface(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_outline_rounded,
              size: 34,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'You do not have access to this page',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ask an administrator if you need it.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
