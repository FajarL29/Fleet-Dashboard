import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/models/drowsiness_report.dart';
import 'package:fleet_dashboard/widgets/common/sortable_header.dart';
import 'package:fleet_dashboard/widgets/safety/safety_event_sort.dart';

DrowsinessEvent _event({
  required int id,
  required DateTime at,
  String risk = 'low',
  double? speed,
  String? location,
}) => DrowsinessEvent(
  id: id,
  vehicleId: 'VIN$id',
  userId: 1,
  time: at,
  status: 'detected',
  riskLevel: risk,
  speedAtEvent: speed,
  location: location,
);

void main() {
  group('safety event sorting', () {
    final events = [
      _event(id: 1, at: DateTime(2026, 9, 1, 8), risk: 'low', speed: 30),
      _event(id: 2, at: DateTime(2026, 9, 3, 8), risk: 'high', speed: 90),
      _event(id: 3, at: DateTime(2026, 9, 2, 8), risk: 'medium'),
    ];

    List<int> idsFor(SafetyEventColumn column, SortDirection direction) =>
        sortSafetyEvents(events, ColumnSort(column, direction))
            .map((event) => event.id)
            .toList();

    test('time sorts both ways', () {
      expect(idsFor(SafetyEventColumn.time, SortDirection.ascending), [1, 3, 2]);
      expect(idsFor(SafetyEventColumn.time, SortDirection.descending), [
        2,
        3,
        1,
      ]);
    });

    test('severity sorts by danger, not alphabetically', () {
      // Alphabetically "high" < "low" < "medium"; by danger it must be
      // low, medium, high.
      expect(idsFor(SafetyEventColumn.severity, SortDirection.ascending), [
        1,
        3,
        2,
      ]);
      expect(idsFor(SafetyEventColumn.severity, SortDirection.descending), [
        2,
        3,
        1,
      ]);
    });

    test('only Time and Severity are offered as sortable', () {
      // A header that reorders on a click nobody wanted is worse than one
      // that stays put, so the rest are plain labels.
      expect(
        SafetyEventColumn.values
            .where((column) => column.sortable)
            .map((column) => column.label),
        ['Time', 'Severity'],
      );
    });

    test('does not mutate the list it was given', () {
      final original = List<DrowsinessEvent>.from(events);
      sortSafetyEvents(
        events,
        const ColumnSort(SafetyEventColumn.severity, SortDirection.ascending),
      );
      expect(events, original);
    });
  });

  group('sortable header', () {
    Widget host({
      required ColumnSort<int>? sort,
      required SortChanged<int> onSort,
    }) => MaterialApp(
      home: Scaffold(
        body: SortableHeader<int>(
          label: 'Time',
          column: 0,
          sort: sort,
          onSort: onSort,
          firstDirection: SortDirection.descending,
        ),
      ),
    );

    testWidgets('an unsorted column shows a neutral arrow, not a direction', (
      tester,
    ) async {
      await tester.pumpWidget(host(sort: null, onSort: (_) {}));

      expect(find.byIcon(Icons.unfold_more_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsNothing);
    });

    testWidgets('the active column points the way it is sorted', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          sort: const ColumnSort(0, SortDirection.ascending),
          onSort: (_) {},
        ),
      );
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

      await tester.pumpWidget(
        host(
          sort: const ColumnSort(0, SortDirection.descending),
          onSort: (_) {},
        ),
      );
      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
    });

    testWidgets('first click uses the column default, then flips', (
      tester,
    ) async {
      ColumnSort<int>? received;

      await tester.pumpWidget(
        host(sort: null, onSort: (next) => received = next),
      );
      await tester.tap(find.text('Time'));
      // Time defaults to newest-first.
      expect(received, const ColumnSort(0, SortDirection.descending));

      await tester.pumpWidget(
        host(sort: received, onSort: (next) => received = next),
      );
      await tester.tap(find.text('Time'));
      expect(received, const ColumnSort(0, SortDirection.ascending));
    });

    testWidgets('clicking a different column starts from its own default', (
      tester,
    ) async {
      ColumnSort<int>? received;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SortableHeader<int>(
              label: 'Vehicle',
              column: 1,
              // Another column is currently sorted.
              sort: const ColumnSort(0, SortDirection.ascending),
              onSort: (next) => received = next,
              firstDirection: SortDirection.ascending,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Vehicle'));

      expect(received, const ColumnSort(1, SortDirection.ascending));
    });
  });
}
