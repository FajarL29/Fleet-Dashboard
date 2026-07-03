import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/vehicle.dart';
import '../models/vehicle_status.dart';
import '../services/vehicle_status_service.dart';
import '../widgets/live_tracking/live_tracking_skeleton.dart';
import '../widgets/map_section.dart';
import '../widgets/report/report_styles.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});

  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingScreenState();
}

class _LiveTrackingScreenState extends State<LiveTrackingScreen> {
  static const Duration _refreshInterval = Duration(seconds: 10);

  final VehicleStatusService _service = const VehicleStatusService();
  final MapController _mapController = MapController();
  final TextEditingController _headerSearchController = TextEditingController();
  final TextEditingController _fleetSearchController = TextEditingController();

  Timer? _refreshTimer;
  VehicleStatusData? _statusData;
  String? _selectedVehicleKey;
  String _statusFilter = 'All';
  String _searchQuery = '';
  bool _isLoading = true;
  bool _isRefreshing = false;
  String? _loadError;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    _headerSearchController.addListener(_handleSearchChanged);
    _fleetSearchController.addListener(_handleSearchChanged);
    _loadStatus();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController.dispose();
    _headerSearchController.dispose();
    _fleetSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allVehicles = _statusData?.vehicles ?? const <VehicleStatusItem>[];
    final filteredVehicles = _filteredVehicles(allVehicles);
    final selectedVehicle = _resolveSelectedVehicle(
      filteredVehicles,
      allVehicles,
    );
    final markerVehicles = filteredVehicles
        .where((item) => item.hasCoordinates)
        .toList();
    final summary = _buildSummary(allVehicles);

    if (_isLoading && allVehicles.isEmpty) {
      return const LiveTrackingSkeleton();
    }

    return Container(
      color: ReportStyles.pageBackground,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    if (_loadError != null && allVehicles.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ErrorBanner(
                          message: _loadError!,
                          actionLabel: 'Retry',
                          onPressed: _loadStatus,
                        ),
                      ),
                    if (_refreshError != null && allVehicles.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _ErrorBanner(
                          message: _refreshError!,
                          actionLabel: 'Retry',
                          onPressed: () => _loadStatus(refresh: true),
                          compact: true,
                        ),
                      ),
                    Expanded(
                      child: _buildResponsiveBody(
                        summary: summary,
                        filteredVehicles: filteredVehicles,
                        selectedVehicle: selectedVehicle,
                        markerVehicles: markerVehicles,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: _buildBottomStatusBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return _PanelCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 980;
          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Tracking',
                  style: TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Real-time visibility of your fleet on the map',
                  style: TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                _SearchField(
                  controller: _headerSearchController,
                  hintText: 'Search vehicles, drivers, or locations...',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _FilterMenu(
                      value: _statusFilter,
                      onSelected: (value) {
                        setState(() {
                          _statusFilter = value;
                          _syncSelectionAfterFilter();
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    _IconBadge(
                      icon: Icons.notifications_none_rounded,
                      count: _alertCount,
                    ),
                    const Spacer(),
                    Text(
                      _timeLabel,
                      style: const TextStyle(
                        color: ReportStyles.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Row(
            children: [
              const Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Tracking',
                      style: TextStyle(
                        color: ReportStyles.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Real-time visibility of your fleet on the map',
                      style: TextStyle(
                        color: ReportStyles.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                flex: 4,
                child: _SearchField(
                  controller: _headerSearchController,
                  hintText: 'Search vehicles, drivers, or locations...',
                ),
              ),
              const SizedBox(width: 18),
              _FilterMenu(
                value: _statusFilter,
                onSelected: (value) {
                  setState(() {
                    _statusFilter = value;
                    _syncSelectionAfterFilter();
                  });
                },
              ),
              const SizedBox(width: 12),
              _IconBadge(
                icon: Icons.notifications_none_rounded,
                count: _alertCount,
              ),
              const SizedBox(width: 18),
              Text(
                _timeLabel,
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildResponsiveBody({
    required _TrackingSummary summary,
    required List<VehicleStatusItem> filteredVehicles,
    required VehicleStatusItem? selectedVehicle,
    required List<VehicleStatusItem> markerVehicles,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1180) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 332,
                child: _buildFleetPanel(
                  summary,
                  filteredVehicles,
                  selectedVehicle,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(child: _buildMapPanel(markerVehicles, selectedVehicle)),
              const SizedBox(width: 16),
              SizedBox(
                width: 332,
                child: _buildSelectedVehiclePanel(selectedVehicle),
              ),
            ],
          );
        }

        if (constraints.maxWidth >= 860) {
          return SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: 380,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 300,
                        child: _buildFleetPanel(
                          summary,
                          filteredVehicles,
                          selectedVehicle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMapPanel(markerVehicles, selectedVehicle),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 420,
                  child: _buildSelectedVehiclePanel(selectedVehicle),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 420,
                child: _buildFleetPanel(
                  summary,
                  filteredVehicles,
                  selectedVehicle,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 380,
                child: _buildMapPanel(markerVehicles, selectedVehicle),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 420,
                child: _buildSelectedVehiclePanel(selectedVehicle),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFleetPanel(
    _TrackingSummary summary,
    List<VehicleStatusItem> filteredVehicles,
    VehicleStatusItem? selectedVehicle,
  ) {
    return _PanelCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fleet (${summary.total})',
            style: const TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryTile(
                label: 'Moving',
                count: summary.moving,
                color: ReportStyles.green,
              ),
              _SummaryTile(
                label: 'Idle',
                count: summary.idle,
                color: ReportStyles.orange,
              ),
              _SummaryTile(
                label: 'Alert',
                count: summary.alert,
                color: ReportStyles.red,
              ),
              _SummaryTile(
                label: 'Offline',
                count: summary.offline,
                color: Colors.blueGrey.shade400,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SearchField(
            controller: _fleetSearchController,
            hintText: 'Search fleet...',
            compact: true,
          ),
          const SizedBox(height: 14),
          Expanded(
            child: filteredVehicles.isEmpty
                ? const _FleetEmptyState()
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: filteredVehicles.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredVehicles[index];
                      final isSelected =
                          _vehicleKey(item) == _selectedVehicleKey;
                      return _FleetVehicleCard(
                        item: item,
                        isSelected: isSelected,
                        onTap: () => _handleVehicleSelected(item),
                        lastSeenLabel: _lastSeenLabel(item),
                        speedLabel: _speedLabel(item.speed),
                        statusLabel: _statusLabel(item),
                        statusColor: _statusColor(item),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          Text(
            filteredVehicles.isEmpty
                ? 'No vehicles match current filters'
                : 'Showing ${filteredVehicles.length} of ${summary.total} vehicles',
            style: const TextStyle(color: ReportStyles.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPanel(
    List<VehicleStatusItem> markerVehicles,
    VehicleStatusItem? selectedVehicle,
  ) {
    return _PanelCard(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: markerVehicles.isEmpty
                  ? const _MapPlaceholder()
                  : MapSection(
                      mapController: _mapController,
                      vehicles: markerVehicles.map(_mapVehicle).toList(),
                      onVehicleSelected: (vehicle) {
                        final item = _findVehicleByKey(vehicle.id);
                        if (item != null) {
                          _handleVehicleSelected(item, focusMap: false);
                        }
                      },
                      showVehicleList: false,
                      showInfoWindow: false,
                      showMarkerLabels: true,
                      selectedVehicleId: selectedVehicle == null
                          ? null
                          : _vehicleKey(selectedVehicle),
                    ),
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: ReportStyles.cardBackground.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: ReportStyles.border.withValues(alpha: 0.85),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.search_rounded,
                      color: ReportStyles.textSecondary,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Search this area',
                      style: TextStyle(
                        color: ReportStyles.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(left: 12, bottom: 12, child: _LegendCard()),
          if (_isRefreshing && markerVehicles.isNotEmpty)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSelectedVehiclePanel(VehicleStatusItem? selectedVehicle) {
    return _PanelCard(
      padding: const EdgeInsets.all(18),
      child: selectedVehicle == null
          ? const _SelectedVehicleEmptyState()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selected Vehicle',
                  style: TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: _statusColor(
                          selectedVehicle,
                        ).withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.local_shipping_rounded,
                        color: _statusColor(selectedVehicle),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _plateLabel(selectedVehicle),
                            style: const TextStyle(
                              color: ReportStyles.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            selectedVehicle
                                    .vehicleIdentificationNumber
                                    .isNotEmpty
                                ? selectedVehicle.vehicleIdentificationNumber
                                : selectedVehicle.vehicleId,
                            style: const TextStyle(
                              color: ReportStyles.textSecondary,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(
                      label: _statusLabel(selectedVehicle),
                      color: _statusColor(selectedVehicle),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      _DetailRow(
                        icon: Icons.person_outline_rounded,
                        label: 'Driver',
                        value: _textOrDash(selectedVehicle.driverName),
                      ),
                      _DetailRow(
                        icon: Icons.speed_rounded,
                        label: 'Speed',
                        value: _speedLabel(selectedVehicle.speed),
                      ),
                      _DetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Last GPS Update',
                        value: _lastSeenLabel(selectedVehicle),
                      ),
                      _DetailRow(
                        icon: Icons.location_on_outlined,
                        label: 'Coordinates',
                        value: _coordinateLabel(selectedVehicle),
                      ),
                      _DetailRow(
                        icon: Icons.event_note_rounded,
                        label: 'Events Today',
                        value: '-',
                      ),
                      _DetailRow(
                        icon: Icons.router_outlined,
                        label: 'Device Status',
                        value: _deviceStatusLabel(selectedVehicle),
                      ),
                      _DetailRow(
                        icon: Icons.route_outlined,
                        label: 'Odometer',
                        value: '-',
                      ),
                      _DetailRow(
                        icon: Icons.local_gas_station_outlined,
                        label: 'Fuel Level',
                        value: '-',
                      ),
                      if (selectedVehicle.statusReason.trim().isNotEmpty)
                        _DetailRow(
                          icon: Icons.info_outline_rounded,
                          label: 'Reason',
                          value: _reasonLabel(selectedVehicle),
                          maxLines: 2,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  label: 'View Route',
                  primary: true,
                  onPressed: null,
                ),
                const SizedBox(height: 10),
                _ActionButton(label: 'View Events', onPressed: null),
                const SizedBox(height: 10),
                _ActionButton(label: 'Driver Profile', onPressed: null),
              ],
            ),
    );
  }

  Widget _buildBottomStatusBar() {
    return _PanelCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 980) {
            return Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _buildRefreshIndicator(),
                const Text(
                  'All times shown in local time (WIB)',
                  style: TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  'Data provided by GPS device',
                  style: TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }

          return Row(
            children: [
              _buildRefreshIndicator(),
              const Spacer(),
              const Text(
                'All times shown in local time (WIB)',
                style: TextStyle(
                  color: ReportStyles.textSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              const Text(
                'Data provided by GPS device',
                style: TextStyle(
                  color: ReportStyles.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRefreshIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: ReportStyles.green,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          'Auto-refresh',
          style: TextStyle(
            color: ReportStyles.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: ReportStyles.surfaceBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: ReportStyles.border.withValues(alpha: 0.72),
            ),
          ),
          child: const Text(
            '10s',
            style: TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadStatus({bool refresh = false}) async {
    if (refresh) {
      if (_isRefreshing) {
        return;
      }
      setState(() {
        _isRefreshing = true;
        _refreshError = null;
      });
    } else {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final data = await _service.getVehicleStatus();
      if (!mounted) {
        return;
      }

      setState(() {
        _statusData = data;
        _selectedVehicleKey = _resolveSelectionKey(data.vehicles);
        _isLoading = false;
        _isRefreshing = false;
        _loadError = null;
        _refreshError = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        if (_statusData == null || _statusData!.vehicles.isEmpty) {
          _loadError = 'Unable to load live tracking data. $error';
        } else {
          _refreshError = 'Live tracking refresh failed. $error';
        }
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) async {
      if (!mounted) {
        return;
      }

      if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
        setState(() {});
        return;
      }

      setState(() {});
      await _loadStatus(refresh: true);
    });
  }

  void _handleSearchChanged() {
    final nextQuery = _headerSearchController.text.trim().isNotEmpty
        ? _headerSearchController.text.trim()
        : _fleetSearchController.text.trim();
    if (nextQuery == _searchQuery) {
      return;
    }
    setState(() {
      _searchQuery = nextQuery;
      _syncSelectionAfterFilter();
    });
  }

  void _handleVehicleSelected(VehicleStatusItem item, {bool focusMap = true}) {
    setState(() {
      _selectedVehicleKey = _vehicleKey(item);
    });

    if (focusMap && item.hasCoordinates) {
      _mapController.move(LatLng(item.latitude!, item.longitude!), 15);
    }
  }

  void _syncSelectionAfterFilter() {
    final vehicles = _statusData?.vehicles ?? const <VehicleStatusItem>[];
    final filteredVehicles = _filteredVehicles(vehicles);
    _selectedVehicleKey = _resolveSelectionKey(
      filteredVehicles.isNotEmpty ? filteredVehicles : vehicles,
    );
  }

  VehicleStatusItem? _findVehicleByKey(String key) {
    for (final item in _statusData?.vehicles ?? const <VehicleStatusItem>[]) {
      if (_vehicleKey(item) == key) {
        return item;
      }
    }
    return null;
  }

  VehicleStatusItem? _resolveSelectedVehicle(
    List<VehicleStatusItem> filteredVehicles,
    List<VehicleStatusItem> allVehicles,
  ) {
    if (_selectedVehicleKey == null) {
      return filteredVehicles.isNotEmpty ? filteredVehicles.first : null;
    }

    for (final item in filteredVehicles) {
      if (_vehicleKey(item) == _selectedVehicleKey) {
        return item;
      }
    }

    for (final item in allVehicles) {
      if (_vehicleKey(item) == _selectedVehicleKey) {
        return item;
      }
    }

    return filteredVehicles.isNotEmpty ? filteredVehicles.first : null;
  }

  String? _resolveSelectionKey(List<VehicleStatusItem> vehicles) {
    if (vehicles.isEmpty) {
      return null;
    }

    if (_selectedVehicleKey != null &&
        vehicles.any((item) => _vehicleKey(item) == _selectedVehicleKey)) {
      return _selectedVehicleKey;
    }

    final firstWithCoordinates = vehicles.where((item) => item.hasCoordinates);
    if (firstWithCoordinates.isNotEmpty) {
      return _vehicleKey(firstWithCoordinates.first);
    }

    return _vehicleKey(vehicles.first);
  }

  List<VehicleStatusItem> _filteredVehicles(List<VehicleStatusItem> vehicles) {
    final query = _searchQuery.trim().toLowerCase();
    return vehicles.where((item) {
      if (_statusFilter != 'All' &&
          !_matchesStatusFilter(item, _statusFilter)) {
        return false;
      }

      if (query.isEmpty) {
        return true;
      }

      final blob = [
        item.plateNumber,
        item.vehicleIdentificationNumber,
        item.driverName,
        item.displayStatus,
        item.statusReason,
      ].join(' ').toLowerCase();

      return blob.contains(query);
    }).toList();
  }

  bool _matchesStatusFilter(VehicleStatusItem item, String filter) {
    final normalized = filter.toLowerCase();
    switch (normalized) {
      case 'moving':
        return _statusLabel(item).toLowerCase() == 'moving';
      case 'idle':
        return _statusLabel(item).toLowerCase() == 'idle';
      case 'alert':
        return _statusLabel(item).toLowerCase() == 'alert' ||
            _statusLabel(item).toLowerCase() == 'warning';
      case 'offline':
        return _statusLabel(item).toLowerCase() == 'offline';
      default:
        return true;
    }
  }

  _TrackingSummary _buildSummary(List<VehicleStatusItem> vehicles) {
    var moving = 0;
    var idle = 0;
    var alert = 0;
    var offline = 0;

    for (final item in vehicles) {
      final status = _statusLabel(item).toLowerCase();
      if (status == 'moving') {
        moving += 1;
      } else if (status == 'idle') {
        idle += 1;
      } else if (status == 'offline') {
        offline += 1;
      } else if (status == 'alert' || status == 'warning') {
        alert += 1;
      }
    }

    return _TrackingSummary(
      total: vehicles.length,
      moving: moving,
      idle: idle,
      alert: alert,
      offline: offline,
    );
  }

  Vehicle _mapVehicle(VehicleStatusItem item) {
    return Vehicle(
      id: _vehicleKey(item),
      apiVehicleId: item.vehicleIdentificationNumber.isNotEmpty
          ? item.vehicleIdentificationNumber
          : null,
      plateNumber: _plateLabel(item),
      type: item.movementStatus.isNotEmpty ? item.movementStatus : 'Unknown',
      driverName: _driverLabel(item),
      activityTime: _lastSeenLabel(item),
      position: LatLng(item.latitude!, item.longitude!),
      status: _mapStatus(item),
      speed: item.speed ?? 0,
      displayStatus: _statusLabel(item),
      statusReason: item.statusReason,
      lastTelemetryTime: item.lastTelemetryTime,
      lastSeenMinutes: item.lastSeenMinutes,
    );
  }

  VehicleStatus _mapStatus(VehicleStatusItem item) {
    switch (_statusLabel(item).toLowerCase()) {
      case 'alert':
        return VehicleStatus.alert;
      case 'warning':
      case 'idle':
        return VehicleStatus.warning;
      case 'offline':
        return VehicleStatus.inactive;
      default:
        return VehicleStatus.active;
    }
  }

  String _vehicleKey(VehicleStatusItem item) {
    if (item.vehicleId.trim().isNotEmpty) {
      return item.vehicleId.trim();
    }
    if (item.vehicleIdentificationNumber.trim().isNotEmpty) {
      return item.vehicleIdentificationNumber.trim();
    }
    return item.plateNumber.trim();
  }

  String _driverLabel(VehicleStatusItem item) {
    return item.driverName.trim().isEmpty
        ? 'Unknown Driver'
        : item.driverName.trim();
  }

  String _plateLabel(VehicleStatusItem item) {
    if (item.plateNumber.trim().isNotEmpty) {
      return item.plateNumber.trim();
    }
    if (item.vehicleIdentificationNumber.trim().isNotEmpty) {
      return item.vehicleIdentificationNumber.trim();
    }
    return item.vehicleId.trim().isEmpty ? '-' : item.vehicleId.trim();
  }

  String _statusLabel(VehicleStatusItem item) {
    final displayStatus = item.displayStatus.trim().toLowerCase();
    if (displayStatus.isNotEmpty) {
      return _titleCase(displayStatus);
    }

    final movementStatus = item.movementStatus.trim().toLowerCase();
    if (movementStatus.isNotEmpty) {
      return _titleCase(movementStatus);
    }

    final deviceStatus = item.deviceStatus.trim().toLowerCase();
    if (deviceStatus.isNotEmpty) {
      return _titleCase(deviceStatus);
    }

    return 'Unknown';
  }

  String _deviceStatusLabel(VehicleStatusItem item) {
    final deviceStatus = item.deviceStatus.trim();
    return deviceStatus.isEmpty ? '-' : _titleCase(deviceStatus);
  }

  Color _statusColor(VehicleStatusItem item) {
    switch (_statusLabel(item).toLowerCase()) {
      case 'moving':
      case 'online':
        return ReportStyles.green;
      case 'idle':
      case 'warning':
        return ReportStyles.orange;
      case 'alert':
        return ReportStyles.red;
      case 'offline':
        return Colors.blueGrey.shade400;
      default:
        return ReportStyles.textMuted;
    }
  }

  String _lastSeenLabel(VehicleStatusItem item) {
    final minutes = item.lastSeenMinutes;
    if (minutes != null) {
      if (minutes < 1) {
        return 'Just now';
      }
      if (minutes < 60) {
        return '$minutes min ago';
      }
      if (minutes < 1440) {
        final hours = (minutes / 60).floor();
        return '$hours hr ago';
      }
      final days = (minutes / 1440).floor();
      return '$days day${days == 1 ? '' : 's'} ago';
    }

    final telemetry = item.lastTelemetryTime;
    if (telemetry == null) {
      return '-';
    }

    final local = telemetry.toLocal();
    return '${_twoDigits(local.hour)}:${_twoDigits(local.minute)}';
  }

  String _speedLabel(double? speed) {
    if (speed == null || speed <= 0) {
      return '0 km/h';
    }
    if (speed == speed.roundToDouble()) {
      return '${speed.toInt()} km/h';
    }
    return '${speed.toStringAsFixed(1)} km/h';
  }

  String _coordinateLabel(VehicleStatusItem item) {
    if (!item.hasCoordinates) {
      return '-';
    }
    return '${item.latitude!.toStringAsFixed(4)}, ${item.longitude!.toStringAsFixed(4)}';
  }

  String _reasonLabel(VehicleStatusItem item) {
    final reason = item.statusReason.trim();
    if (reason.isEmpty) {
      return '-';
    }
    final lower = reason.toLowerCase();
    if (lower.contains('stale')) {
      return 'Stale telemetry';
    }
    if (lower.contains('no telemetry')) {
      return 'No telemetry received';
    }
    return reason;
  }

  String _textOrDash(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '-' : trimmed;
  }

  String _titleCase(String value) {
    return value
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _twoDigits(int value) => value.toString().padLeft(2, '0');

  int get _alertCount {
    final vehicles = _statusData?.vehicles ?? const <VehicleStatusItem>[];
    return vehicles
        .where((item) => _statusLabel(item).toLowerCase() == 'alert')
        .length;
  }

  String get _timeLabel {
    final now = DateTime.now();
    return '${_twoDigits(now.hour)}:${_twoDigits(now.minute)}';
  }
}

class _TrackingSummary {
  const _TrackingSummary({
    required this.total,
    required this.moving,
    required this.idle,
    required this.alert,
    required this.offline,
  });

  final int total;
  final int moving;
  final int idle;
  final int alert;
  final int offline;
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.78)),
        boxShadow: ReportStyles.cardShadow,
      ),
      child: child,
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.hintText,
    this.compact = false,
  });

  final TextEditingController controller;
  final String hintText;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: ReportStyles.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: ReportStyles.textMuted, fontSize: 13),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: ReportStyles.textSecondary,
          size: 18,
        ),
        filled: true,
        fillColor: ReportStyles.surfaceBackground,
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 12 : 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: ReportStyles.border.withValues(alpha: 0.72),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ReportStyles.blue),
        ),
      ),
    );
  }
}

class _FilterMenu extends StatelessWidget {
  const _FilterMenu({required this.value, required this.onSelected});

  final String value;
  final ValueChanged<String> onSelected;

  static const List<String> options = [
    'All',
    'Moving',
    'Idle',
    'Alert',
    'Offline',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.72)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: ReportStyles.surfaceBackground,
          iconEnabledColor: ReportStyles.textSecondary,
          borderRadius: BorderRadius.circular(12),
          style: const TextStyle(
            color: ReportStyles.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          items: options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (option == value) ...[
                        const Icon(
                          Icons.filter_alt_outlined,
                          color: ReportStyles.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(option),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (next) {
            if (next != null) {
              onSelected(next);
            }
          },
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.count});

  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: ReportStyles.surfaceBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ReportStyles.border.withValues(alpha: 0.72),
            ),
          ),
          child: Icon(icon, color: ReportStyles.textPrimary),
        ),
        if (count > 0)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: ReportStyles.red,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.68)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetVehicleCard extends StatelessWidget {
  const _FleetVehicleCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
    required this.lastSeenLabel,
    required this.speedLabel,
    required this.statusLabel,
    required this.statusColor,
  });

  final VehicleStatusItem item;
  final bool isSelected;
  final VoidCallback onTap;
  final String lastSeenLabel;
  final String speedLabel;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF11253E)
                : ReportStyles.surfaceBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? ReportStyles.blue
                  : ReportStyles.border.withValues(alpha: 0.7),
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.local_shipping_rounded,
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.vehicleId.trim().isNotEmpty
                              ? item.vehicleId.trim()
                              : '-',
                          style: const TextStyle(
                            color: ReportStyles.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.plateNumber.trim().isNotEmpty
                              ? item.plateNumber.trim()
                              : item.vehicleIdentificationNumber,
                          style: const TextStyle(
                            color: ReportStyles.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        speedLabel,
                        style: const TextStyle(
                          color: ReportStyles.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _StatusChip(
                        label: statusLabel,
                        color: statusColor,
                        compact: true,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: ReportStyles.textMuted,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.driverName.trim().isEmpty
                          ? 'Unknown Driver'
                          : item.driverName.trim(),
                      style: const TextStyle(
                        color: ReportStyles.textSecondary,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    lastSeenLabel,
                    style: const TextStyle(
                      color: ReportStyles.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.color,
    this.compact = false,
  });

  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LegendCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.82)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Legend',
            style: TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 10),
          _LegendItem(label: 'Moving', color: ReportStyles.green),
          SizedBox(height: 8),
          _LegendItem(label: 'Idle', color: ReportStyles.orange),
          SizedBox(height: 8),
          _LegendItem(label: 'Alert', color: ReportStyles.red),
          SizedBox(height: 8),
          _LegendItem(label: 'Offline', color: Colors.blueGrey),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: ReportStyles.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.maxLines = 1,
  });

  final IconData icon;
  final String label;
  final String value;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ReportStyles.textSecondary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    this.primary = false,
    this.onPressed,
  });

  final String label;
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = primary
        ? ReportStyles.blue
        : ReportStyles.surfaceBackground;
    final borderColor = primary
        ? ReportStyles.blue
        : ReportStyles.border.withValues(alpha: 0.82);

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: onPressed == null && primary
              ? ReportStyles.blue.withValues(alpha: 0.35)
              : backgroundColor,
          side: BorderSide(color: borderColor),
          padding: const EdgeInsets.symmetric(vertical: 14),
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white70,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
    this.compact = false,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 14,
        vertical: compact ? 12 : 14,
      ),
      decoration: BoxDecoration(
        color: ReportStyles.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.red.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: ReportStyles.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0B1421),
      alignment: Alignment.center,
      child: const Text(
        'No vehicle location data available',
        style: TextStyle(
          color: ReportStyles.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FleetEmptyState extends StatelessWidget {
  const _FleetEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'No fleet data matches the current search or filter.',
        textAlign: TextAlign.center,
        style: TextStyle(color: ReportStyles.textSecondary, fontSize: 13),
      ),
    );
  }
}

class _SelectedVehicleEmptyState extends StatelessWidget {
  const _SelectedVehicleEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Select a vehicle from the list or map to view details.',
        textAlign: TextAlign.center,
        style: TextStyle(color: ReportStyles.textSecondary, fontSize: 13),
      ),
    );
  }
}
