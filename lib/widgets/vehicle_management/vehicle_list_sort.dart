import '../../models/vehicle_management.dart';
import '../common/sortable_header.dart';

/// Columns of the vehicle list, in display order.
///
/// Only Status sorts: it is the one column with an order worth asking for.
/// Plate, VIN and Last Seen are looked up, not ranked.
enum VehicleListColumn {
  vehicle('Vehicle'),
  status('Status', sortable: true, firstDirection: SortDirection.descending),
  vin('VIN'),
  lastSeen('Last Seen');

  const VehicleListColumn(
    this.label, {
    this.sortable = false,
    this.firstDirection = SortDirection.ascending,
  });

  final String label;
  final bool sortable;

  /// Status starts descending so the vehicles that need attention surface
  /// first.
  final SortDirection firstDirection;
}

/// Orders status by how much it should worry someone, not alphabetically.
int _statusRank(ManagedVehicle vehicle) {
  switch (vehicle.mergedStatusLabel.trim().toLowerCase()) {
    case 'alert':
      return 5;
    case 'warning':
      return 4;
    case 'moving':
      return 3;
    case 'idle':
      return 2;
    case 'offline':
      return 1;
    default:
      return 0;
  }
}

/// Returns [vehicles] ordered by [sort], leaving the caller's list untouched.
List<ManagedVehicle> sortManagedVehicles(
  List<ManagedVehicle> vehicles,
  ColumnSort<VehicleListColumn> sort,
) {
  final sorted = List<ManagedVehicle>.from(vehicles);

  int compare(ManagedVehicle a, ManagedVehicle b) {
    switch (sort.column) {
      case VehicleListColumn.status:
        return _statusRank(a).compareTo(_statusRank(b));
      // Not sortable: the header does not offer them. Plate order is a sane
      // fallback rather than throwing if that ever changes.
      case VehicleListColumn.vehicle:
      case VehicleListColumn.vin:
      case VehicleListColumn.lastSeen:
        return _text(a.plateNumber, b.plateNumber);
    }
  }

  sorted.sort((a, b) {
    final result = sort.order(compare(a, b));
    return result != 0 ? result : _text(a.plateNumber, b.plateNumber);
  });

  return sorted;
}

int _text(String a, String b) => a.toLowerCase().compareTo(b.toLowerCase());
