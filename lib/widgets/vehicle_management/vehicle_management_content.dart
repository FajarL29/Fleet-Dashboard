import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../models/vehicle_management.dart';
import '../../models/vehicle_status.dart';
import '../auth/role_scope.dart';
import '../../services/page_data_cache.dart';
import '../../services/vehicle_management_service.dart';
import '../../services/vehicle_status_service.dart';
import '../../theme/app_theme.dart';
import '../common/app_page_body.dart';
import '../common/app_page_surface.dart';
import '../common/fleet_loader.dart';
import '../common/sortable_header.dart';
import 'vehicle_list_sort.dart';
import 'vehicle_detail_panel.dart';
import 'vehicle_form_dialog.dart';
import 'vehicle_list_card.dart';
import 'vehicle_management_header.dart';
import 'vehicle_management_kpi_row.dart';
import 'vehicle_trip_detail_panel.dart';

typedef _VehiclesSnapshot = ({
  List<VehicleStatusItem> statusItems,
  List<VehicleRegistryItem> registryItems,
  bool hasRegistry,
  String? warning,
  DateTime fetchedAt,
});

/// Vehicle Management page: owns the registry + status load, search, paging,
/// row selection and the create/edit flow.
class VehicleManagementContent extends StatefulWidget {
  const VehicleManagementContent({super.key});

  @override
  State<VehicleManagementContent> createState() =>
      _VehicleManagementContentState();
}

class _VehicleManagementContentState extends State<VehicleManagementContent> {
  static const int _pageSize = 8;
  static const double _wideBreakpoint = 1080;

  final VehicleManagementService _registryService =
      const VehicleManagementService();
  final VehicleStatusService _statusService = const VehicleStatusService();
  final TextEditingController _searchController = TextEditingController();

  /// The raw API responses. The rows shown are derived from these plus the
  /// live GPS fixes, so a fix arriving does not need a refetch.
  List<VehicleStatusItem> _rawStatusItems = const [];
  List<VehicleRegistryItem> _rawRegistryItems = const [];

  /// Registry rows with device status merged in.
  ///
  /// Deliberately not live: this page reports what the fleet *is* — type,
  /// driver, device, last known state — rather than tracking it minute to
  /// minute. Live positions belong on Overview and Live Tracking, which are
  /// maps of what is moving.
  List<ManagedVehicle> get _vehicles => _hasRegistry
      ? _merge(_rawRegistryItems, _rawStatusItems)
      : _fromStatusOnly(_rawStatusItems);

  String _searchQuery = '';
  String? _selectedVehicleId;
  int _page = 0;

  ColumnSort<VehicleListColumn> _sort = const ColumnSort(
    VehicleListColumn.status,
    SortDirection.descending,
  );

  bool _isLoading = true;
  String? _loadError;

  /// Explains a partial load: registry locked, or telemetry down.
  String? _statusWarning;

  /// False when the registry call failed, so registry-only counters show a
  /// dash instead of a misleading zero.
  bool _hasRegistry = true;
  Object? _lastRegistryError;

  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _load();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- DATA ---------------------------------------------------------------

  static const String _cacheKey = 'vehicle-management';

  /// Loads both feeds independently so one being down does not blank the page.
  ///
  /// The registry needs a token; live status does not. When only status is
  /// reachable the table still works, just without registry-only fields.
  Future<void> _load() async {
    final cache = context.read<PageDataCache>();
    final cached = cache.read<_VehiclesSnapshot>(_cacheKey);
    final sharedStatus = context
        .read<DashboardBloc>()
        .state
        .vehicleStatusData
        ?.vehicles;

    setState(() {
      _loadError = null;
      if (cached == null) {
        _isLoading = true;
        _statusWarning = null;
      } else {
        _apply(cached);
      }
    });

    List<VehicleStatusItem> statusItems = const [];
    Object? statusError;
    List<VehicleRegistryItem> registryItems = const [];
    var hasRegistry = false;

    await Future.wait([
      () async {
        try {
          statusItems =
              sharedStatus ??
              (await _statusService.getVehicleStatus()).vehicles;
        } catch (error) {
          statusError = error;
        }
      }(),
      () async {
        try {
          registryItems = (await _registryService.getVehicles()).vehicles;
          hasRegistry = true;
        } catch (error) {
          _lastRegistryError = error;
        }
      }(),
    ]);

    if (!mounted) return;

    if (!hasRegistry && statusItems.isEmpty) {
      setState(() {
        _isLoading = false;
        if (cached != null) return;
        _loadError = statusError != null
            ? 'Failed to load vehicles. $statusError'
            : 'Failed to load vehicles. ${_lastRegistryError ?? ''}';
      });
      return;
    }

    final snapshot = (
      statusItems: statusItems,
      registryItems: registryItems,
      hasRegistry: hasRegistry,
      warning: _buildWarning(
        hasRegistry: hasRegistry,
        statusError: statusError,
      ),
      fetchedAt: DateTime.now(),
    );
    cache.write(_cacheKey, snapshot);
    setState(() => _apply(snapshot));
  }

  void _apply(_VehiclesSnapshot snapshot) {
    _rawStatusItems = snapshot.statusItems;
    _rawRegistryItems = snapshot.registryItems;
    _hasRegistry = snapshot.hasRegistry;
    _statusWarning = snapshot.warning;
    _isLoading = false;
    _lastUpdated = snapshot.fetchedAt;
    _selectedVehicleId = _resolveSelection(_vehicles);
    _clampPage();
  }

  String? _buildWarning({required bool hasRegistry, Object? statusError}) {
    if (!hasRegistry) {
      return 'Vehicle registry needs a valid API token, so vehicle type, '
          'driver and device fields are unavailable. Showing live telemetry '
          'only.';
    }
    if (statusError != null) {
      return 'Live device status is unavailable. Showing registry data only.';
    }
    return null;
  }

  /// Builds rows from live status alone, for when the registry is locked.
  List<ManagedVehicle> _fromStatusOnly(List<VehicleStatusItem> statusItems) {
    return statusItems
        .map(
          (item) => ManagedVehicle(
            registry: VehicleRegistryItem(
              vehicleId: item.vehicleId,
              vehicleIdentificationNumber: item.vehicleIdentificationNumber,
              plateNumber: item.plateNumber,
              vehicleType: '',
              driverId: '',
              driverName: item.driverName,
              deviceId: '',
              imei: '',
              isActive: true,
              notes: '',
              createdDt: null,
              updatedDt: null,
            ),
            status: item,
          ),
        )
        .toList();
  }

  /// Pairs each registry entry with its live status, matching on vehicle id
  /// first and falling back to VIN.
  List<ManagedVehicle> _merge(
    List<VehicleRegistryItem> registryItems,
    List<VehicleStatusItem> statusItems,
  ) {
    final statusByKey = <String, VehicleStatusItem>{};
    for (final item in statusItems) {
      for (final key in [item.vehicleId, item.vehicleIdentificationNumber]) {
        final trimmed = key.trim();
        if (trimmed.isNotEmpty) statusByKey.putIfAbsent(trimmed, () => item);
      }
    }

    return registryItems.map((registry) {
      final status =
          statusByKey[registry.vehicleId] ??
          statusByKey[registry.vehicleIdentificationNumber];
      return ManagedVehicle(registry: registry, status: status);
    }).toList();
  }

  /// Keeps the current selection across refreshes, but never picks one on the
  /// user's behalf: the detail column stays hidden until a row is clicked.
  String? _resolveSelection(List<ManagedVehicle> vehicles) {
    final current = _selectedVehicleId;
    if (current == null) return null;

    final stillListed = vehicles.any((vehicle) => vehicle.vehicleId == current);
    return stillListed ? current : null;
  }

  // --- DERIVED ------------------------------------------------------------

  List<ManagedVehicle> get _filtered {
    final query = _searchQuery.toLowerCase();
    final matches = query.isEmpty
        ? _vehicles
        : _vehicles
              .where((vehicle) => vehicle.searchBlob.contains(query))
              .toList();

    // Sort the matches, not the page: ordering a single page would leave the
    // top row of page 2 outranking the bottom row of page 1.
    return sortManagedVehicles(matches, _sort);
  }

  ManagedVehicle? get _selectedVehicle {
    for (final vehicle in _vehicles) {
      if (vehicle.vehicleId == _selectedVehicleId) return vehicle;
    }
    return null;
  }

  int _pageCountFor(int itemCount) =>
      itemCount == 0 ? 1 : (itemCount + _pageSize - 1) ~/ _pageSize;

  void _clampPage() {
    final pageCount = _pageCountFor(_filtered.length);
    _page = _page.clamp(0, pageCount - 1);
  }

  /// Vehicle types offered by the form: whatever the registry already uses,
  /// plus a few sensible defaults.
  List<String> get _typeOptions {
    final types = {
      ..._vehicles
          .map((vehicle) => vehicle.vehicleType.trim())
          .where((type) => type.isNotEmpty),
      'Van',
      'Truck',
      'Bus',
      'Car',
    };
    final sorted = types.toList()..sort();
    return sorted;
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

  Future<void> _handleEditVehicle(ManagedVehicle vehicle) async {
    // Same dialog as Add — passing a vehicle is what switches it to edit and
    // makes it call updateVehicle instead of createVehicle. That path existed
    // in the service and the dialog all along; nothing in the UI ever reached
    // it, so the registry was effectively create-only.
    final saved = await showVehicleFormDialog(
      context: context,
      service: _registryService,
      typeOptions: _typeOptions,
      vehicle: vehicle,
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle updated successfully')),
      );
      await _load();
    }
  }

  Future<void> _handleDeactivateVehicle(ManagedVehicle vehicle) async {
    final label = vehicle.plateNumber.trim().isEmpty
        ? vehicle.vin
        : vehicle.plateNumber;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deactivate vehicle?'),
        content: Text(
          '$label will be retired from the active fleet. Its trips, safety '
          'events and reports stay intact, and it can be brought back later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.redText),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _registryService.deactivateVehicle(vehicle.vehicleId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$label deactivated')));
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not deactivate $label. $error')),
      );
    }
  }

  Future<void> _handleAddVehicle() async {
    final saved = await showVehicleFormDialog(
      context: context,
      service: _registryService,
      typeOptions: _typeOptions,
    );
    if (saved && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle created successfully')),
      );
      await _load();
    }
  }

  // --- BUILD --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AppPageSurface(
      child: AppPageBody(
        wideBreakpoint: _wideBreakpoint,
        builder: (context, {required isWide, required fills}) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VehicleManagementHeader(
                lastUpdated: _lastUpdated,
                searchController: _searchController,
                onAddVehicle: RoleScope.of(context).canManageFleet
                    ? _handleAddVehicle
                    : null,
                isWide: isWide,
              ),
              const SizedBox(height: 20),
              if (_statusWarning != null) ...[
                _Notice(message: _statusWarning!),
                const SizedBox(height: 12),
              ],
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: FleetLoader(message: 'Loading vehicles...'),
                  ),
                )
              else if (_loadError != null)
                _ErrorState(message: _loadError!, onRetry: _load)
              else ...[
                VehicleManagementKpiRow(
                  vehicles: _vehicles,
                  hasRegistry: _hasRegistry,
                  isWide: isWide,
                ),
                const SizedBox(height: 14),
                _buildBody(isWide: isWide),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody({required bool isWide}) {
    final filtered = _filtered;
    final pageCount = _pageCountFor(filtered.length);
    final page = _page.clamp(0, pageCount - 1);
    final pageVehicles = filtered
        .skip(page * _pageSize)
        .take(_pageSize)
        .toList();

    final list = VehicleListCard(
      pageVehicles: pageVehicles,
      shownCount: filtered.length,
      totalCount: _vehicles.length,
      selectedVehicleId: _selectedVehicleId,
      onVehicleTap: (vehicle) =>
          setState(() => _selectedVehicleId = vehicle.vehicleId),
      page: page,
      pageCount: pageCount,
      onPageChanged: (next) => setState(() => _page = next),
      sort: _sort,
      onSort: (next) => setState(() {
        _sort = next;
        // A new order makes the old page number meaningless.
        _page = 0;
      }),
      emptyMessage: _vehicles.isEmpty
          ? 'No vehicles registered yet'
          : 'No vehicles match this search',
    );

    final selected = _selectedVehicle;

    // Nothing picked yet: the table owns the full width, no empty side panels.
    if (selected == null) return list;

    // Null hides the action entirely rather than showing a button that
    // refuses — a control you cannot use is worse than one that is not there.
    final mayManage = RoleScope.of(context).canManageFleet;

    final detail = VehicleDetailPanel(
      vehicle: selected,
      onClose: () => setState(() => _selectedVehicleId = null),
      onEdit: mayManage ? () => _handleEditVehicle(selected) : null,
      // Already retired: there is nothing left to deactivate, so the action
      // is hidden rather than shown as a button that does nothing.
      onDeactivate: mayManage && selected.isActive
          ? () => _handleDeactivateVehicle(selected)
          : null,
    );

    // Trips are not wired yet, so the timeline explains itself instead of
    // rendering an invented journey.
    const tripDetail = VehicleTripDetailPanel(
      trip: null,
      emptyMessage: 'Trip history is not available yet',
    );

    if (!isWide) {
      return Column(
        children: [
          list,
          const SizedBox(height: 14),
          detail,
          const SizedBox(height: 14),
          tripDetail,
        ],
      );
    }

    // IntrinsicHeight so both columns end on the same line whichever side is
    // taller; the trip card absorbs the slack on the right.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 660, child: list),
          const SizedBox(width: 14),
          Expanded(
            flex: 330,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                detail,
                const SizedBox(height: 14),
                const Expanded(child: tripDetail),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amberSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: AppColors.amberText,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.amberText,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Center(
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
              message,
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
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
