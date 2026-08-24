import 'dart:convert';

import 'package:fleet_dashboard/bloc/auth/auth_cubit.dart';
import 'package:fleet_dashboard/models/auth_session.dart';
import 'package:fleet_dashboard/screens/login.dart';
import 'package:fleet_dashboard/screens/register.dart';
import 'package:fleet_dashboard/services/auth_service.dart';
import 'package:fleet_dashboard/services/auth_session_store.dart';
import 'package:fleet_dashboard/widgets/auth/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('navigates from Login to Register and back to Login', (
    tester,
  ) async {
    final registrationService = _registrationService(
      (_) async => _successResponse(),
    );
    final cubit = await _pumpAuthApp(tester, registrationService);
    addTearDown(cubit.close);

    expect(find.text("Don't have an account?"), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
    expect(find.text('Already have an account? '), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(RegisterPage), findsNothing);
  });

  testWidgets('successful registration returns to Login with feedback', (
    tester,
  ) async {
    final registrationService = _registrationService(
      (_) async => _successResponse(),
    );
    final cubit = await _pumpAuthApp(tester, registrationService);
    addTearDown(cubit.close);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await _submitValidRegistration(tester);
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(RegisterPage), findsNothing);
    expect(
      find.text('Account created successfully. Please sign in.'),
      findsOneWidget,
    );
  });

  testWidgets('registration failure stays on Register and shows its error', (
    tester,
  ) async {
    final registrationService = _registrationService(
      (_) async => http.Response(
        json.encode(<String, dynamic>{
          'status': 'failed',
          'stat_code': 409,
          'message': 'Username already exists',
        }),
        409,
      ),
    );
    final cubit = await _pumpAuthApp(tester, registrationService);
    addTearDown(cubit.close);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await _submitValidRegistration(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
    expect(find.text('Username already exists.'), findsOneWidget);
    expect(
      find.text('Account created successfully. Please sign in.'),
      findsNothing,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Create Account'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('registration timeout stops loading and keeps form usable', (
    tester,
  ) async {
    final registrationService = AuthService(
      requestTimeout: const Duration(milliseconds: 1),
      client: MockClient((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return _successResponse();
      }),
    );
    final cubit = await _pumpAuthApp(tester, registrationService);
    addTearDown(cubit.close);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await _submitValidRegistration(tester);
    await tester.pump(const Duration(milliseconds: 25));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
    expect(
      find.text('The authentication server took too long to respond.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Create Account'),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('backend-unavailable registration keeps form usable', (
    tester,
  ) async {
    final registrationService = _registrationService(
      (_) async => throw http.ClientException('offline'),
    );
    final cubit = await _pumpAuthApp(tester, registrationService);
    addTearDown(cubit.close);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await _submitValidRegistration(tester);
    await tester.pumpAndSettle();

    expect(find.byType(RegisterPage), findsOneWidget);
    expect(
      find.text('Unable to reach the authentication server.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Create Account'),
          )
          .onPressed,
      isNotNull,
    );
  });
}

Future<AuthCubit> _pumpAuthApp(
  WidgetTester tester,
  AuthService registrationService,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1440, 1400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final cubit = AuthCubit(
    service: AuthService(
      client: MockClient((_) async => http.Response('{}', 500)),
    ),
    store: _MemorySessionStore(),
  );
  await cubit.restoreSession();
  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: cubit,
      child: MaterialApp(
        home: AuthGate(registrationServiceFactory: () => registrationService),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return cubit;
}

AuthService _registrationService(
  Future<http.Response> Function(http.Request) handler,
) {
  return AuthService(client: MockClient(handler));
}

http.Response _successResponse() {
  return http.Response(
    json.encode(<String, dynamic>{
      'status': 'success',
      'stat_code': 200,
      'data': 'Account created',
    }),
    200,
  );
}

Future<void> _submitValidRegistration(WidgetTester tester) async {
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

  final submit = find.widgetWithText(FilledButton, 'Create Account');
  await tester.ensureVisible(submit);
  await tester.tap(submit);
  await tester.pump();
}

class _MemorySessionStore implements AuthSessionStore {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthSession?> read() async => null;

  @override
  Future<void> write(AuthSession value) async {}
}
