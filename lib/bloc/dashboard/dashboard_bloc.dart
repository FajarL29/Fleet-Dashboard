import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../models/driver_behavior_summary.dart';
import '../../models/drowsiness_report.dart';
import '../../models/live_gps_fix.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_status.dart';
import '../../services/api_config.dart';
import '../../utils/last_seen_format.dart';
import '../../services/live_fix_merge.dart';
import '../../services/auth_service.dart';
import '../../services/authenticated_http_client.dart';
import '../../services/drowsiness_report_service.dart';
import '../../services/gps_socket_service.dart';
import '../../services/last_known_fix_store.dart';
import '../../services/vehicle_status_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GpsSocketService _gpsSocketService = GpsSocketService();
  final DrowsinessReportService _drowsinessReportService =
      const DrowsinessReportService();
  final VehicleStatusService _vehicleStatusService =
      const VehicleStatusService();
  final LastKnownFixStore _lastKnownFixStore = const LastKnownFixStore();
  StreamSubscription? _gpsSubscription;

  /// Pending GPS reconnect, and how many attempts have been made since the
  /// last frame arrived — together these drive the backoff.
  Timer? _gpsReconnectTimer;
  int _gpsReconnectAttempts = 0;

  // Tambahan untuk Drowsiness Polling
  Timer? _drowsinessTimer;

  /// Periodic `/vehicles/status` poll, shared by every page.
  Timer? _vehicleStatusTimer;

  /// Pending write of the last-known positions.
  ///
  /// Frames arrive every few seconds; writing the file on each one would touch
  /// the disk constantly for data that is only ever read at startup. One
  /// coalesced write every [_fixPersistInterval] keeps it current enough.
  Timer? _fixPersistTimer;
  static const Duration _fixPersistInterval = Duration(seconds: 10);

  /// Newest detection already folded into the state, so the ten-second poll
  /// can tell a fresh event from the one it just re-read.
  int? _lastDrowsinessId;

  /// Driver the monitoring cards attribute every alert to.
  ///
  /// The `user_id` the API sends does not line up with the ids those cards are
  /// keyed by, so alerts are parked on this one until it does.
  static const int _alertDriverId = 3034;

  DashboardBloc() : super(DashboardState.initial()) {
    on<DashboardInitialized>(_onDashboardInitialized);
    on<MenuItemSelected>(_onMenuItemSelected);
    on<VehicleSelected>(_onVehicleSelected);
    on<SelectionCleared>(_onSelectionCleared);
    on<AlertCleared>(_onAlertCleared);
    on<GpsDataReceived>(_onGpsDataReceived);
    on<StreamImageReceived>(_onStreamImageReceived);
    on<DashboardDisposed>(_onDashboardDisposed);
    on<DrowsinessDataReceived>(_onDrowsinessDataReceived);
    on<VehicleStatusRefreshed>(_onVehicleStatusRefreshed);
  }

  Future<void> _onDashboardInitialized(
    DashboardInitialized event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));

    // Where each device was last seen, from the previous run. Restored before
    // anything else so a rig that is currently silent still has a marker while
    // the first live frame is awaited, rather than the map starting empty.
    final remembered = await _lastKnownFixStore.load();
    if (remembered.isNotEmpty) {
      emit(
        state.copyWith(
          liveFixes: remembered,
          vehicles: _vehiclesFrom(state.vehicleStatusData, remembered),
        ),
      );
    }

    // 1. Jalankan GPS WebSocket
    _initRealtimeGps();

    // 2. Jalankan Polling Drowsiness (setiap 10 detik).
    // Token diambil dari AuthService, bukan ditanam di kode.
    _startDrowsinessPolling();
    // _startDrowsinessPolling(userId: event.userID, token: event.token);
    _startVehicleStatusPolling();

    await _loadOverviewData(emit);
  }

  /// Keeps `/vehicles/status` fresh for every page reading this bloc.
  ///
  /// Overview used to load it once at startup and never again, while Live
  /// Tracking polled the same endpoint on its own ten-second timer — so the
  /// two pages could show different rows for the same fleet. One timer here
  /// keeps them identical.
  void _startVehicleStatusPolling() {
    _vehicleStatusTimer?.cancel();
    _vehicleStatusTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (isClosed) return;
      add(const VehicleStatusRefreshed());
    });
  }

  /// Refreshes the vehicle rows without touching anything else on the page.
  ///
  /// Deliberately quieter than [_loadOverviewData]: no loading flag, and a
  /// failure leaves the previous rows in place rather than blanking the map
  /// every time one poll misses.
  Future<void> _onVehicleStatusRefreshed(
    VehicleStatusRefreshed event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final data = await _vehicleStatusService.getVehicleStatus();
      if (isClosed) return;

      emit(
        state.copyWith(
          vehicleStatusData: data,
          // Through the same builder as the socket: mapping the raw rows here
          // would throw away every live position until the next GPS frame.
          vehicles: _vehiclesFrom(data, state.liveFixes),
          clearVehicleStatusError: true,
        ),
      );
    } catch (error) {
      debugPrint('[Overview] status refresh failed, keeping last rows: $error');
    }
  }

  /// --- LOGIKA DROWSINESS POLLING (HTTP) ---
  void _startDrowsinessPolling() {
    _drowsinessTimer?.cancel();
    _drowsinessTimer = Timer.periodic(const Duration(seconds: 10), (
      timer,
    ) async {
      try {
        final vin = _resolveLatestDrowsinessVin();
        if (vin == null) {
          if (kDebugMode) {
            debugPrint(
              '[DrowsinessLatest] Skipped because vehicle VIN is empty',
            );
          }
          return;
        }

        if (AuthService.instance.currentToken == null) {
          if (kDebugMode) {
            debugPrint('[DrowsinessLatest] Skipped: no API token available');
          }
          return;
        }

        if (kDebugMode) {
          debugPrint('[DrowsinessLatest] Fetch latest for vin=$vin');
        }

        // Through the shared client, so this poll refreshes and signs out on
        // a 401 exactly like every other request in the app.
        final response = await AuthenticatedHttpClient.instance
            .get(
              Uri.parse(
                '$kApiBaseUrl/drowsiness/latest/${Uri.encodeComponent(vin)}',
              ),
              headers: const {'Content-Type': 'application/json'},
            )
            .timeout(kApiRequestTimeout);

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded['status'] == 'success' && decoded['data'] != null) {
            add(DrowsinessDataReceived(decoded['data']));
          }
        }
      } catch (error) {
        if (kDebugMode) {
          debugPrint('[DrowsinessLatest] Poll failed: $error');
        }
      }
    });
  }

  void _onDrowsinessDataReceived(
    DrowsinessDataReceived event,
    Emitter<DashboardState> emit,
  ) {
    final latest = DrowsinessEvent.fromJson(event.data);

    // The poll re-reads the same endpoint every ten seconds, so the detection
    // already on screen keeps coming back until a newer one replaces it.
    if (_lastDrowsinessId != null && latest.id <= _lastDrowsinessId!) return;
    _lastDrowsinessId = latest.id;

    final alert = <String, dynamic>{
      'vehicle_id': latest.vehicleId,
      'image': latest.imageUrl,
      'type': latest.status,
      'time': latest.time,
    };

    // Overview loads the event list once when the page opens. Without topping
    // it up here, a vehicle whose camera is plainly still reporting drops out
    // of the online count as soon as its last loaded event passes
    // [kSafetyReportMaxAge].
    final events = <DrowsinessEvent>[
      latest,
      for (final existing in state.recentDrowsinessEvents)
        if (existing.id != latest.id) existing,
    ]..sort((a, b) => b.time.compareTo(a.time));

    if (kDebugMode) {
      debugPrint(
        '[DrowsinessLatest] New event ${latest.id} for ${latest.vehicleId}',
      );
    }

    emit(
      state.copyWith(
        currentAlert: alert,
        driverAlerts: Map<int, Map<String, dynamic>>.from(state.driverAlerts)
          ..[_alertDriverId] = alert,
        alertLog: [
          'Alert: ${latest.status} - Unit ${latest.vehicleId}',
          ...state.alertLog,
        ].take(20).toList(),
        recentDrowsinessEvents: events.take(50).toList(),
      ),
    );
  }

  /// --- LOGIKA GPS WEBSOCKET (EXISTING) ---
  void _initRealtimeGps() {
    _gpsReconnectTimer?.cancel();
    _gpsSubscription?.cancel();

    _gpsSubscription = _gpsSocketService
        .connect(vehicleId: kGpsTrackerId, deviceType: 'DASHBOARD')
        .listen(
          (message) {
            // A frame arrived, so whatever went wrong before is over.
            _gpsReconnectAttempts = 0;
            _handleIncomingWsData(message);
          },
          // Both paths lead to the same place: a socket that has stopped
          // delivering. A clean close used to be ignored entirely, which left
          // the map frozen with no hint that the feed had ended.
          onError: (err) {
            debugPrint('[GPS] socket error: $err');
            _scheduleGpsReconnect();
          },
          onDone: () {
            debugPrint('[GPS] socket closed by server');
            _scheduleGpsReconnect();
          },
        );
  }

  /// Reconnects the GPS feed after a backoff.
  ///
  /// A dropped socket used to tear the whole dashboard down — cancelling the
  /// drowsiness polling with it — and never came back, so a single blip meant
  /// restarting the app. Only the GPS feed is restarted here; nothing else on
  /// the page depends on it.
  void _scheduleGpsReconnect() {
    if (isClosed) return;

    _gpsSubscription?.cancel();
    _gpsSubscription = null;
    _gpsSocketService.disconnect();

    // 2s, 4s, 8s, 16s, then every 30s — quick enough to catch a blip, slow
    // enough not to hammer a server that is genuinely down.
    _gpsReconnectAttempts++;
    final seconds = math.min(30, 1 << math.min(_gpsReconnectAttempts, 5));
    debugPrint(
      '[GPS] reconnecting in ${seconds}s '
      '(attempt $_gpsReconnectAttempts)',
    );

    _gpsReconnectTimer?.cancel();
    _gpsReconnectTimer = Timer(Duration(seconds: seconds), () {
      if (isClosed) return;
      _initRealtimeGps();
    });
  }

  void _handleIncomingWsData(dynamic message) {
    try {
      Map<String, dynamic> data;
      if (message is String) {
        if (message.trim().isEmpty) {
          return;
        }
        data = json.decode(message);
      } else if (message is Map<String, dynamic>) {
        data = message;
      } else {
        return;
      }

      if (data['event'] == 'STREAM_IMAGE') {
        add(StreamImageReceived(data));
        return;
      }

      if (data.containsKey('gps_lat') && data.containsKey('gps_lng')) {
        add(GpsDataReceived(data));
      }
    } catch (e) {
      debugPrint("❌ Error parsing WS data: $e");
    }
  }

  /// Trackers whose id matched nothing in the fleet, already reported once.
  ///
  /// The device streams every few seconds; without this the console would fill
  /// with the same warning and drown out everything else.
  final Set<String> _reportedUnknownTrackers = <String>{};

  void _onGpsDataReceived(GpsDataReceived event, Emitter<DashboardState> emit) {
    final data = event.data;

    // The frame carries the tracker's own id; translate it to the fleet
    // vehicle it is fitted to before trying to match anything.
    final String trackerId =
        data['vehicle_id']?.toString() ??
        data['id']?.toString() ??
        kGpsTrackerId;
    final String vId = kTrackerToVehicleId[trackerId] ?? trackerId;
    final double lat = (data['gps_lat'] as num).toDouble();
    final double lng = (data['gps_lng'] as num).toDouble();
    // Pastikan key 'speed_kmph' sesuai dengan JSON dari Postman/RasPi
    final double speed = (data['speed_kmph'] as num?)?.toDouble() ?? 0.0;
    // The tracker reports its compass bearing; without this the marker points
    // the same way no matter which direction the vehicle is actually going.
    final double? heading = (data['heading_deg'] as num?)?.toDouble();

    final fix = LiveGpsFix(
      trackerId: trackerId,
      vehicleId: vId,
      position: LatLng(lat, lng),
      speed: speed,
      heading: heading,
      receivedAt: DateTime.now(),
    );
    final fixes = {...state.liveFixes, vId: fix};

    final vehicles = _vehiclesFrom(state.vehicleStatusData, fixes);

    if (!vehicles.any((v) => v.id.trim() == vId || v.vin == vId) &&
        _reportedUnknownTrackers.add(trackerId)) {
      debugPrint(
        '[GPS] Tracker "$trackerId" resolved to vehicle "$vId", which is not '
        'in /vehicles/status. Showing it as a standalone live marker.',
      );
    }

    // Re-resolve the selection against the new list so the detail panel keeps
    // pointing at the same vehicle rather than a stale copy of it.
    Vehicle? updatedSelected;
    final selectedId = state.selectedVehicle?.id;
    if (selectedId != null) {
      for (final vehicle in vehicles) {
        if (vehicle.id == selectedId) {
          updatedSelected = vehicle;
          break;
        }
      }
      updatedSelected ??= state.selectedVehicle;
    }

    emit(
      state.copyWith(
        vehicles: vehicles,
        selectedVehicle: updatedSelected,
        status: DashboardStatus.connected,
        liveFixes: fixes,
      ),
    );
    _schedulePersistFixes(fixes);

    debugPrint(
      '🚗 GPS $trackerId→$vId $lat,$lng | ${speed.toStringAsFixed(1)} km/h'
      '${heading == null ? "" : " | ${heading.toStringAsFixed(0)}°"}',
    );
  }

  /// Queues the last-known positions to be written, at most one write per
  /// [_fixPersistInterval].
  void _schedulePersistFixes(Map<String, LiveGpsFix> fixes) {
    if (_fixPersistTimer?.isActive ?? false) return;
    _fixPersistTimer = Timer(_fixPersistInterval, () {
      // Read from state rather than closing over `fixes`: by the time this
      // fires, newer frames have usually arrived.
      _lastKnownFixStore.save(state.liveFixes);
    });
  }

  /// The map markers, built from the status rows with live fixes overlaid.
  ///
  /// Both the socket and the ten-second status poll come through here, so
  /// there is one definition of "where the fleet is" rather than one per
  /// caller — and it is the same [applyLiveFixes] that Live Tracking uses, so
  /// the two pages cannot disagree.
  List<Vehicle> _vehiclesFrom(
    VehicleStatusData? statusData,
    Map<String, LiveGpsFix> fixes,
  ) {
    final rows = applyLiveFixes(
      statusData?.vehicles ?? const <VehicleStatusItem>[],
      fixes,
      includeUnregistered: true,
    );
    return _mapVehiclesWithCoordinates(rows);
  }

  void _onStreamImageReceived(
    StreamImageReceived event,
    Emitter<DashboardState> emit,
  ) {
    final data = event.data;
    // Format alert dari WebSocket
    final newAlert = {
      'vehicle_id': data['vehicle_id'],
      'image': data['data']['image'], // Biasanya Base64 kalau dari WS
      'type': data['data']['behavior_type'],
      'time': DateTime.now(),
    };

    final newAlertLog = List<String>.from(state.alertLog);
    newAlertLog.insert(
      0,
      "WS Alert: ${data['data']['behavior_type']} - Unit ${data['vehicle_id']}",
    );

    emit(
      state.copyWith(
        currentAlert: newAlert,
        alertLog: newAlertLog.take(20).toList(),
      ),
    );
  }

  // --- UI CONTROL EVENTS ---
  void _onMenuItemSelected(
    MenuItemSelected event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(selectedMenuIndex: event.index));
  }

  Future<void> _onVehicleSelected(
    VehicleSelected event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(selectedVehicle: event.vehicle));
    await _loadRecentDrowsinessEvents(emit, vehicle: event.vehicle);
  }

  void _onSelectionCleared(
    SelectionCleared event,
    Emitter<DashboardState> emit,
  ) {
    debugPrint('🔄 SelectionCleared event received, clearing selectedVehicle');
    emit(state.copyWith(selectedVehicle: null));
  }

  void _onAlertCleared(AlertCleared event, Emitter<DashboardState> emit) {
    emit(state.copyWith(clearCurrentAlert: true));
  }

  void _onDashboardDisposed(
    DashboardDisposed event,
    Emitter<DashboardState> emit,
  ) {
    _cleanup();
    emit(state.copyWith(status: DashboardStatus.disconnected));
  }

  @override
  Future<void> close() {
    _cleanup();
    return super.close();
  }

  void _cleanup() {
    _gpsReconnectTimer?.cancel();
    _gpsSubscription?.cancel();
    _drowsinessTimer?.cancel(); // Pastikan timer mati
    _vehicleStatusTimer?.cancel();
    _gpsSocketService.disconnect();

    // Flush rather than drop: closing within the write-behind window would
    // otherwise lose the most recent position, which is the one worth keeping.
    _fixPersistTimer?.cancel();
    _fixPersistTimer = null;
    if (state.liveFixes.isNotEmpty) {
      _lastKnownFixStore.save(state.liveFixes);
    }
  }

  Future<void> _loadRecentDrowsinessEvents(
    Emitter<DashboardState> emit, {
    Vehicle? vehicle,
  }) async {
    final fallbackVehicle = state.vehicles.isEmpty
        ? null
        : state.vehicles.first;
    final selected = vehicle ?? state.selectedVehicle;
    final targetVehicle = selected ?? fallbackVehicle;

    // Scoped to one vehicle only when the user actually picked one. With
    // nothing selected the page is showing the fleet, so it asks about the
    // fleet — previously it silently reported on `vehicles.first` alone.
    final fleetIdentifiers = selected != null
        ? [_eventVehicleIds(vehicle: selected)]
        : _fleetEventIdentifiers(
            vehicles: state.vehicles,
            statusData: state.vehicleStatusData,
          );
    final targetVehicleIds = [for (final group in fleetIdentifiers) ...group];

    if (targetVehicle == null && targetVehicleIds.isEmpty) {
      emit(
        state.copyWith(
          recentDrowsinessEvents: const [],
          clearCurrentDrowsinessReport: true,
          driverBehaviorSummaries: const [],
          isOverviewLoading: false,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);

    try {
      emit(state.copyWith(isOverviewLoading: true));
      DrowsinessReport? report;
      List<DriverBehaviorSummary> driverBehaviorSummaries =
          state.driverBehaviorSummaries;
      try {
        report = await _fetchDrowsinessReport(targetVehicleIds);
      } catch (e) {
        debugPrint('Failed to load drowsiness report: $e');
        report = state.currentDrowsinessReport;
      }
      try {
        driverBehaviorSummaries = await _fetchDriverBehavior(targetVehicleIds);
      } catch (e) {
        debugPrint('Failed to load driver behavior: $e');
      }

      var events = await _fetchFleetEvents(
        vehicles: fleetIdentifiers,
        startDate: todayStart,
        endDate: now,
      );

      if (events.isEmpty) {
        events = await _fetchFleetEvents(
          vehicles: fleetIdentifiers,
          startDate: now.subtract(const Duration(days: 30)),
          endDate: now,
        );
      }

      final sortedEvents = List<DrowsinessEvent>.from(events)
        ..sort((a, b) => b.time.compareTo(a.time));

      final todayCounts = _buildTodayEventCounts(sortedEvents, now);
      debugPrint(
        '[Overview] todayEvents drowsy=${todayCounts.drowsy} distraction=${todayCounts.distraction} date=${todayStart.toIso8601String()}',
      );

      emit(
        state.copyWith(
          recentDrowsinessEvents: sortedEvents,
          currentDrowsinessReport: report,
          driverBehaviorSummaries: driverBehaviorSummaries,
          isOverviewLoading: false,
        ),
      );
    } catch (e) {
      debugPrint('Failed to load overview drowsiness data: $e');
      emit(
        state.copyWith(
          recentDrowsinessEvents: state.recentDrowsinessEvents,
          currentDrowsinessReport: state.currentDrowsinessReport,
          driverBehaviorSummaries: state.driverBehaviorSummaries,
          isOverviewLoading: false,
        ),
      );
    }
  }

  Future<void> _loadOverviewData(Emitter<DashboardState> emit) async {
    emit(
      state.copyWith(isOverviewLoading: true, clearVehicleStatusError: true),
    );

    VehicleStatusData? vehicleStatusData;
    List<Vehicle> vehicles = const [];
    Vehicle? selectedVehicle;
    String? vehicleStatusError;

    try {
      vehicleStatusData = await _vehicleStatusService.getVehicleStatus();
      vehicles = _vehiclesFrom(vehicleStatusData, state.liveFixes);
      selectedVehicle = _resolveSelectedVehicle(
        vehicles: vehicles,
        selectedVehicleId: state.selectedVehicle?.id,
      );
      debugPrint(
        '[Overview] vehicleStatus total=${vehicleStatusData.summary.totalVehicles} online=${vehicleStatusData.summary.onlineVehicles} offline=${vehicleStatusData.summary.offline} vehicles=${vehicleStatusData.vehicles.length} markers=${vehicles.length}',
      );
      // Out now rather than with the safety figures below, which take several
      // more round trips: the KPIs and map can paint while those load.
      emit(
        state.copyWith(
          vehicles: vehicles,
          selectedVehicle: selectedVehicle,
          vehicleStatusData: vehicleStatusData,
        ),
      );
    } catch (e) {
      debugPrint('Failed to load vehicle status data: $e');
      vehicleStatusError = 'Vehicle status unavailable';
      selectedVehicle = null;
    }

    // The whole fleet, not just the first vehicle: this page's figures are
    // fleet-wide, and asking one vehicle made them read zero whenever that
    // vehicle happened to have no events.
    final fleetIdentifiers = _fleetEventIdentifiers(
      vehicles: vehicles,
      statusData: vehicleStatusData,
    );
    final targetVehicleIds = [for (final group in fleetIdentifiers) ...group];

    DrowsinessReport? report = state.currentDrowsinessReport;
    List<DriverBehaviorSummary> driverBehaviorSummaries =
        state.driverBehaviorSummaries;
    List<DrowsinessEvent> sortedEvents = state.recentDrowsinessEvents;

    if (targetVehicleIds.isNotEmpty) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Independent of each other, so they run side by side.
      await Future.wait([
        _fetchDrowsinessReport(targetVehicleIds).then(
          (value) => report = value,
          onError: (Object e) {
            debugPrint('Failed to load drowsiness report: $e');
            return report;
          },
        ),
        _fetchDriverBehavior(targetVehicleIds).then(
          (value) => driverBehaviorSummaries = value,
          onError: (Object e) {
            debugPrint('Failed to load driver behavior: $e');
            return driverBehaviorSummaries;
          },
        ),
        () async {
          try {
            var events = await _fetchFleetEvents(
              vehicles: fleetIdentifiers,
              startDate: todayStart,
              endDate: now,
            );

            if (events.isEmpty) {
              events = await _fetchFleetEvents(
                vehicles: fleetIdentifiers,
                startDate: now.subtract(const Duration(days: 30)),
                endDate: now,
              );
            }

            sortedEvents = events;
            final todayCounts = _buildTodayEventCounts(sortedEvents, now);
            debugPrint(
              '[Overview] todayEvents drowsy=${todayCounts.drowsy} distraction=${todayCounts.distraction} date=${todayStart.toIso8601String()}',
            );
          } catch (e) {
            debugPrint('Failed to load overview drowsiness data: $e');
          }
        }(),
      ]);
    } else {
      report = null;
      driverBehaviorSummaries = const [];
      sortedEvents = const [];
    }

    emit(
      state.copyWith(
        vehicles: vehicles,
        selectedVehicle: selectedVehicle,
        vehicleStatusData: vehicleStatusData,
        vehicleStatusError: vehicleStatusError,
        recentDrowsinessEvents: sortedEvents,
        currentDrowsinessReport: report,
        driverBehaviorSummaries: driverBehaviorSummaries,
        isOverviewLoading: false,
      ),
    );
  }

  /// The first identifier, in order, whose report has anything in it.
  ///
  /// All are asked at once; walking them one by one meant a fleet whose early
  /// vehicles had no data waited through every empty answer before the first
  /// useful one.
  Future<DrowsinessReport?> _fetchDrowsinessReport(
    List<String> vehicleIds,
  ) async {
    Object? failure;
    final reports = await Future.wait(
      vehicleIds.map(
        (vehicleId) => _drowsinessReportService
            .getReport(vehicleId: vehicleId)
            .then<DrowsinessReport?>(
              (r) => r,
              onError: (Object error) {
                failure ??= error;
                return null;
              },
            ),
      ),
    );

    for (final report in reports) {
      if (report != null &&
          (report.summary.vehicleId.isNotEmpty ||
              report.eventsByDay.isNotEmpty ||
              report.summary.totalEvents > 0)) {
        return report;
      }
    }

    // Every request failed: let the caller keep what it already had.
    if (failure != null && reports.every((r) => r == null)) throw failure!;
    return null;
  }

  /// Events across the whole fleet, merged.
  ///
  /// Within a vehicle's identifier group the first that answers wins; across
  /// vehicles every result is kept. A vehicle that errors is skipped rather
  /// than sinking the others — one unreachable vehicle should not blank the
  /// safety figures for the rest.
  Future<List<DrowsinessEvent>> _fetchFleetEvents({
    required List<List<String>> vehicles,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    Future<List<DrowsinessEvent>> eventsFor(List<String> identifiers) async {
      for (final vehicleId in identifiers) {
        try {
          final events = await _drowsinessReportService.getEventsByVehicle(
            vehicleId: vehicleId,
            startDate: startDate,
            endDate: endDate,
            limit: 100,
          );
          if (events.isNotEmpty) return events;
        } catch (error) {
          if (kDebugMode) {
            debugPrint('[Overview] events for $vehicleId failed: $error');
          }
        }
      }
      return const <DrowsinessEvent>[];
    }

    final perVehicle = await Future.wait(vehicles.map(eventsFor));
    return [for (final events in perVehicle) ...events]
      ..sort((a, b) => b.time.compareTo(a.time));
  }

  /// The first identifier, in order, with any behaviour on record; all asked
  /// at once, for the same reason as [_fetchDrowsinessReport].
  Future<List<DriverBehaviorSummary>> _fetchDriverBehavior(
    List<String> vehicleIds,
  ) async {
    Object? failure;
    var failures = 0;
    final results = await Future.wait(
      vehicleIds.map(
        (vehicleId) => _drowsinessReportService
            .getDriverBehavior(vehicleId: vehicleId, limit: 100)
            .then<List<DriverBehaviorSummary>>(
              (r) => r,
              onError: (Object error) {
                failure ??= error;
                failures++;
                return const <DriverBehaviorSummary>[];
              },
            ),
      ),
    );

    for (final behaviorSummaries in results) {
      if (behaviorSummaries.isNotEmpty) {
        return List<DriverBehaviorSummary>.from(behaviorSummaries);
      }
    }

    // Every request failed: let the caller keep what it already had.
    if (failure != null && failures == vehicleIds.length) throw failure!;
    return <DriverBehaviorSummary>[];
  }

  _TodayEventCounts _buildTodayEventCounts(
    List<DrowsinessEvent> events,
    DateTime date,
  ) {
    var drowsy = 0;
    var distraction = 0;

    for (final event in events) {
      if (!_isSameDay(event.time, date)) {
        continue;
      }

      final normalized = _normalizeBehavior(event);
      if (normalized == 'drowsy') {
        drowsy += 1;
      } else if (normalized == 'distraction') {
        distraction += 1;
      }
    }

    return _TodayEventCounts(drowsy: drowsy, distraction: distraction);
  }

  String? _resolveLatestDrowsinessVin() {
    final candidates = <Vehicle?>[
      state.selectedVehicle,
      if (state.vehicles.isNotEmpty) state.vehicles.first,
    ];

    for (final vehicle in candidates) {
      final vin = vehicle?.vin;
      if (vin != null && vin.isNotEmpty) {
        return vin;
      }
    }

    return null;
  }

  /// One group of interchangeable identifiers per vehicle in the fleet.
  ///
  /// VIN, numeric id and plate all name the same vehicle, so within a group
  /// the first that answers wins. Across groups the results are merged —
  /// which is what makes the Overview's figures cover the fleet rather than
  /// whichever vehicle happened to sort first.
  ///
  /// That was the bug: the page asked only about `vehicles.first`, and on this
  /// fleet that is a vehicle with no events at all, so the safety counters read
  /// zero while another vehicle had a high-risk event on record.
  List<List<String>> _fleetEventIdentifiers({
    required List<Vehicle> vehicles,
    required VehicleStatusData? statusData,
  }) {
    final groups = <List<String>>[];
    final seen = <String>{};

    void addGroup(List<String?> candidates) {
      final ids = <String>[];
      for (final candidate in candidates) {
        final trimmed = candidate?.trim();
        if (trimmed != null && trimmed.isNotEmpty && !ids.contains(trimmed)) {
          ids.add(trimmed);
        }
      }
      // Keyed on the best identifier so a vehicle present in both the marker
      // list and the status payload is not queried twice.
      if (ids.isEmpty || !seen.add(ids.first)) return;
      groups.add(ids);
    }

    for (final vehicle in vehicles) {
      addGroup([vehicle.apiVehicleId, vehicle.id, vehicle.plateNumber]);
    }
    for (final item in statusData?.vehicles ?? const <VehicleStatusItem>[]) {
      addGroup([
        item.vehicleIdentificationNumber,
        item.vehicleId,
        item.plateNumber,
      ]);
    }

    return groups;
  }

  List<String> _eventVehicleIds({
    Vehicle? vehicle,
    VehicleStatusItem? statusItem,
  }) {
    final identifiers = <String>{};

    void addIdentifier(String? value) {
      final trimmed = value?.trim();
      if (trimmed != null && trimmed.isNotEmpty) {
        identifiers.add(trimmed);
      }
    }

    addIdentifier(vehicle?.apiVehicleId);
    addIdentifier(vehicle?.id);
    addIdentifier(vehicle?.plateNumber);
    addIdentifier(statusItem?.vehicleIdentificationNumber);
    addIdentifier(statusItem?.vehicleId);
    addIdentifier(statusItem?.plateNumber);

    return identifiers.toList();
  }

  List<Vehicle> _mapVehiclesWithCoordinates(List<VehicleStatusItem> items) {
    return items.where((item) => item.hasCoordinates).map((item) {
      final latitude = item.latitude!;
      final longitude = item.longitude!;

      return Vehicle(
        id: item.vehicleId.isNotEmpty
            ? item.vehicleId
            : item.vehicleIdentificationNumber,
        apiVehicleId: item.vehicleIdentificationNumber.isNotEmpty
            ? item.vehicleIdentificationNumber
            : null,
        plateNumber: item.plateNumber.isNotEmpty
            ? item.plateNumber
            : item.vehicleIdentificationNumber,
        type: item.movementStatus.isNotEmpty ? item.movementStatus : 'Unknown',
        driverName: item.driverName.isNotEmpty
            ? item.driverName
            : 'Unknown Driver',
        activityTime: _activityLabel(item),
        position: LatLng(latitude, longitude),
        status: _vehicleStatusFromDisplayStatus(item.displayStatus),
        speed: item.speed ?? 0,
        heading: item.heading ?? 0,
        displayStatus: item.displayStatus,
        statusReason: item.statusReason,
        lastTelemetryTime: item.lastTelemetryTime,
        lastSeenMinutes: item.lastSeenMinutes,
      );
    }).toList();
  }

  Vehicle? _resolveSelectedVehicle({
    required List<Vehicle> vehicles,
    String? selectedVehicleId,
  }) {
    if (vehicles.isEmpty) {
      return null;
    }

    if (selectedVehicleId == null || selectedVehicleId.isEmpty) {
      return null;
    }

    for (final vehicle in vehicles) {
      if (vehicle.id == selectedVehicleId) {
        return vehicle;
      }
    }

    return vehicles.first;
  }

  String _activityLabel(VehicleStatusItem item) {
    final minutes = item.lastSeenMinutes;
    if (minutes != null) {
      return 'Last seen ${formatLastSeen(minutes)}';
    }

    if (item.lastTelemetryTime != null) {
      return item.lastTelemetryTime!.toIso8601String();
    }

    return 'Telemetry unavailable';
  }

  VehicleStatus _vehicleStatusFromDisplayStatus(String rawStatus) {
    switch (rawStatus.trim().toLowerCase()) {
      case 'alert':
        return VehicleStatus.alert;
      case 'warning':
        return VehicleStatus.warning;
      case 'offline':
        return VehicleStatus.inactive;
      default:
        return VehicleStatus.active;
    }
  }

  String? _normalizeBehavior(DrowsinessEvent event) {
    final raw = '${event.behaviorType ?? ''} ${event.status}'.toLowerCase();
    if (raw.contains('drows')) return 'drowsy';
    if (raw.contains('yawn')) return 'yawn';
    if (raw.contains('distraction')) return 'distraction';
    if (raw.contains('one_hand_off_wheel') ||
        raw.contains('one hand off wheel') ||
        raw.contains('hands_off') ||
        raw.contains('hand off wheel')) {
      return 'one_hand_off_wheel';
    }
    return null;
  }

  bool _isSameDay(DateTime left, DateTime right) {
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}

class _TodayEventCounts {
  const _TodayEventCounts({required this.drowsy, required this.distraction});

  final int drowsy;
  final int distraction;
}

// Tambahkan class event ini di file dashboard_event.dart Anda
// class DrowsinessDataReceived extends DashboardEvent {
//   final Map<String, dynamic> data;
//   const DrowsinessDataReceived(this.data);
// }
