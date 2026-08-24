import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/auth_session.dart';
import '../../services/auth_service.dart';
import '../../services/auth_session_store.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required AuthService service, required AuthSessionStore store})
    : _service = service,
      _store = store,
      super(const AuthState.initial());

  final AuthService _service;
  final AuthSessionStore _store;

  AuthSession? _session;
  bool _rememberSession = false;
  bool _loginInProgress = false;
  Future<bool>? _refreshOperation;
  int _sessionGeneration = 0;

  AuthSession? get session => _session;

  String? get accessToken => _session?.accessToken;

  Future<void> restoreSession() async {
    emit(const AuthState.restoring());
    try {
      final stored = await _store.read();
      if (stored == null) {
        emit(const AuthState.unauthenticated());
        return;
      }

      _session = stored;
      _rememberSession = true;
      _sessionGeneration += 1;
      if (stored.isAccessTokenUsable()) {
        emit(AuthState.authenticated(stored));
        return;
      }

      if (!stored.isRefreshTokenUsable()) {
        await clearSession();
        return;
      }
      await refreshSession();
    } catch (_) {
      await clearSession();
    }
  }

  Future<String?> login(
    String username,
    String password,
    bool rememberMe,
  ) async {
    if (_loginInProgress) return 'A sign-in request is already in progress.';
    _loginInProgress = true;
    try {
      final session = await _service.login(
        username: username,
        password: password,
      );
      if (rememberMe) {
        await _store.write(session);
      } else {
        await _store.clear();
      }

      _rememberSession = rememberMe;
      _session = session;
      _sessionGeneration += 1;
      emit(AuthState.authenticated(session));
      return null;
    } on AuthException catch (error) {
      return error.message;
    } catch (_) {
      return 'Unable to store the authenticated session securely.';
    } finally {
      _loginInProgress = false;
    }
  }

  Future<bool> refreshSession() {
    final running = _refreshOperation;
    if (running != null) return running;

    final operation = _performRefresh();
    _refreshOperation = operation;
    return operation.whenComplete(() {
      if (identical(_refreshOperation, operation)) _refreshOperation = null;
    });
  }

  Future<bool> _performRefresh() async {
    final current = _session;
    final generation = _sessionGeneration;
    if (current == null || !current.isRefreshTokenUsable()) {
      await clearSession();
      return false;
    }

    try {
      final refreshed = await _service.refreshSession(current);
      if (!_isCurrentSession(current, generation)) return false;
      if (_rememberSession) await _store.write(refreshed);
      if (!_isCurrentSession(current, generation)) return false;
      _session = refreshed;
      emit(AuthState.authenticated(refreshed));
      return true;
    } catch (_) {
      if (_isCurrentSession(current, generation)) await clearSession();
      return false;
    }
  }

  Future<void> logout() async {
    final current = _session;
    final runningRefresh = _refreshOperation;
    _invalidateInMemorySession();
    try {
      if (current != null) await _service.logout(current.accessToken);
    } catch (_) {
      // Local logout must succeed even when the backend request fails.
    } finally {
      if (runningRefresh != null) {
        try {
          await runningRefresh;
        } catch (_) {
          // Refresh errors are handled by the refresh operation itself.
        }
      }
      try {
        await _store.clear();
      } catch (_) {
        // The in-memory session has already been invalidated.
      }
    }
  }

  Future<void> clearSession() async {
    _invalidateInMemorySession();
    try {
      await _store.clear();
    } catch (_) {
      // In-memory logout and AuthGate transition must still complete.
    }
  }

  bool _isCurrentSession(AuthSession session, int generation) {
    return generation == _sessionGeneration && identical(_session, session);
  }

  void _invalidateInMemorySession() {
    _sessionGeneration += 1;
    _session = null;
    _rememberSession = false;
    if (!isClosed) emit(const AuthState.unauthenticated());
  }

  @override
  Future<void> close() {
    _service.close();
    return super.close();
  }
}
