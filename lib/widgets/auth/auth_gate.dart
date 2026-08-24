import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_event.dart';
import '../../screens/dashboard_screen.dart';
import '../../screens/login.dart';
import '../../screens/register.dart';
import '../../services/auth_service.dart';
import '../../theme/auth_colors.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.registrationServiceFactory});

  final AuthService Function()? registrationServiceFactory;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.initial:
          case AuthStatus.restoring:
            return const _AuthStartupLoading();
          case AuthStatus.unauthenticated:
            return LoginPage(
              onSignIn: context.read<AuthCubit>().login,
              onCreateAccount: () => _openRegister(context),
            );
          case AuthStatus.authenticated:
            return BlocProvider(
              key: ValueKey(state.session!.user.userId),
              create: (_) => DashboardBloc()..add(const DashboardInitialized()),
              child: const DashboardScreen(),
            );
        }
      },
    );
  }

  Future<void> _openRegister(BuildContext context) async {
    final service = registrationServiceFactory?.call() ?? AuthService();
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (registerContext) => RegisterPage(
            authService: service,
            onSignIn: () => Navigator.of(registerContext).pop(),
          ),
        ),
      );
    } finally {
      service.close();
    }
  }
}

class _AuthStartupLoading extends StatelessWidget {
  const _AuthStartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: AuthColors.brandBlue),
      ),
    );
  }
}
