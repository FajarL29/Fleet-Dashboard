import 'dart:async';
import 'dart:convert';
import 'package:fleet_dashboard/data/services/gps_socket_service.dart';
import 'package:fleet_dashboard/models/vehicle.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GpsSocketService _socketService;
  StreamSubscription? _gpsSubscription;

  // Data internal (Mirror dari Provider kamu)
  List<Vehicle> _vehicles = [
    Vehicle(
      id: '1210', 
      plateNumber: 'B 1234 SUF',
      type: 'HIACE Commuter',
      driverName: 'Fajar',
      activityTime: '10.30 a.m. - 13.00 p.m.',
      position: const LatLng(-6.140847, 106.889218),
      status: VehicleStatus.warning,
    ),
    Vehicle(
      id: '1211', 
      plateNumber: 'B 1256 SUF',
      type: 'HIACE Commuter',
      driverName: 'Firman',
      activityTime: '10.30 a.m. - 13.00 p.m.',
      position: const LatLng(-6.358706, 107.296430),
      status: VehicleStatus.active,
    ),
    Vehicle(
      id: '1212', 
      plateNumber: 'B 1256 SUF',
      type: 'HIACE Commuter',
      driverName: 'Firman',
      activityTime: '10.30 a.m. - 13.00 p.m.',
      position: const LatLng(-6.284569, 107.078738),
      status: VehicleStatus.error,
    ),
  ];
  List<String> _alertLog = [
    "Alert: Sudden Braking - 1210",
    "Alert: Sharp Turn - 1211",
    "Alert: High Speed - 1212",

  ];

  DashboardBloc(this._socketService) : super(DashboardInitial()) {
    on<StartGpsTracking>(_onStartTracking);
    on<OnWsDataReceived>(_onDataReceived);
    on<ChangeMenuIndex>(_onChangeMenu);
    on<ClearAlert>(_onClearAlert);
  }

  Future<void> _onStartTracking(StartGpsTracking event, Emitter<DashboardState> emit) async {
    emit(DashboardLoading());
    
    _gpsSubscription?.cancel();
    _gpsSubscription = _socketService
        .connect(vehicleId: event.vehicleId, deviceType: 'DASHBOARD')
        .listen(
          (msg) => add(OnWsDataReceived(msg)),
          onError: (err) => emit(DashboardError("Connection Error: $err")),
        );
  }

  void _onDataReceived(OnWsDataReceived event, Emitter<DashboardState> emit) {
    try {
      final data = event.message is String ? json.decode(event.message) : event.message;

      // 1. Logika Alert
      if (data['event'] == 'STREAM_IMAGE') {
        final newAlert = {
          'vehicle_id': data['vehicle_id'],
          'image': data['data']['image'],
          'type': data['data']['behavior_type'],
          'time': DateTime.now(),
        };
        _alertLog.insert(0, "Alert: ${data['data']['behavior_type']} - ${data['vehicle_id']}");
        
        if (state is DashboardLoaded) {
          emit((state as DashboardLoaded).copyWith(
            currentAlert: newAlert,
            alertLog: List.from(_alertLog),
          ));
        }
        return;
      }

      // 2. Logika GPS
      if (data.containsKey('gps_lat') && data.containsKey('gps_lng')) {
        _updateLocalVehicleList(data);
      }

      // Emit state baru dengan data kendaraan terupdate
      emit(DashboardLoaded(
        vehicles: List.from(_vehicles),
        alertLog: List.from(_alertLog),
        selectedMenuIndex: (state is DashboardLoaded) ? (state as DashboardLoaded).selectedMenuIndex : 0, drivers: [],
      ));

    } catch (e) {
      print("Error parsing: $e");
    }
  }

  void _updateLocalVehicleList(Map<String, dynamic> data) {
    final String vId = data['vehicle_id']?.toString() ?? '1210';
    final index = _vehicles.indexWhere((v) => v.id == vId);
    if (index != -1) {
      _vehicles[index].position = LatLng(
        (data['gps_lat'] as num).toDouble(),
        (data['gps_lng'] as num).toDouble(),
      );
    }
  }

  void _onChangeMenu(ChangeMenuIndex event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      emit((state as DashboardLoaded).copyWith(selectedMenuIndex: event.index));
    }
  }

  void _onClearAlert(ClearAlert event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      emit((state as DashboardLoaded).copyWith(currentAlert: null));
    }
  }

  @override
  Future<void> close() {
    _gpsSubscription?.cancel();
    return super.close();
  }
}