import 'package:fleet_dashboard/theme/auth_colors.dart';
import 'package:fleet_dashboard/widgets/auth/auth_brand.dart';
import 'package:fleet_dashboard/widgets/auth/auth_text_field.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

typedef RegisterSubmit =
    Future<void> Function({
      required String fullname,
      required String username,
      required String password,
      required String role,
      required String division,
    });

class RegisterForm extends StatefulWidget {
  const RegisterForm({
    super.key,
    this.onSubmit,
    this.onSignIn,
    this.showBrand = false,
  });

  final RegisterSubmit? onSubmit;
  final VoidCallback? onSignIn;
  final bool showBrand;

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  final _formKey = GlobalKey<FormState>();

  final _fullnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _divisionController = TextEditingController();

  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  bool _termsAccepted = false;
  bool _isSubmitting = false;

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
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _divisionController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) {
      return;
    }

    FocusScope.of(context).unfocus();

    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (!_termsAccepted) {
      _showMessage('Please agree to the Terms of Service and Privacy Policy.');
      return;
    }

    if (widget.onSubmit == null) {
      _showMessage('Register UI is ready to connect to AuthService.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await widget.onSubmit!(
        fullname: _fullnameController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole!,
        division: _divisionController.text.trim(),
      );
    } on AuthException catch (error) {
      if (mounted) {
        _showMessage(error.message);
      }
    } catch (_) {
      if (mounted) {
        _showMessage('Unable to create account. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showBrand) ...[
                    const AuthBrand(compact: true),
                    const SizedBox(height: 30),
                  ],

                  _buildSignInLink(),

                  const SizedBox(height: 10),

                  const Text(
                    'Create your account',
                    style: TextStyle(
                      color: AuthColors.textPrimary,
                      fontSize: 31,
                      height: 1.15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Fill in the details below to create your FleetSafe account.',
                    style: TextStyle(color: AuthColors.muted, fontSize: 13),
                  ),

                  const SizedBox(height: 28),

                  _sectionTitle('Personal Information'),

                  const SizedBox(height: 12),

                  _responsiveFields(_fullNameField(), _usernameField()),

                  const SizedBox(height: 28),

                  const Divider(color: AuthColors.border),

                  const SizedBox(height: 22),

                  _sectionTitle('Account Information'),

                  const SizedBox(height: 12),

                  _responsiveFields(_passwordField(), _confirmPasswordField()),

                  const SizedBox(height: 18),

                  _responsiveFields(_roleDropdown(), _divisionField()),

                  const SizedBox(height: 28),

                  _terms(),

                  const SizedBox(height: 24),

                  _submitButton(),

                  const SizedBox(height: 22),

                  _divider(),

                  const SizedBox(height: 22),

                  _ssoButton(),

                  const SizedBox(height: 34),

                  _securityFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fullNameField() {
    return _labeledField(
      label: 'Full Name',
      child: AuthTextField(
        controller: _fullnameController,
        hintText: 'Enter your full name',
        prefixIcon: Icons.person_outline,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.name],
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Full name is required';
          }

          return null;
        },
      ),
    );
  }

  Widget _usernameField() {
    return _labeledField(
      label: 'Email / Employee ID',
      child: AuthTextField(
        controller: _usernameController,
        hintText: 'Enter your email or employee ID',
        prefixIcon: Icons.badge_outlined,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Email or Employee ID is required';
          }

          return null;
        },
      ),
    );
  }

  Widget _passwordField() {
    return _labeledField(
      label: 'Password',
      child: AuthTextField(
        controller: _passwordController,
        hintText: 'Create a strong password',
        prefixIcon: Icons.lock_outline,
        obscureText: !_passwordVisible,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        suffixIcon: IconButton(
          tooltip: _passwordVisible ? 'Hide password' : 'Show password',
          onPressed: () {
            setState(() {
              _passwordVisible = !_passwordVisible;
            });
          },
          icon: Icon(
            _passwordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 19,
            color: AuthColors.muted,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Password is required';
          }

          if (value.length < 8) {
            return 'Minimum 8 characters';
          }

          return null;
        },
      ),
    );
  }

  Widget _confirmPasswordField() {
    return _labeledField(
      label: 'Confirm Password',
      child: AuthTextField(
        controller: _confirmPasswordController,
        hintText: 'Confirm your password',
        prefixIcon: Icons.lock_outline,
        obscureText: !_confirmPasswordVisible,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.newPassword],
        suffixIcon: IconButton(
          tooltip: _confirmPasswordVisible ? 'Hide password' : 'Show password',
          onPressed: () {
            setState(() {
              _confirmPasswordVisible = !_confirmPasswordVisible;
            });
          },
          icon: Icon(
            _confirmPasswordVisible
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            size: 19,
            color: AuthColors.muted,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please confirm your password';
          }

          if (value != _passwordController.text) {
            return 'Passwords do not match';
          }

          return null;
        },
      ),
    );
  }

  Widget _divisionField() {
    return _labeledField(
      label: 'Division',
      child: AuthTextField(
        controller: _divisionController,
        hintText: 'Enter your division',
        prefixIcon: Icons.account_tree_outlined,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) {
          if (!_isSubmitting) {
            _submit();
          }
        },
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Division is required';
          }

          return null;
        },
      ),
    );
  }

  Widget _roleDropdown() {
    return _labeledField(
      label: 'Role / Position',
      child: DropdownButtonFormField<String>(
        initialValue: _selectedRole,
        isExpanded: true,
        style: const TextStyle(color: AuthColors.textPrimary, fontSize: 15),
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AuthColors.muted,
        ),
        decoration: InputDecoration(
          hintText: 'Select your role',
          hintStyle: const TextStyle(
            fontSize: 15,
            color: AuthColors.placeholder,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 19,
          ),
          enabledBorder: _fieldBorder(AuthColors.border),
          focusedBorder: _fieldBorder(AuthColors.brandBlue, width: 1.4),
          errorBorder: _fieldBorder(AuthColors.danger),
          focusedErrorBorder: _fieldBorder(AuthColors.danger, width: 1.4),
        ),
        items: _roles.map((role) {
          return DropdownMenuItem<String>(value: role, child: Text(role));
        }).toList(),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please select your role';
          }

          return null;
        },
        onChanged: _isSubmitting
            ? null
            : (value) {
                setState(() {
                  _selectedRole = value;
                });
              },
      ),
    );
  }

  Widget _labeledField({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AuthColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }

  Widget _responsiveFields(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 580) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 18),
              Expanded(child: right),
            ],
          );
        }

        return Column(children: [left, const SizedBox(height: 18), right]);
      },
    );
  }

  Widget _buildSignInLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Text(
            'Already have an account? ',
            style: TextStyle(color: AuthColors.muted, fontSize: 12),
          ),
          TextButton(
            onPressed: _isSubmitting ? null : widget.onSignIn,
            style: TextButton.styleFrom(
              foregroundColor: AuthColors.brandBlue,
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
            ),
            child: const Text(
              'Sign in',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AuthColors.textPrimary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _terms() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _termsAccepted,
            activeColor: AuthColors.brandBlue,
            side: const BorderSide(color: AuthColors.border),
            onChanged: _isSubmitting
                ? null
                : (value) {
                    setState(() {
                      _termsAccepted = value ?? false;
                    });
                  },
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'I agree to the '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: AuthColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AuthColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            style: TextStyle(color: AuthColors.muted, fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton(
        onPressed: _isSubmitting ? null : _submit,
        style: FilledButton.styleFrom(
          backgroundColor: AuthColors.brandBlue,
          disabledBackgroundColor: AuthColors.brandBlue.withValues(alpha: 0.55),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _isSubmitting
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
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  SizedBox(width: 12),
                  Icon(Icons.arrow_forward, size: 19),
                ],
              ),
      ),
    );
  }

  Widget _divider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AuthColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or sign up with',
            style: TextStyle(color: AuthColors.muted, fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: AuthColors.border)),
      ],
    );
  }

  Widget _ssoButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        // Backend SSO belum tersedia.
        onPressed: null,
        icon: const Icon(Icons.apartment_outlined, size: 20),
        label: const Text(
          'Sign up with Company SSO',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          disabledForegroundColor: AuthColors.brandBlue.withValues(alpha: 0.65),
          side: BorderSide(color: AuthColors.brandBlue.withValues(alpha: 0.30)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _securityFooter() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFD),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: const Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield_outlined, size: 16, color: AuthColors.muted),
              SizedBox(width: 8),
              Text(
                'FleetSafe is a secure system.',
                style: TextStyle(
                  color: AuthColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'All data is protected and monitored.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AuthColors.muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}
