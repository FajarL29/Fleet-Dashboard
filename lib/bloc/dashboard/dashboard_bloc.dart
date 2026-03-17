import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../models/vehicle.dart';
import '../../services/gps_socket_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

/// BLoC for managing dashboard state
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  // Service & Subscription
  final GpsSocketService _gpsSocketService = GpsSocketService();
  StreamSubscription? _gpsSubscription;

  DashboardBloc() : super(DashboardState.initial()) {
    on<DashboardInitialized>(_onDashboardInitialized);
    on<MenuItemSelected>(_onMenuItemSelected);
    on<VehicleSelected>(_onVehicleSelected);
    on<AlertCleared>(_onAlertCleared);
    on<GpsDataReceived>(_onGpsDataReceived);
    on<StreamImageReceived>(_onStreamImageReceived);
    on<DashboardDisposed>(_onDashboardDisposed);
  }

  /// Handle dashboard initialization
  Future<void> _onDashboardInitialized(
    DashboardInitialized event,
    Emitter<DashboardState> emit,
  ) async {
    emit(state.copyWith(status: DashboardStatus.loading));
    _initRealtimeGps();
  }

  /// Initialize real-time GPS connection
  void _initRealtimeGps() {
    _gpsSubscription = _gpsSocketService.connect(
      vehicleId: '1210',
      deviceType: 'DASHBOARD',
    ).listen(
      (message) {
        // Handle incoming data
        _handleIncomingWsData(message);
      },
      onError: (err) {
        debugPrint("WS Error: $err");
        add(const DashboardDisposed());
      },
      onDone: () {
        debugPrint("Koneksi Selesai");
      },
    );
  }

  /// Handle incoming WebSocket data
  void _handleIncomingWsData(dynamic message) {
    try {
      Map<String, dynamic> data;

      // 1. Parsing data mentah (String vs Map)
      if (message is String) {
        data = json.decode(message);
      } else if (message is Map<String, dynamic>) {
        data = message;
      } else {
        return;
      }

      print("Data masuk: $data");

      // 2. Cek pesan koneksi awal
      if (data.containsKey('message') && data['message'] == 'Connected') {
        debugPrint("✅ Dashboard Connected to Server");
        // Update status to connected
        return;
      }

      // 3. LOGIKA ALERT (STREAM_IMAGE)
      if (data['event'] == 'STREAM_IMAGE') {
        add(StreamImageReceived(data));
        return;
      }

      // 4. LOGIKA PERGERAKAN (GPS)
      // Menangani jika data berupa Map tunggal atau List (untuk fleksibilitas)
      if (data.containsKey('gps_lat') && data.containsKey('gps_lng')) {
        add(GpsDataReceived(data));
      } else if (data.containsKey('data') && data['data'] is List) {
        // Jika data datang dalam format { "data": [...] } seperti REST API sebelumnya
        final dataList = List<Map<String, dynamic>>.from(data['data']);
        for (var singleData in dataList) {
          add(GpsDataReceived(singleData));
        }
      }
    } catch (e) {
      debugPrint("❌ Error parsing WS data: $e");
    }
  }

  /// Handle GPS data received event
  void _onGpsDataReceived(
    GpsDataReceived event,
    Emitter<DashboardState> emit,
  ) {
    final data = event.data;
    final String vId = data['vehicle_id']?.toString() ?? data['id']?.toString() ?? '1210';
    final double lat = (data['gps_lat'] as num).toDouble();
    final double lng = (data['gps_lng'] as num).toDouble();

    // Create updated vehicles list
    final updatedVehicles = state.vehicles.map((vehicle) {
      if (vehicle.id == vId) {
        return Vehicle(
          id: vehicle.id,
          plateNumber: vehicle.plateNumber,
          type: vehicle.type,
          driverName: vehicle.driverName,
          activityTime: vehicle.activityTime,
          position: LatLng(lat, lng),
          status: vehicle.status,
          heading: vehicle.heading,
        );
      }
      return vehicle;
    }).toList();

    emit(state.copyWith(
      vehicles: updatedVehicles,
      status: DashboardStatus.connected,
    ));
  }

  /// Handle stream image (alert) received event
  void _onStreamImageReceived(
    StreamImageReceived event,
    Emitter<DashboardState> emit,
  ) {
    final data = event.data;
    final newAlert = {
      'vehicle_id': data['vehicle_id'],
      'image': data['data']['image'],
      'type': data['data']['behavior_type'],
      'time': DateTime.now(),
    };

    final newAlertLog = List<String>.from(state.alertLog);
    newAlertLog.insert(
      0,
      "Alert: ${data['data']['behavior_type']} - Unit ${data['vehicle_id']}",
    );
    if (newAlertLog.length > 20) {
      newAlertLog.removeLast();
    }

    emit(state.copyWith(
      currentAlert: newAlert,
      alertLog: newAlertLog,
    ));
  }

  /// Handle menu item selection
  void _onMenuItemSelected(
    MenuItemSelected event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(selectedMenuIndex: event.index));
  }

  /// Handle vehicle selection
  void _onVehicleSelected(
    VehicleSelected event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(selectedVehicle: event.vehicle));
  }

  /// Handle alert clear
  void _onAlertCleared(
    AlertCleared event,
    Emitter<DashboardState> emit,
  ) {
    emit(state.copyWith(clearCurrentAlert: true));
  }

  /// Handle dispose/cleanup
  void _onDashboardDisposed(
    DashboardDisposed event,
    Emitter<DashboardState> emit,
  ) {
    _gpsSubscription?.cancel();
    _gpsSocketService.disconnect();
    emit(state.copyWith(status: DashboardStatus.disconnected));
  }

  @override
  Future<void> close() {
    _gpsSubscription?.cancel();
    _gpsSocketService.disconnect();
    return super.close();
  }
}
