import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Shell background plus the white rounded panel every light page sits on.
///
/// The account bar is drawn by the app shell above this, so the panel only
/// rounds its top corners and runs to the bottom of the viewport.
class AppPageSurface extends StatelessWidget {
  const AppPageSurface({
    super.key,
    required this.child,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;

  /// Inner padding. Pages that scroll usually pass [EdgeInsets.zero] here and
  /// let their scroll view own the padding instead.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.shell,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
