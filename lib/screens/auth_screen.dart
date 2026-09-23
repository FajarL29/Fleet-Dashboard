import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/auth_colors.dart';
import '../widgets/auth/auth_shell.dart';
import '../widgets/auth/login_form.dart';
import '../widgets/register/register_form.dart';

/// Which half of the auth page is showing.
enum AuthMode { login, register }

/// The single page behind both signing in and signing up.
///
/// The two used to be separate routes, which meant pushing a whole new screen —
/// and a second, different brand panel — just to change the words on the right.
/// Keeping one page and swapping only the form makes the toggle instant, keeps
/// the animation on the left running, and leaves one copy of the layout.
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    this.onSignIn,
    this.authService,
    this.initialMode = AuthMode.login,
  });

  final Future<String?> Function(
    String username,
    String password,
    bool rememberMe,
  )?
  onSignIn;

  /// Used for registration only. Defaults to the shared instance; tests and
  /// [AuthGate] pass their own.
  final AuthService? authService;

  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode = widget.initialMode;

  /// Shown above the sign-in form after an account has just been created.
  String? _notice;

  AuthService get _authService => widget.authService ?? AuthService.instance;

  void _switchTo(AuthMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      _notice = null;
    });
  }

  Future<void> _register({
    required String fullname,
    required String username,
    required String password,
    required String role,
    required String division,
  }) async {
    await _authService.register(
      fullname: fullname,
      username: username,
      password: password,
      role: role,
      division: division,
    );

    if (!mounted) return;

    // The API creates the account but does not sign anyone in, so the new user
    // lands back on the sign-in form with their Employee ID already known.
    setState(() {
      _mode = AuthMode.login;
      _notice = 'Account created. Sign in with your Employee ID to continue.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLogin = _mode == AuthMode.login;

    return AuthShell(
      switchPrompt: isLogin
          ? "Don't have an account?"
          : 'Already have an account?',
      switchAction: isLogin ? 'Sign Up' : 'Log in',
      onSwitch: () => _switchTo(isLogin ? AuthMode.register : AuthMode.login),
      showLegalFooter: isLogin,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        // Fade only. A slide would drag the eye across the seam the shell
        // exists to hide.
        transitionBuilder: (child, animation) =>
            FadeTransition(opacity: animation, child: child),
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: isLogin
            ? Column(
                key: const ValueKey(AuthMode.login),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_notice != null) ...[
                    _AccountCreatedNotice(message: _notice!),
                    const SizedBox(height: 16),
                  ],
                  LoginForm(onSignIn: widget.onSignIn),
                ],
              )
            : RegisterForm(
                key: const ValueKey(AuthMode.register),
                onSubmit: _register,
              ),
      ),
    );
  }
}

/// Confirmation banner shown on the sign-in form after registering.
class _AccountCreatedNotice extends StatelessWidget {
  const _AccountCreatedNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AuthColors.successSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AuthColors.success),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AuthColors.successText,
            size: 17,
          ),
          const SizedBox(width: 9),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: AuthColors.successText,
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
