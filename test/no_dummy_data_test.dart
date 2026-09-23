import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/bloc/dashboard/dashboard_state.dart';
import 'package:fleet_dashboard/models/aqi_data.dart';
import 'package:fleet_dashboard/widgets/overview/overview_air_quality_card.dart';
import 'package:fleet_dashboard/widgets/overview/overview_vital_sign_card.dart';
import 'package:fleet_dashboard/widgets/vital_sign/vital_sign_kpi_row.dart';

void main() {
  test('initial state seeds no fake fleet data', () {
    final state = DashboardState.initial();

    expect(state.driversHealth, isEmpty);
    expect(state.vehicles, isEmpty);
    expect(state.alertLog, isEmpty);
    expect(state.onlineDrivers, 0);
    expect(state.highRiskAlerts, 0);
    expect(state.aqiData.co2, 0);
  });

  testWidgets('metric cards show a dash instead of invented numbers when the '
      'server has sent nothing', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              OverviewVitalSignCard(driversHealth: []),
              OverviewAirQualityCard(
                aqiData: AQIData(index: 0, pm25: 0, co2: 0, no2: 0),
                vehicleStatusData: null,
                vehicles: [],
              ),
              VitalSignKpiRow(readings: [], isWide: true),
            ],
          ),
        ),
      ),
    );

    // Overview vital sign (heart rate, SpO2), overview air quality (average
    // CO2, highest CO2) and the vital sign KPIs (heart rate, SpO2).
    expect(find.text('-'), findsNWidgets(6));

    // The trend badges are analysis output; with no history they stay hidden.
    expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
  });
}
