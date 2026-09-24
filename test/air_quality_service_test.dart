import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fleet_dashboard/services/air_quality_service.dart';
import 'package:fleet_dashboard/widgets/air_quality/air_quality_level.dart';

/// Verbatim body from /air-monitor/get-air-by-date?date=2026-08-18.
const _realBody = '''
{"status":"success","stat_code":200,"data":[{"air_condition_id":4003882,
"vehicle_id":11,"created_time":"13:41:40","created_dt":"2026-08-18T00:00:00.000Z",
"co":2.0999999046325684,"co2":620,"o2":20.799999237060547,
"temperature":26.399999618530273,"humidity":61,"pm_25":null,"pm_10":null,
"aqi":55,"user_id":null,"device_id":"AQ-01","timestamp":"2026-08-18T13:40:00.000Z",
"pm25":18,"pm10":31}]}
''';

void main() {
  test('parses a real reading, including ints sent for double sensors', () async {
    late Uri requested;
    final service = AirQualityService(
      client: MockClient((request) async {
        requested = request.url;
        return http.Response(_realBody, 200);
      }),
    );

    final readings = await service.getAirByDate(DateTime(2026, 8, 18));

    // Date is zero-padded into the query the API expects.
    expect(requested.queryParameters['date'], '2026-08-18');

    expect(readings, hasLength(1));
    final reading = readings.single;
    expect(reading.vehicleId, '11');
    expect(reading.aqi, 55);
    // co2 and humidity arrive as ints but the model holds doubles.
    expect(reading.co2Ppm, 620);
    expect(reading.humidityPercent, 61);
    expect(reading.coPpm, closeTo(2.1, 0.001));
    expect(reading.o2Percent, closeTo(20.8, 0.001));
    expect(reading.temperatureCelsius, closeTo(26.4, 0.001));

    // AQI 55 sits in the Moderate band.
    expect(reading.level, AirQualityLevel.moderate);

    // `timestamp` is stamped `Z` but never converted — the same row's
    // `created_time` reads 13:41:40, so 13:40 is already local. Honouring the
    // `Z` added UTC+7 and slid evening samples into the next day's bucket.
    expect(reading.recordedAt, DateTime(2026, 8, 18, 13, 40));
    expect(reading.recordedAt.isUtc, isFalse);

    // The payload has no coordinates, so the map has nothing to plot.
    expect(reading.position, isNull);
  });

  test('a day with no readings is empty, not an error', () async {
    final service = AirQualityService(
      client: MockClient(
        (_) async => http.Response(
          json.encode({'status': 'success', 'stat_code': 200, 'data': []}),
          200,
        ),
      ),
    );

    expect(await service.getAirByDate(DateTime(2026, 9, 8)), isEmpty);
  });

  test('a failing day throws so the caller can skip just that day', () async {
    final service = AirQualityService(
      client: MockClient((_) async => http.Response('nope', 500)),
    );

    expect(
      () => service.getAirByDate(DateTime(2026, 8, 18)),
      throwsA(isA<Exception>()),
    );
  });
}
