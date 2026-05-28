import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_driver_option.dart';
import '../../models/drowsiness_report.dart';
import '../../services/drowsiness_report_service.dart';
import 'report_event_log_card.dart';
import 'report_executive_risk_summary_card.dart';
import 'report_filter_bar.dart';
import 'report_hour_card.dart';
import 'report_map_card.dart';
import 'report_review_summary_section.dart';
import 'report_stats_row.dart';
import 'report_styles.dart';
import 'report_weekly_behavior_trend_section.dart';

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
  List<DrowsinessDriverOption> _driverOptions = const [];
  DrowsinessDriverOption? _selectedDriver;
  bool _isLoadingDrivers = false;
  String? _driverLoadError;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
    _driverOptions = [DrowsinessDriverOption.allDrivers()];
    _selectedDriver = _driverOptions.first;
    _future = _loadData();
  }

  Future<_ReportData> _loadData() async {
    await _loadDrivers();

    try {
      final results = await Future.wait([
        _service.getReport(
          vehicleId: vehicleId,
          startDate: _startDate,
          endDate: _endDate,
          userId: _selectedDriver?.userId,
        ),
        _service.getEvents(
          vehicleId: vehicleId,
          startDate: _startDate,
          endDate: _endDate,
          userId: _selectedDriver?.userId,
        ),
      ]);

      return _ReportData(
        report: results[0] as DrowsinessReport,
        events: results[1] as List<DrowsinessEvent>,
      );
    } catch (error) {
      if (_selectedDriver?.userId != null && _isInvalidUserError(error)) {
        if (mounted) {
          setState(() {
            _selectedDriver = _driverOptions.first;
          });
        }
        _showDriverMessage(
          'Selected driver is no longer valid. Reset to All Drivers.',
        );

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

      rethrow;
    }
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

  Future<void> _loadDrivers() async {
    if (mounted) {
      setState(() {
        _isLoadingDrivers = true;
        _driverLoadError = null;
      });
    }

    try {
      final options = await _service.fetchDrowsinessDrivers(
        vehicleId: vehicleId,
        startDate: _startDate,
        endDate: _endDate,
      );
      final selectedUserId = _selectedDriver?.userId;
      final nextSelected = options.firstWhere(
        (option) => option.userId == selectedUserId,
        orElse: () => options.first,
      );

      if (!mounted) return;

      setState(() {
        _driverOptions = options;
        _selectedDriver = nextSelected;
        _isLoadingDrivers = false;
        _driverLoadError = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _driverOptions = [DrowsinessDriverOption.allDrivers()];
        _selectedDriver = DrowsinessDriverOption.allDrivers();
        _isLoadingDrivers = false;
        _driverLoadError = error.toString();
      });

      _showDriverMessage(
        'Driver list could not be loaded. Showing All Drivers only.',
      );
    }
  }

  void _onDriverChanged(DrowsinessDriverOption? value) {
    if (value == null) return;
    if (value.userId == _selectedDriver?.userId) return;

    setState(() {
      _selectedDriver = value;
      _future = _loadData();
    });
  }

  void _showDriverMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    });
  }

  bool _isInvalidUserError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('400') && message.contains('user_id');
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
                const Expanded(
                  child: Text(
                    'Drowsiness Report',
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: ReportStyles.textPrimary,
                      letterSpacing: 0,
                      height: 1.05,
                    ),
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
            const SizedBox(height: 12),
            ReportFilterBar(
              label: _dateRangeLabel(_startDate, _endDate),
              driverOptions: _driverOptions,
              selectedDriver: _selectedDriver,
              isLoadingDrivers: _isLoadingDrivers,
              onDateRangeTap: _pickDateRange,
              onDriverChanged: _onDriverChanged,
              onRefresh: _refresh,
            ),
            const SizedBox(height: 8),
            _DriverFocusBanner(
              selectedDriver: _selectedDriver ?? DrowsinessDriverOption.allDrivers(),
              driverLoadError: _driverLoadError,
            ),
            const SizedBox(height: 10),
            if (snapshot.hasError)
              _ReportErrorCard(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              )
            else ...[
              ReportExecutiveRiskSummaryCard(
                riskSummary: data?.report.riskSummary ??
                    const ReportRiskSummary(
                      riskLevel: 'no_data',
                      riskScore: 0,
                      headline: 'No drowsiness events detected',
                      shortSummary:
                          'No drowsiness events were detected for the selected period.',
                      primaryFinding: ReportPrimaryFinding(
                        title: 'Peak risk day',
                        value: '-',
                        description:
                            'No weekday trend is available for the selected period.',
                      ),
                      mainContributor: ReportMainContributor(
                        userId: null,
                        driverName: '',
                        totalEvents: 0,
                        percentage: 0.0,
                        description:
                            'No driver contribution data is available.',
                      ),
                      dominantBehavior: ReportDominantBehavior(
                        key: '',
                        label: 'No dominant behavior',
                        description:
                            'No dominant behavior is available for the selected period.',
                      ),
                      reviewBacklog: ReportReviewBacklog(
                        newEvents: 0,
                        reviewCompletionRate: 0.0,
                        description:
                            'There is no review backlog for the selected period.',
                      ),
                      recommendedActions: [],
                      flags: [],
                    ),
              ),
              const SizedBox(height: 10),
              ReportStatsRow(
                report: data?.report,
                events: data?.events ?? const [],
              ),
              const SizedBox(height: 10),
              ReportReviewSummarySection(
                reviewSummary: data?.report.reviewSummary ??
                    const DrowsinessReviewSummary(
                      totalEvents: 0,
                      newEvents: 0,
                      confirmed: 0,
                      falseAlarm: 0,
                      followUpRequired: 0,
                      followedUp: 0,
                      reviewedTotal: 0,
                      reviewCompletionRate: 0.0,
                      falseAlarmRate: 0.0,
                      closureRate: 0.0,
                    ),
              ),
              const SizedBox(height: 10),
              ReportWeeklyBehaviorTrendSection(
                weekdaySummaries:
                    data?.report.weekdayBehaviorSummary ?? const [],
                isDriverFiltered: (_selectedDriver?.userId != null),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 1080;

                  if (isWide) {
                    return SizedBox(
                      height: 316,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 54,
                            child:
                                ReportMapCard(events: data?.events ?? const []),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 46,
                            child: ReportHourCard(
                              report: data?.report,
                              events: data?.events ?? const [],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: ReportMapCard(events: data?.events ?? const []),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 280,
                        child: ReportHourCard(
                          report: data?.report,
                          events: data?.events ?? const [],
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 296,
                child: ReportEventLogCard(
                  events: data?.events ?? const [],
                  emptyMessage: _emptyStateMessage(),
                ),
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

  String _emptyStateMessage() {
    if (_selectedDriver == null || _selectedDriver!.isAllDrivers) {
      return 'No drowsiness events found';
    }

    return 'No drowsiness data found for ${_selectedDriver!.driverName} in the selected period.';
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

class _DriverFocusBanner extends StatelessWidget {
  const _DriverFocusBanner({
    required this.selectedDriver,
    required this.driverLoadError,
  });

  final DrowsinessDriverOption selectedDriver;
  final String? driverLoadError;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        RichText(
          text: TextSpan(
            text: 'Driver Focus: ',
            style: const TextStyle(
              color: ReportStyles.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: selectedDriver.driverName,
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        if (!selectedDriver.isAllDrivers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: ReportStyles.blue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: ReportStyles.blue.withValues(alpha: 0.24),
              ),
            ),
            child: const Text(
              'Filtered',
              style: TextStyle(
                color: ReportStyles.blue,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        if (driverLoadError != null)
          const Text(
            'Driver list unavailable. Using All Drivers.',
            style: TextStyle(
              color: ReportStyles.orange,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
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
