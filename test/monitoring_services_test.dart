import 'package:fleet_dashboard/models/air_quality_reading.dart';
import 'package:fleet_dashboard/models/vital_sign_reading.dart';
import 'package:fleet_dashboard/services/air_quality_service.dart';
import 'package:fleet_dashboard/services/vital_sign_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('monitoring models', () {
    test('Vital Sign parsing preserves nullable measurements', () {
      final reading = VitalSignReading.fromJson(<String, dynamic>{
        'health_report_id': 12,
        'user_id': '34',
        'vehicle_id': 'vehicle-7',
        'device_id': 'health-2',
        'time': '2026-08-14T10:00:00Z',
        'heart_rate': '72.5',
        'spo2': null,
        'body_temperature': 36.7,
        'systolic_bp': 120,
        'diastolic_bp': 80,
        'respiratory_rate': 17,
      });

      expect(reading.healthReportId, 12);
      expect(reading.userId, 34);
      expect(reading.heartRate, 72.5);
      expect(reading.spo2, isNull);
      expect(reading.vehicleId, 'vehicle-7');
    });

    test('Air Quality parsing preserves nullable measurements', () {
      final reading = AirQualityReading.fromJson(<String, dynamic>{
        'air_condition_id': '9',
        'vehicle_id': 'vehicle-7',
        'device_id': 'air-2',
        'timestamp': '2026-08-14T10:00:00Z',
        'co': 1.2,
        'co2': '430',
        'pm25': null,
        'pm10': 8,
        'temperature': 25.4,
        'o2': 20.8,
        'humidity': 61,
        'aqi': 32,
      });

      expect(reading.airConditionId, 9);
      expect(reading.co2, 430);
      expect(reading.pm25, isNull);
      expect(reading.aqi, 32);
    });
  });

  group('monitoring services', () {
    test('Vital Sign latest uses vehicle ID and parses API envelope', () async {
      late Uri requestedUri;
      final service = VitalSignService(
        baseUrl: 'http://example.test/api/v1',
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            '{"status":"success","data":{"vehicle_id":"fleet 7","heart_rate":71}}',
            200,
          );
        }),
      );

      final reading = await service.getLatestByVehicle('fleet 7');

      expect(requestedUri.path, '/api/v1/health/latest/fleet%207');
      expect(reading?.heartRate, 71);
    });

    test('Air Quality history sends optional date range', () async {
      late Uri requestedUri;
      final service = AirQualityService(
        baseUrl: 'http://example.test/api/v1',
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            '{"status":"success","data":[{"vehicle_id":"7","aqi":41}]}',
            200,
          );
        }),
      );

      final readings = await service.getHistoryByVehicle(
        '7',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 14),
      );

      expect(requestedUri.path, '/api/v1/air-monitor/history/7');
      expect(requestedUri.queryParameters['start_date'], '2026-08-01');
      expect(requestedUri.queryParameters['end_date'], '2026-08-14');
      expect(readings.single.aqi, 41);
    });

    test('Air Quality latest uses the internal vehicle ID', () async {
      late Uri requestedUri;
      final service = AirQualityService(
        baseUrl: 'http://example.test/api/v1',
        client: MockClient((request) async {
          requestedUri = request.url;
          return http.Response(
            '{"status":"success","data":{"vehicle_id":"11","aqi":55}}',
            200,
          );
        }),
      );

      final reading = await service.getLatestByVehicle('11');

      expect(requestedUri.path, '/api/v1/air-monitor/latest/11');
      expect(reading?.vehicleId, '11');
      expect(reading?.aqi, 55);
    });

    test('empty latest response returns no reading', () async {
      final service = VitalSignService(
        baseUrl: 'http://example.test/api/v1',
        client: MockClient((_) async => http.Response('', 200)),
      );

      expect(await service.getLatestByVehicle('7'), isNull);
    });

    test('invalid response fails without affecting other modules', () async {
      final service = AirQualityService(
        baseUrl: 'http://example.test/api/v1',
        client: MockClient((_) async => http.Response('not-json', 200)),
      );

      expect(service.getLatestByVehicle('7'), throwsA(isA<FormatException>()));
    });
  });
}
