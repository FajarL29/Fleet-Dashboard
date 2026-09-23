import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';
import 'auth_actions.dart';
import 'auth_shell.dart';
import 'auth_text_field.dart';

/// The sign-in half of the auth page: the right-hand column, nothing else.
///
/// It shares its heading, field, button and divider metrics with
/// [RegisterForm] through the widgets in `auth_shell.dart` and
/// `auth_actions.dart`, so toggling between the two moves the words without
/// moving the furniture.
class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    this.onSignIn,
    this.onForgotPassword,
    this.onCompanySso,
  });

  final Future<String?> Function(
    String username,
    String password,
    bool rememberMe,
  )?
  onSignIn;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onCompanySso;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  /// The design has no "remember me" control, so the choice is made here.
  /// Staying signed in is what makes the stored session and the silent token
  /// refresh worth having; a shared workstation would want this false.
  static const bool _rememberMe = true;

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _submitError;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_isLoading) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (widget.onSignIn == null) return;

    setState(() {
      _isLoading = true;
      _submitError = null;
    });
    try {
      final error = await widget.onSignIn!.call(
        _usernameController.text.trim(),
        _passwordController.text,
        _rememberMe,
      );
      if (mounted && error != null) setState(() => _submitError = error);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AutofillGroup(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthFormHeader(
              title: 'Welcome back 👋',
              subtitle: 'Log in to continue to FleetSafe',
            ),
            const SizedBox(height: 80),

            // Labelled Employee ID, not "Full Name" as the mockup has it: this
            // is the value the API authenticates on, and it is the same one
            // the sign-up form collects. Ask for a full name here and people
            // type their name and cannot get in.
            AuthTextField(
              label: 'Employee ID',
              controller: _usernameController,
              hintText: 'Enter your employee ID',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Employee ID is required'
                  : null,
            ),
            const SizedBox(height: 24),

            AuthTextField(
              label: 'Password',
              controller: _passwordController,
              hintText: 'Enter your Password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              onSubmitted: (_) => _signIn(),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (value) => value == null || value.isEmpty
                  ? 'Password is required'
                  : null,
              suffixIcon: AuthVisibilityToggle(
                obscured: _obscurePassword,
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),

            if (_submitError != null) ...[
              const SizedBox(height: 12),
              AuthErrorBanner(message: _submitError!),
            ],

            const SizedBox(height: 12),
            _ForgotPasswordLink(onPressed: widget.onForgotPassword),

            const SizedBox(height: 120),
            AuthPrimaryButton(
              label: 'Log in',
              busy: _isLoading,
              onPressed: widget.onSignIn == null ? null : _signIn,
            ),

            const SizedBox(height: 20),
            const AuthOrDivider(label: 'or'),
            const SizedBox(height: 20),

            AuthSsoButton(
              label: 'Sign up with Company SSO',
              onPressed: widget.onCompanySso,
            ),
          ],
        ),
      ),
    );
  }
}

/// The "Forgot your password?" link, right-aligned under the password field.
class _ForgotPasswordLink extends StatelessWidget {
  const _ForgotPasswordLink({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Tooltip(
        message: onPressed == null
            ? 'Password recovery is not available yet'
            : '',
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AuthColors.brandBlue,
            disabledForegroundColor: AuthColors.muted,
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Forgot your password?',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
