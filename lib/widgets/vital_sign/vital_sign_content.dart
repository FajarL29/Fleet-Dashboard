import 'package:flutter/material.dart';

import '../../services/vital_sign_service.dart';
import '../common/app_page_body.dart';
import '../common/app_page_surface.dart';
import 'vital_sign_header.dart';
import 'vital_sign_kpi_row.dart';
import 'vital_sign_overview_table.dart';
import 'vital_sign_reading.dart';

/// Vital Sign Monitoring page: owns the search, driver filter, date filter and
/// paging state, and fetches the readings itself.
class VitalSignContent extends StatefulWidget {
  const VitalSignContent({super.key});

  @override
  State<VitalSignContent> createState() => _VitalSignContentState();
}

class _VitalSignContentState extends State<VitalSignContent> {
  static const int _pageSize = 9;
  static const double _wideBreakpoint = 940;

  final VitalSignService _service = const VitalSignService();
  final TextEditingController _searchController = TextEditingController();

  List<VitalSignReading> _readings = const [];
  bool _isLoading = true;
  String? _loadError;
  DateTime _lastUpdated = DateTime.now();

  String _searchQuery = '';
  String? _selectedDriver;
  DateTimeRange? _dateRange;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_handleSearchChanged);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final readings = await _service.getDriverVitals();
      if (!mounted) return;
      setState(() {
        _readings = readings;
        _isLoading = false;
        _lastUpdated = DateTime.now();
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load vital signs. $error';
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearchChanged() {
    final query = _searchController.text.trim();
    if (query == _searchQuery) return;
    setState(() {
      _searchQuery = query;
      _page = 0;
    });
  }

  void _handleDateRangeChanged(DateTimeRange? range) {
    setState(() {
      _dateRange = range;
      _page = 0;
    });
  }

  List<VitalSignReading> _applyFilters(List<VitalSignReading> readings) {
    final query = _searchQuery.toLowerCase();
    final range = _dateRange;

    return readings.where((reading) {
      if (_selectedDriver != null && reading.driverName != _selectedDriver) {
        return false;
      }

      if (range != null) {
        final telemetry = reading.lastTelemetry;
        // Keep rows with no timestamp: filtering them out would silently hide
        // drivers whose vehicle has not reported yet.
        if (telemetry != null &&
            (telemetry.isBefore(range.start) ||
                telemetry.isAfter(range.end.add(const Duration(days: 1))))) {
          return false;
        }
      }

      if (query.isEmpty) return true;
      return reading.searchBlob.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final readings = _readings;
    final filtered = _applyFilters(readings);
    final pageCount = filtered.isEmpty
        ? 1
        : (filtered.length + _pageSize - 1) ~/ _pageSize;
    final page = _page.clamp(0, pageCount - 1);
    final pageReadings = filtered
        .skip(page * _pageSize)
        .take(_pageSize)
        .toList();

    return AppPageSurface(
      child: AppPageBody(
        wideBreakpoint: _wideBreakpoint,
        builder: (context, {required isWide, required fills}) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VitalSignHeader(
                lastUpdated: _lastUpdated,
                searchController: _searchController,
                dateRange: _dateRange,
                onDateRangeChanged: _handleDateRangeChanged,
                driverNames: readings
                    .map((item) => item.driverName)
                    .toSet()
                    .toList(),
                selectedDriver: _selectedDriver,
                onDriverChanged: (driver) => setState(() {
                  _selectedDriver = driver;
                  _page = 0;
                }),
                isWide: isWide,
              ),
              const SizedBox(height: 22),
              // Trends are left null until the backend returns the
              // period-over-period analysis; the badges stay hidden
              // rather than showing an invented delta.
              VitalSignKpiRow(readings: readings, isWide: isWide),
              const SizedBox(height: 14),
              VitalSignOverviewTable(
                pageReadings: pageReadings,
                page: page,
                pageCount: pageCount,
                onPageChanged: (next) => setState(() => _page = next),
                emptyMessage: _emptyMessage,
              ),
            ],
          );
        },
      ),
    );
  }

  /// Says which of the three reasons the table is empty, instead of implying
  /// the wearables reported nothing when the request simply failed.
  String get _emptyMessage {
    if (_isLoading) return 'Loading driver vital signs...';
    if (_loadError != null) return _loadError!;
    if (_readings.isEmpty) return 'No driver vital sign data yet';
    return 'No drivers match this filter';
  }
}
