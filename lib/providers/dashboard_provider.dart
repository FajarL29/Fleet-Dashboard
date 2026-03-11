import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/vehicle.dart';
import '../models/driver_health.dart';
import '../models/aqi_data.dart';
import '../services/gps_socket_service.dart';

class DashboardProvider with ChangeNotifier {
  // Service & Subscription
  final GpsSocketService _gpsSocketService = GpsSocketService();
  StreamSubscription? _gpsSubscription;

  // UI State
  int _selectedMenuIndex = 0;
  int get selectedMenuIndex => _selectedMenuIndex;

  Vehicle? _selectedVehicle;
  Vehicle? get selectedVehicle => _selectedVehicle;

  Map<String, dynamic>? _currentAlert;
  Map<String, dynamic>? get currentAlert => _currentAlert;

  // Data Vehicles
  final List<Vehicle> _vehicles = [
    Vehicle(
      id: '1210', 
      plateNumber: 'B 1234 SUF',
      type: 'HIACE Commuter',
      driverName: 'Fajar',
      activityTime: '10.30 a.m. - 13.00 p.m.',
      position: LatLng(-6.2088, 106.8456),
      status: VehicleStatus.active,
    ),
  ];
  List<Vehicle> get vehicles => _vehicles;

  DashboardProvider() {
    _initRealtimeGps();
  }

  // --- Real-time Logic ---

  void _initRealtimeGps() {
    _gpsSubscription = _gpsSocketService.connect(
      vehicleId: '1210', 
      deviceType: 'DASHBOARD'
    ).listen(
      (message) {
        // Langsung kirim ke handler utama, parsing dilakukan di sana
        _handleIncomingWsData(message);
      },
      onError: (err) => debugPrint("WS Error: $err"),
      onDone: () => debugPrint("Koneksi Selesai"),
    );
  }

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
        return;
      }

      // 3. LOGIKA ALERT (STREAM_IMAGE)
      if (data['event'] == 'STREAM_IMAGE') {
        _currentAlert = {
          'vehicle_id': data['vehicle_id'],
          'image': data['data']['image'], 
          'type': data['data']['behavior_type'],
          'time': DateTime.now(),
        };
        
        _alertLog.insert(0, "Alert: ${data['data']['behavior_type']} - Unit ${data['vehicle_id']}");
        if (_alertLog.length > 20) _alertLog.removeLast();

        notifyListeners();
        return;
      }

      // 4. LOGIKA PERGERAKAN (GPS)
      // Menangani jika data berupa Map tunggal atau List (untuk fleksibilitas)
      if (data.containsKey('gps_lat') && data.containsKey('gps_lng')) {
        _updateSingleVehiclePosition(data);
      } 
      else if (data.containsKey('data') && data['data'] is List) {
        // Jika data datang dalam format { "data": [...] } seperti REST API sebelumnya
        _updateMultiplePositions(List<Map<String, dynamic>>.from(data['data']));
      }

    } catch (e) {
      debugPrint("❌ Error parsing WS data: $e");
    }
  }

  void _updateSingleVehiclePosition(Map<String, dynamic> data) {
    final String vId = data['vehicle_id']?.toString() ?? data['id']?.toString() ?? '1210';
    final double lat = (data['gps_lat'] as num).toDouble();
    final double lng = (data['gps_lng'] as num).toDouble();

    final index = _vehicles.indexWhere((v) => v.id == vId);
    if (index != -1) {
      _vehicles[index].position = LatLng(lat, lng);
      Future.microtask(() => notifyListeners());
    }
  }

  void _updateMultiplePositions(List<Map<String, dynamic>> dataList) {
    bool hasChanged = false;
    for (var data in dataList) {
      final String id = data['id'].toString();
      final double lat = (data['gps_lat'] as num?)?.toDouble() ?? 0.0;
      final double lng = (data['gps_lng'] as num?)?.toDouble() ?? 0.0;

      final index = _vehicles.indexWhere((v) => v.id == id);
      if (index != -1) {
        _vehicles[index].position = LatLng(lat, lng);
        hasChanged = true;
      }
    }
    if (hasChanged) Future.microtask(() => notifyListeners());
  }

  void clearAlert() {
    _currentAlert = null;
    notifyListeners();
  }

  // --- UI State & Dummy Data ---

  void selectMenuItem(int index) {
    _selectedMenuIndex = index;
    notifyListeners();
  }

  void selectVehicle(Vehicle vehicle) {
    _selectedVehicle = vehicle;
    notifyListeners();
  }

  final List<DriverHealth> _driversHealth = [
    DriverHealth(
      driverId: 'D-101',
      name: 'Budi',
      imageUrl: 'https://th.bing.com/th/id/OIP.3bw4A-iBUi5Pa3PeIGXRZQHaE8?o=7',
      heartRate: 75,
      temperature: 36.5,
      status: HealthStatus.normal,
      activity: 'Active',
    ),
  ];
  List<DriverHealth> get driversHealth => _driversHealth;

  final AQIData _aqiData = const AQIData(index: 42, pm25: 72, co2: 22, no2: 15);
  AQIData get aqiData => _aqiData;

  final int _onlineDrivers = 28;
  int get onlineDrivers => _onlineDrivers;

  final int _highRiskAlerts = 3;
  int get highRiskAlerts => _highRiskAlerts;

  final List<String> _alertLog = [
    'Driver Agus showing signs of drowsiness',
    'Vehicle V-110 exceeding speed limit',
    'High CO2 levels detected in V-112',
  ];
  List<String> get alertLog => _alertLog;

  @override
  void dispose() {
    _gpsSubscription?.cancel();
    _gpsSocketService.disconnect();
    super.dispose();
  }
}