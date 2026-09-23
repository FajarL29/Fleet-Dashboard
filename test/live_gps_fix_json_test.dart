import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fleet_dashboard/models/live_gps_fix.dart';

void main() {
  final fix = LiveGpsFix(
    trackerId: '1210',
    vehicleId: '11',
    position: const LatLng(-6.3584065, 107.2924625),
    speed: 12.5,
    heading: 88.51,
    receivedAt: DateTime.parse('2026-09-15T08:30:00.000'),
  );

  test('a fix survives a trip through the store file', () {
    final restored = LiveGpsFix.tryFromJson(
      jsonDecode(jsonEncode(fix.toJson())),
    )!;

    expect(restored.trackerId, '1210');
    expect(restored.vehicleId, '11');
    expect(restored.position.latitude, closeTo(-6.3584065, 1e-9));
    expect(restored.position.longitude, closeTo(107.2924625, 1e-9));
    expect(restored.speed, 12.5);
    expect(restored.heading, closeTo(88.51, 1e-9));
    expect(restored.receivedAt, fix.receivedAt);
  });

  test('the timestamp is kept, so age is measured from the real moment', () {
    // The whole point of remembering a position is being able to say how old
    // it is; a fix restored as "now" would claim to be live.
    final restored = LiveGpsFix.tryFromJson(fix.toJson())!;
    final age = restored.age(now: DateTime.parse('2026-09-15T10:30:00.000'));

    expect(age, const Duration(hours: 2));
  });

  test('a malformed entry is dropped rather than throwing', () {
    expect(LiveGpsFix.tryFromJson(null), isNull);
    expect(LiveGpsFix.tryFromJson('nonsense'), isNull);
    expect(LiveGpsFix.tryFromJson(const <String, dynamic>{}), isNull);
    expect(
      LiveGpsFix.tryFromJson({'tracker_id': '1210', 'lat': -6.3}),
      isNull,
      reason: 'a fix with no longitude cannot be drawn anywhere',
    );
    expect(
      LiveGpsFix.tryFromJson({
        'tracker_id': '1210',
        'lat': -6.3,
        'lng': 107.2,
        'received_at': 'not a date',
      }),
      isNull,
      reason: 'without a timestamp its age is unknowable',
    );
  });

  test('a fix with no vehicle mapping falls back to its own id', () {
    final restored = LiveGpsFix.tryFromJson({
      'tracker_id': '1210',
      'lat': -6.3,
      'lng': 107.2,
      'received_at': '2026-09-15T08:30:00.000',
    })!;

    expect(restored.vehicleId, '1210');
    expect(restored.isMappedToFleetVehicle, isFalse);
  });
}
