import 'dart:async';

import 'package:fleet_dashboard/widgets/auth/login_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows required validation for empty credentials', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LoginForm(onSignIn: (_, _, _) async => null),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sign In'));
    await tester.pump();

    expect(find.text('Username is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('submits username, password, and remember-me value', (
    tester,
  ) async {
    String? username;
    String? password;
    bool? rememberMe;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LoginForm(
              onSignIn: (value, secret, remember) async {
                username = value;
                password = secret;
                rememberMe = remember;
                return null;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'driver');
    await tester.enterText(find.byType(TextFormField).last, 'test-only-secret');
    await tester.tap(find.byType(Checkbox));
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(username, 'driver');
    expect(password, 'test-only-secret');
    expect(rememberMe, isTrue);
  });

  testWidgets('keeps the form usable and displays authentication errors', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LoginForm(
              onSignIn: (_, _, _) async => 'Username or password is incorrect.',
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'driver');
    await tester.enterText(find.byType(TextFormField).last, 'invalid');
    await tester.tap(find.text('Sign In'));
    await tester.pumpAndSettle();

    expect(find.text('Username or password is incorrect.'), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled,
      isTrue,
    );
  });

  testWidgets('prevents duplicate submissions while login is pending', (
    tester,
  ) async {
    final completion = Completer<String?>();
    var submissions = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LoginForm(
              onSignIn: (_, _, _) {
                submissions += 1;
                return completion.future;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'driver');
    await tester.enterText(find.byType(TextFormField).last, 'test-only-secret');
    await tester.tap(find.text('Sign In'));
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(submissions, 1);
    completion.complete(null);
    await tester.pumpAndSettle();
  });
}
