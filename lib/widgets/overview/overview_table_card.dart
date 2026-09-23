import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import '../common/sortable_header.dart';

/// Builds one row of cells, in the same order as the card's header columns.
typedef OverviewTableRowBuilder =
    List<Widget> Function(BuildContext context, int index);

class OverviewTableCard extends StatelessWidget {
  const OverviewTableCard({
    super.key,
    required this.title,
    required this.onViewAll,
    required this.headers,
    required this.flex,
    required this.rowCount,
    required this.rowBuilder,
    required this.emptyMessage,
    this.sort,
    this.onSort,
  });

  final String title;
  final VoidCallback onViewAll;
  final List<OverviewTableColumn> headers;
  final List<int> flex;
  final int rowCount;
  final OverviewTableRowBuilder rowBuilder;
  final String emptyMessage;

  /// Current sort, by column index. Null on a table with no sortable columns.
  final ColumnSort<int>? sort;
  final SortChanged<int>? onSort;

  /// Fixed width for a leading column declared with flex 0 (the "No" column).
  static const double _numberColumnWidth = 26;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              OverviewViewAllButton(onTap: onViewAll),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildRow([
              for (var i = 0; i < headers.length; i++)
                _TableHeaderCell(
                  column: headers[i],
                  index: i,
                  sort: sort,
                  onSort: onSort,
                ),
            ]),
          ),
          const Divider(color: AppColors.divider, height: 1, thickness: 1),
          Expanded(
            child: rowCount == 0
                ? Center(
                    child: Text(
                      emptyMessage,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: rowCount,
                    separatorBuilder: (context, index) => const Divider(
                      color: AppColors.divider,
                      height: 1,
                      thickness: 1,
                    ),
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: _buildRow(rowBuilder(context, index)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(List<Widget> cells) {
    return Row(
      children: [
        for (var i = 0; i < cells.length; i++) ...[
          if (i > 0) const SizedBox(width: 8),
          if (flex[i] == 0)
            SizedBox(width: _numberColumnWidth, child: cells[i])
          else
            Expanded(flex: flex[i], child: cells[i]),
        ],
      ],
    );
  }
}

class OverviewTableColumn {
  const OverviewTableColumn(
    this.label, {
    this.sortable = false,
    this.firstDirection = SortDirection.ascending,
  });

  final String label;
  final bool sortable;

  /// What a first click on this column means. Times and severities are more
  /// useful worst/newest first.
  final SortDirection firstDirection;
}

class _TableHeaderCell extends StatelessWidget {
  const _TableHeaderCell({
    required this.column,
    required this.index,
    required this.sort,
    required this.onSort,
  });

  final OverviewTableColumn column;
  final int index;
  final ColumnSort<int>? sort;
  final SortChanged<int>? onSort;

  static const TextStyle _style = TextStyle(
    color: AppColors.textMuted,
    fontSize: 9.5,
    fontWeight: FontWeight.w500,
    height: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    final handler = onSort;
    if (!column.sortable || handler == null) {
      return Text(
        column.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _style,
      );
    }

    return SortableHeader<int>(
      label: column.label,
      column: index,
      sort: sort,
      onSort: handler,
      firstDirection: column.firstDirection,
      textStyle: _style,
      iconSize: 9.5,
    );
  }
}

class OverviewTableText extends StatelessWidget {
  const OverviewTableText(this.value, {super.key, this.emphasis = false});

  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: emphasis ? AppColors.textPrimary : AppColors.textSecondary,
        fontSize: 10.5,
        fontWeight: emphasis ? FontWeight.w500 : FontWeight.w400,
        height: 1.2,
      ),
    );
  }
}

class OverviewSeverityPill extends StatelessWidget {
  const OverviewSeverityPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final lower = label.toLowerCase();
    final background = lower.contains('high')
        ? AppColors.redSoft
        : lower.contains('medium')
        ? AppColors.amberSoft
        : AppColors.greenSoft;
    final foreground = lower.contains('high')
        ? AppColors.redText
        : lower.contains('medium')
        ? AppColors.amberText
        : AppColors.greenText;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}

class OverviewViewAllButton extends StatelessWidget {
  const OverviewViewAllButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View All',
              style: TextStyle(
                color: AppColors.blue,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 11, color: AppColors.blue),
          ],
        ),
      ),
    );
  }
}
