import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fleet_dashboard/services/drowsiness_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory sandbox;

  setUp(() async {
    sandbox = await Directory.systemTemp.createTemp('export_test');

    // Stands in for the platform's Downloads lookup. On a sandboxed macOS
    // build this is what path_provider answers with; the old code read HOME
    // directly, which points at the app container, found no Downloads folder,
    // and fell through to Directory.current — "/" for an .app bundle, where
    // the write failed.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (call) async => switch (call.method) {
            'getDownloadsDirectory' => '${sandbox.path}/Downloads',
            'getApplicationDocumentsPath' => '${sandbox.path}/Documents',
            _ => null,
          },
        );
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          null,
        );
    if (sandbox.existsSync()) await sandbox.delete(recursive: true);
  });

  DrowsinessReportService serviceReturning(String csv, {String? disposition}) {
    return DrowsinessReportService(
      client: MockClient(
        (_) async => http.Response(
          csv,
          200,
          headers: {
            'content-type': 'text/csv',
            if (disposition != null) 'content-disposition': disposition,
          },
        ),
      ),
    );
  }

  test('an export lands in Downloads and holds the server bytes', () async {
    const csv = 'event_time,driver_name\n2026-09-11,Ghefira\n';
    final path = await serviceReturning(csv).exportDrowsinessReportCsv(
      vehicleId: 'VIN-0001',
      startDate: DateTime(2026, 9, 1),
      endDate: DateTime(2026, 9, 11),
    );

    expect(path, contains('Downloads'));
    final file = File(path);
    expect(
      file.existsSync(),
      isTrue,
      reason: 'the file must actually be there',
    );
    expect(file.readAsStringSync(), csv);
  });

  test('the Downloads folder is created when it does not exist yet', () async {
    // A fresh container has no Downloads directory. The old code treated that
    // as "try somewhere else" and ended up somewhere unwritable.
    expect(Directory('${sandbox.path}/Downloads').existsSync(), isFalse);

    final path = await serviceReturning(
      'a,b\n1,2\n',
    ).exportDrowsinessReportCsv(vehicleId: 'VIN-0001');

    expect(File(path).existsSync(), isTrue);
  });

  test('the server filename is honoured when it sends one', () async {
    final path = await serviceReturning(
      'x,y\n',
      disposition: 'attachment; filename="fleet-report-sept.csv"',
    ).exportDrowsinessReportCsv(vehicleId: 'VIN-0001');

    expect(path, endsWith('fleet-report-sept.csv'));
  });

  test(
    'a refused export throws rather than writing a file of error text',
    () async {
      final service = DrowsinessReportService(
        client: MockClient(
          (_) async => http.Response(
            json.encode({'message': 'Vehicle not found'}),
            404,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      await expectLater(
        service.exportDrowsinessReportCsv(vehicleId: 'nope'),
        throwsA(isA<Exception>()),
      );
    },
  );

  group('fleet export', () {
    DrowsinessReportService serviceFor(Map<String, String> csvByVin) {
      return DrowsinessReportService(
        client: MockClient((request) async {
          // /drowsiness/report/{vin}/export/csv
          final vin = request
              .url
              .pathSegments[request.url.pathSegments.indexOf('report') + 1];
          final csv = csvByVin[vin];
          if (csv == null) {
            return http.Response('{"message":"not found"}', 404);
          }
          return http.Response(csv, 200, headers: {'content-type': 'text/csv'});
        }),
      );
    }

    test('every vehicle lands in one file, tagged by plate', () async {
      final service = serviceFor({
        'VIN-1': 'event_time,behavior\n2026-09-01,drowsy\n2026-09-02,yawn\n',
        'VIN-2': 'event_time,behavior\n2026-09-03,distraction\n',
      });

      final result = await service.exportFleetDrowsinessReportCsv(
        vehicles: const [
          ReportExportTarget(id: 'VIN-1', label: 'B 1234 ABC'),
          ReportExportTarget(id: 'VIN-2', label: 'D5678DEF'),
        ],
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 11),
      );

      expect(result.vehiclesIncluded, 2);
      expect(result.rowCount, 3);
      expect(result.skippedVehicles, isEmpty);

      final lines = File(result.path).readAsLinesSync();
      expect(lines.first, 'Vehicle,event_time,behavior');
      expect(lines, hasLength(4), reason: 'one header plus three rows');
      // Each row carries the plate, so the fleet file can be pivoted by vehicle.
      expect(lines[1], startsWith('"B 1234 ABC",'));
      expect(lines[3], startsWith('"D5678DEF",'));
    });

    test('a vehicle with no rows is skipped and named, not fatal', () async {
      final service = serviceFor({
        'VIN-1': 'event_time,behavior\n2026-09-01,drowsy\n',
        // Header only: the server answered, but there is nothing in range.
        'VIN-2': 'event_time,behavior\n',
      });

      final result = await service.exportFleetDrowsinessReportCsv(
        vehicles: const [
          ReportExportTarget(id: 'VIN-1', label: 'B 1234 ABC'),
          ReportExportTarget(id: 'VIN-2', label: 'D5678DEF'),
        ],
      );

      expect(result.vehiclesIncluded, 1);
      expect(result.skippedVehicles, ['D5678DEF']);
      expect(File(result.path).existsSync(), isTrue);
    });

    test('one vehicle failing does not lose the others', () async {
      final service = serviceFor({
        'VIN-1': 'event_time,behavior\n2026-09-01,drowsy\n',
        // VIN-2 is absent, so the mock answers 404.
      });

      final result = await service.exportFleetDrowsinessReportCsv(
        vehicles: const [
          ReportExportTarget(id: 'VIN-1', label: 'B 1234 ABC'),
          ReportExportTarget(id: 'VIN-2', label: 'D5678DEF'),
        ],
      );

      expect(result.vehiclesIncluded, 1);
      expect(result.skippedVehicles, ['D5678DEF']);
    });

    test('a plate containing a comma does not shift the columns', () async {
      final service = serviceFor({
        'VIN-1': 'event_time,behavior\n2026-09-01,drowsy\n',
      });

      final result = await service.exportFleetDrowsinessReportCsv(
        vehicles: const [
          ReportExportTarget(id: 'VIN-1', label: 'Truck, Unit 4'),
        ],
      );

      final row = File(result.path).readAsLinesSync()[1];
      expect(row, '"Truck, Unit 4",2026-09-01,drowsy');
    });

    test('nothing at all to export is an error, not an empty file', () async {
      final service = serviceFor(const {});

      await expectLater(
        service.exportFleetDrowsinessReportCsv(
          vehicles: const [ReportExportTarget(id: 'VIN-1', label: 'B 1 X')],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
