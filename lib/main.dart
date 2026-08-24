import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/auth/auth_cubit.dart';
import 'services/auth_service.dart';
import 'services/auth_session_store.dart';
import 'services/authenticated_http_client.dart';
import 'theme/app_theme.dart';
import 'widgets/auth/auth_gate.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthCubit>(
      create: (_) {
        final authCubit = AuthCubit(
          service: AuthService(),
          store: SecureAuthSessionStore(),
        );
        AuthenticatedHttpClient.instance.configure(
          accessToken: () => authCubit.accessToken,
          refreshSession: authCubit.refreshSession,
          onSessionInvalid: authCubit.clearSession,
        );
        return authCubit..restoreSession();
      },
      child: MaterialApp(
        home: const AuthGate(),
        title: 'Fleet Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
      ),
    );
  }
}
