import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fleet_dashboard/models/live_gps_fix.dart';
import 'package:fleet_dashboard/models/vehicle_status.dart';
import 'package:fleet_dashboard/services/live_fix_merge.dart';

VehicleStatusData _statusOf(List<VehicleStatusItem> rows, {int online = 0}) {
  return VehicleStatusData(
    summary: VehicleStatusSummary(
      totalVehicles: rows.length,
      // Deliberately wrong on purpose in these tests: this is the stale
      // snapshot the server sent, which the merge is expected to replace.
      onlineVehicles: online,
      moving: 0,
      idle: 0,
      warning: 0,
      offline: rows.length - online,
      alert: 0,
    ),
    vehicles: rows,
  );
}

VehicleStatusItem _row(String id, {String plate = '', String vin = ''}) {
  return VehicleStatusItem(
    vehicleId: id,
    vehicleIdentificationNumber: vin,
    plateNumber: plate.isEmpty ? 'B $id XY' : plate,
    driverName: 'Driver $id',
    lastTelemetryTime: null,
    lastSeenMinutes: null,
    latitude: null,
    longitude: null,
    speed: null,
    deviceStatus: 'offline',
    movementStatus: '',
    safetyStatus: 'normal',
    displayStatus: 'offline',
    statusReason: '',
  );
}

/// Coordinates and bearing captured from the live rig.
LiveGpsFix _fix(
  String tracker,
  String vehicle, {
  double speed = 0.319,
  Duration age = Duration.zero,
}) {
  return LiveGpsFix(
    trackerId: tracker,
    vehicleId: vehicle,
    position: const LatLng(-6.3584065, 107.2924625),
    speed: speed,
    heading: 88.51,
    receivedAt: DateTime.now().subtract(age),
  );
}

void main() {
  test('a fix moves the vehicle it belongs to and marks it online', () {
    final merged = applyLiveFixes(
      [_row('5'), _row('11')],
      {'11': _fix('1210', '11', speed: 42)},
    );

    final target = merged.firstWhere((r) => r.vehicleId == '11');
    expect(target.latitude, closeTo(-6.3584065, 1e-9));
    expect(target.speed, 42);
    // The status endpoint had it offline; a fix seconds old says otherwise.
    expect(target.deviceStatus, 'online');
    expect(target.displayStatus, 'moving');

    // Everything else is untouched.
    final other = merged.firstWhere((r) => r.vehicleId == '5');
    expect(other.latitude, isNull);
    expect(other.deviceStatus, 'offline');
  });

  test('a slow fix reads as idle, not moving', () {
    final merged = applyLiveFixes([_row('11')], {'11': _fix('1210', '11')});
    expect(merged.single.displayStatus, 'idle');
  });

  test('matches on VIN and on plate, not just id', () {
    final byVin = applyLiveFixes(
      [_row('7', vin: 'VIN-7')],
      {'VIN-7': _fix('VIN-7', 'VIN-7')},
    );
    expect(byVin.single.latitude, closeTo(-6.3584065, 1e-9));

    final byPlate = applyLiveFixes(
      [_row('9', plate: 'TEST-0608-BI')],
      {'TEST-0608-BI': _fix('TEST-0608-BI', 'TEST-0608-BI')},
    );
    expect(byPlate.single.latitude, closeTo(-6.3584065, 1e-9));
  });

  test('a stale fix is kept as a last known position, not as a live one', () {
    // The rig drops off constantly during testing. Dropping the marker with
    // it left nothing on the map at all, which is worse than a point that is
    // visibly labelled as old.
    final merged = applyLiveFixes(
      [_row('11')],
      {'11': _fix('1210', '11', age: const Duration(minutes: 5))},
    );
    final row = merged.single;

    expect(row.latitude, closeTo(-6.3584065, 1e-9));
    expect(row.deviceStatus, 'offline', reason: 'it is not reporting');
    expect(row.displayStatus, 'offline');
    expect(row.speed, 0, reason: 'whatever it was doing, it is not doing now');
    expect(row.lastSeenMinutes, 5);
    expect(isLastKnownPosition(row), isTrue);
    expect(row.statusReason, contains('5 min ago'));
    expect(isVehicleOnline(row), isFalse);
  });

  test('a newer server position outranks an older remembered fix', () {
    // A device off the socket but still posting telemetry: the endpoint knows
    // more than the socket does, so its row must survive the merge intact.
    final reported = DateTime.now().subtract(const Duration(minutes: 2));
    final row = _row('11').copyWith(
      latitude: -6.2,
      longitude: 106.8,
      lastTelemetryTime: reported,
    );

    final merged = applyLiveFixes(
      [row],
      {'11': _fix('1210', '11', age: const Duration(hours: 3))},
    );

    expect(merged.single.latitude, closeTo(-6.2, 1e-9));
    expect(merged.single.lastTelemetryTime, reported);
  });

  test('the live map keeps an unregistered tracker', () {
    // Exactly the rig's situation: transmitting, but not in the registry.
    final merged = applyLiveFixes(
      [_row('5')],
      {'1210': _fix('1210', '1210')},
      includeUnregistered: true,
    );

    expect(merged, hasLength(2));
    final tracker = merged.last;
    expect(tracker.vehicleId, '1210');
    expect(tracker.plateNumber, contains('1210'));
    expect(tracker.latitude, closeTo(-6.3584065, 1e-9));
  });

  test('the registry does not invent a row for an unregistered tracker', () {
    final merged = applyLiveFixes([_row('5')], {'1210': _fix('1210', '1210')});

    expect(merged, hasLength(1), reason: 'the fleet still has one vehicle');
    expect(merged.single.vehicleId, '5');
  });

  test('no fixes leaves the rows exactly as they came back', () {
    final rows = [_row('5'), _row('11')];
    expect(applyLiveFixes(rows, const {}), same(rows));
  });

  group('online counting', () {
    test('moving and idle both count as online', () {
      // How the server actually reports a live vehicle: the connectivity
      // field and the movement field agree.
      for (final movement in ['moving', 'idle']) {
        expect(
          isVehicleOnline(
            _row('1').copyWith(deviceStatus: 'online', displayStatus: movement),
          ),
          isTrue,
          reason: '"$movement" is a state of a device that is reporting',
        );
      }
    });

    test('movement alone is enough when connectivity is not stated', () {
      expect(
        isVehicleOnline(
          _row('1').copyWith(deviceStatus: '', displayStatus: 'moving'),
        ),
        isTrue,
      );
    });

    test('an explicit offline wins over a stale movement value', () {
      // The server blanks movement when a device drops, so this pairing does
      // not occur in practice — but if it ever did, connectivity is the
      // current fact and movement is the leftover.
      expect(
        isVehicleOnline(
          _row('1').copyWith(deviceStatus: 'offline', displayStatus: 'moving'),
        ),
        isFalse,
      );
    });

    test('a device that has gone quiet does not', () {
      expect(
        isVehicleOnline(
          _row('3').copyWith(deviceStatus: 'offline', displayStatus: 'offline'),
        ),
        isFalse,
      );
    });

    test(
      'the summary is recomputed from the rows, not taken from the server',
      () {
        // The server answered "0 online" before the fix arrived. The KPI used to
        // print that verbatim while the map underneath showed a vehicle moving.
        final merged = mergeVehicleStatus(
          _statusOf([_row('5'), _row('11')], online: 0),
          {'11': _fix('1210', '11', speed: 42)},
        );

        expect(merged.summary.onlineVehicles, 1);
        expect(merged.summary.moving, 1);
        expect(merged.summary.offline, 1);
        expect(merged.summary.totalVehicles, 2);
      },
    );

    test('a live tracker on the map is counted on the map', () {
      final merged = mergeVehicleStatus(_statusOf([_row('5')], online: 0), {
        '1210': _fix('1210', '1210', speed: 42),
      }, includeUnregistered: true);

      // Shown as a marker, so counted: the headline number and the map agree.
      expect(merged.summary.totalVehicles, 2);
      expect(merged.summary.onlineVehicles, 1);
      expect(merged.vehicles.last.plateNumber, contains('1210'));
    });

    test('a stale fix leaves the fleet reading offline', () {
      final merged = mergeVehicleStatus(_statusOf([_row('11')], online: 0), {
        '11': _fix('1210', '11', age: const Duration(minutes: 5)),
      });

      expect(merged.summary.onlineVehicles, 0);
      expect(merged.summary.offline, 1);
    });
  });

  group('the test rig as a vehicle', () {
    test('it is listed even when it has never transmitted', () {
      // The rig was invisible until it started sending, so there was nothing
      // to select or watch while waiting for it to come up.
      final merged = applyLiveFixes(
        [_row('5')],
        const {},
        includeUnregistered: true,
      );

      expect(merged, hasLength(2));
      final rig = merged.firstWhere((r) => r.vehicleId == '1210');
      expect(rig.plateNumber, contains('1210'));
      expect(rig.deviceStatus, 'offline');
      expect(rig.statusReason, contains('Waiting'));
    });

    test('a rig that has never reported claims no position', () {
      // Nothing heard and nothing remembered: there is genuinely no point to
      // draw, so it lists without one rather than being pinned anywhere.
      final merged = applyLiveFixes([], const {}, includeUnregistered: true);
      final rig = merged.single;

      expect(rig.latitude, isNull);
      expect(rig.longitude, isNull);
      expect(rig.lastTelemetryTime, isNull);
      expect(isVehicleOnline(rig), isFalse);
    });

    test('a rig that has gone quiet stays on the map where it was', () {
      final merged = applyLiveFixes(
        [],
        {'1210': _fix('1210', '1210', age: const Duration(hours: 2))},
        includeUnregistered: true,
      );
      final rig = merged.single;

      expect(rig.vehicleId, '1210');
      expect(rig.latitude, closeTo(-6.3584065, 1e-9));
      expect(rig.plateNumber, contains('1210'));
      expect(isLastKnownPosition(rig), isTrue);
      expect(rig.statusReason, contains('2 h ago'));
      expect(isVehicleOnline(rig), isFalse);
    });

    test('a remembered rig is listed once, not twice', () {
      // It is both a known tracker and a configured standalone device; only
      // one of those may produce a row.
      final merged = applyLiveFixes(
        [],
        {'1210': _fix('1210', '1210', age: const Duration(days: 1))},
        includeUnregistered: true,
      );

      expect(merged.where((r) => r.vehicleId == '1210'), hasLength(1));
    });

    test('a live fix takes over, without adding a second row', () {
      final merged = applyLiveFixes(
        [_row('5')],
        {'1210': _fix('1210', '1210', speed: 42)},
        includeUnregistered: true,
      );

      final rigs = merged.where((r) => r.vehicleId == '1210').toList();
      expect(rigs, hasLength(1), reason: 'one row, not one per source');
      expect(rigs.single.latitude, closeTo(-6.3584065, 1e-9));
      expect(rigs.single.deviceStatus, 'online');
    });

    test('the registry is still left alone', () {
      // Vehicle Management lists what the fleet owns. A test device is not
      // owned, so it must not appear there.
      final merged = applyLiveFixes([_row('5')], const {});
      expect(merged, hasLength(1));
      expect(merged.single.vehicleId, '5');
    });

    test('a silent rig does not inflate the online count', () {
      final merged = mergeVehicleStatus(
        _statusOf([_row('5')], online: 0),
        const {},
        includeUnregistered: true,
      );

      expect(merged.summary.totalVehicles, 2);
      expect(merged.summary.onlineVehicles, 0);
      expect(merged.summary.offline, 2);
    });
  });
}
