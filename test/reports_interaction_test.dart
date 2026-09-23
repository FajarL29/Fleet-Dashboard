import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/widgets/reports/reports_risk_gauge.dart';
import 'package:fleet_dashboard/widgets/reports/reports_severity_donut_card.dart';

Future<TestGesture> _hover(WidgetTester tester, Offset position) async {
  final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
  await gesture.addPointer(location: Offset.zero);
  addTearDown(gesture.removePointer);
  await tester.pump();
  await gesture.moveTo(position);
  await tester.pumpAndSettle();
  return gesture;
}

void main() {
  testWidgets('donut centre shows the total, then the hovered slice count', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(700, 420);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReportsSeverityDonutCard(
            critical: 70,
            medium: 25,
            low: 30,
            emptyMessage: 'none',
          ),
        ),
      ),
    );

    // 70 + 25 + 30 = 125 shown while nothing is hovered.
    expect(find.text('125'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);

    // Hovering the "Critical" legend row names that slice in the centre.
    await _hover(tester, tester.getCenter(find.text('Critical')));

    expect(find.text('70'), findsWidgets);
    // Counts only: a share the reader has to convert back is not the number
    // anyone came for.
    expect(find.textContaining('%'), findsNothing);
    expect(find.text('Total'), findsNothing);
    expect(find.text('Critical'), findsWidgets);
  });

  testWidgets('gauge names the band under the pointer', (tester) async {
    tester.view.physicalSize = const Size(400, 300);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: ReportsRiskGauge(score: 83))),
      ),
    );

    expect(find.text('83/100'), findsOneWidget);

    // Anchor on the painted arc, not the widget box: the Column stretches to
    // the full width while the gauge itself is only `width` across.
    // Points are fractions of the arc's own width rather than pixels, so
    // resizing the gauge does not silently move them off the ring.
    final arc = tester.getRect(find.byType(CustomPaint).last);
    Offset onArc(double fx, double fy) =>
        arc.topLeft + Offset(arc.width * fx, arc.width * fy);

    final gesture = await _hover(tester, onArc(0.195, 0.195));

    // Upper-left of a half-circle arc is early in the sweep, inside the risk.
    // Same readout shape as the donut: big number, word underneath.
    expect(find.text('83'), findsOneWidget);
    expect(find.text('Risk'), findsOneWidget);
    expect(find.text('83/100'), findsNothing);

    // The far end of the sweep is the remaining headroom.
    await gesture.moveTo(onArc(0.926, 0.432));
    await tester.pumpAndSettle();
    expect(find.text('17'), findsOneWidget);
    expect(find.text('Headroom'), findsOneWidget);

    // Leaving the ring restores the plain score.
    await gesture.moveTo(arc.center);
    await tester.pumpAndSettle();
    expect(find.text('83/100'), findsOneWidget);
  });
}
