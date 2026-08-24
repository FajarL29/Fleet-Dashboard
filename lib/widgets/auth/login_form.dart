import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';
import 'auth_divider.dart';
import 'auth_text_field.dart';

class LoginForm extends StatefulWidget {
  const LoginForm({
    super.key,
    this.onSignIn,
    this.onCreateAccount,
    this.onForgotPassword,
    this.onCompanySso,
  });

  final Future<String?> Function(
    String username,
    String password,
    bool rememberMe,
  )?
  onSignIn;
  final VoidCallback? onCreateAccount;
  final VoidCallback? onForgotPassword;
  final VoidCallback? onCompanySso;

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _submitError;

  @override
  void dispose() {
    _emailController.dispose();
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
        _emailController.text.trim(),
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
            const Text(
              'Welcome back',
              style: TextStyle(
                color: AuthColors.textPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w700,
                height: 1.15,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sign in to continue to FleetSafe',
              style: TextStyle(color: AuthColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 46),
            const _FieldLabel(label: 'Username'),
            const SizedBox(height: 10),
            AuthTextField(
              controller: _emailController,
              hintText: 'Enter your username',
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.username],
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Username is required'
                  : null,
            ),
            const SizedBox(height: 28),
            const _FieldLabel(label: 'Password'),
            const SizedBox(height: 10),
            AuthTextField(
              controller: _passwordController,
              hintText: 'Enter your password',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              onSubmitted: (_) => _signIn(),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              validator: (value) => value == null || value.isEmpty
                  ? 'Password is required'
                  : null,
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AuthColors.muted,
                  size: 22,
                ),
              ),
            ),
            if (_submitError != null) ...[
              const SizedBox(height: 14),
              _LoginError(message: _submitError!),
            ],
            const SizedBox(height: 22),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 24,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: Checkbox(
                        value: _rememberMe,
                        side: const BorderSide(color: AuthColors.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        activeColor: AuthColors.brandBlue,
                        onChanged: (value) =>
                            setState(() => _rememberMe = value ?? false),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Remember me',
                      style: TextStyle(
                        color: AuthColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Tooltip(
                  message: widget.onForgotPassword == null
                      ? 'Password recovery is not available yet'
                      : '',
                  child: TextButton(
                    onPressed: widget.onForgotPassword,
                    style: TextButton.styleFrom(
                      foregroundColor: AuthColors.brandBlue,
                      disabledForegroundColor: AuthColors.muted,
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading || widget.onSignIn == null
                    ? null
                    : _signIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AuthColors.brandBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AuthColors.brandBlue.withValues(
                    alpha: 0.65,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 14),
                          Icon(Icons.arrow_forward_rounded, size: 21),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(
                    color: AuthColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                TextButton(
                  onPressed: _isLoading ? null : widget.onCreateAccount,
                  style: TextButton.styleFrom(
                    foregroundColor: AuthColors.brandBlue,
                    disabledForegroundColor: AuthColors.muted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                  ),
                  child: const Text(
                    'Create an account',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const AuthDivider(),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 58,
              child: OutlinedButton(
                onPressed: widget.onCompanySso,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AuthColors.brandBlue,
                  disabledForegroundColor: AuthColors.muted,
                  side: BorderSide(
                    color: widget.onCompanySso == null
                        ? AuthColors.borderStrong
                        : AuthColors.brandBlue,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.apartment_rounded, size: 23),
                    SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        'Company Account (SSO) unavailable',
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shield_rounded,
                      color: AuthColors.muted,
                      size: 20,
                    ),
                    SizedBox(width: 9),
                    Flexible(
                      child: Text(
                        'FleetSafe is a secure system for authorized users only.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AuthColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Text(
                  'All data is protected and monitored.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AuthColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LoginError extends StatelessWidget {
  const _LoginError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AuthColors.danger.withValues(alpha: 0.08),
        border: Border.all(color: AuthColors.danger.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: AuthColors.danger),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AuthColors.danger, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AuthColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
