import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/auth/auth_cubit.dart';
import 'services/deployment_check.dart';
import 'theme/auth_colors.dart';
import 'widgets/auth/auth_gate.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Logged before anything tries to use the network, so a bad build announces
  // itself rather than waiting for a user to fail at the login screen.
  DeploymentCheck.report();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // `restore()` runs here rather than in the gate's build, which can run
      // more than once. It leaves the state on AuthStatus.restoring until the
      // stored session has been read, so the gate shows its spinner instead of
      // flashing the login form at a user who is already signed in.
      create: (_) => AuthCubit()..restore(),
      child: MaterialApp(
        title: 'Fleet Management',
        debugShowCheckedModeBanner: false,
        theme: AuthTheme.materialTheme,
        home: const AuthGate(),
      ),
    );
  }
}
