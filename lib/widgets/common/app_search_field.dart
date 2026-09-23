import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Bordered search box used in the light pages' headers.
class AppSearchField extends StatelessWidget {
  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.height = 40,
  });

  final TextEditingController controller;
  final String hintText;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        cursorColor: AppColors.blue,
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: AppColors.surface,
          hintText: hintText,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: AppColors.textMuted,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 38,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 11),
          enabledBorder: _border(AppColors.cardBorder),
          focusedBorder: _border(AppColors.blue),
          border: _border(AppColors.cardBorder),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(8),
    borderSide: BorderSide(color: color),
  );
}
