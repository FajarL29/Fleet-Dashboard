import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';

import '../../models/vehicle_status.dart';
import '../../services/air_quality_service.dart';
import '../../services/vehicle_status_service.dart';
import '../common/app_page_surface.dart';
import 'air_quality_header.dart';
import 'air_quality_map_card.dart';
import 'air_quality_metric_row.dart';
import 'air_quality_reading.dart';
import 'air_quality_trend_card.dart';
import '../../utils/app_navigation.dart';

/// Air Quality Monitoring page: owns the vehicle list, filters and the
/// selected trend range.
///
/// Readings come from `/air-monitor/get-air-by-date`, which serves a single
/// day per call, so the selected window is fetched a day at a time.
class AirQualityContent extends StatefulWidget {
  const AirQualityContent({super.key});

  @override
  State<AirQualityContent> createState() => _AirQualityContentState();
}

class _AirQualityContentState extends State<AirQualityContent> {
  static const double _wideBreakpoint = 900;

  final VehicleStatusService _statusService = const VehicleStatusService();
  final AirQualityService _airService = const AirQualityService();
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  List<VehicleStatusItem> _vehicles = const [];
  List<AirQualityReading> _readings = const [];

  bool _isLoadingReadings = true;
  String? _readingsError;

  String _searchQuery = '';
  String? _selectedVehicle;
  DateTimeRange? _dateRange;

  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _loadVehicles();
    _loadReadings();
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  /// Window used until the user picks dates of their own.
  static const Duration _defaultWindow = Duration(days: 7);

  /// Days the current filter covers, newest first.
  ///
  /// The API serves one day per request, so a wider window means one call per
  /// day. Capped so an accidental multi-year range cannot fire hundreds of
  /// requests.
  List<DateTime> get _datesToFetch {
    const maxDays = 31;
    final range = _dateRange;
    final today = DateUtils.dateOnly(DateTime.now());

    final last = range == null ? today : DateUtils.dateOnly(range.end);
    final first = range == null
        ? DateUtils.dateOnly(today.subtract(_defaultWindow))
        : DateUtils.dateOnly(range.start);

    final span = last.difference(first).inDays;
    final days = (span < 0 ? 0 : span) + 1;

    return [
      for (var i = 0; i < (days > maxDays ? maxDays : days); i++)
        last.subtract(Duration(days: i)),
    ];
  }

  /// Fetches every day the filters cover and merges the results.
  ///
  /// A day that fails is skipped rather than blanking the page; only a total
  /// wash-out surfaces an error.
  Future<void> _loadReadings() async {
    setState(() {
      _isLoadingReadings = true;
      _readingsError = null;
    });

    final collected = <AirQualityReading>[];
    Object? lastFailure;
    var succeeded = 0;

    for (final date in _datesToFetch) {
      try {
        collected.addAll(await _airService.getAirByDate(date));
        succeeded++;
      } catch (error) {
        lastFailure = error;
      }
    }

    if (!mounted) return;

    collected.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    setState(() {
      _readings = collected;
      _isLoadingReadings = false;
      _lastUpdated = DateTime.now();
      _readingsError = (succeeded == 0 && lastFailure != null)
          ? 'Failed to load air quality. $lastFailure'
          : null;
    });
  }

  /// Only the vehicle list is real today; it drives the Vehicle filter.
  Future<void> _loadVehicles() async {
    try {
      final data = await _statusService.getVehicleStatus();
      if (!mounted) return;
      setState(() {
        _vehicles = data.vehicles;
        _lastUpdated = DateTime.now();
      });
    } catch (_) {
      // Non-fatal: the filter simply has no vehicles to offer.
    }
  }

  void _handleSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    setState(() => _searchQuery = query);
  }

  void _handleDateRangeChanged(DateTimeRange? range) {
    setState(() => _dateRange = range);
    _loadReadings();
  }

  /// What the trend card prints above the chart. The date picker is the only
  /// thing that changes it, so it always matches what is actually plotted.
  String get _rangeLabel {
    final format = DateFormat('d MMM');
    final range = _dateRange;
    if (range != null) {
      return '${format.format(range.start)} - ${format.format(range.end)}';
    }

    final today = DateTime.now();
    return 'Last ${_defaultWindow.inDays} days · '
        '${format.format(today.subtract(_defaultWindow))} - '
        '${format.format(today)}';
  }

  List<String> get _vehiclePlates {
    final query = _searchQuery.toLowerCase();
    return _vehicles
        .map(
          (item) => item.plateNumber.trim().isNotEmpty
              ? item.plateNumber.trim()
              : item.vehicleIdentificationNumber.trim(),
        )
        .where((plate) => plate.isNotEmpty)
        .where((plate) => query.isEmpty || plate.toLowerCase().contains(query))
        .toSet()
        .toList();
  }

  /// Readings inside the vehicle filter and the chosen dates.
  ///
  /// The fetch already asks for exactly the days in range, so this only has to
  /// trim the edges of the first and last day and apply the vehicle filter.
  List<AirQualityReading> get _filteredReadings {
    final dates = _dateRange;

    return _readings.where((reading) {
      if (_selectedVehicle != null && reading.plateNumber != _selectedVehicle) {
        return false;
      }
      if (dates != null) {
        if (reading.recordedAt.isBefore(dates.start) ||
            reading.recordedAt.isAfter(
              dates.end.add(const Duration(days: 1)),
            )) {
          return false;
        }
      }
      return true;
    }).toList()..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
  }

  AirQualityReading? get _latest {
    final readings = _filteredReadings;
    return readings.isEmpty ? null : readings.last;
  }

  @override
  Widget build(BuildContext context) {
    final readings = _filteredReadings;

    return AppPageSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;

          return Padding(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AirQualityHeader(
                  lastUpdated: _lastUpdated,
                  searchController: _searchController,
                  dateRange: _dateRange,
                  onDateRangeChanged: _handleDateRangeChanged,
                  vehiclePlates: _vehiclePlates,
                  selectedVehicle: _selectedVehicle,
                  onVehicleChanged: (plate) =>
                      setState(() => _selectedVehicle = plate),
                  onAddVehicle: () => openAppRoute(context, '/vehicles'),
                  isWide: isWide,
                ),
                const SizedBox(height: 20),
                AirQualityMetricRow(latest: _latest, isWide: isWide),
                const SizedBox(height: 14),
                if (isWide)
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: AirQualityTrendCard(
                            readings: readings,
                            emptyMessage: _emptyMessage,
                            rangeLabel: _rangeLabel,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: AirQualityMapCard(
                            mapController: _mapController,
                            readings: readings,
                            emptyMessage: _locationEmptyMessage,
                            expandMap: true,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  AirQualityTrendCard(
                    readings: readings,
                    emptyMessage: _emptyMessage,
                    rangeLabel: _rangeLabel,
                  ),
                  const SizedBox(height: 14),
                  AirQualityMapCard(
                    mapController: _mapController,
                    readings: readings,
                    emptyMessage: _locationEmptyMessage,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  /// Tells the cards why they are empty: still loading, the fetch failed, or
  /// the devices genuinely reported nothing for the chosen days.
  String get _emptyMessage {
    if (_isLoadingReadings) return 'Loading air quality readings...';
    if (_readingsError != null) return _readingsError!;
    if (_readings.isEmpty) {
      return 'No air quality readings for the selected dates';
    }
    return 'No readings match this filter';
  }

  /// The map's own reason to be empty: `/air-monitor/get-air-by-date` sends no
  /// latitude/longitude, so it is always empty even when readings exist — that
  /// is a different situation from the trend card having nothing to plot, and
  /// deserves its own message rather than reusing [_emptyMessage].
  String get _locationEmptyMessage {
    if (_isLoadingReadings) return 'Loading air quality readings...';
    if (_readingsError != null) return _readingsError!;
    if (_readings.isEmpty) {
      return 'No air quality readings for the selected dates';
    }
    final count = _filteredReadings.length;
    return 'The $count reading${count == 1 ? '' : 's'} in this period carry no '
        'coordinates, so there is nothing to place on the map';
  }
}
