import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/dashboard/dashboard_bloc.dart';
import '../../bloc/dashboard/dashboard_event.dart';
import '../../screens/auth_screen.dart';
import '../../screens/dashboard_screen.dart';
import '../../services/page_data_cache.dart';
import '../../theme/auth_colors.dart';
import '../common/fleet_loader.dart';
import 'role_scope.dart';

/// Chooses what the app shows based on who is signed in.
///
/// Signing in or out is a change of state here, never a navigation: there is
/// no route to pop back to a dashboard you have signed out of, and no way to
/// end up on a login page stacked on top of a live session.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        switch (state.status) {
          case AuthStatus.initial:
          case AuthStatus.restoring:
            return const _AuthStartupLoading();
          case AuthStatus.unauthenticated:
            // Sign-up lives inside this screen rather than on a pushed route,
            // so switching between the two keeps the animated panel running.
            return AuthScreen(onSignIn: context.read<AuthCubit>().login);
          case AuthStatus.authenticated:
            return BlocProvider(
              key: ValueKey(state.session!.user.userId),
              create: (_) => DashboardBloc()..add(const DashboardInitialized()),
              child: RepositoryProvider(
                create: (_) => PageDataCache(),
                // Wrapped once, here, so every page below can ask what this
                // person may do without reaching for the auth bloc itself.
                child: RoleScope.fromAuth(child: const DashboardScreen()),
              ),
            );
        }
      },
    );
  }
}

class _AuthStartupLoading extends StatelessWidget {
  const _AuthStartupLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AuthColors.pageBackground,
      body: Center(child: FleetLoader(message: 'Starting Fleet Dashboard...')),
    );
  }
}
