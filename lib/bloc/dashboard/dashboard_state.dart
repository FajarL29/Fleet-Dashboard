import 'package:equatable/equatable.dart';
import '../../models/driver_behavior_summary.dart';
import '../../models/drowsiness_report.dart';
import '../../models/vehicle.dart';
import '../../models/vehicle_status.dart';

/// Represents the status of the dashboard
enum DashboardStatus { initial, loading, connected, disconnected, error }

/// State class containing all dashboard data
class DashboardState extends Equatable {
  final Map<int, Map<String, dynamic>>
  driverAlerts; // Menyimpan data drowsiness per driver ID
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

  /// Number of online drivers
  final int onlineDrivers;

  /// Number of high risk alerts
  final int highRiskAlerts;

  /// Alert log
  final List<String> alertLog;

  /// Recent drowsiness events from the API
  final List<DrowsinessEvent> recentDrowsinessEvents;

  /// Aggregate drowsiness report from the API
  final DrowsinessReport? currentDrowsinessReport;

  /// Aggregate driver behavior summaries from the API
  final List<DriverBehaviorSummary> driverBehaviorSummaries;
  final bool isOverviewLoading;
  final VehicleStatusData? vehicleStatusData;
  final String? vehicleStatusError;

  /// Error message (if any)
  final String? errorMessage;

  const DashboardState({
    this.status = DashboardStatus.initial,
    this.selectedMenuIndex = 0,
    this.selectedVehicle,
    this.currentAlert,
    this.vehicles = const [],
    this.onlineDrivers = 0,
    this.highRiskAlerts = 0,
    this.alertLog = const [],
    this.recentDrowsinessEvents = const [],
    this.currentDrowsinessReport,
    this.driverBehaviorSummaries = const [],
    this.isOverviewLoading = false,
    this.vehicleStatusData,
    this.vehicleStatusError,
    this.errorMessage,
    this.driverAlerts = const {},
  });

  /// Initial state with default/empty data
  factory DashboardState.initial() {
    return DashboardState(
      status: DashboardStatus.initial,
      vehicles: const [],
      onlineDrivers: 28,
      highRiskAlerts: 3,
      alertLog: [
        'Driver Agus showing signs of drowsiness',
        'Vehicle V-110 exceeding speed limit',
        'High CO2 levels detected in V-112',
      ],
      recentDrowsinessEvents: const [],
      currentDrowsinessReport: null,
      driverBehaviorSummaries: const [],
      isOverviewLoading: false,
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
    int? onlineDrivers,
    int? highRiskAlerts,
    List<String>? alertLog,
    List<DrowsinessEvent>? recentDrowsinessEvents,
    DrowsinessReport? currentDrowsinessReport,
    bool clearCurrentDrowsinessReport = false,
    List<DriverBehaviorSummary>? driverBehaviorSummaries,
    bool? isOverviewLoading,
    VehicleStatusData? vehicleStatusData,
    bool clearVehicleStatusData = false,
    String? vehicleStatusError,
    bool clearVehicleStatusError = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    Map<int, Map<String, dynamic>>?
    driverAlerts, // Perbaikan: Pakai ? dan hapus required
  }) {
    return DashboardState(
      status: status ?? this.status,
      selectedMenuIndex: selectedMenuIndex ?? this.selectedMenuIndex,
      selectedVehicle: clearSelectedVehicle
          ? null
          : (selectedVehicle ?? this.selectedVehicle),
      currentAlert: clearCurrentAlert
          ? null
          : (currentAlert ?? this.currentAlert),
      vehicles: vehicles ?? this.vehicles,
      onlineDrivers: onlineDrivers ?? this.onlineDrivers,
      highRiskAlerts: highRiskAlerts ?? this.highRiskAlerts,
      alertLog: alertLog ?? this.alertLog,
      recentDrowsinessEvents:
          recentDrowsinessEvents ?? this.recentDrowsinessEvents,
      currentDrowsinessReport: clearCurrentDrowsinessReport
          ? null
          : (currentDrowsinessReport ?? this.currentDrowsinessReport),
      driverBehaviorSummaries:
          driverBehaviorSummaries ?? this.driverBehaviorSummaries,
      isOverviewLoading: isOverviewLoading ?? this.isOverviewLoading,
      vehicleStatusData: clearVehicleStatusData
          ? null
          : (vehicleStatusData ?? this.vehicleStatusData),
      vehicleStatusError: clearVehicleStatusError
          ? null
          : (vehicleStatusError ?? this.vehicleStatusError),
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      driverAlerts:
          driverAlerts ?? this.driverAlerts, // Perbaikan: Tambahkan ini
    );
  }

  @override
  List<Object?> get props => [
    status,
    selectedMenuIndex,
    selectedVehicle,
    currentAlert,
    vehicles,
    onlineDrivers,
    highRiskAlerts,
    alertLog,
    recentDrowsinessEvents,
    currentDrowsinessReport,
    driverBehaviorSummaries,
    isOverviewLoading,
    vehicleStatusData,
    vehicleStatusError,
    errorMessage,
    driverAlerts, // Perbaikan: Masukkan ke props agar UI sinkron
  ];
}
