import 'package:fleet_dashboard/models/air_quality_reading.dart';
import 'package:fleet_dashboard/models/vehicle.dart';
import 'package:fleet_dashboard/models/vital_sign_reading.dart';
import 'package:fleet_dashboard/widgets/overview/overview_monitoring_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  testWidgets('loads both summaries with the selected internal vehicle ID', (
    tester,
  ) async {
    final vitalIds = <String>[];
    final airIds = <String>[];

    await tester.pumpWidget(
      _app(
        OverviewMonitoringSummary(
          vehicle: _vehicle('internal-42'),
          refreshInterval: const Duration(days: 1),
          loadVitalSign: (id) async {
            vitalIds.add(id);
            return const VitalSignReading(
              heartRate: 72,
              spo2: 98,
              bodyTemperature: 36.6,
            );
          },
          loadAirQuality: (id) async {
            airIds.add(id);
            return const AirQualityReading(aqi: 31, pm25: 8, co2: 425);
          },
        ),
      ),
    );
    await tester.pump();

    expect(vitalIds, ['internal-42']);
    expect(airIds, ['internal-42']);
    expect(find.text('72 bpm'), findsOneWidget);
    expect(find.text('98 %'), findsOneWidget);
    expect(find.text('31'), findsOneWidget);
    expect(find.text('425'), findsOneWidget);
  });

  testWidgets('isolates a Vital Sign failure from Air Quality data', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        OverviewMonitoringSummary(
          vehicle: _vehicle('7'),
          refreshInterval: const Duration(days: 1),
          loadVitalSign: (_) async => throw Exception('offline'),
          loadAirQuality: (_) async =>
              const AirQualityReading(aqi: 44, pm25: 12, co2: 500),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Unable to load Vital Sign data.'), findsOneWidget);
    expect(find.text('44'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
  });

  testWidgets('refreshes immediately when the selected vehicle changes', (
    tester,
  ) async {
    final ids = <String>[];
    final key = GlobalKey<_HarnessState>();

    await tester.pumpWidget(
      _app(
        _Harness(
          key: key,
          loader: (id) async {
            ids.add(id);
            return const VitalSignReading(heartRate: 70);
          },
        ),
      ),
    );
    await tester.pump();
    key.currentState!.select('second');
    await tester.pump();

    expect(ids, ['first', 'second']);
  });
}

Widget _app(Widget child) => MaterialApp(home: Scaffold(body: child));

Vehicle _vehicle(String id) => Vehicle(
  id: id,
  plateNumber: 'B 1 TEST',
  type: 'Truck',
  driverName: 'Driver',
  activityTime: '',
  position: const LatLng(0, 0),
  status: VehicleStatus.active,
);

class _Harness extends StatefulWidget {
  const _Harness({super.key, required this.loader});

  final LatestVitalSignLoader loader;

  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  String id = 'first';

  void select(String value) => setState(() => id = value);

  @override
  Widget build(BuildContext context) {
    return OverviewMonitoringSummary(
      vehicle: _vehicle(id),
      refreshInterval: const Duration(days: 1),
      loadVitalSign: widget.loader,
      loadAirQuality: (_) async => null,
    );
  }
}
