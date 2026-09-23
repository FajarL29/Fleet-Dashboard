import 'package:latlong2/latlong.dart';

/// One position report straight off the GPS websocket.
///
/// The socket is opened once, by `DashboardBloc`. Every page that wants live
/// positions reads these rather than opening a socket of its own — a second
/// subscription would double the server's fan-out and, worse, let two pages
/// disagree about where a vehicle is.
class LiveGpsFix {
  const LiveGpsFix({
    required this.trackerId,
    required this.vehicleId,
    required this.position,
    required this.speed,
    required this.receivedAt,
    this.heading,
  });

  /// The id the device announces itself by.
  final String trackerId;

  /// The fleet vehicle this fix belongs to, after `kTrackerToVehicleId`.
  /// Equal to [trackerId] when the device is not mapped to one.
  final String vehicleId;

  final LatLng position;

  /// km/h.
  final double speed;

  /// Compass bearing in degrees, when the device carries a compass.
  final double? heading;

  final DateTime receivedAt;

  /// Whether this device is mapped onto a vehicle in the fleet registry.
  ///
  /// An unmapped device is a tracker in its own right — the test rig, say —
  /// and pages decide for themselves whether that belongs in their view.
  bool get isMappedToFleetVehicle => trackerId != vehicleId;

  /// How stale this fix is. Live maps grey out a vehicle that has gone quiet
  /// rather than leaving it pinned where it was last seen.
  Duration age({DateTime? now}) =>
      (now ?? DateTime.now()).difference(receivedAt);

  /// Serialised for [LastKnownFixStore], so a device that has gone quiet is
  /// still on the map after a restart rather than starting again from nothing.
  Map<String, dynamic> toJson() => {
    'tracker_id': trackerId,
    'vehicle_id': vehicleId,
    'lat': position.latitude,
    'lng': position.longitude,
    'speed': speed,
    'heading': heading,
    'received_at': receivedAt.toIso8601String(),
  };

  /// Reads back [toJson], returning null for anything malformed.
  ///
  /// A remembered position is a convenience, never something worth failing
  /// startup over — a half-written file just means the marker waits for the
  /// next live fix.
  static LiveGpsFix? tryFromJson(Object? json) {
    if (json is! Map) return null;
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    final trackerId = json['tracker_id']?.toString();
    final receivedAt = DateTime.tryParse('${json['received_at']}');
    if (lat == null || lng == null || trackerId == null || receivedAt == null) {
      return null;
    }
    return LiveGpsFix(
      trackerId: trackerId,
      vehicleId: json['vehicle_id']?.toString() ?? trackerId,
      position: LatLng(lat, lng),
      speed: (json['speed'] as num?)?.toDouble() ?? 0,
      heading: (json['heading'] as num?)?.toDouble(),
      receivedAt: receivedAt,
    );
  }

  LiveGpsFix copyWith({
    LatLng? position,
    double? speed,
    double? heading,
    DateTime? receivedAt,
  }) {
    return LiveGpsFix(
      trackerId: trackerId,
      vehicleId: vehicleId,
      position: position ?? this.position,
      speed: speed ?? this.speed,
      heading: heading ?? this.heading,
      receivedAt: receivedAt ?? this.receivedAt,
    );
  }

  @override
  String toString() =>
      'LiveGpsFix($trackerId→$vehicleId, ${position.latitude},'
      '${position.longitude}, ${speed}km/h)';
}
