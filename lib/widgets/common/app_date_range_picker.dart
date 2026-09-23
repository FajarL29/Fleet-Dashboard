import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import 'app_action_button.dart';

/// Header action that opens a two-month calendar and returns a date range.
///
/// Replaces Flutter's [showDateRangePicker] dialog: the panel is anchored to
/// the button and stays inside the page instead of taking over the screen.
class AppDateRangePicker extends StatefulWidget {
  const AppDateRangePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label = 'Pick Dates',
    this.icon = Icons.calendar_month_outlined,
    this.firstDate,
    this.lastDate,
  });

  /// Currently applied range, or null when the filter is off.
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;

  final String label;
  final IconData icon;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<AppDateRangePicker> createState() => _AppDateRangePickerState();
}

class _AppDateRangePickerState extends State<AppDateRangePicker> {
  final MenuController _menuController = MenuController();

  /// Left-hand month of the two shown side by side.
  late DateTime _leftMonth;

  /// First tap of an in-progress selection; null once a range is committed.
  DateTime? _pendingStart;

  @override
  void initState() {
    super.initState();
    _leftMonth = _monthOf(widget.value?.start ?? DateTime.now());
  }

  static DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

  void _handleDayTap(DateTime day) {
    final pending = _pendingStart;

    // No selection in progress, or restarting below the pending start.
    if (pending == null || day.isBefore(pending)) {
      setState(() => _pendingStart = day);
      return;
    }

    setState(() => _pendingStart = null);
    widget.onChanged(DateTimeRange(start: pending, end: day));
    _menuController.close();
  }

  void _reset() {
    setState(() => _pendingStart = null);
    widget.onChanged(null);
    _menuController.close();
  }

  String get _buttonLabel {
    final range = widget.value;
    if (range == null) return widget.label;

    final format = DateFormat('d MMM');
    return '${format.format(range.start)} - ${format.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      controller: _menuController,
      consumeOutsideTap: true,
      alignmentOffset: const Offset(0, 6),
      style: MenuStyle(
        backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shadowColor: WidgetStatePropertyAll(AppColors.menuShadow),
        elevation: const WidgetStatePropertyAll(9),
        padding: const WidgetStatePropertyAll(EdgeInsets.zero),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      menuChildren: [
        _CalendarPanel(
          leftMonth: _leftMonth,
          selection: widget.value,
          pendingStart: _pendingStart,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          onDayTap: _handleDayTap,
          onShiftMonths: (delta) => setState(() {
            _leftMonth = DateTime(_leftMonth.year, _leftMonth.month + delta);
          }),
          onReset: widget.value == null && _pendingStart == null
              ? null
              : _reset,
        ),
      ],
      builder: (context, controller, child) {
        return AppActionButton(
          icon: widget.icon,
          label: _buttonLabel,
          onPressed: () =>
              controller.isOpen ? controller.close() : controller.open(),
        );
      },
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.leftMonth,
    required this.selection,
    required this.pendingStart,
    required this.firstDate,
    required this.lastDate,
    required this.onDayTap,
    required this.onShiftMonths,
    required this.onReset,
  });

  final DateTime leftMonth;
  final DateTimeRange? selection;
  final DateTime? pendingStart;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onDayTap;
  final ValueChanged<int> onShiftMonths;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final rightMonth = DateTime(leftMonth.year, leftMonth.month + 1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NavArrow(
                icon: Icons.chevron_left_rounded,
                onTap: () => onShiftMonths(-1),
              ),
              const SizedBox(width: 6),
              _MonthGrid(
                month: leftMonth,
                selection: selection,
                pendingStart: pendingStart,
                firstDate: firstDate,
                lastDate: lastDate,
                onDayTap: onDayTap,
              ),
              const SizedBox(width: 28),
              _MonthGrid(
                month: rightMonth,
                selection: selection,
                pendingStart: pendingStart,
                firstDate: firstDate,
                lastDate: lastDate,
                onDayTap: onDayTap,
              ),
              const SizedBox(width: 6),
              _NavArrow(
                icon: Icons.chevron_right_rounded,
                onTap: () => onShiftMonths(1),
              ),
            ],
          ),
          if (onReset != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: InkWell(
                onTap: onReset,
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text(
                    'Reset',
                    style: TextStyle(
                      color: AppColors.blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, size: 22, color: AppColors.blue),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
        splashRadius: 18,
      ),
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selection,
    required this.pendingStart,
    required this.firstDate,
    required this.lastDate,
    required this.onDayTap,
  });

  final DateTime month;
  final DateTimeRange? selection;
  final DateTime? pendingStart;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime> onDayTap;

  static const double _cellWidth = 36;
  static const double _cellHeight = 34;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 34,
          child: Center(
            child: Text(
              DateFormat('MMMM yyyy').format(month),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var weekday = 0; weekday < 7; weekday++)
              SizedBox(
                width: _cellWidth,
                child: Center(
                  child: Text(
                    _weekdayLabels[weekday],
                    style: TextStyle(
                      // Sundays are highlighted, matching the design.
                      color: weekday == 0
                          ? AppColors.red
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (final week in _weeks)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final day in week)
                SizedBox(
                  width: _cellWidth,
                  height: _cellHeight,
                  child: day == null
                      ? const SizedBox.shrink()
                      : _DayCell(
                          day: day,
                          state: _stateFor(day),
                          enabled: _isEnabled(day),
                          onTap: () => onDayTap(day),
                        ),
                ),
            ],
          ),
      ],
    );
  }

  static const List<String> _weekdayLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  /// Weeks of [month], padded with nulls so the 1st lands under its weekday.
  List<List<DateTime?>> get _weeks {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final dayCount = DateTime(month.year, month.month + 1, 0).day;
    // DateTime.weekday is Mon=1..Sun=7; % 7 makes Sunday column zero.
    final leadingBlanks = firstOfMonth.weekday % 7;

    final cells = <DateTime?>[
      ...List<DateTime?>.filled(leadingBlanks, null),
      for (var day = 1; day <= dayCount; day++)
        DateTime(month.year, month.month, day),
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    return [for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7)];
  }

  bool _isEnabled(DateTime day) {
    if (firstDate != null && day.isBefore(_dateOnly(firstDate!))) return false;
    if (lastDate != null && day.isAfter(_dateOnly(lastDate!))) return false;
    return true;
  }

  _DayState _stateFor(DateTime day) {
    final pending = pendingStart;
    if (pending != null) {
      return _isSameDay(day, pending) ? _DayState.edge : _DayState.none;
    }

    final range = selection;
    if (range == null) return _DayState.none;

    if (_isSameDay(day, range.start) || _isSameDay(day, range.end)) {
      return _DayState.edge;
    }
    if (day.isAfter(range.start) && day.isBefore(range.end)) {
      return _DayState.inRange;
    }
    return _DayState.none;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

enum _DayState { none, inRange, edge }

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.state,
    required this.enabled,
    required this.onTap,
  });

  final DateTime day;
  final _DayState state;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isSunday = day.weekday == DateTime.sunday;

    final Color foreground;
    if (!enabled) {
      foreground = AppColors.textMuted;
    } else if (state == _DayState.edge) {
      foreground = Colors.white;
    } else if (isSunday) {
      foreground = AppColors.red;
    } else {
      foreground = AppColors.textPrimary;
    }

    return Center(
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: switch (state) {
              _DayState.edge => AppColors.navy,
              _DayState.inRange => AppColors.blueSoft,
              _DayState.none => Colors.transparent,
            },
          ),
          child: Text(
            '${day.day}',
            style: TextStyle(
              color: foreground,
              fontSize: 13,
              fontWeight: state == _DayState.edge
                  ? FontWeight.w700
                  : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
