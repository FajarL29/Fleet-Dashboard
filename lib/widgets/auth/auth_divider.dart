import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AuthColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 22),
          child: Text(
            'or continue with',
            style: TextStyle(color: AuthColors.muted, fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: AuthColors.border)),
      ],
    );
  }
}
