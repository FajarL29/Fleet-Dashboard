import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fleet_dashboard/screens/auth_screen.dart';
import 'package:fleet_dashboard/services/auth_service.dart';
import 'package:fleet_dashboard/theme/auth_colors.dart';
import 'package:fleet_dashboard/widgets/auth/animated_fleet_panel.dart';

/// Advances a few frames.
///
/// `pumpAndSettle` cannot be used on these pages: the left panel animates in a
/// loop that never ends, so "settled" never arrives.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// A laptop window: the size these pages are actually used at.
const Size _desktop = Size(1440, 900);
const Size _mobile = Size(430, 940);

Future<AuthService> _pump(
  WidgetTester tester, {
  Size size = _desktop,
  AuthMode mode = AuthMode.login,
  MockClient? client,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final service = AuthService()
    ..clientOverride =
        client ?? MockClient((_) async => http.Response('{}', 200));
  addTearDown(service.close);

  await tester.pumpWidget(
    MaterialApp(
      theme: AuthTheme.materialTheme,
      home: AuthScreen(initialMode: mode, authService: service),
    ),
  );
  await _settle(tester);
  return service;
}

/// The scroll view wrapping the form column.
ScrollableState _formScroller(WidgetTester tester) {
  return tester.state<ScrollableState>(find.byType(Scrollable).first);
}

void main() {
  tearDown(AuthService.instance.reset);

  group('fits without scrolling', () {
    testWidgets('the sign-in form needs no scrolling on a laptop', (
      tester,
    ) async {
      await _pump(tester, mode: AuthMode.login);

      expect(tester.takeException(), isNull);
      expect(
        _formScroller(tester).position.maxScrollExtent,
        0,
        reason: 'sign-in should fit the window outright',
      );
    });

    testWidgets('the sign-up form needs no scrolling on a laptop', (
      tester,
    ) async {
      await _pump(tester, mode: AuthMode.register);

      expect(tester.takeException(), isNull);
      expect(
        _formScroller(tester).position.maxScrollExtent,
        0,
        reason: 'sign-up is the taller of the two and is the real test',
      );
    });

    testWidgets('both forms still render on a phone', (tester) async {
      await _pump(tester, size: _mobile, mode: AuthMode.register);
      expect(tester.takeException(), isNull);
      expect(find.text('Create your account'), findsOneWidget);
    });
  });

  group('the panel survives the toggle', () {
    testWidgets('switching modes changes only the words on the right', (
      tester,
    ) async {
      await _pump(tester, mode: AuthMode.login);

      expect(find.text('Welcome back 👋'), findsOneWidget);
      final panelBefore = tester.state(find.byType(AnimatedFleetPanel));

      await tester.tap(find.text('Sign Up'));
      await _settle(tester);

      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Welcome back 👋'), findsNothing);

      // Same State object: the animation was never torn down and restarted,
      // which is the whole point of hoisting the panel into the shell.
      expect(
        tester.state(find.byType(AnimatedFleetPanel)),
        same(panelBefore),
        reason: 'the animated panel must not rebuild when the mode changes',
      );

      await tester.tap(find.text('Log in'));
      await _settle(tester);

      expect(find.text('Welcome back 👋'), findsOneWidget);
      expect(tester.state(find.byType(AnimatedFleetPanel)), same(panelBefore));
    });

    testWidgets('the heading sits at the same height in both modes', (
      tester,
    ) async {
      await _pump(tester, mode: AuthMode.login);
      final loginHeading = tester.getTopLeft(find.text('Welcome back 👋'));

      await tester.tap(find.text('Sign Up'));
      await _settle(tester);
      final registerHeading = tester.getTopLeft(
        find.text('Create your account'),
      );

      // Same pixel, so toggling reads as the words changing rather than the
      // whole form sliding up and down.
      expect(registerHeading.dy, loginHeading.dy);
      expect(registerHeading.dx, loginHeading.dx);
    });

    testWidgets('the panel is shown once, not once per form', (tester) async {
      await _pump(tester, mode: AuthMode.register);
      expect(find.byType(AnimatedFleetPanel), findsOneWidget);
    });
  });

  group('sign-up fields', () {
    testWidgets('every required field is marked with an asterisk', (
      tester,
    ) async {
      await _pump(tester, mode: AuthMode.register);

      for (final label in const [
        'Name',
        'Employee ID',
        'Password',
        'Confirm Password',
        'Role',
        'Department',
      ]) {
        // At least one: "Password *" is also a substring of
        // "Confirm Password *", and both of them are genuinely required.
        expect(
          find.textContaining('$label *', findRichText: true),
          findsAtLeastNWidgets(1),
          reason: '"$label" should be marked required',
        );
      }
    });

    testWidgets('department is typed, not picked from a list', (tester) async {
      await _pump(tester, mode: AuthMode.register);

      // Role is the only dropdown left on the form.
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      expect(find.text('Select your role'), findsOneWidget);
      expect(find.text('Enter your department'), findsOneWidget);
    });
  });

  testWidgets('creating an account returns to sign-in with a confirmation', (
    tester,
  ) async {
    late Map<String, dynamic> sent;
    await _pump(
      tester,
      mode: AuthMode.register,
      client: MockClient((request) async {
        sent = json.decode(request.body) as Map<String, dynamic>;
        return http.Response(json.encode({'status': 'success'}), 200);
      }),
    );

    await tester.enterText(find.byType(TextFormField).at(0), 'Ghefira');
    await tester.enterText(find.byType(TextFormField).at(1), 'EMP-2024');
    await tester.enterText(find.byType(TextFormField).at(2), 'rahasia123');
    await tester.enterText(find.byType(TextFormField).at(3), 'rahasia123');
    await tester.enterText(find.byType(TextFormField).at(4), 'Operations');

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await _settle(tester);
    await tester.tap(find.text('UI/UX Engineer').last);
    await _settle(tester);

    await tester.tap(find.byType(Checkbox));
    await _settle(tester);

    await tester.tap(find.text('Create Account'));
    await _settle(tester);

    // Employee ID goes out as `username`, Department as `division`.
    expect(sent['username'], 'EMP-2024');
    expect(sent['division'], 'Operations');
    expect(sent['fullname'], 'Ghefira');

    expect(find.text('Welcome back 👋'), findsOneWidget);
    expect(find.textContaining('Account created'), findsOneWidget);
  });
}
