import 'package:flutter/material.dart';

import '../../theme/auth_colors.dart';

/// A labelled field, sized so a whole registration form fits on one screen.
///
/// The label lives here rather than at each call site so every field on both
/// pages has the same label-to-box spacing — that consistency is what lets the
/// sign-in and sign-up forms line up row for row.
class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.label,
    required this.controller,
    required this.hintText,
    this.prefixIcon,
    this.required = true,
    this.obscureText = false,
    this.onSubmitted,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
  });

  final String label;

  /// Marks the label with an asterisk. Every field on these forms is required,
  /// so the marker is on by default and the caller opts out.
  final bool required;

  final TextEditingController controller;
  final String hintText;
  final IconData? prefixIcon;
  final bool obscureText;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  /// Height of the input box, shared with [AuthDropdownField] so a text field
  /// and a dropdown sitting side by side are the same size.
  static const double fieldHeight = 46;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AuthFieldLabel(label: label, required: required),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          onFieldSubmitted: onSubmitted,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          enableSuggestions: !obscureText,
          autocorrect: false,
          style: const TextStyle(color: AuthColors.textPrimary, fontSize: 14),
          decoration: authInputDecoration(
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}

/// A field label, with the asterisk that marks it required.
class AuthFieldLabel extends StatelessWidget {
  const AuthFieldLabel({super.key, required this.label, this.required = true});

  final String label;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: AuthColors.danger),
            ),
        ],
      ),
      style: const TextStyle(
        color: AuthColors.textPrimary,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// The one input decoration both the text fields and the role dropdown use.
InputDecoration authInputDecoration({
  required String hintText,
  IconData? prefixIcon,
  Widget? suffixIcon,
}) {
  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(9),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(fontSize: 14, color: AuthColors.placeholder),
    prefixIcon: prefixIcon == null
        ? null
        : Icon(prefixIcon, color: AuthColors.muted, size: 19),
    prefixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
    suffixIcon: suffixIcon,
    suffixIconConstraints: const BoxConstraints(minWidth: 42, minHeight: 42),
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    // Errors show under the box; reserving no extra room keeps the two columns
    // aligned until one of them actually has something to say.
    errorStyle: const TextStyle(fontSize: 11.5, height: 1.1),
    enabledBorder: border(AuthColors.border),
    focusedBorder: border(AuthColors.brandBlue, width: 1.4),
    errorBorder: border(AuthColors.danger),
    focusedErrorBorder: border(AuthColors.danger, width: 1.4),
  );
}
