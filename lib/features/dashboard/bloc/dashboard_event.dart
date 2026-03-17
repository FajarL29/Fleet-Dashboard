abstract class DashboardEvent {}

class StartGpsTracking extends DashboardEvent {
  final String vehicleId;
  StartGpsTracking(this.vehicleId);
}

class OnWsDataReceived extends DashboardEvent {
  final dynamic message;
  OnWsDataReceived(this.message);
}

class ChangeMenuIndex extends DashboardEvent {
  final int index;
  ChangeMenuIndex(this.index);
}

class ClearAlert extends DashboardEvent {}