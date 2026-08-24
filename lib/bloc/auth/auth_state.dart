import '../../models/auth_session.dart';

enum AuthStatus { initial, restoring, unauthenticated, authenticated }

class AuthState {
  const AuthState._({required this.status, this.session});

  const AuthState.initial() : this._(status: AuthStatus.initial);

  const AuthState.restoring() : this._(status: AuthStatus.restoring);

  const AuthState.unauthenticated()
    : this._(status: AuthStatus.unauthenticated);

  const AuthState.authenticated(AuthSession session)
    : this._(status: AuthStatus.authenticated, session: session);

  final AuthStatus status;
  final AuthSession? session;
}
