import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_cubit.dart';
import '../../models/user_role.dart';

/// Makes the signed-in person's role reachable from anywhere below it.
///
/// Widgets deep in a page should not each reach into [AuthCubit] to work out
/// what the user may do — that scatters the same lookup across the tree and
/// makes it easy for one of them to forget. They read `RoleScope.of(context)`
/// and ask it a question about the action they are about to offer.
class RoleScope extends InheritedWidget {
  const RoleScope({super.key, required this.role, required super.child});

  final UserRole role;

  /// The current role, or [UserRole.user] where none is in scope.
  ///
  /// Defaulting to the least privileged role matters: a widget rendered
  /// outside the scope — in a test, or a dialog pushed on the root navigator —
  /// hides privileged actions rather than showing them to everyone.
  static UserRole of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RoleScope>()?.role ??
        UserRole.user;
  }

  /// Wraps [child] with the role of whoever is signed in right now.
  static Widget fromAuth({required Widget child}) {
    return Builder(
      builder: (context) {
        final session = context.watch<AuthCubit>().state.session;
        return RoleScope(
          role: session?.user.accessRole ?? UserRole.user,
          child: child,
        );
      },
    );
  }

  @override
  bool updateShouldNotify(RoleScope oldWidget) => oldWidget.role != role;
}
