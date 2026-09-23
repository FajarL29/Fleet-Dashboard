import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:fleet_dashboard/bloc/auth/auth_cubit.dart';
import 'package:fleet_dashboard/bloc/auth/auth_state.dart';
import 'package:fleet_dashboard/models/auth_session.dart';
import 'package:fleet_dashboard/services/auth_service.dart';
import 'package:fleet_dashboard/services/auth_session_store.dart';
import 'package:fleet_dashboard/theme/auth_colors.dart';
import 'package:fleet_dashboard/widgets/auth/auth_gate.dart';
import 'package:fleet_dashboard/widgets/common/fleet_loader.dart';
import 'package:fleet_dashboard/widgets/overview/overview_dashboard.dart';

String _jwt() {
  String seg(Map<String, dynamic> v) =>
      base64Url.encode(utf8.encode(json.encode(v))).replaceAll('=', '');
  final exp = DateTime.now().toUtc().add(const Duration(hours: 1));
  return '${seg({'alg': 'HS256'})}'
      '.${seg({
        'user_id': '1',
        'username': 'ghefira',
        'fullname': 'Ghefira Maharani',
        'role': 'Supervisor',
        'exp': exp.millisecondsSinceEpoch ~/ 1000,
      })}'
      '.sig';
}

class _MemoryStore implements AuthSessionStore {
  AuthSession? saved;
  @override
  Future<AuthSession?> read() async => saved;
  @override
  Future<void> write(AuthSession session) async => saved = session;
  @override
  Future<void> clear() async => saved = null;
}

void main() {
  tearDown(AuthService.instance.reset);

  testWidgets('a successful sign-in lands on the Overview dashboard',
      (tester) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final service = AuthService()
      ..clientOverride = MockClient(
        (_) async => http.Response(
          json.encode({
            'status': 'success',
            'data': {
              'token': _jwt(),
              'refreshToken': 'r-1',
              'user': {
                'user_id': '1',
                'username': 'ghefira',
                'fullname': 'Ghefira Maharani',
                'email': '',
                'role': 'Supervisor',
              },
            },
          }),
          200,
        ),
      );

    final cubit = AuthCubit(authService: service, sessionStore: _MemoryStore());

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          theme: AuthTheme.materialTheme,
          home: const AuthGate(),
        ),
      ),
    );

    // Nobody is signed in yet, so the gate holds its startup loader.
    expect(find.byType(FleetLoader), findsOneWidget);

    await cubit.restore();
    // Not pumpAndSettle: the sign-in page's left panel animates in a loop, so
    // the frame queue never empties.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Welcome back 👋'), findsOneWidget);

    // Sign in with credentials the server accepts.
    expect(await cubit.login('ghefira', 'rahasia123', true), isNull);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // The gate has swapped the login page for the dashboard shell, and the
    // shell's default route is Overview.
    expect(find.text('Welcome back 👋'), findsNothing);
    expect(find.byType(OverviewDashboard), findsOneWidget);

    // The account bar reads the real signed-in user, not a placeholder.
    expect(find.text('Ghefira Maharani'), findsWidgets);
    expect(cubit.state.status, AuthStatus.authenticated);
  });
}
