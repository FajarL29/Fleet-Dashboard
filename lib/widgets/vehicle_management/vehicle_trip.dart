/// One stop along a trip, as shown in the Trip Detail timeline.
///
/// Shape is deliberately minimal: the backend's `/vehicles/trips` payload is
/// not wired yet, so the mapping lives in one place and only this file needs
/// to change once the real response is known.
class VehicleTripStop {
  const VehicleTripStop({
    required this.time,
    required this.name,
    required this.address,
  });

  final DateTime time;
  final String name;
  final String address;
}

/// A single trip for one vehicle.
class VehicleTrip {
  const VehicleTrip({
    required this.tripId,
    required this.stops,
    this.distanceKm,
    this.duration,
  });

  final String tripId;

  /// Ordered stops, earliest first.
  final List<VehicleTripStop> stops;
  final double? distanceKm;
  final Duration? duration;
}
