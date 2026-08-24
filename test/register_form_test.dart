import 'dart:async';

import 'package:fleet_dashboard/widgets/register/register_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('prevents duplicate registration submissions', (tester) async {
    await _useLargeTestSurface(tester);
    final completion = Completer<void>();
    var submissions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RegisterForm(
            onSubmit:
                ({
                  required fullname,
                  required username,
                  required password,
                  required role,
                  required division,
                }) {
                  submissions += 1;
                  return completion.future;
                },
          ),
        ),
      ),
    );

    await _fillValidRegistration(tester);
    final submit = find.byType(FilledButton);
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();

    expect(submissions, 1);
    completion.complete();
    await tester.pumpAndSettle();
  });
}

Future<void> _useLargeTestSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _fillValidRegistration(WidgetTester tester) async {
  final fields = find.byType(TextFormField);
  expect(fields, findsNWidgets(5));
  await tester.enterText(fields.at(0), 'Fleet Operator');
  await tester.enterText(fields.at(1), 'operator');
  await tester.enterText(fields.at(2), 'test-only-secret');
  await tester.enterText(fields.at(3), 'test-only-secret');
  await tester.enterText(fields.at(4), 'Operations');

  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Supervisor').last);
  await tester.pumpAndSettle();
  await tester.tap(find.byType(Checkbox));
  await tester.pump();
}
