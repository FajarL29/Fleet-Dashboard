import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/models/drowsiness_report.dart';
import 'package:fleet_dashboard/widgets/reports/reports_heatmap.dart';
import 'package:fleet_dashboard/widgets/reports/reports_heatmap_card.dart';

DrowsinessEvent _event(DateTime at) => DrowsinessEvent(
  id: at.millisecondsSinceEpoch,
  vehicleId: 'VIN',
  userId: 1,
  time: at,
  status: 'detected',
  riskLevel: 'high',
);

void main() {
  test('buckets events by weekday and hour', () {
    // 2026-09-08 is a Tuesday.
    final data = buildReportsHeatmap([
      _event(DateTime(2026, 9, 8, 12, 5)),
      _event(DateTime(2026, 9, 8, 12, 40)),
      _event(DateTime(2026, 9, 8, 13, 10)),
      _event(DateTime(2026, 9, 9, 12, 0)),
    ]);

    expect(data.countAt(DateTime.tuesday, 12), 2);
    expect(data.countAt(DateTime.tuesday, 13), 1);
    expect(data.countAt(DateTime.wednesday, 12), 1);
    expect(data.busiest, 2);

    // Empty hours never become columns.
    expect(data.hours, [12, 13]);
  });

  test('always shows the working week, and weekends only when used', () {
    final weekdayOnly = buildReportsHeatmap([
      _event(DateTime(2026, 9, 8, 9)),
    ]);
    expect(weekdayOnly.weekdays, [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
    ]);

    // A Sunday event must not be silently dropped just because the design
    // sketch only showed Mon-Fri.
    final withWeekend = buildReportsHeatmap([
      _event(DateTime(2026, 9, 8, 9)),
      _event(DateTime(2026, 9, 13, 23)),
    ]);
    expect(withWeekend.weekdays.contains(DateTime.sunday), isTrue);
    expect(withWeekend.countAt(DateTime.sunday, 23), 1);
  });

  test('no events yields an empty grid rather than a blank one', () {
    expect(buildReportsHeatmap(const []).isEmpty, isTrue);
  });

  testWidgets('grid renders a cell per weekday/hour without overflowing', (
    tester,
  ) async {
    final data = buildReportsHeatmap([
      for (var day = 7; day <= 11; day++)
        for (var hour = 7; hour <= 18; hour++)
          for (var i = 0; i < (day + hour) % 5; i++)
            _event(DateTime(2026, 9, day, hour)),
    ]);

    for (final height in [140.0, 220.0, 320.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 720,
                height: height,
                child: ReportsHeatmapCard(
                  data: data,
                  emptyMessage: 'none',
                  fill: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'overflowed at height=$height',
      );
    }

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Fri'), findsOneWidget);
    expect(find.text('07'), findsOneWidget);
    expect(find.text('18'), findsOneWidget);
  });
}
