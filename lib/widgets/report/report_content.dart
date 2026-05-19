import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import '../../services/drowsiness_report_service.dart';
import 'report_event_log_card.dart';
import 'report_filter_bar.dart';
import 'report_hour_card.dart';
import 'report_map_card.dart';
import 'report_stats_row.dart';
import 'report_styles.dart';

class ReportContent extends StatefulWidget {
  const ReportContent({super.key});

  @override
  State<ReportContent> createState() => _ReportContentState();
}

class _ReportContentState extends State<ReportContent> {
  static const String vehicleId = 'VIN-0001';

  final DrowsinessReportService _service = const DrowsinessReportService();
  late DateTime _endDate;
  late DateTime _startDate;
  late Future<_ReportData> _future;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
    _future = _loadData();
  }

  Future<_ReportData> _loadData() async {
    final results = await Future.wait([
      _service.getReport(
        vehicleId: vehicleId,
        startDate: _startDate,
        endDate: _endDate,
      ),
      _service.getEvents(
        vehicleId: vehicleId,
        startDate: _startDate,
        endDate: _endDate,
      ),
    ]);

    return _ReportData(
      report: results[0] as DrowsinessReport,
      events: results[1] as List<DrowsinessEvent>,
    );
  }

  void _refresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (context) => _CompactDateRangeDialog(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        firstDate: DateTime(2020),
        lastDate: DateTime.now().add(const Duration(days: 1)),
      ),
    );

    if (picked == null) return;

    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
      _future = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReportData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Drowsiness Report',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: ReportStyles.textPrimary,
                  ),
                ),
                const SizedBox(width: 10),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ReportFilterBar(
              label: _dateRangeLabel(_startDate, _endDate),
              onDateRangeTap: _pickDateRange,
              onRefresh: _refresh,
            ),
            const SizedBox(height: 14),
            if (snapshot.hasError)
              _ReportErrorCard(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              )
            else ...[
              ReportStatsRow(
                report: data?.report,
                events: data?.events ?? const [],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 330,
                child: Row(
                  children: [
                    Expanded(
                      flex: 52,
                      child: ReportMapCard(events: data?.events ?? const []),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 48,
                      child: ReportHourCard(events: data?.events ?? const []),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 310,
                child: ReportEventLogCard(events: data?.events ?? const []),
              ),
            ],
          ],
        );
      },
    );
  }

  String _dateRangeLabel(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }
}

class _ReportData {
  const _ReportData({
    required this.report,
    required this.events,
  });

  final DrowsinessReport report;
  final List<DrowsinessEvent> events;
}

class _ReportErrorCard extends StatelessWidget {
  const _ReportErrorCard({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: ReportStyles.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ToolbarButton(
            icon: Icons.refresh_rounded,
            label: 'Retry',
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

class _CompactDateRangeDialog extends StatefulWidget {
  const _CompactDateRangeDialog({
    required this.initialStartDate,
    required this.initialEndDate,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_CompactDateRangeDialog> createState() =>
      _CompactDateRangeDialogState();
}

class _CompactDateRangeDialogState extends State<_CompactDateRangeDialog> {
  late DateTime _startDate;
  late DateTime _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, yyyy');
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 760;

    return Dialog(
      backgroundColor: ReportStyles.cardBackground,
      insetPadding: const EdgeInsets.all(24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isNarrow ? 380 : 720,
          maxHeight: isNarrow ? 720 : 660,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: ReportStyles.blue,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Select Date Range',
                    style: TextStyle(
                      color: ReportStyles.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: ReportStyles.textSecondary,
                    ),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _DateChip(
                      label: 'Start',
                      value: formatter.format(_startDate),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DateChip(
                      label: 'End',
                      value: formatter.format(_endDate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Flexible(
                child: SingleChildScrollView(
                  child: isNarrow
                      ? Column(
                          children: _calendarChildren(isNarrow: true),
                        )
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _calendarChildren(isNarrow: false),
                        ),
                ),
              ),
              const Divider(color: ReportStyles.border, height: 18),
              Row(
                children: [
                  Text(
                    '${formatter.format(_startDate)} - ${formatter.format(_endDate)}',
                    style: const TextStyle(
                      color: ReportStyles.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        DateTimeRange(start: _startDate, end: _endDate),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _calendarChildren({required bool isNarrow}) {
    final startCalendar = _CalendarPanel(
      title: 'Start Date',
      selectedDate: _startDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      onDateChanged: (date) {
        setState(() {
          _startDate = date;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        });
      },
    );

    final endCalendar = _CalendarPanel(
      title: 'End Date',
      selectedDate: _endDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      onDateChanged: (date) {
        setState(() {
          _endDate = date;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        });
      },
    );

    if (isNarrow) {
      return [
        startCalendar,
        const SizedBox(height: 12),
        endCalendar,
      ];
    }

    return [
      Expanded(child: startCalendar),
      const SizedBox(width: 12),
      Expanded(child: endCalendar),
    ];
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: ReportStyles.textMuted,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.title,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
  });

  final String title;
  final DateTime selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ReportStyles.border),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      child: Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: ReportStyles.blue,
            surface: ReportStyles.surfaceBackground,
            onSurface: ReportStyles.textPrimary,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 2),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 370,
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: firstDate,
                lastDate: lastDate,
                onDateChanged: onDateChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
