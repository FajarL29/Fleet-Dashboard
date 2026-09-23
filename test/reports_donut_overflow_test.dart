import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/widgets/reports/reports_severity_donut_card.dart';

void main() {
  testWidgets('donut never overflows even when squeezed short', (
    tester,
  ) async {
    // Short enough that the legend's natural size used to exceed it. Below
    // ~64px the card's own title and padding cannot fit regardless of the
    // chart, so that floor is excluded — this checks the legend specifically.
    const tightHeights = [70.0, 90.0, 110.0, 130.0];

    for (final height in tightHeights) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 340,
              height: height,
              child: const ReportsSeverityDonutCard(
                critical: 70,
                medium: 25,
                low: 30,
                emptyMessage: 'none',
                fill: true,
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
  });

  testWidgets('donut fills a generous height without overflowing either', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 400,
            child: ReportsSeverityDonutCard(
              critical: 70,
              medium: 25,
              low: 30,
              emptyMessage: 'none',
              fill: true,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Critical'), findsOneWidget);
    expect(find.text('70'), findsOneWidget);
  });
}
