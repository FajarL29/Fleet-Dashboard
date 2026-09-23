import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../models/drowsiness_report.dart';
import '../../models/vehicle_status.dart';
import '../../services/drowsiness_report_service.dart';
import '../../services/page_data_cache.dart';
import '../../services/vehicle_status_service.dart';
import '../../theme/app_theme.dart';
import '../common/app_page_body.dart';
import '../common/app_page_surface.dart';
import '../common/fleet_loader.dart';
import '../common/sortable_header.dart';
import 'safety_event_sort.dart';
import 'safety_event_detail_panel.dart';
import 'safety_event_table.dart';
import 'safety_header.dart';

typedef _SafetySnapshot = ({
  List<VehicleStatusItem> vehicles,
  List<DrowsinessEvent> events,
  DateTime fetchedAt,
});

/// Safety Monitoring page: loads the fleet and its events, owns the search,
/// date and vehicle filters, paging, and the selected event.
class SafetyContent extends StatefulWidget {
  const SafetyContent({super.key});

  @override
  State<SafetyContent> createState() => _SafetyContentState();
}

class _SafetyContentState extends State<SafetyContent> {
  static const int _pageSize = 10;

  /// Newest events shown before any date or vehicle filter is picked.
  static const int _unfilteredEventLimit = 50;

  /// Per-vehicle cap once a filter is applied.
  static const int _filteredEventLimit = 100;
  static const double _wideBreakpoint = 1180;

  /// How far back events are fetched when no date range is picked.
  static const Duration _defaultWindow = Duration(days: 30);

  /// How often the page re-fetches so new events appear without a reload.
  static const Duration _pollInterval = Duration(seconds: 10);

  final DrowsinessReportService _eventService = const DrowsinessReportService();
  final VehicleStatusService _statusService = const VehicleStatusService();
  final TextEditingController _searchController = TextEditingController();

  List<VehicleStatusItem> _vehicles = const [];
  List<DrowsinessEvent> _events = const [];

  String _searchQuery = '';
  String? _selectedVin;
  DateTimeRange? _dateRange;
  int? _selectedEventId;
  int _page = 0;

  /// Newest first, which is what someone opening the page wants to see.
  ColumnSort<SafetyEventColumn> _sort = const ColumnSort(
    SafetyEventColumn.time,
    SortDirection.descending,
  );

  bool _isLoading = true;
  bool _isFetching = false;
  String? _loadError;
  DateTime _lastUpdated = DateTime.now();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _load();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // --- DATA ---------------------------------------------------------------

  String get _cacheKey =>
      'safety|${_dateRange?.start}|${_dateRange?.end}|$_selectedVin';

  /// Shows what was cached for these filters straight away, then refreshes.
  /// A failed refresh only surfaces as an error when there was nothing to show.
  ///
  /// A [silent] load is the poll: it never shows the spinner, never replaces
  /// rows with an error, and stands down while another load is already running.
  Future<void> _load({bool silent = false}) async {
    if (silent && _isFetching) return;
    _isFetching = true;

    final key = _cacheKey;
    final cache = context.read<PageDataCache>();
    final cached = cache.read<_SafetySnapshot>(key);
    final dashboard = context.read<DashboardBloc>().state;

    if (!silent) {
      setState(() {
        _loadError = null;
        if (cached == null) {
          _isLoading = true;
        } else {
          _apply(cached);
        }
      });
    }

    try {
      final vehicles =
          dashboard.vehicleStatusData?.vehicles ??
          (await _statusService.getVehicleStatus()).vehicles;
      final events = await _fetchEvents(vehicles);
      final snapshot = (
        vehicles: vehicles,
        events: events,
        fetchedAt: DateTime.now(),
      );
      cache.write(key, snapshot);
      // The filters moved on while this was in flight; a newer load owns the page.
      if (!mounted || key != _cacheKey) return;

      setState(() => _apply(snapshot));
    } catch (error) {
      // A poll that fails keeps the rows already on screen; the next tick tries
      // again, so a blip in the network must not blank the page.
      if (!mounted || silent || key != _cacheKey) return;
      setState(() {
        _isLoading = false;
        if (cached == null) {
          _loadError = 'Failed to load safety events. $error';
        }
      });
    } finally {
      _isFetching = false;
    }
  }

  void _apply(_SafetySnapshot snapshot) {
    _vehicles = snapshot.vehicles;
    _events = snapshot.events;
    _isLoading = false;
    // A poll that succeeds after a failed load has data to show, so the error
    // state must not outlive it.
    _loadError = null;
    _lastUpdated = snapshot.fetchedAt;
    _selectedEventId = _resolveSelection(snapshot.events);
    _clampPage();
  }

  /// Events are fetched per vehicle, so one vehicle failing does not empty the
  /// whole list. The unfiltered view shows only the newest
  /// [_unfilteredEventLimit] across the fleet.
  Future<List<DrowsinessEvent>> _fetchEvents(
    List<VehicleStatusItem> items,
  ) async {
    final range = _dateRange;
    final end = range?.end ?? DateTime.now();
    final start = range?.start ?? end.subtract(_defaultWindow);
    final isUnfiltered = range == null && _selectedVin == null;
    // No vehicle can contribute more than the fleet-wide cap, so asking each
    // for that many is enough to find the newest overall.
    final perVehicleLimit = isUnfiltered
        ? _unfilteredEventLimit
        : _filteredEventLimit;

    final vins = items
        .map((item) => item.vehicleIdentificationNumber.trim())
        .where((vin) => vin.isNotEmpty)
        .where((vin) => _selectedVin == null || vin == _selectedVin)
        .toSet();

    final perVehicle = await Future.wait(
      vins.map((vin) async {
        try {
          return await _eventService.getEvents(
            vehicleId: vin,
            startDate: start,
            endDate: end,
            limit: perVehicleLimit,
          );
        } catch (_) {
          // Skip vehicles the events API rejects; the rest still load.
          return const <DrowsinessEvent>[];
        }
      }),
    );

    final collected = [for (final events in perVehicle) ...events]
      ..sort((a, b) => b.time.compareTo(a.time));
    return isUnfiltered
        ? collected.take(_unfilteredEventLimit).toList()
        : collected;
  }

  int? _resolveSelection(List<DrowsinessEvent> events) {
    final current = _selectedEventId;
    if (current == null) return null;
    return events.any((event) => event.id == current) ? current : null;
  }

  // --- DERIVED ------------------------------------------------------------

  List<DrowsinessEvent> get _filtered {
    final query = _searchQuery.toLowerCase();

    final matches = _events.where((event) {
      if (_selectedVin != null && event.vehicleId != _selectedVin) return false;
      if (query.isEmpty) return true;

      final vehicle = _vehicleFor(event);
      return [
        event.vehicleId,
        vehicle?.plateNumber ?? '',
        safetyEventTypeLabel(event),
        event.riskLevel,
      ].join(' ').toLowerCase().contains(query);
    }).toList();

    // Sort the matches, not the page: ordering a single page would leave the
    // top row of page 2 outranking the bottom row of page 1.
    return sortSafetyEvents(matches, _sort);
  }

  VehicleStatusItem? _vehicleFor(DrowsinessEvent event) {
    for (final vehicle in _vehicles) {
      if (vehicle.vehicleIdentificationNumber == event.vehicleId ||
          vehicle.vehicleId == event.vehicleId) {
        return vehicle;
      }
    }
    return null;
  }

  DrowsinessEvent? get _selectedEvent {
    for (final event in _events) {
      if (event.id == _selectedEventId) return event;
    }
    return null;
  }

  /// Filter entries labelled by plate, keyed by the VIN the API needs.
  List<VehicleFilterOption> get _vehicleOptions {
    final seen = <String>{};
    final options = <VehicleFilterOption>[];

    for (final vehicle in _vehicles) {
      final vin = vehicle.vehicleIdentificationNumber.trim();
      if (vin.isEmpty || !seen.add(vin)) continue;

      final plate = vehicle.plateNumber.trim();
      options.add(
        VehicleFilterOption(vin: vin, label: plate.isEmpty ? vin : plate),
      );
    }

    options.sort((a, b) => a.label.compareTo(b.label));
    return options;
  }

  int _pageCountFor(int itemCount) =>
      itemCount == 0 ? 1 : (itemCount + _pageSize - 1) ~/ _pageSize;

  void _clampPage() {
    _page = _page.clamp(0, _pageCountFor(_filtered.length) - 1);
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
              SafetyHeader(
                lastUpdated: _lastUpdated,
                searchController: _searchController,
                dateRange: _dateRange,
                onDateRangeChanged: (range) {
                  setState(() {
                    _dateRange = range;
                    _page = 0;
                  });
                  _load();
                },
                vehicleOptions: _vehicleOptions,
                selectedVin: _selectedVin,
                onVehicleChanged: (vin) {
                  setState(() {
                    _selectedVin = vin;
                    _page = 0;
                  });
                  _load();
                },
                isWide: isWide,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: FleetLoader(message: 'Loading safety events...'),
                  ),
                )
              else if (_loadError != null)
                _ErrorState(message: _loadError!, onRetry: _load)
              else
                _buildBody(isWide: isWide),
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
    final pageEvents = filtered.skip(page * _pageSize).take(_pageSize).toList();

    final table = SafetyEventTable(
      pageEvents: pageEvents,
      vehicles: _vehicles,
      selectedEventId: _selectedEventId,
      onEventTap: (event) => setState(() => _selectedEventId = event.id),
      page: page,
      pageCount: pageCount,
      onPageChanged: (next) => setState(() => _page = next),
      sort: _sort,
      onSort: (next) => setState(() {
        _sort = next;
        // A new order makes the old page number meaningless.
        _page = 0;
      }),
      emptyMessage: _events.isEmpty
          ? 'No safety events in this period'
          : 'No events match this filter',
    );

    final selected = _selectedEvent;

    // Nothing picked yet: the table owns the full width.
    if (selected == null) return table;

    final detail = SafetyEventDetailPanel(
      event: selected,
      onClose: () => setState(() => _selectedEventId = null),
    );

    if (!isWide) {
      return Column(children: [table, const SizedBox(height: 14), detail]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 640, child: table),
        const SizedBox(width: 14),
        Expanded(flex: 340, child: detail),
      ],
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
