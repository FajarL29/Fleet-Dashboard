import 'package:fleet_dashboard/services/auth_service.dart';
import 'package:fleet_dashboard/widgets/register/register_form.dart';
import 'package:fleet_dashboard/widgets/register/register_left_panel.dart';
import 'package:flutter/material.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.authService, this.onSignIn});

  final AuthService authService;
  final VoidCallback? onSignIn;

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  Future<void> _handleRegister({
    required String fullname,
    required String username,
    required String password,
    required String role,
    required String division,
  }) async {
    await widget.authService.register(
      fullname: fullname,
      username: username,
      password: password,
      role: role,
      division: division,
    );

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Account created successfully. Please sign in.'),
      ),
    );

    widget.onSignIn?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 1050;

          if (!isDesktop) {
            return SafeArea(
              child: RegisterForm(
                showBrand: true,
                onSignIn: widget.onSignIn,
                onSubmit: _handleRegister,
              ),
            );
          }

          return Row(
            children: [
              const Expanded(child: RegisterLeftPanel()),
              Expanded(
                child: SafeArea(
                  child: RegisterForm(
                    onSignIn: widget.onSignIn,
                    onSubmit: _handleRegister,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
