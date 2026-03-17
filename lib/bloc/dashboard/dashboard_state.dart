import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';
import '../../models/vehicle.dart';
import '../../models/driver_health.dart';
import '../../models/aqi_data.dart';

/// Represents the status of the dashboard
enum DashboardStatus {
  initial,
  loading,
  connected,
  disconnected,
  error,
}

/// State class containing all dashboard data
class DashboardState extends Equatable {
  /// Current status of the dashboard
  final DashboardStatus status;

  /// Currently selected menu index
  final int selectedMenuIndex;

  /// Currently selected vehicle
  final Vehicle? selectedVehicle;

  /// Current alert data (if any)
  final Map<String, dynamic>? currentAlert;

  /// List of all vehicles
  final List<Vehicle> vehicles;

  /// List of driver health data
  final List<DriverHealth> driversHealth;

  /// AQI data
  final AQIData aqiData;

  /// Number of online drivers
  final int onlineDrivers;

  /// Number of high risk alerts
  final int highRiskAlerts;

  /// Alert log
  final List<String> alertLog;

  /// Error message (if any)
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.selectedMenuIndex = 0,
    this.selectedVehicle,
    this.currentAlert,
    this.vehicles = const [],
    this.driversHealth = const [],
    this.aqiData = const AQIData(index: 0, pm25: 0, co2: 0, no2: 0),
    this.onlineDrivers = 0,
    this.highRiskAlerts = 0,
    this.alertLog = const [],
    this.errorMessage,
  });

  /// Initial state with default/empty data
  factory DashboardState.initial() {
    return DashboardState(
      status: DashboardStatus.initial,
      vehicles: [
        Vehicle(
          id: '1210',
          plateNumber: 'B 1234 SUF',
          type: 'HIACE Commuter',
          driverName: 'Fajar',
          activityTime: '10.30 a.m. - 13.00 p.m.',
          position: LatLng(-6.2088, 106.8456),
          status: VehicleStatus.active,
        ),
      ],
      driversHealth: [
        DriverHealth(
          driverId: 'D-101',
          name: 'Budi',
          imageUrl: 'https://th.bing.com/th/id/OIP.3bw4A-iBUi5Pa3PeIGXRZQHaE8?o=7',
          heartRate: 75,
          temperature: 36.5,
          status: HealthStatus.normal,
          activity: 'Active',
        ),
      ],
      aqiData: const AQIData(index: 42, pm25: 72, co2: 22, no2: 15),
      onlineDrivers: 28,
      highRiskAlerts: 3,
      alertLog: [
        'Driver Agus showing signs of drowsiness',
        'Vehicle V-110 exceeding speed limit',
        'High CO2 levels detected in V-112',
      ],
    );
  }

  /// Create a copy with updated fields
  DashboardState copyWith({
    DashboardStatus? status,
    int? selectedMenuIndex,
    Vehicle? selectedVehicle,
    bool clearSelectedVehicle = false,
    Map<String, dynamic>? currentAlert,
    bool clearCurrentAlert = false,
    List<Vehicle>? vehicles,
    List<DriverHealth>? driversHealth,
    AQIData? aqiData,
    int? onlineDrivers,
    int? highRiskAlerts,
    List<String>? alertLog,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return DashboardState(
      status: status ?? this.status,
      selectedMenuIndex: selectedMenuIndex ?? this.selectedMenuIndex,
      selectedVehicle:
          clearSelectedVehicle ? null : (selectedVehicle ?? this.selectedVehicle),
      currentAlert:
          clearCurrentAlert ? null : (currentAlert ?? this.currentAlert),
      vehicles: vehicles ?? this.vehicles,
      driversHealth: driversHealth ?? this.driversHealth,
      aqiData: aqiData ?? this.aqiData,
      onlineDrivers: onlineDrivers ?? this.onlineDrivers,
      highRiskAlerts: highRiskAlerts ?? this.highRiskAlerts,
      alertLog: alertLog ?? this.alertLog,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        selectedMenuIndex,
        selectedVehicle,
        currentAlert,
        vehicles,
        driversHealth,
        aqiData,
        onlineDrivers,
        highRiskAlerts,
        alertLog,
        errorMessage,
      ];
}
