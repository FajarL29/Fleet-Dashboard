import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/bloc/dashboard/dashboard_bloc.dart';
import 'package:fleet_dashboard/bloc/dashboard/dashboard_event.dart';
import 'package:fleet_dashboard/models/vehicle_status.dart';

/// Captured verbatim from ws://203.100.57.59:3300 on 2026-09-10.
const String _liveFrame =
    '{"event":"UPDATE_LOCATION","target":"DASHBOARD","vehicle_id":"1210",'
    '"gps_lat":-6.3584065,"gps_lng":107.2924625,"speed_kmph":0.319,'
    '"satellites":6,"hdop":1.3,"gps_fix":true,"seq":374,'
    '"heading_deg":88.50998334215923,"heading_source":"compass"}';

VehicleStatusItem _row(String id, {double? lat, double? lng}) {
  return VehicleStatusItem(
    vehicleId: id,
    vehicleIdentificationNumber: 'VIN-$id',
    plateNumber: 'B $id XY',
    driverName: 'Driver $id',
    lastTelemetryTime: null,
    lastSeenMinutes: null,
    latitude: lat ?? -6.2,
    longitude: lng ?? 106.8,
    speed: null,
    deviceStatus: 'offline',
    movementStatus: '',
    safetyStatus: 'normal',
    displayStatus: 'offline',
    statusReason: '',
  );
}

VehicleStatusData _status(List<VehicleStatusItem> rows) {
  return VehicleStatusData(
    summary: VehicleStatusSummary(
      totalVehicles: rows.length,
      onlineVehicles: 0,
      moving: 0,
      idle: 0,
      warning: 0,
      offline: rows.length,
      alert: 0,
    ),
    vehicles: rows,
  );
}

void main() {
  late DashboardBloc bloc;

  setUp(() => bloc = DashboardBloc());
  tearDown(() => bloc.close());

  Future<void> send(Map<String, dynamic> frame) async {
    bloc.add(GpsDataReceived(frame));
    await Future<void>.delayed(Duration.zero);
  }

  test('a frame is published as a fix the whole app can read', () async {
    await send(json.decode(_liveFrame));

    final fix = bloc.state.liveFixes['1210'];
    expect(fix, isNotNull);
    expect(fix!.position.latitude, closeTo(-6.3584065, 1e-9));
    expect(fix.position.longitude, closeTo(107.2924625, 1e-9));
    expect(fix.speed, closeTo(0.319, 1e-9));
    // The compass bearing used to be parsed and thrown away, so every marker
    // pointed north no matter which way the vehicle was going.
    expect(fix.heading, closeTo(88.51, 0.01));
  });

  test('the test rig gets its own pin and leaves the fleet alone', () async {
    // Tracker 1210 is the Raspberry Pi rig, not a device fitted to any fleet
    // vehicle. Mapping it onto one would overwrite that vehicle's real
    // position with test coordinates, so it must stay separate.
    bloc.emit(
      bloc.state.copyWith(vehicleStatusData: _status([_row('5'), _row('11')])),
    );

    await send(json.decode(_liveFrame));

    expect(bloc.state.vehicles, hasLength(3), reason: 'rig adds its own pin');

    final rig = bloc.state.vehicles.firstWhere((v) => v.id == '1210');
    expect(rig.position.latitude, closeTo(-6.3584065, 1e-9));

    // The guarantee that actually matters: no real vehicle moved.
    for (final id in ['5', '11']) {
      final vehicle = bloc.state.vehicles.firstWhere((v) => v.id == id);
      expect(vehicle.position.latitude, closeTo(-6.2, 1e-9));
      expect(vehicle.position.longitude, closeTo(106.8, 1e-9));
    }
  });

  test('a frame for a real fleet vehicle moves that vehicle', () async {
    bloc.emit(
      bloc.state.copyWith(vehicleStatusData: _status([_row('11')])),
    );

    final frame = json.decode(_liveFrame) as Map<String, dynamic>
      ..['vehicle_id'] = '11';
    await send(frame);

    expect(bloc.state.vehicles, hasLength(1), reason: 'no extra marker');
    expect(
      bloc.state.vehicles.single.position.latitude,
      closeTo(-6.3584065, 1e-9),
    );
  });

  test('repeated frames move the pin rather than duplicating it', () async {
    bloc.emit(bloc.state.copyWith(vehicleStatusData: _status([_row('5')])));

    await send(json.decode(_liveFrame));
    expect(bloc.state.vehicles, hasLength(2));

    final moved = json.decode(_liveFrame) as Map<String, dynamic>
      ..['gps_lat'] = -6.40
      ..['speed_kmph'] = 42.0;
    await send(moved);

    expect(bloc.state.vehicles, hasLength(2), reason: 'still one rig pin');
    final rig = bloc.state.vehicles.firstWhere((v) => v.id == '1210');
    expect(rig.position.latitude, closeTo(-6.40, 1e-9));
    expect(rig.speed, 42.0);
  });

  test('a status refresh does not throw away the live position', () async {
    // The ten-second poll re-reads /vehicles/status, which still reports the
    // vehicle at its stale coordinates. Rebuilding from those alone would
    // snap the marker back every tick.
    bloc.emit(bloc.state.copyWith(vehicleStatusData: _status([_row('5')])));
    await send(json.decode(_liveFrame));

    bloc.emit(
      bloc.state.copyWith(vehicleStatusData: _status([_row('5')])),
    );
    await send(json.decode(_liveFrame));

    final rig = bloc.state.vehicles.firstWhere((v) => v.id == '1210');
    expect(rig.position.latitude, closeTo(-6.3584065, 1e-9));
  });
}
