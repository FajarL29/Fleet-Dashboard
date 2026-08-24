import 'package:flutter/material.dart';

import '../theme/auth_colors.dart';
import '../widgets/auth/fleet_brand_panel.dart';
import '../widgets/auth/fleet_safe_logo.dart';
import '../widgets/auth/login_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
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
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 1050) {
            return _buildMobileLayout();
          }
          return Row(
            children: [
              const Expanded(flex: 53, child: FleetBrandPanel()),
              Expanded(flex: 47, child: _buildDesktopForm()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: FleetSafeLogo(compact: true),
            ),
            const SizedBox(height: 36),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: LoginForm(
                onSignIn: widget.onSignIn,
                onCreateAccount: widget.onCreateAccount,
                onForgotPassword: widget.onForgotPassword,
                onCompanySso: widget.onCompanySso,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopForm() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 32, right: 42),
              child: _buildLanguageSelector(),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(48, 24, 48, 48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 535),
                child: LoginForm(
                  onSignIn: widget.onSignIn,
                  onCreateAccount: widget.onCreateAccount,
                  onForgotPassword: widget.onForgotPassword,
                  onCompanySso: widget.onCompanySso,
                ),
              ),
            ),
          ),
          const _FooterArea(),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AuthColors.border),
        borderRadius: BorderRadius.circular(9),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _language,
          style: const TextStyle(color: AuthColors.textPrimary, fontSize: 14),
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AuthColors.muted,
          ),
          borderRadius: BorderRadius.circular(10),
          items: const [
            DropdownMenuItem(
              value: 'English',
              child: _LanguageOption(label: 'English'),
            ),
            DropdownMenuItem(
              value: 'Bahasa',
              child: _LanguageOption(label: 'Bahasa'),
            ),
          ],
          onChanged: null,
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.language_rounded, size: 20, color: AuthColors.muted),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(color: AuthColors.textPrimary)),
      ],
    );
  }
}

class _FooterArea extends StatelessWidget {
  const _FooterArea();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AuthColors.footer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: const Text(
        '© 2026 FleetSafe. All rights reserved.',
        style: TextStyle(color: AuthColors.muted, fontSize: 12),
      ),
    );
  }
}
