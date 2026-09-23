import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Numbered pager with prev/next arrows, shared by the light pages' tables.
class AppPagination extends StatelessWidget {
  const AppPagination({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
    this.alignment = MainAxisAlignment.center,
  });

  /// Zero-based index of the current page.
  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;
  final MainAxisAlignment alignment;

  /// Number pages shown at once; the window slides to keep [page] visible.
  static const int _windowSize = 4;

  @override
  Widget build(BuildContext context) {
    var start = page - _windowSize ~/ 2;
    if (start > pageCount - _windowSize) start = pageCount - _windowSize;
    if (start < 0) start = 0;
    final end = (start + _windowSize).clamp(0, pageCount);

    return Row(
      mainAxisAlignment: alignment,
      children: [
        _PageButton(
          icon: Icons.chevron_left_rounded,
          onTap: page > 0 ? () => onPageChanged(page - 1) : null,
        ),
        for (var index = start; index < end; index++) ...[
          const SizedBox(width: 6),
          _PageButton(
            label: '${index + 1}',
            selected: index == page,
            onTap: () => onPageChanged(index),
          ),
        ],
        const SizedBox(width: 6),
        _PageButton(
          icon: Icons.chevron_right_rounded,
          onTap: page < pageCount - 1 ? () => onPageChanged(page + 1) : null,
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    this.label,
    this.icon,
    this.selected = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final foreground = selected
        ? Colors.white
        : enabled
        ? AppColors.textPrimary
        : AppColors.textMuted;

    return Material(
      color: selected ? AppColors.navy : AppColors.surface,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: selected ? AppColors.navy : AppColors.cardBorder,
            ),
          ),
          child: icon != null
              ? Icon(icon, size: 16, color: foreground)
              : Text(
                  label!,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
