import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/widgets/common/app_date_range_picker.dart';

Widget _host({
  DateTimeRange? value,
  required ValueChanged<DateTimeRange?> onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: AppDateRangePicker(value: value, onChanged: onChanged),
      ),
    ),
  );
}

void main() {
  testWidgets('two taps commit a range and close the calendar', (tester) async {
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    DateTimeRange? picked;
    await tester.pumpWidget(_host(onChanged: (value) => picked = value));

    await tester.tap(find.text('Pick Dates'));
    await tester.pumpAndSettle();

    // Both months are on screen at once.
    expect(find.text('Sun'), findsNWidgets(2));

    await tester.tap(find.text('7').first);
    await tester.pumpAndSettle();
    expect(picked, isNull, reason: 'first tap only starts the range');

    await tester.tap(find.text('15').first);
    await tester.pumpAndSettle();

    expect(picked, isNotNull);
    expect(picked!.start.day, 7);
    expect(picked!.end.day, 15);
    expect(find.text('Sun'), findsNothing, reason: 'calendar closes on commit');
  });

  testWidgets('tapping earlier than the pending start restarts the range', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    DateTimeRange? picked;
    await tester.pumpWidget(_host(onChanged: (value) => picked = value));

    await tester.tap(find.text('Pick Dates'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('20').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('5').first);
    await tester.pumpAndSettle();

    expect(picked, isNull, reason: 'going backwards restarts, never commits');

    await tester.tap(find.text('9').first);
    await tester.pumpAndSettle();

    expect(picked!.start.day, 5);
    expect(picked!.end.day, 9);
  });

  testWidgets('Reset clears an applied range', (tester) async {
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final now = DateTime.now();
    var cleared = false;

    await tester.pumpWidget(
      _host(
        value: DateTimeRange(
          start: DateTime(now.year, now.month, 7),
          end: DateTime(now.year, now.month, 15),
        ),
        onChanged: (value) => cleared = value == null,
      ),
    );

    await tester.tap(find.byType(AppDateRangePicker));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(cleared, isTrue);
  });
}
