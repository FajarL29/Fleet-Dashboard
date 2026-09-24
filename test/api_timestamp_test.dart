import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/models/drowsiness_report.dart';
import 'package:fleet_dashboard/models/vehicle_status.dart';
import 'package:fleet_dashboard/utils/api_timestamp.dart';
import 'package:fleet_dashboard/widgets/air_quality/air_quality_reading.dart';

void main() {
  test('a Z the API never converted is read as the recorded wall clock', () {
    // Proven twice in docs/api: the epoch in a drowsiness img_path sits seven
    // hours before its own event_time, and an air-monitor row reads
    // created_time 13:41:40 beside timestamp 13:40:00Z.
    final parsed = parseApiTimestamp('2026-09-23T19:17:14.000Z');

    expect(parsed, DateTime(2026, 9, 23, 19, 17, 14));
    expect(parsed!.isUtc, isFalse);
  });

  test('an evening reading stays on its own day', () {
    // The failure people actually saw: +7 pushed anything after 17:00 past
    // midnight, so the date column was wrong as well as the time.
    expect(
      parseApiTimestamp('2026-05-15T18:30:00.000Z'),
      DateTime(2026, 5, 15, 18, 30),
    );
  });

  test('values without a marker are left exactly as they are', () {
    expect(
      parseApiTimestamp('2026-05-15 16:36:29'),
      DateTime(2026, 5, 15, 16, 36, 29),
    );
    // event_date and peak_date arrive date-only.
    expect(parseApiTimestamp('2026-05-15'), DateTime(2026, 5, 15));
  });

  test('a DateTime is passed straight through', () {
    final already = DateTime(2026, 5, 15, 8);
    expect(parseApiTimestamp(already), same(already));
  });

  test('nothing usable gives null rather than a wrong time', () {
    for (final value in [null, '', '   ', 'not a date', 42]) {
      expect(parseApiTimestamp(value), isNull, reason: 'for $value');
    }
  });

  test('every model reads one timestamp the same way', () {
    // The point of the shared parser. These three used to keep their own
    // copies, and last_telemetry_time rendered as the recorded hour on one
    // card and seven hours later in the map tooltip.
    const raw = '2026-08-18T13:40:00.000Z';
    const expected = '2026-08-18 13:40:00.000';

    final vehicle = VehicleStatusItem.fromJson(const {
      'vehicle_id': 11,
      'last_telemetry_time': raw,
    });
    final event = DrowsinessEvent.fromJson(const {
      'drowsiness_id': 1,
      'event_time': raw,
    });
    final reading = airQualityReadingFromJson(const {'timestamp': raw});

    expect(vehicle.lastTelemetryTime.toString(), expected);
    expect(event.time.toString(), expected);
    expect(reading.recordedAt.toString(), expected);

    // And none of them is left flagged UTC, which is what made .toLocal() at
    // the display site shift one page and not another.
    expect(vehicle.lastTelemetryTime!.isUtc, isFalse);
    expect(event.time.isUtc, isFalse);
    expect(reading.recordedAt.isUtc, isFalse);
  });
}
