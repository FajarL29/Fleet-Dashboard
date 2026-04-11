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

  final Map<int, Map<String, dynamic>> driverAlerts; // Menyimpan data drowsiness per driver ID
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
    this.driverAlerts = const {},
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
          driverName: 'Budi',
          activityTime: '10.30 a.m. - 13.00 p.m.',
          position: LatLng(-6.140869, 106.889175),
          status: VehicleStatus.active,
        ),

        Vehicle(
        id: '999', 
        plateNumber: 'B 9999 XYZ',
        type: 'HIACE Luxury',
        driverName: 'Bahrudin',
        position: LatLng(-6.35, 107.29), // Posisi awal bebas
        status: VehicleStatus.active, activityTime: '11.00 ',
      ),
      Vehicle(
        id: '1234', 
        plateNumber: 'B 1111 UOB',
        type: 'Innova Ribon',
        driverName: 'Gito',
        position: LatLng(-6.265246, 106.883481), // Posisi awal bebas -6.265246, 106.883481
        status: VehicleStatus.active, activityTime: '11.00 ',
      ),
      ],
      driversHealth: [
        DriverHealth(
          driverId: '3034',
          name: 'Budi',
          imageUrl: 'https://th.bing.com/th/id/OIP.3bw4A-iBUi5Pa3PeIGXRZQHaE8?o=7',
          heartRate: 75,
          temperature: 36.5,
          status: HealthStatus.normal,
          activity: 'Active',
        ),
        DriverHealth(
          driverId: '999',
          name: 'Bahrudin',
          imageUrl: 'https://static.vecteezy.com/system/resources/previews/004/975/153/large_2x/driver-color-icon-transportation-service-isolated-illustration-vector.jpg',
          heartRate: 75,
          temperature: 36.5,
          status: HealthStatus.normal,
          activity: 'Active',
        ),
        DriverHealth(
          driverId: '1234',
          name: 'Gito',
          imageUrl: 'https://static.vecteezy.com/system/resources/previews/004/975/153/large_2x/driver-color-icon-transportation-service-isolated-illustration-vector.jpg',
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
    Map<int, Map<String, dynamic>>? driverAlerts, // Perbaikan: Pakai ? dan hapus required
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
      driverAlerts: driverAlerts ?? this.driverAlerts, // Perbaikan: Tambahkan ini
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
        driverAlerts, // Perbaikan: Masukkan ke props agar UI sinkron
      ];
}
