import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/widgets/air_quality/air_quality_reading.dart';
import 'package:fleet_dashboard/widgets/air_quality/air_quality_trend_card.dart';

const _empty = 'nothing to plot';

AirQualityReading _reading(DateTime at, {int? aqi = 55}) {
  return AirQualityReading(recordedAt: at, aqi: aqi);
}

Future<LineChartData?> _pumpTrend(
  WidgetTester tester,
  List<AirQualityReading> readings,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AirQualityTrendCard(
          readings: readings,
          emptyMessage: _empty,
          rangeLabel: '1 Aug - 31 Aug',
        ),
      ),
    ),
  );

  final charts = find.byType(LineChart);
  if (charts.evaluate().isEmpty) return null;
  return tester.widget<LineChart>(charts).data;
}

void main() {
  testWidgets('a single day is drawn, not left blank', (tester) async {
    // The air-monitor has produced one reading in months. With dots off and no
    // neighbour to draw a line to, the card rendered empty axes and the day
    // looked like missing data.
    final data = await _pumpTrend(tester, [
      _reading(DateTime(2026, 8, 18, 13, 40)),
    ]);

    expect(data, isNotNull, reason: 'the chart should render, not the message');
    expect(find.text(_empty), findsNothing);

    final bar = data!.lineBarsData.single;
    expect(bar.spots, hasLength(1));
    expect(bar.dotData.show, isTrue, reason: 'the lone point is all there is');

    // Centred, so the dot is not clipped against the left axis.
    expect(data.minX, lessThan(bar.spots.single.x));
    expect(data.maxX, greaterThan(bar.spots.single.x));
  });

  testWidgets('several days keep the plain line', (tester) async {
    final data = await _pumpTrend(tester, [
      for (var day = 1; day <= 4; day++) _reading(DateTime(2026, 8, day, 9)),
    ]);

    final bar = data!.lineBarsData.single;
    expect(bar.spots, hasLength(4));
    expect(bar.dotData.show, isFalse, reason: 'the line carries the shape');
    expect(data.minX, 0);
    expect(data.maxX, 3);
  });

  testWidgets('readings without an AQI fall back to the message', (
    tester,
  ) async {
    // Every other sensor can report while the AQI column stays null, and the
    // chart plots AQI alone.
    final data = await _pumpTrend(tester, [
      _reading(DateTime(2026, 8, 18, 13, 40), aqi: null),
    ]);

    expect(data, isNull);
    expect(find.text(_empty), findsOneWidget);
  });

  testWidgets('samples taken on the same day average into one point', (
    tester,
  ) async {
    final data = await _pumpTrend(tester, [
      _reading(DateTime(2026, 8, 18, 9), aqi: 40),
      _reading(DateTime(2026, 8, 18, 17), aqi: 60),
    ]);

    final spots = data!.lineBarsData.single.spots;
    expect(spots, hasLength(1));
    expect(spots.single.y, 50);
  });
}
