import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http; // Tambahkan http
import '../../models/vehicle.dart';
import '../../services/gps_socket_service.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GpsSocketService _gpsSocketService = GpsSocketService();
  StreamSubscription? _gpsSubscription;
  
  // Tambahan untuk Drowsiness Polling
  Timer? _drowsinessTimer;
  int? _lastDrowsinessId; 

  DashboardBloc() : super(DashboardState.initial()) {
    on<DashboardInitialized>(_onDashboardInitialized);
    on<MenuItemSelected>(_onMenuItemSelected);
    on<VehicleSelected>(_onVehicleSelected);
    on<AlertCleared>(_onAlertCleared);
    on<GpsDataReceived>(_onGpsDataReceived);
    on<StreamImageReceived>(_onStreamImageReceived);
    on<DashboardDisposed>(_onDashboardDisposed);
    
    // Event baru untuk menangani hasil polling
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
    _startDrowsinessPolling(userId: 1, token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VybmFtZSI6ImRyaXZlcl9wcm9fMDEiLCJmdWxsbmFtZSI6IlJlaW5lciBQcmFrb3NvIiwiZW1haWwiOiJyZWluZXJAZXhhbXBsZS5jb20iLCJjcmVhdGVkX2J5IjoiU1lTVEVNIiwiY3JlYXRlZF9kdCI6IjIwMjYtMDMtMzBUMTA6MTk6MzYuMDAwWiIsImFkZHJlc3MiOiJCZWthc2ssIEluZG9uZXNpYSIsImlhdCI6MTc3NDg0MDkwOSwiZXhwIjoxNzc0ODQ0NTA5fQ.XWOT48IaoQWCCaQjfzYBabv6QSjiRKLdd0E6QJoQot0");
    // _startDrowsinessPolling(userId: event.userID, token: event.token);

  }

  /// --- LOGIKA DROWSINESS POLLING (HTTP) ---
  void _startDrowsinessPolling({required int userId, required String token}) {
    _drowsinessTimer?.cancel();
    _drowsinessTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        final response = await http.get(
          Uri.parse('http://203.100.57.59:3000/api/v1/drowsiness/latest/$userId'),
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
    final int userId = 3034; // Hardcoded untuk testing, ganti dengan data sebenarnya nanti

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
      final updatedDriverAlerts = Map<int, Map<String, dynamic>>.from(state.driverAlerts);
      updatedDriverAlerts[userId] = newAlertData; // Masukkan alert ke slot Driver yang bersangkutan

      debugPrint("📥 Updated DriverAlerts: $updatedDriverAlerts");
      debugPrint("📥 Updated DriverAlerts type: ${updatedDriverAlerts.runtimeType}");
      debugPrint("📥 Updated DriverAlerts keys: ${updatedDriverAlerts.keys.toList()}");
      debugPrint("📥 Updated DriverAlerts[3034]: ${updatedDriverAlerts[3034]}");

      // 4. Update Alert Log (History)
      final newAlertLog = List<String>.from(state.alertLog);
      newAlertLog.insert(0, "Alert: ${data['status']} - Unit ${data['vehicle_identification_number']}");

      // 5. EMIT State Baru
      debugPrint("📥 Emitting state dengan driverAlerts: $updatedDriverAlerts");
      emit(state.copyWith(
        currentAlert: newAlertData, // Alert paling terakhir secara global
        driverAlerts: updatedDriverAlerts, // Data per-driver untuk monitoring cards
        alertLog: newAlertLog.take(20).toList(),
      ));
      
      debugPrint("🔔 New Drowsiness for User $userId: ID $currentId");
      debugPrint("img_path: ${data['img_path']}");
      debugPrint("📥 State emitted, driverAlerts: ${state.driverAlerts}");
    } else {
      debugPrint("📥 Data drowsiness bukan data baru, diabaikan");
    }
  }

  /// --- LOGIKA GPS WEBSOCKET (EXISTING) ---
  void _initRealtimeGps() {
    _gpsSubscription = _gpsSocketService.connect(
      vehicleId: '1210',
      deviceType: 'DASHBOARD',
    ).listen(
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
  final String vId = data['vehicle_id']?.toString() ?? data['id']?.toString() ?? '1210';
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
        (v) => v.id.toString() == state.selectedVehicle!.id.toString()
      );
    } catch (_) {
      updatedSelected = state.selectedVehicle;
    }
  }

  // 3. EMIT dengan referensi List baru agar BlocBuilder mendeteksi perubahan
  emit(state.copyWith(
    vehicles: List.from(updatedVehicles), // Pakai List.from untuk trigger rebuild
    selectedVehicle: updatedSelected,
    status: DashboardStatus.connected,
  ));
  
  print("🚗 BLOC UPDATED: ID $vId | Speed: $speed");
}

  void _onStreamImageReceived(StreamImageReceived event, Emitter<DashboardState> emit) {
    final data = event.data;
    // Format alert dari WebSocket
    final newAlert = {
      'vehicle_id': data['vehicle_id'],
      'image': data['data']['image'], // Biasanya Base64 kalau dari WS
      'type': data['data']['behavior_type'],
      'time': DateTime.now(),
    };

    final newAlertLog = List<String>.from(state.alertLog);
    newAlertLog.insert(0, "WS Alert: ${data['data']['behavior_type']} - Unit ${data['vehicle_id']}");

    emit(state.copyWith(
      currentAlert: newAlert,
      alertLog: newAlertLog.take(20).toList(),
    ));
  }

  // --- UI CONTROL EVENTS ---
  void _onMenuItemSelected(MenuItemSelected event, Emitter<DashboardState> emit) {
    emit(state.copyWith(selectedMenuIndex: event.index));
  }

  void _onVehicleSelected(VehicleSelected event, Emitter<DashboardState> emit) {
    emit(state.copyWith(selectedVehicle: event.vehicle));
  }

  void _onAlertCleared(AlertCleared event, Emitter<DashboardState> emit) {
    emit(state.copyWith(clearCurrentAlert: true));
  }

  void _onDashboardDisposed(DashboardDisposed event, Emitter<DashboardState> emit) {
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
}

// Tambahkan class event ini di file dashboard_event.dart Anda
// class DrowsinessDataReceived extends DashboardEvent {
//   final Map<String, dynamic> data;
//   const DrowsinessDataReceived(this.data);
// }