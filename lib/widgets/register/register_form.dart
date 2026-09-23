import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';
import '../auth/auth_actions.dart';
import '../auth/auth_shell.dart';
import '../auth/auth_text_field.dart';

/// What [RegisterForm] hands back on submit.
///
/// `username` carries the Employee ID and `division` the Department: the form
/// uses the words the company does, the API uses its own, and this typedef is
/// the one place the two vocabularies meet.
typedef RegisterSubmit =
    Future<void> Function({
      required String fullname,
      required String username,
      required String password,
      required String role,
      required String division,
    });

/// The sign-up half of the auth page: the right-hand column, nothing else.
///
/// Built from the same header, field, button and divider widgets as the login
/// form, so the two pages differ only in the rows between them.
class RegisterForm extends StatefulWidget {
  const RegisterForm({super.key, this.onSubmit, this.onCompanySso});

  final RegisterSubmit? onSubmit;
  final VoidCallback? onCompanySso;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final _fullnameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _departmentController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _termsAccepted = false;
  bool _isSubmitting = false;
  String? _submitError;
  String? _selectedRole;

  static const List<String> _roles = [
    'UI/UX Engineer',
    'Software Engineer',
    'Data Engineer',
    'QA Engineer',
    'System Engineer',
    'Supervisor',
    'Manager',
    'Other',
  ];

  @override
  void dispose() {
    _fullnameController.dispose();
    _employeeIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_termsAccepted) {
      setState(() {
        _submitError =
            'Please agree to the Terms of Service and Privacy Policy.';
      });
      return;
    }
    if (widget.onSubmit == null) return;

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      await widget.onSubmit!(
        fullname: _fullnameController.text.trim(),
        username: _employeeIdController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole!,
        division: _departmentController.text.trim(),
      );
    } catch (error) {
      // Shown inline rather than in a snack bar: a snack bar covers the button
      // it is complaining about and is gone before it has been read.
      if (mounted) setState(() => _submitError = _messageFor(error));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// Strips the `Exception:` prefix Dart puts in front of `toString`, so the
  /// server's own wording reaches the user unadorned.
  static String _messageFor(Object error) {
    final cleaned = '$error'
        .replaceFirst(RegExp(r'^\w*Exception(\([^)]*\))?:?\s*'), '')
        .trim();
    return cleaned.isEmpty
        ? 'Unable to create the account. Please try again.'
        : cleaned;
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
              title: 'Create your account',
              subtitle:
                  'Fill in the details below to create your FleetSafe account.',
            ),
            const SizedBox(height: 32),

            const AuthSectionTitle('Personal Information'),
            const SizedBox(height: 12),
            AuthFieldRow(
              left: AuthTextField(
                label: 'Name',
                controller: _fullnameController,
                hintText: 'Enter your full name',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Name is required'
                    : null,
              ),
              right: AuthTextField(
                label: 'Employee ID',
                controller: _employeeIdController,
                hintText: 'Enter your employee ID',
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Employee ID is required'
                    : null,
              ),
            ),

            const SizedBox(height: 26),
            const Divider(color: AuthColors.border, height: 1),
            const SizedBox(height: 24),

            const AuthSectionTitle('Account Information'),
            const SizedBox(height: 12),
            AuthFieldRow(
              left: AuthTextField(
                label: 'Password',
                controller: _passwordController,
                hintText: 'Create a strong password',
                obscureText: !_passwordVisible,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.newPassword],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 8) return 'Use at least 8 characters';
                  return null;
                },
                suffixIcon: AuthVisibilityToggle(
                  obscured: !_passwordVisible,
                  onPressed: () =>
                      setState(() => _passwordVisible = !_passwordVisible),
                ),
              ),
              right: AuthTextField(
                label: 'Confirm Password',
                controller: _confirmPasswordController,
                hintText: 'Re-enter your password',
                obscureText: !_confirmPasswordVisible,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm your password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
                suffixIcon: AuthVisibilityToggle(
                  obscured: !_confirmPasswordVisible,
                  onPressed: () => setState(
                    () => _confirmPasswordVisible = !_confirmPasswordVisible,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
            AuthFieldRow(
              left: _RoleDropdown(
                value: _selectedRole,
                items: _roles,
                onChanged: (value) => setState(() => _selectedRole = value),
              ),
              // Free text, not a dropdown: departments differ per site, and a
              // fixed list would push people into the nearest wrong one.
              right: AuthTextField(
                label: 'Department',
                controller: _departmentController,
                hintText: 'Enter your department',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Department is required'
                    : null,
              ),
            ),

            if (_submitError != null) ...[
              const SizedBox(height: 14),
              AuthErrorBanner(message: _submitError!),
            ],

            const SizedBox(height: 32),
            AuthCheckboxRow(
              value: _termsAccepted,
              onChanged: (value) => setState(() => _termsAccepted = value),
              child: const Text(
                'I agree to the Terms of Service and Privacy Policy',
                style: TextStyle(
                  color: AuthColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 20),
            AuthPrimaryButton(
              label: 'Create Account',
              busy: _isSubmitting,
              onPressed: widget.onSubmit == null ? null : _submit,
            ),

            const SizedBox(height: 18),
            const AuthOrDivider(label: 'or sign up with'),
            const SizedBox(height: 18),

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

/// The role picker, dressed to match [AuthTextField] exactly so the pair sits
/// level in its row.
class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AuthFieldLabel(label: 'Role'),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          style: const TextStyle(color: AuthColors.textPrimary, fontSize: 14),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AuthColors.muted,
            size: 20,
          ),
          decoration: authInputDecoration(hintText: 'Select your role'),
          items: items
              .map(
                (role) => DropdownMenuItem<String>(
                  value: role,
                  child: Text(role, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          validator: (value) =>
              value == null || value.isEmpty ? 'Role is required' : null,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
