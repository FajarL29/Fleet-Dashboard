import 'package:equatable/equatable.dart';
import 'package:fleet_dashboard/models/aqi_data.dart';
import 'package:fleet_dashboard/models/driver_health.dart';
import 'package:fleet_dashboard/models/vehicle.dart';

abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final List<Vehicle> vehicles;
  final Map<String, dynamic>? currentAlert;
  final List<String> alertLog;
  final int selectedMenuIndex;
  final int onlineDrivers;
  final int highRiskAlerts;
  final List<DriverHealth> drivers;
  final AQIData aqiData;

  DashboardLoaded({
    required this.vehicles,
    required this.drivers,
    this.currentAlert,
    required this.alertLog,
    this.selectedMenuIndex = 0,
    this.onlineDrivers = 28,
    this.highRiskAlerts = 3,
    this.aqiData = const AQIData(
      index: 75,
      pm25: 25.0,
      co2: 400.0,
      o2: 20.9,
    ),
  });

  // Helper untuk update state tanpa nulis ulang semua field
  DashboardLoaded copyWith({
    List<Vehicle>? vehicles,
    Map<String, dynamic>? currentAlert,
    List<String>? alertLog,
    int? selectedMenuIndex,
  }) {
    return DashboardLoaded(
      vehicles: vehicles ?? this.vehicles,
      currentAlert: currentAlert, // Kita biarkan bisa null untuk clear alert
      alertLog: alertLog ?? this.alertLog,
      selectedMenuIndex: selectedMenuIndex ?? this.selectedMenuIndex, drivers: this.drivers,
    );
  }

  @override
  List<Object?> get props => [vehicles, currentAlert, alertLog, selectedMenuIndex];
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);

  @override
  List<Object?> get props => [message];
}