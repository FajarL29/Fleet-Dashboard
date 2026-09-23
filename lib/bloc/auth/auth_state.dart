import 'package:equatable/equatable.dart';

import '../../models/auth_session.dart';

/// Where the app is in the sign-in lifecycle.
///
/// [initial] and [restoring] both mean "we do not know yet", and the gate
/// shows a spinner for either. They stay separate so a stuck startup is
/// legible in the devtools: [restoring] means the stored session is actually
/// being read back.
enum AuthStatus { initial, restoring, unauthenticated, authenticated }

class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.initial, this.session});

  const AuthState.unauthenticated()
    : status = AuthStatus.unauthenticated,
      session = null;

  const AuthState.authenticated(AuthSession this.session)
    : status = AuthStatus.authenticated;

  final AuthStatus status;

  /// The signed-in session. Non-null exactly when [status] is
  /// [AuthStatus.authenticated].
  final AuthSession? session;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  AuthState copyWith({AuthStatus? status, AuthSession? session}) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
    );
  }

  @override
  List<Object?> get props => [
    status,
    session?.accessToken,
    session?.user.userId,
  ];
}
