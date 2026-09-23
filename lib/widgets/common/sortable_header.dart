import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum SortDirection { ascending, descending }

/// Which column a table is sorted by, and which way.
@immutable
class ColumnSort<K> {
  const ColumnSort(this.column, this.direction);

  final K column;
  final SortDirection direction;

  bool get isAscending => direction == SortDirection.ascending;

  ColumnSort<K> flipped() => ColumnSort(
    column,
    isAscending ? SortDirection.descending : SortDirection.ascending,
  );

  /// Applies this direction to a comparison written in ascending order.
  int order(int comparison) => isAscending ? comparison : -comparison;

  @override
  bool operator ==(Object other) =>
      other is ColumnSort<K> &&
      other.column == column &&
      other.direction == direction;

  @override
  int get hashCode => Object.hash(column, direction);
}

/// Tapping a [SortableHeader] hands back the next sort for the whole table.
typedef SortChanged<K> = void Function(ColumnSort<K> sort);

/// A column header that sorts the table when clicked.
///
/// The arrow is the control, not decoration: it points the way the column is
/// currently sorted, and shows a dimmed double-chevron on the columns that
/// could be sorted but are not. Clicking the active column flips it; clicking
/// any other switches to it using that column's own natural first direction —
/// times want newest first, names want A-Z.
class SortableHeader<K> extends StatefulWidget {
  const SortableHeader({
    super.key,
    required this.label,
    required this.column,
    required this.sort,
    required this.onSort,
    this.firstDirection = SortDirection.ascending,
    this.textStyle,
    this.iconSize = 11,
  });

  final String label;
  final K column;

  /// The table's current sort, whichever column it is on.
  final ColumnSort<K>? sort;
  final SortChanged<K> onSort;

  /// Direction to use the first time this column is picked.
  final SortDirection firstDirection;

  final TextStyle? textStyle;
  final double iconSize;

  @override
  State<SortableHeader<K>> createState() => _SortableHeaderState<K>();
}

class _SortableHeaderState<K> extends State<SortableHeader<K>> {
  bool _hovered = false;

  bool get _isActive => widget.sort?.column == widget.column;

  void _handleTap() {
    final sort = widget.sort;
    widget.onSort(
      _isActive && sort != null
          ? sort.flipped()
          : ColumnSort(widget.column, widget.firstDirection),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base =
        widget.textStyle ??
        const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          height: 1.25,
        );

    final active = _isActive;
    final labelColour = active
        ? AppColors.blue
        : (_hovered ? AppColors.textPrimary : base.color);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Tooltip(
          message: active
              ? 'Sorted by ${widget.label}, '
                    '${widget.sort!.isAscending ? 'ascending' : 'descending'}'
                    ' — click to reverse'
              : 'Sort by ${widget.label}',
          waitDuration: const Duration(milliseconds: 400),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: base.copyWith(
                    color: labelColour,
                    fontWeight: active ? FontWeight.w700 : base.fontWeight,
                  ),
                ),
              ),
              const SizedBox(width: 3),
              Icon(
                active
                    ? (widget.sort!.isAscending
                          ? Icons.arrow_upward_rounded
                          : Icons.arrow_downward_rounded)
                    // Dimmed until it means something: a plain down arrow on
                    // an unsorted column claims an order the table does not
                    // actually have.
                    : Icons.unfold_more_rounded,
                size: widget.iconSize,
                color: active
                    ? AppColors.blue
                    // Muted, but never invisible: an arrow the eye cannot
                    // find is the same as no arrow at all, and nobody
                    // discovers a column is sortable by guessing.
                    : (_hovered
                          ? AppColors.textSecondary
                          : AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
