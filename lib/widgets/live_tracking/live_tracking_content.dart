import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/vehicle.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_event.dart';
import '../../models/live_gps_fix.dart';
import '../../services/live_fix_merge.dart';
import '../../models/vehicle_status.dart';
import '../../services/vehicle_management_service.dart';
import '../common/app_page_surface.dart';
import '../common/fleet_loader.dart';
import 'live_tracking_header.dart';
import 'live_tracking_map_card.dart';
import 'live_tracking_status.dart';
import 'live_tracking_vehicle_detail_panel.dart';
import '../../theme/app_theme.dart';

/// Live Tracking page: owns the polling, search, status filter, paging and map
/// selection state, and feeds the sections below it.
class LiveTrackingContent extends StatefulWidget {
  const LiveTrackingContent({super.key});

  @override
  State<LiveTrackingContent> createState() => _LiveTrackingContentState();
}

class _LiveTrackingContentState extends State<LiveTrackingContent> {
  static const int _pageSize = 10;
  static const double _wideBreakpoint = 940;

  final VehicleManagementService _registryService =
      const VehicleManagementService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  /// Mirrored from `DashboardBloc` on every build — this page no longer
  /// fetches status itself.
  VehicleStatusData? _statusData;
  String? _sharedError;

  /// Vehicle type per vehicle key, joined in from the registry. Best effort:
  /// the page still works when the registry call fails.
  Map<String, String> _vehicleTypes = const {};

  LiveTrackingStatus? _statusFilter;
  String _searchQuery = '';
  String? _vehicleFilterKey;
  String? _selectedVehicleKey;
  int _page = 0;

  /// True until the shared bloc has delivered its first status payload.
  bool get _isLoading => _statusData == null && _sharedError == null;

  /// Set only when the bloc has nothing to show at all; once rows exist, a
  /// failed poll is reported as a soft banner instead of blanking the page.
  String? get _loadError => _statusData == null ? _sharedError : null;

  String? get _refreshError => _statusData == null ? null : _sharedError;

  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _loadVehicleTypes();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // --- DATA ---------------------------------------------------------------

  /// Vehicle types live in the registry, not the status feed, so they are
  /// fetched separately and joined by vehicle id / VIN / plate.
  Future<void> _loadVehicleTypes() async {
    try {
      final registry = await _registryService.getVehicles(limit: 200);
      if (!mounted) return;

      final types = <String, String>{};
      for (final item in registry.vehicles) {
        final type = item.vehicleType.trim();
        if (type.isEmpty) continue;
        for (final key in [
          item.vehicleId,
          item.vehicleIdentificationNumber,
          item.plateNumber,
        ]) {
          final trimmed = key.trim();
          if (trimmed.isNotEmpty) types[trimmed] = type;
        }
      }

      setState(() => _vehicleTypes = types);
    } catch (error) {
      // Non-fatal: rows fall back to "-" for the vehicle type.
      if (kDebugMode) {
        debugPrint('[LiveTracking] Vehicle registry unavailable: $error');
      }
    }
  }

  // --- DERIVED ------------------------------------------------------------

  /// The status rows with live GPS overlaid.
  ///
  /// The websocket belongs to [DashboardBloc], which sits above this page, so
  /// the fixes are read from there rather than opening a second socket. Rows
  /// the tracker is transmitting for but the registry does not list are kept:
  /// this is the live map, and something really is out there moving.
  List<VehicleStatusItem> get _allVehicles => applyLiveFixes(
    _statusData?.vehicles ?? const <VehicleStatusItem>[],
    _liveFixes,
    includeUnregistered: true,
  );

  Map<String, LiveGpsFix> _liveFixes = const {};

  List<String> get _vehiclePlates => _allVehicles
      .map(liveTrackingPlateLabel)
      .where((plate) => plate.isNotEmpty)
      .toSet()
      .toList();

  String? get _selectedVehicleFilterPlate {
    final key = _vehicleFilterKey;
    if (key == null) return null;

    for (final item in _allVehicles) {
      if (liveTrackingVehicleKey(item) == key) {
        return liveTrackingPlateLabel(item);
      }
    }
    return null;
  }

  List<VehicleStatusItem> get _filteredVehicles {
    final query = _searchQuery.trim().toLowerCase();

    return _allVehicles.where((item) {
      if (_vehicleFilterKey != null &&
          liveTrackingVehicleKey(item) != _vehicleFilterKey) {
        return false;
      }
      if (_statusFilter != null &&
          liveTrackingStatusOf(item) != _statusFilter) {
        return false;
      }
      if (query.isEmpty) return true;

      return [
        item.plateNumber,
        item.vehicleIdentificationNumber,
        item.driverName,
        item.deviceStatus,
        item.displayStatus,
        item.statusReason,
      ].join(' ').toLowerCase().contains(query);
    }).toList();
  }

  Map<LiveTrackingStatus, int> get _counts {
    final counts = <LiveTrackingStatus, int>{};
    for (final item in _allVehicles) {
      final status = liveTrackingStatusOf(item);
      counts[status] = (counts[status] ?? 0) + 1;
    }
    return counts;
  }

  int _pageCountFor(int itemCount) =>
      itemCount == 0 ? 1 : (itemCount + _pageSize - 1) ~/ _pageSize;

  void _clampPage() {
    final pageCount = _pageCountFor(_filteredVehicles.length);
    if (_page >= pageCount) _page = pageCount - 1;
    if (_page < 0) _page = 0;
  }

  /// Vehicles that can actually be drawn, mapped onto the map's model.
  List<Vehicle> get _mapVehicles => _allVehicles
      .where(
        (item) =>
            _vehicleFilterKey == null ||
            liveTrackingVehicleKey(item) == _vehicleFilterKey,
      )
      .where((item) => item.hasCoordinates)
      .map(_toMapVehicle)
      .toList();

  Vehicle _toMapVehicle(VehicleStatusItem item) {
    final status = liveTrackingStatusOf(item);

    return Vehicle(
      id: liveTrackingVehicleKey(item),
      apiVehicleId: item.vehicleIdentificationNumber.isNotEmpty
          ? item.vehicleIdentificationNumber
          : null,
      plateNumber: liveTrackingPlateLabel(item),
      type: _vehicleTypes[liveTrackingVehicleKey(item)] ?? 'Unknown',
      driverName: item.driverName.trim().isEmpty
          ? 'Unknown Driver'
          : item.driverName.trim(),
      activityTime: liveTrackingLastSeenLabel(item),
      position: LatLng(item.latitude!, item.longitude!),
      status: switch (status) {
        LiveTrackingStatus.emergency => VehicleStatus.alert,
        LiveTrackingStatus.idle => VehicleStatus.warning,
        LiveTrackingStatus.offline => VehicleStatus.inactive,
        _ => VehicleStatus.active,
      },
      speed: item.speed ?? 0,
      heading: item.heading ?? 0,
      displayStatus: liveTrackingStatusLabel(item),
      statusReason: item.statusReason,
      lastTelemetryTime: item.lastTelemetryTime,
      lastSeenMinutes: item.lastSeenMinutes,
    );
  }

  String? get _mapStateMessage {
    if (_refreshError != null) return _refreshError;
    if (_allVehicles.isEmpty) return 'Vehicle status data unavailable';
    if (_mapVehicles.isEmpty) return 'No vehicle coordinates available';
    return null;
  }

  // --- HANDLERS -----------------------------------------------------------

  void _handleSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;

    setState(() {
      _searchQuery = query;
      _page = 0;
      _clampPage();
    });
  }

  void _handleFilterChanged(LiveTrackingStatus? status) {
    setState(() {
      _statusFilter = status;
      _page = 0;
      _clampPage();
    });
  }

  void _handleVehicleFilterChanged(String? plate) {
    final vehicle = plate == null
        ? null
        : _allVehicles.cast<VehicleStatusItem?>().firstWhere(
            (item) => liveTrackingPlateLabel(item!) == plate,
            orElse: () => null,
          );

    setState(() {
      _vehicleFilterKey = vehicle == null
          ? null
          : liveTrackingVehicleKey(vehicle);
      _page = 0;
      _clampPage();
    });
  }

  void _handleVehicleTap(VehicleStatusItem item) {
    setState(() => _selectedVehicleKey = liveTrackingVehicleKey(item));

    if (item.hasCoordinates) {
      _mapController.move(LatLng(item.latitude!, item.longitude!), 15);
    }
  }

  void _handleMapVehicleSelected(Vehicle vehicle) {
    setState(() => _selectedVehicleKey = vehicle.id);
  }

  // --- BUILD --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Both the rows and the live fixes come from the one bloc that owns the
    // status poll and the GPS socket, so this page and Overview's map are
    // showing literally the same data rather than two independent polls of
    // the same endpoint that drift apart between ticks.
    final dashboard = context.watch<DashboardBloc>().state;
    _liveFixes = dashboard.liveFixes;
    _statusData = dashboard.vehicleStatusData;
    _sharedError = dashboard.vehicleStatusError;

    if (_isLoading && _statusData == null) {
      return const AppPageSurface(
        child: Center(child: FleetLoader(message: 'Locating your fleet...')),
      );
    }

    return AppPageSurface(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LiveTrackingHeader(
                lastUpdated: _lastUpdated,
                searchController: _searchController,
                vehiclePlates: _vehiclePlates,
                selectedVehicle: _selectedVehicleFilterPlate,
                onVehicleChanged: _handleVehicleFilterChanged,
                isWide: isWide,
              ),
              const SizedBox(height: 20),
              Expanded(child: _buildBody(isWide: isWide)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody({required bool isWide}) {
    if (_loadError != null && _statusData == null) {
      return _buildErrorState();
    }

    final filtered = _filteredVehicles;
    final pageCount = _pageCountFor(filtered.length);
    final page = _page.clamp(0, pageCount - 1);
    final pageVehicles = filtered
        .skip(page * _pageSize)
        .take(_pageSize)
        .toList();

    final map = LiveTrackingMapCard(
      mapController: _mapController,
      vehicles: _mapVehicles,
      selectedVehicleId: _selectedVehicleKey,
      onVehicleSelected: _handleMapVehicleSelected,
      stateMessage: _mapStateMessage,
    );

    final panel = LiveTrackingVehicleDetailPanel(
      pageVehicles: pageVehicles,
      counts: _counts,
      totalCount: _allVehicles.length,
      activeFilter: _statusFilter,
      onFilterChanged: _handleFilterChanged,
      page: page,
      pageCount: pageCount,
      onPageChanged: (next) => setState(() => _page = next),
      selectedVehicleKey: _selectedVehicleKey,
      onVehicleTap: _handleVehicleTap,
      vehicleTypes: _vehicleTypes,
      emptyMessage: _allVehicles.isEmpty
          ? 'No vehicles reporting yet'
          : 'No vehicles match this filter',
    );

    if (!isWide) {
      return SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 320, child: map),
            const SizedBox(height: 12),
            SizedBox(height: 520, child: panel),
          ],
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(flex: 640, child: map),
        const SizedBox(width: 20),
        Expanded(flex: 380, child: panel),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 40,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 12),
          Text(
            _loadError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              // Explicit: the app's ThemeData is still dark, so without this
              // the label picks up that scheme's foreground colour.
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => context.read<DashboardBloc>().add(
              const VehicleStatusRefreshed(),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}
