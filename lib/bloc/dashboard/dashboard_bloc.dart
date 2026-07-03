import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; // Tambahkan http
import '../../models/driver_behavior_summary.dart';
import '../../models/drowsiness_report.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_status.dart';
import '../../services/drowsiness_report_service.dart';
import '../../services/gps_socket_service.dart';
import '../../services/vehicle_status_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GpsSocketService _gpsSocketService = GpsSocketService();
  final DrowsinessReportService _drowsinessReportService =
      const DrowsinessReportService();
  final VehicleStatusService _vehicleStatusService =
      const VehicleStatusService();
  StreamSubscription? _gpsSubscription;

  // Tambahan untuk Drowsiness Polling
  Timer? _drowsinessTimer;
  int? _lastDrowsinessId;

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
  }

  Future<void> _onDashboardInitialized(
    DashboardInitialized event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));

    // 1. Jalankan GPS WebSocket
    _initRealtimeGps();

    // 2. Jalankan Polling Drowsiness (Misal setiap 10 detik)
    // Asumsi: Token dan UserID didapat dari session/auth
    _startDrowsinessPolling(
      userId: Null,
      // VehicleID:
      token:
          "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImRyaXZlcl9wcm9fMDEiLCJmdWxsbmFtZSI6IlJlaW5lciBQcmFrb3NvIiwiZW1haWwiOiJyZWluZXJAZXhhbXBsZS5jb20iLCJjcmVhdGVkX2J5IjoiU1lTVEVNIiwiY3JlYXRlZF9kdCI6IjIwMjYtMDMtMzBUMTA6MTk6MzYuMDAwWiIsImFkZHJlc3MiOiJCZWthc2ssIEluZG9uZXNpYSIsImlhdCI6MTc3NDg0MDkwOSwiZXhwIjoxNzc0ODQ0NTA5fQ.XWOT48IaoQWCCaQjfzYBabv6QSjiRKLdd0E6QJoQot0",
    );
    // _startDrowsinessPolling(userId: event.userID, token: event.token);

    await _loadOverviewData(emit);
  }

  /// --- LOGIKA DROWSINESS POLLING (HTTP) ---
  void _startDrowsinessPolling({
    required dynamic userId,
    required String token,
  }) {
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

        if (kDebugMode) {
          debugPrint('[DrowsinessLatest] Fetch latest for vin=$vin');
        }

        final response = await http.get(
          Uri.parse(
            'http://localhost:3000/api/v1/drowsiness/latest/${Uri.encodeComponent(vin)}',
          ),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final decoded = json.decode(response.body);
          if (decoded['status'] == 'success' && decoded['data'] != null) {
            add(DrowsinessDataReceived(decoded['data']));
          }
        }
      } catch (e) {
        debugPrint("❌ Drowsiness Polling Error: $e");
      }
    });
  }

  void _onDrowsinessDataReceived(
    DrowsinessDataReceived event,
    Emitter<DashboardState> emit,
  ) {
    final data = event.data;
    final int currentId = data['drowsiness_id'];
    //final int userId = data['user_id']; // Ambil ID driver dari API
    final int userId =
        3034; // Hardcoded untuk testing, ganti dengan data sebenarnya nanti

    debugPrint("📥 Drowsiness Data Received: $data");
    debugPrint("📥 Current ID: $currentId, Last ID: $_lastDrowsinessId");
    debugPrint("📥 User ID dari data: ${data['user_id']}");
    debugPrint("📥 User ID yang digunakan: $userId");

    // 1. Cek apakah ini benar-benar data baru (ID lebih besar dari sebelumnya)
    if (_lastDrowsinessId == null || currentId > _lastDrowsinessId!) {
      _lastDrowsinessId = currentId;

      // 2. Siapkan data alert baru
      final newAlertData = {
        'vehicle_id': data['vehicle_identification_number'],
        'image': data['img_path'], // URL Foto dari Server
        'type': data['status'],
        'time': DateTime.parse(data['time']),
      };

      debugPrint("📥 New Alert Data: $newAlertData");
      debugPrint("📥 User ID untuk alert: $userId");

      // 3. Update MAP driverAlerts (Agar Card Budi & Fajar punya data terpisah)
      final updatedDriverAlerts = Map<int, Map<String, dynamic>>.from(
        state.driverAlerts,
      );
      updatedDriverAlerts[userId] =
          newAlertData; // Masukkan alert ke slot Driver yang bersangkutan

      debugPrint("📥 Updated DriverAlerts: $updatedDriverAlerts");
      debugPrint(
        "📥 Updated DriverAlerts type: ${updatedDriverAlerts.runtimeType}",
      );
      debugPrint(
        "📥 Updated DriverAlerts keys: ${updatedDriverAlerts.keys.toList()}",
      );
      debugPrint("📥 Updated DriverAlerts[3034]: ${updatedDriverAlerts[3034]}");

      // 4. Update Alert Log (History)
      final newAlertLog = List<String>.from(state.alertLog);
      newAlertLog.insert(
        0,
        "Alert: ${data['status']} - Unit ${data['vehicle_identification_number']}",
      );

      // 5. EMIT State Baru
      debugPrint("📥 Emitting state dengan driverAlerts: $updatedDriverAlerts");
      emit(
        state.copyWith(
          currentAlert: newAlertData, // Alert paling terakhir secara global
          driverAlerts:
              updatedDriverAlerts, // Data per-driver untuk monitoring cards
          alertLog: newAlertLog.take(20).toList(),
        ),
      );

      debugPrint("🔔 New Drowsiness for User $userId: ID $currentId");
      debugPrint("img_path: ${data['img_path']}");
      debugPrint("📥 State emitted, driverAlerts: ${state.driverAlerts}");
    } else {
      debugPrint("📥 Data drowsiness bukan data baru, diabaikan");
    }
  }

  /// --- LOGIKA GPS WEBSOCKET (EXISTING) ---
  void _initRealtimeGps() {
    _gpsSubscription = _gpsSocketService
        .connect(vehicleId: '1210', deviceType: 'DASHBOARD')
        .listen(
          (message) => _handleIncomingWsData(message),
          onError: (err) {
            debugPrint("WS Error: $err");
            add(const DashboardDisposed());
          },
        );
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

  void _onGpsDataReceived(GpsDataReceived event, Emitter<DashboardState> emit) {
    final data = event.data;
    final String vId =
        data['vehicle_id']?.toString() ?? data['id']?.toString() ?? '1210';
    final double lat = (data['gps_lat'] as num).toDouble();
    final double lng = (data['gps_lng'] as num).toDouble();
    // Pastikan key 'speed_kmph' sesuai dengan JSON dari Postman/RasPi
    final double speed = (data['speed_kmph'] as num?)?.toDouble() ?? 0.0;
    final LatLng newPos = LatLng(lat, lng);

    // 1. Gunakan map untuk membuat list kendaraan yang diperbarui
    final updatedVehicles = state.vehicles.map((vehicle) {
      if (vehicle.id.toString() == vId) {
        return vehicle.copyWith(position: newPos, speed: speed);
      }
      return vehicle;
    }).toList();

    // 2. Cari ulang objek selected dari LIST YANG BARU agar referensinya terupdate
    Vehicle? updatedSelected;
    if (state.selectedVehicle != null) {
      try {
        updatedSelected = updatedVehicles.firstWhere(
          (v) => v.id.toString() == state.selectedVehicle!.id.toString(),
        );
      } catch (_) {
        updatedSelected = state.selectedVehicle;
      }
    }

    // 3. EMIT dengan referensi List baru agar BlocBuilder mendeteksi perubahan
    emit(
      state.copyWith(
        vehicles: List.from(
          updatedVehicles,
        ), // Pakai List.from untuk trigger rebuild
        selectedVehicle: updatedSelected,
        status: DashboardStatus.connected,
      ),
    );

    debugPrint("🚗 BLOC UPDATED: ID $vId | Speed: $speed");
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
    _gpsSubscription?.cancel();
    _drowsinessTimer?.cancel(); // Pastikan timer mati
    _gpsSocketService.disconnect();
  }

  Future<void> _loadRecentDrowsinessEvents(
    Emitter<DashboardState> emit, {
    Vehicle? vehicle,
  }) async {
    final fallbackVehicle = state.vehicles.isEmpty
        ? null
        : state.vehicles.first;
    final targetVehicle = vehicle ?? state.selectedVehicle ?? fallbackVehicle;
    final targetVehicleIds = _eventVehicleIds(
      vehicle: targetVehicle,
      statusItem: state.vehicleStatusData?.vehicles.isEmpty == false
          ? state.vehicleStatusData!.vehicles.first
          : null,
    );

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

      var events = await _fetchEventsForDateRange(
        vehicleIds: targetVehicleIds,
        startDate: todayStart,
        endDate: now,
      );

      if (events.isEmpty) {
        events = await _fetchEventsForDateRange(
          vehicleIds: targetVehicleIds,
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
      vehicles = _mapVehiclesWithCoordinates(vehicleStatusData.vehicles);
      selectedVehicle = _resolveSelectedVehicle(
        vehicles: vehicles,
        selectedVehicleId: state.selectedVehicle?.id,
      );
      debugPrint(
        '[Overview] vehicleStatus total=${vehicleStatusData.summary.totalVehicles} online=${vehicleStatusData.summary.onlineVehicles} offline=${vehicleStatusData.summary.offline} vehicles=${vehicleStatusData.vehicles.length} markers=${vehicles.length}',
      );
    } catch (e) {
      debugPrint('Failed to load vehicle status data: $e');
      vehicleStatusError = 'Vehicle status unavailable';
      selectedVehicle = null;
    }

    final targetVehicleIds = _eventVehicleIds(
      vehicle: selectedVehicle ?? (vehicles.isEmpty ? null : vehicles.first),
      statusItem: vehicleStatusData?.vehicles.isEmpty == false
          ? vehicleStatusData!.vehicles.first
          : null,
    );

    DrowsinessReport? report = state.currentDrowsinessReport;
    List<DriverBehaviorSummary> driverBehaviorSummaries =
        state.driverBehaviorSummaries;
    List<DrowsinessEvent> sortedEvents = state.recentDrowsinessEvents;

    if (targetVehicleIds.isNotEmpty) {
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      try {
        report = await _fetchDrowsinessReport(targetVehicleIds);
      } catch (e) {
        debugPrint('Failed to load drowsiness report: $e');
      }

      try {
        driverBehaviorSummaries = await _fetchDriverBehavior(targetVehicleIds);
      } catch (e) {
        debugPrint('Failed to load driver behavior: $e');
      }

      try {
        var events = await _fetchEventsForDateRange(
          vehicleIds: targetVehicleIds,
          startDate: todayStart,
          endDate: now,
        );

        if (events.isEmpty) {
          events = await _fetchEventsForDateRange(
            vehicleIds: targetVehicleIds,
            startDate: now.subtract(const Duration(days: 30)),
            endDate: now,
          );
        }

        sortedEvents = List<DrowsinessEvent>.from(events)
          ..sort((a, b) => b.time.compareTo(a.time));
        final todayCounts = _buildTodayEventCounts(sortedEvents, now);
        debugPrint(
          '[Overview] todayEvents drowsy=${todayCounts.drowsy} distraction=${todayCounts.distraction} date=${todayStart.toIso8601String()}',
        );
      } catch (e) {
        debugPrint('Failed to load overview drowsiness data: $e');
      }
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

  Future<DrowsinessReport?> _fetchDrowsinessReport(
    List<String> vehicleIds,
  ) async {
    for (final vehicleId in vehicleIds) {
      final report = await _drowsinessReportService.getReport(
        vehicleId: vehicleId,
      );

      if (report.summary.vehicleId.isNotEmpty ||
          report.eventsByDay.isNotEmpty ||
          report.summary.totalEvents > 0) {
        return report;
      }
    }

    return null;
  }

  Future<List<DrowsinessEvent>> _fetchEventsForDateRange({
    required List<String> vehicleIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    for (final vehicleId in vehicleIds) {
      final events = await _drowsinessReportService.getEventsByVehicle(
        vehicleId: vehicleId,
        startDate: startDate,
        endDate: endDate,
        limit: 100,
      );

      if (events.isNotEmpty) {
        return List<DrowsinessEvent>.from(events);
      }
    }

    return <DrowsinessEvent>[];
  }

  Future<List<DriverBehaviorSummary>> _fetchDriverBehavior(
    List<String> vehicleIds,
  ) async {
    for (final vehicleId in vehicleIds) {
      final behaviorSummaries = await _drowsinessReportService
          .getDriverBehavior(vehicleId: vehicleId, limit: 100);

      if (behaviorSummaries.isNotEmpty) {
        return List<DriverBehaviorSummary>.from(behaviorSummaries);
      }
    }

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
    if (item.lastSeenMinutes != null) {
      return 'Last seen ${item.lastSeenMinutes} min ago';
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
