import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/auth_session.dart';
import '../../services/auth_service.dart';
import '../../services/auth_session_store.dart';
import '../../services/authenticated_http_client.dart';
import 'auth_state.dart';

/// Owns who is signed in.
///
/// [AuthGate] rebuilds off this, so every transition here swaps the whole page
/// tree: emitting [AuthStatus.unauthenticated] is what sends the user back to
/// the login form.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    AuthService? authService,
    AuthSessionStore? sessionStore,
    AuthenticatedHttpClient? httpClient,
  }) : _authService = authService ?? AuthService.instance,
       _sessionStore = sessionStore ?? SecureAuthSessionStore(),
       _httpClient = httpClient ?? AuthenticatedHttpClient.instance,
       super(const AuthState()) {
    // Every data service sends through this client, so wiring it here is what
    // makes a 401 anywhere in the app refresh the token and, failing that,
    // drop the user back on the login page.
    _httpClient.configure(
      accessToken: () => _authService.currentToken,
      refreshSession: _refreshSession,
      onSessionInvalid: logout,
    );
  }

  final AuthService _authService;
  final AuthSessionStore _sessionStore;
  final AuthenticatedHttpClient _httpClient;

  /// Whether this sign-in asked to be remembered, so a refreshed session is
  /// written back only for a user who chose that.
  bool _remembered = false;

  /// In-flight refresh, shared so a burst of 401s triggers exactly one.
  Future<bool>? _pendingRefresh;

  /// Reads back a remembered session at startup.
  ///
  /// A stored session whose access token has already lapsed is dropped rather
  /// than trusted: the user signs in again instead of landing on a dashboard
  /// where every request 401s.
  Future<void> restore() async {
    if (state.status != AuthStatus.initial) return;
    emit(state.copyWith(status: AuthStatus.restoring));

    try {
      final stored = await _sessionStore.read();
      if (stored != null && stored.isAccessTokenUsable()) {
        _remembered = true;
        _authService.adoptSession(stored);
        emit(AuthState.authenticated(stored));
        return;
      }

      // The access token has lapsed, but a stored session was remembered on
      // purpose: try the refresh token before making the user type again.
      if (stored != null && _refreshWorthTrying(stored)) {
        _remembered = true;
        _authService.adoptSession(stored);
        if (await _refreshSession()) return;
      }

      if (stored != null) await _sessionStore.clear();
    } catch (error) {
      if (kDebugMode) debugPrint('[Auth] Could not restore session: $error');
    }

    emit(const AuthState.unauthenticated());
  }

  /// Signs in. Returns null on success, or the message the form should show.
  ///
  /// The error comes back as a value instead of an exception because the login
  /// form renders it inline; a thrown error would have to travel through the
  /// state and then be cleared again on the next keystroke.
  Future<String?> login(
    String username,
    String password,
    bool rememberMe,
  ) async {
    if (username.trim().isEmpty || password.isEmpty) {
      return 'Enter your username and password.';
    }

    try {
      final session = await _authService.signIn(
        username: username,
        password: password,
      );

      // Only a "remember me" sign-in survives a restart; otherwise clear any
      // session an earlier remembered sign-in left behind.
      _remembered = rememberMe;
      await _persist(rememberMe ? session : null);

      emit(AuthState.authenticated(session));
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (error) {
      if (kDebugMode) debugPrint('[Auth] Login failed: $error');
      return 'Something went wrong signing in. Please try again.';
    }
  }

  /// Exchanges the refresh token for a new session, keeping the user signed in.
  ///
  /// Returns false when the session is truly over, which is
  /// [AuthenticatedHttpClient]'s cue to call [logout].
  Future<bool> _refreshSession() {
    return _pendingRefresh ??= _runRefresh().whenComplete(
      () => _pendingRefresh = null,
    );
  }

  /// Writes or clears the remembered session, swallowing storage failures.
  ///
  /// Persisting is a convenience, never a precondition for being signed in.
  /// The keychain can be unavailable for reasons that have nothing to do with
  /// the user's credentials — a macOS build without the keychain entitlement,
  /// a browser with site data blocked — and letting that fail the sign-in
  /// locks people out of an app they just authenticated to.
  Future<void> _persist(AuthSession? session) async {
    try {
      if (session != null) {
        await _sessionStore.write(session);
      } else {
        await _sessionStore.clear();
      }
    } catch (error) {
      // Storage is not working, so stop pretending this session is remembered:
      // a refreshed one would only fail to save in the same way.
      _remembered = false;
      if (kDebugMode) debugPrint('[Auth] Could not persist session: $error');
    }
  }

  /// Whether a refresh round trip is worth making.
  ///
  /// Plenty of APIs issue opaque refresh tokens with no readable expiry — only
  /// the server knows whether they are still good. Refusing those outright
  /// (as [AuthSession.isRefreshTokenUsable] does, since it can only read a
  /// JWT) would mean refresh never fires at all. So only a token that is
  /// missing, or a JWT that has provably lapsed, is rejected without asking.
  static bool _refreshWorthTrying(AuthSession session) {
    if (session.refreshToken.trim().isEmpty) return false;
    final expiry = jwtExpiration(session.refreshToken);
    return expiry == null || expiry.isAfter(DateTime.now().toUtc());
  }

  Future<bool> _runRefresh() async {
    final current = _authService.session ?? state.session;
    if (current == null || !_refreshWorthTrying(current)) return false;

    try {
      final refreshed = await _authService.refresh(current.refreshToken);
      if (_remembered) await _persist(refreshed);
      emit(AuthState.authenticated(refreshed));
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('[Auth] Refresh failed: $error');
      return false;
    }
  }

  /// Signs out and forgets the stored session.
  Future<void> logout() async {
    if (state.status == AuthStatus.unauthenticated) return;

    _remembered = false;
    // Retire the session server-side first, while the token is still at hand,
    // so the refresh token cannot outlive the sign-out.
    await _authService.signOut();
    _authService.clearSession();
    try {
      await _sessionStore.clear();
    } catch (error) {
      if (kDebugMode) debugPrint('[Auth] Could not clear session: $error');
    }
    emit(const AuthState.unauthenticated());
  }
}
