import 'package:flutter_test/flutter_test.dart';
import 'package:fleet_dashboard/utils/last_seen_format.dart';

void main() {
  test('the real figure from B 7041 UDB reads as months, not minutes', () {
    // /vehicles/status reports last_seen_minutes: 166661 for that vehicle.
    // Printed raw it said "166661 min ago", which nobody reads as "the device
    // stopped reporting in May" — and that is the fact being looked for when
    // a vehicle sits motionless on the map.
    expect(formatLastSeen(166661), '3 months ago');
  });

  test('minutes stay minutes for the first hour', () {
    expect(formatLastSeen(0), 'just now');
    expect(formatLastSeen(1), '1 min ago');
    expect(formatLastSeen(59), '59 min ago');
  });

  test('hours carry their remainder, so 90 minutes is not "1 h"', () {
    expect(formatLastSeen(60), '1 h ago');
    expect(formatLastSeen(90), '1 h 30 min ago');
    expect(formatLastSeen(23 * 60), '23 h ago');
  });

  test('days, then weeks, then months', () {
    expect(formatLastSeen(24 * 60), '1 d ago');
    expect(formatLastSeen(3 * 24 * 60), '3 d ago');
    expect(formatLastSeen(10 * 24 * 60), '1 week ago');
    expect(formatLastSeen(21 * 24 * 60), '3 weeks ago');
    expect(formatLastSeen(45 * 24 * 60), '1 month ago');
  });

  test('a negative figure does not render as a negative age', () {
    // Clock skew between the device and the server can produce one.
    expect(formatLastSeen(-5), 'just now');
  });

  test('very old telemetry says so plainly', () {
    expect(formatLastSeen(400 * 24 * 60), 'over a year ago');
  });
}
