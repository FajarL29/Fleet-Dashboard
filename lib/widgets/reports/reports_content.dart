import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../models/drowsiness_report.dart';
import '../../models/vehicle_status.dart';
import '../../services/drowsiness_report_service.dart';
import '../../services/page_data_cache.dart';
import '../../services/vehicle_status_service.dart';
import '../../theme/app_theme.dart';
import '../common/app_page_surface.dart';
import '../common/fleet_loader.dart';
import 'reports_events_over_time_card.dart';
import 'reports_header.dart';
import 'reports_heatmap.dart';
import 'reports_heatmap_card.dart';
import 'reports_hotspot.dart';
import 'reports_hotspot_card.dart';
import 'reports_kpi_row.dart';
import 'reports_severity_donut_card.dart';
import 'reports_summary.dart';

typedef _ReportsSnapshot = ({
  List<VehicleStatusItem> vehicles,
  ReportsSummary summary,
  List<DrowsinessEvent> events,
  DateTime fetchedAt,
});

/// Reports page: pulls the drowsiness report and its events, then derives the
/// KPIs, trend, severity split and hotspots from them.
class ReportsContent extends StatefulWidget {
  const ReportsContent({super.key});

  @override
  State<ReportsContent> createState() => _ReportsContentState();
}

class _ReportsContentState extends State<ReportsContent> {
  static const double _wideBreakpoint = 1080;

  /// Reporting window when no range is chosen.
  static const Duration _window = Duration(days: 30);

  final DrowsinessReportService _reportService =
      const DrowsinessReportService();
  final VehicleStatusService _statusService = const VehicleStatusService();
  final MapController _mapController = MapController();

  List<VehicleStatusItem> _vehicles = const [];
  ReportsSummary _summary = ReportsSummary.empty;
  List<DrowsinessEvent> _events = const [];

  DateTimeRange? _dateRange;

  bool _isLoading = true;
  bool _isExporting = false;
  String? _loadError;
  DateTime _lastUpdated = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  // --- DATA ---------------------------------------------------------------

  String get _cacheKey => 'reports|${_dateRange?.start}|${_dateRange?.end}';

  /// Loads a report per vehicle and rolls them up.
  ///
  /// Each vehicle is fetched independently so one failing (or simply having no
  /// events) does not blank the whole page — the same tolerance the other
  /// pages already have. Cached figures for the same range paint first.
  Future<void> _load() async {
    final key = _cacheKey;
    final cache = context.read<PageDataCache>();
    final cached = cache.read<_ReportsSnapshot>(key);
    final dashboard = context.read<DashboardBloc>().state;

    setState(() {
      _loadError = null;
      if (cached == null) {
        _isLoading = true;
      } else {
        _apply(cached);
      }
    });

    try {
      final vehicles =
          dashboard.vehicleStatusData?.vehicles ??
          (await _statusService.getVehicleStatus()).vehicles;

      final vins = vehicles
          .map((item) => item.vehicleIdentificationNumber.trim())
          .where((vin) => vin.isNotEmpty)
          .toSet();

      final end = _dateRange?.end ?? DateTime.now();
      final start = _dateRange?.start ?? end.subtract(_window);

      final reports = <DrowsinessReport>[];
      final events = <DrowsinessEvent>[];
      Object? lastFailure;

      await Future.wait([
        for (final vin in vins) ...[
          _reportService
              .getReport(vehicleId: vin, startDate: start, endDate: end)
              .then(
                reports.add,
                onError: (Object error) {
                  lastFailure = error;
                },
              ),
          _reportService
              .getEvents(vehicleId: vin, startDate: start, endDate: end)
              .then(
                events.addAll,
                onError: (Object error) {
                  lastFailure = error;
                },
              ),
        ],
      ]);

      // Only a total wash-out is an error; partial data is still useful.
      final washedOut =
          reports.isEmpty && events.isEmpty && lastFailure != null;
      final snapshot = (
        vehicles: vehicles,
        summary: aggregateReports(reports),
        events: events,
        fetchedAt: DateTime.now(),
      );
      if (!washedOut) cache.write(key, snapshot);
      if (!mounted || key != _cacheKey) return;

      setState(() {
        if (washedOut) {
          _isLoading = false;
          if (cached == null) {
            _loadError = 'Failed to load reports. $lastFailure';
          }
        } else {
          _apply(snapshot);
        }
      });
    } catch (error) {
      if (!mounted || key != _cacheKey) return;
      setState(() {
        _isLoading = false;
        if (cached == null) _loadError = 'Failed to load reports. $error';
      });
    }
  }

  void _apply(_ReportsSnapshot snapshot) {
    _vehicles = snapshot.vehicles;
    _summary = snapshot.summary;
    _events = snapshot.events;
    _isLoading = false;
    _lastUpdated = snapshot.fetchedAt;
  }

  /// Exports the whole fleet, or one vehicle, over the range on screen.
  ///
  /// [target] null means every vehicle. The date range is whatever the picker
  /// is showing, so the file always matches the figures next to the button.
  Future<void> _handleExport(ReportExportTarget? target) async {
    final targets = _exportTargets;
    if (targets.isEmpty) {
      // Used to return silently, so pressing Export did nothing at all and
      // looked like a broken button rather than missing data.
      _showSnack('Nothing to export: no vehicle in this range has a VIN.');
      return;
    }

    final end = _dateRange?.end ?? DateTime.now();
    final start = _dateRange?.start ?? end.subtract(_window);

    setState(() => _isExporting = true);
    try {
      if (target == null) {
        final result = await _reportService.exportFleetDrowsinessReportCsv(
          vehicles: targets,
          startDate: start,
          endDate: end,
        );
        if (!mounted) return;
        _showSnack(_fleetMessage(result));
      } else {
        final path = await _reportService.exportDrowsinessReportCsv(
          vehicleId: target.id,
          startDate: start,
          endDate: end,
        );
        if (!mounted) return;
        _showSnack('${target.label} exported. ${_whereLabel(path)}');
      }
    } catch (error) {
      if (!mounted) return;
      _showSnack('CSV export failed: $error');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _fleetMessage(ReportExport result) {
    final vehicles =
        '${result.vehiclesIncluded} vehicle'
        '${result.vehiclesIncluded == 1 ? "" : "s"}';
    final skipped = result.skippedVehicles.isEmpty
        ? ''
        : ' No data for ${result.skippedVehicles.join(", ")}.';

    return '${result.rowCount} rows from $vehicles exported. '
        '${_whereLabel(result.path)}$skipped';
  }

  String _whereLabel(String path) {
    final inDownloads =
        path.contains(r'\Downloads\') || path.contains('/Downloads/');
    return inDownloads ? 'Saved to Downloads.' : 'Saved to $path.';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  // --- DERIVED ------------------------------------------------------------

  /// The vehicles the export menu offers.
  ///
  /// Keyed by VIN because that is what the report endpoint takes, but labelled
  /// by plate because that is what people recognise. Vehicles with no VIN are
  /// left out: there is no way to ask the API for their report.
  List<ReportExportTarget> get _exportTargets {
    final seen = <String>{};
    final targets = <ReportExportTarget>[];

    for (final item in _vehicles) {
      final vin = item.vehicleIdentificationNumber.trim();
      if (vin.isEmpty || !seen.add(vin)) continue;

      final plate = item.plateNumber.trim();
      targets.add(
        ReportExportTarget(id: vin, label: plate.isEmpty ? vin : plate),
      );
    }

    targets.sort((a, b) => a.label.compareTo(b.label));
    return targets;
  }

  /// Counts per risk level, from the events the report period returned.
  ({int critical, int medium, int low}) get _severity {
    var critical = 0;
    var medium = 0;
    var low = 0;

    for (final event in _events) {
      switch (event.riskLevel.trim().toLowerCase()) {
        case 'high':
        case 'critical':
          critical++;
        case 'medium':
          medium++;
        default:
          low++;
      }
    }

    return (critical: critical, medium: medium, low: low);
  }

  List<ReportsHotspot> get _hotspots => buildReportsHotspots(_events);

  ReportsHeatmapData get _heatmap => buildReportsHeatmap(_events);

  /// The heatmap only needs timestamps, which every event has, so its empty
  /// state is simply "nothing happened" — unlike the map, which also goes
  /// empty when the feed omits coordinates.
  String get _heatmapEmptyMessage =>
      _events.isEmpty ? 'No events in this period' : 'No events to plot';

  /// Separates "nothing happened" from "the feed omits coordinates", so an
  /// empty map does not read as a broken card.
  String get _locationEmptyMessage {
    if (_events.isEmpty) return 'No events in this period';
    return 'The ${_events.length} events in this period carry no coordinates, '
        'so there is nothing to place on the map';
  }

  // --- BUILD --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return AppPageSurface(
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= _wideBreakpoint;

          final page = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReportsHeader(
                lastUpdated: _lastUpdated,
                isExporting: _isExporting,
                exportTargets: _exportTargets,
                onExport: _handleExport,
                dateRange: _dateRange,
                onDateRangeChanged: (range) {
                  setState(() => _dateRange = range);
                  _load();
                },
                isWide: isWide,
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 80),
                  child: Center(
                    child: FleetLoader(message: 'Building fleet report...'),
                  ),
                )
              else if (_loadError != null)
                _ErrorState(message: _loadError!, onRetry: _load)
              else
                _buildBody(isWide: isWide),
            ],
          );

          // Wide screens show the whole report at once; narrow ones fall back
          // to scrolling because the cards cannot shrink any further.
          if (!isWide) return SingleChildScrollView(child: page);
          return page;
        },
      ),
    );
  }

  Widget _buildBody({required bool isWide}) {
    final summary = _summary;
    final severity = _severity;
    final hotspots = _hotspots;
    const empty = 'No report data for this period';
    final locationMessage = _locationEmptyMessage;

    final overTime = ReportsEventsOverTimeCard(
      eventsByDay: summary.eventsByDay,
      emptyMessage: empty,
      fill: isWide,
    );
    final donut = ReportsSeverityDonutCard(
      critical: severity.critical,
      medium: severity.medium,
      low: severity.low,
      emptyMessage: empty,
      fill: isWide,
    );
    // Hotspot answers "where", so it owns the map; heatmap answers "when",
    // so it owns the weekday x hour grid.
    final hotspot = ReportsHotspotCard(
      mapController: _mapController,
      hotspots: hotspots,
      emptyMessage: locationMessage,
      fill: isWide,
    );
    final heatmap = ReportsHeatmapCard(
      data: _heatmap,
      emptyMessage: _heatmapEmptyMessage,
      fill: isWide,
    );

    final chartRow = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: overTime),
        const SizedBox(width: 14),
        Expanded(child: donut),
      ],
    );
    final mapRow = Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: hotspot),
        const SizedBox(width: 14),
        Expanded(child: heatmap),
      ],
    );

    if (!isWide) {
      return Column(
        children: [
          ReportsKpiRow(
            totalEvents: summary.totalEvents,
            riskScore: summary.riskScore,
            highRiskEvents: summary.highRiskEvents,
            isWide: isWide,
          ),
          const SizedBox(height: 14),
          overTime,
          const SizedBox(height: 14),
          donut,
          const SizedBox(height: 14),
          hotspot,
          const SizedBox(height: 14),
          heatmap,
        ],
      );
    }

    return Expanded(
      child: Column(
        children: [
          ReportsKpiRow(
            totalEvents: summary.totalEvents,
            riskScore: summary.riskScore,
            highRiskEvents: summary.highRiskEvents,
            isWide: isWide,
          ),
          const SizedBox(height: 14),
          // The bottom row carries the map and the hour grid, both of which
          // need room to be readable, so it gets the larger share.
          Expanded(flex: 4, child: chartRow),
          const SizedBox(height: 14),
          Expanded(flex: 5, child: mapRow),
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
