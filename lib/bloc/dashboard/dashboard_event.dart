import 'package:equatable/equatable.dart';
import '../../models/vehicle.dart';

/// Base class for all Dashboard events
abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

/// Event to initialize the dashboard and start GPS connection
class DashboardInitialized extends DashboardEvent {
  const DashboardInitialized();
}

/// Event when a menu item is selected
class MenuItemSelected extends DashboardEvent {
  final int index;

  const MenuItemSelected(this.index);

  @override
  List<Object?> get props => [index];
}

/// Event when a vehicle is selected from the map or list
class VehicleSelected extends DashboardEvent {
  final Vehicle vehicle;

  const VehicleSelected(this.vehicle);

  @override
  List<Object?> get props => [vehicle];
}

/// Event to clear the current alert
class AlertCleared extends DashboardEvent {
  const AlertCleared();
}

/// Event when GPS data is received from the WebSocket
class GpsDataReceived extends DashboardEvent {
  final Map<String, dynamic> data;

  const GpsDataReceived(this.data);

  @override
  List<Object?> get props => [data];
}

/// Event when a stream image (alert) is received
class StreamImageReceived extends DashboardEvent {
  final Map<String, dynamic> data;

  const StreamImageReceived(this.data);

  @override
  List<Object?> get props => [data];
}

/// Event to dispose/cleanup resources
class DashboardDisposed extends DashboardEvent {
  const DashboardDisposed();
}

// Di dashboard_event.dart
class DrowsinessDataRequested extends DashboardEvent {
  final int userId;
  final String token;
  const DrowsinessDataRequested({required this.userId, required this.token});
}

class DrowsinessDataReceived extends DashboardEvent {
  final Map<String, dynamic> data;
  const DrowsinessDataReceived(this.data);
}
