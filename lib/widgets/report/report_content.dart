import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_driver_option.dart';
import '../../models/drowsiness_report.dart';
import '../../services/drowsiness_report_service.dart';
import 'report_filter_bar.dart';
import 'report_mockup_dashboard.dart';
import 'report_skeleton_loading.dart';
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
  int _reportRequestSeq = 0;
  List<DrowsinessDriverOption> _driverOptions = const [];
  DrowsinessDriverOption? _selectedDriver;
  bool _isLoadingDrivers = false;
  String? _driverLoadError;
  bool _isExportingCsv = false;
  bool _isExportingPdf = false;
  _ReportData? _lastData;

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
    final requestSeq = ++_reportRequestSeq;
    final requestedFilters = _currentFilters();
    _debugLog(
      'Load start seq=$requestSeq userId=${requestedFilters.userId ?? 'all'} '
      'range=${_dateRangeLabel(requestedFilters.startDate, requestedFilters.endDate)}',
    );

    final selectionReset = await _loadDrivers(
      requestSeq: requestSeq,
      filters: requestedFilters,
    );
    if (!_isActiveRequest(requestSeq)) {
      _debugLog(
        'Discarded driver load seq=$requestSeq because a newer request exists',
      );
      return _awaitLatestReportData();
    }

    final filters = _currentFilters();

    if (selectionReset) {
      _showDriverMessage(
        'Selected driver is unavailable for this date range. Reset to All Drivers.',
      );
    }

    try {
      final data = await _fetchReportData(filters, requestSeq: requestSeq);
      if (!_isActiveRequest(requestSeq)) {
        _debugLog(
          'Discarded report seq=$requestSeq because a newer request exists',
        );
        return _awaitLatestReportData();
      }
      _debugLog(
        'Applied report seq=$requestSeq userId=${filters.userId ?? 'all'} '
        'totalEvents=${data.report.summary.totalEvents} events=${data.events.length}',
      );
      _lastData = data;
      return data;
    } catch (error) {
      if (filters.userId != null && _isInvalidUserError(error)) {
        await _resetToAllDrivers();
        _showDriverMessage('Driver filter is invalid. Reset to All Drivers.');
        return _fetchReportData(_currentFilters(), requestSeq: requestSeq);
      }

      rethrow;
    }
  }

  void _refresh() {
    setState(() {
      _future = _loadData();
    });
  }

  Future<void> _exportCsv() async {
    await _runExport(
      label: 'CSV',
      setLoading: (value) {
        if (!mounted) return;
        setState(() {
          _isExportingCsv = value;
        });
      },
      action: () => _service.exportDrowsinessReportCsv(
        vehicleId: vehicleId,
        startDate: _startDate,
        endDate: _endDate,
        userId: _selectedDriver?.userId,
      ),
    );
  }

  Future<void> _exportPdf() async {
    await _runExport(
      label: 'PDF',
      setLoading: (value) {
        if (!mounted) return;
        setState(() {
          _isExportingPdf = value;
        });
      },
      action: () => _service.exportDrowsinessReportPdf(
        vehicleId: vehicleId,
        startDate: _startDate,
        endDate: _endDate,
        userId: _selectedDriver?.userId,
      ),
    );
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

  Future<bool> _loadDrivers({
    required int requestSeq,
    required _ActiveReportFilters filters,
  }) async {
    if (mounted) {
      setState(() {
        _isLoadingDrivers = true;
        _driverLoadError = null;
      });
    }

    try {
      _debugLog(
        'Fetch drivers seq=$requestSeq userId=${filters.userId ?? 'all'} '
        'range=${_dateRangeLabel(filters.startDate, filters.endDate)}',
      );
      final options = await _service.fetchDrowsinessDrivers(
        vehicleId: filters.vehicleId,
        startDate: filters.startDate,
        endDate: filters.endDate,
      );
      final selectedUserId = _selectedDriver?.userId;
      final hadSelectedDriver = selectedUserId != null;
      final nextSelected = options.firstWhere(
        (option) => option.userId == selectedUserId,
        orElse: () => options.first,
      );
      final selectionReset =
          hadSelectedDriver && nextSelected.userId != selectedUserId;

      if (!mounted) return selectionReset;
      if (!_isActiveRequest(requestSeq)) return selectionReset;

      setState(() {
        _driverOptions = options;
        _selectedDriver = nextSelected;
        _isLoadingDrivers = false;
        _driverLoadError = null;
      });
      _debugLog(
        'Applied drivers seq=$requestSeq selectedUserId=${_selectedDriver?.userId ?? 'all'} '
        'options=${options.length}',
      );
      return selectionReset;
    } catch (error) {
      final hadSelectedDriver = _selectedDriver?.userId != null;
      if (!mounted) return hadSelectedDriver;
      if (!_isActiveRequest(requestSeq)) return hadSelectedDriver;

      setState(() {
        _driverOptions = [DrowsinessDriverOption.allDrivers()];
        _selectedDriver = DrowsinessDriverOption.allDrivers();
        _isLoadingDrivers = false;
        _driverLoadError = error.toString();
      });

      _showDriverMessage(
        'Driver list could not be loaded. Showing All Drivers only.',
      );
      return hadSelectedDriver;
    }
  }

  void _onDriverChanged(DrowsinessDriverOption? value) {
    if (value == null) return;
    if (value.userId == _selectedDriver?.userId) return;
    _debugLog(
      'Driver changed: ${value.driverName} userId=${value.userId ?? 'all'}',
    );

    setState(() {
      _selectedDriver = value;
      _future = _loadData();
    });
  }

  void _showDriverMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(SnackBar(content: Text(message)));
    });
  }

  bool _isInvalidUserError(Object error) {
    if (error is ApiRequestException) {
      return error.statusCode == 400 &&
          error.message.toLowerCase().contains(
            'user_id must be a positive integer',
          );
    }

    final message = error.toString().toLowerCase();
    return message.contains('400') &&
        message.contains('user_id must be a positive integer');
  }

  Future<void> _runExport({
    required String label,
    required Future<String> Function() action,
    required ValueSetter<bool> setLoading,
  }) async {
    setLoading(true);

    try {
      final savedPath = await action();
      _showDriverMessage(_exportSuccessMessage(savedPath));
    } catch (error) {
      if (_selectedDriver?.userId != null && _isInvalidUserError(error)) {
        await _resetToAllDrivers(reload: true);
        _showDriverMessage('Driver filter is invalid. Reset to All Drivers.');
      } else {
        _showDriverMessage(
          'Export failed: ${_exportErrorMessage(error, label)}',
        );
      }
    } finally {
      setLoading(false);
    }
  }

  String _exportErrorMessage(Object error, String label) {
    final message = error.toString();
    if (message.isEmpty) {
      return '$label export failed';
    }
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  Future<_ReportData> _fetchReportData(
    _ActiveReportFilters filters, {
    required int requestSeq,
  }) async {
    _debugLog('Fetch report seq=$requestSeq userId=${filters.userId ?? 'all'}');
    _debugLog('Fetch events seq=$requestSeq userId=${filters.userId ?? 'all'}');
    final results = await Future.wait([
      _service.getReport(
        vehicleId: filters.vehicleId,
        startDate: filters.startDate,
        endDate: filters.endDate,
        userId: filters.userId,
      ),
      _service.getEvents(
        vehicleId: filters.vehicleId,
        startDate: filters.startDate,
        endDate: filters.endDate,
        userId: filters.userId,
      ),
    ]);

    return _ReportData(
      report: results[0] as DrowsinessReport,
      events: results[1] as List<DrowsinessEvent>,
    );
  }

  _ActiveReportFilters _currentFilters() {
    return _ActiveReportFilters(
      vehicleId: vehicleId,
      startDate: _startDate,
      endDate: _endDate,
      userId: _selectedDriver?.userId,
    );
  }

  Future<void> _resetToAllDrivers({bool reload = false}) async {
    if (!mounted) return;

    final fallback = _driverOptions.isNotEmpty
        ? _driverOptions.first
        : DrowsinessDriverOption.allDrivers();

    setState(() {
      _selectedDriver = fallback;
      if (_driverOptions.isEmpty) {
        _driverOptions = [fallback];
      }
      if (reload) {
        _future = _loadData();
      }
    });
  }

  String _exportSuccessMessage(String savedPath) {
    if (savedPath.contains(r'\Downloads\') ||
        savedPath.contains('/Downloads/')) {
      return 'Export successful. Saved to Downloads';
    }

    return 'Export successful. Saved to: $savedPath';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReportData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _lastData;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        if (data != null) {
          _debugLog(
            'Executive dashboard rebuild userId=${_selectedDriver?.userId ?? 'all'} '
            'totalEvents=${data.report.summary.totalEvents} events=${data.events.length}',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ReportFilterBar(
              title: 'Drowsiness Report',
              label: _dateRangeLabel(_startDate, _endDate),
              driverOptions: _driverOptions,
              selectedDriver: _selectedDriver,
              isLoadingDrivers: _isLoadingDrivers,
              onDateRangeTap: _pickDateRange,
              onDriverChanged: _onDriverChanged,
              onRefresh: _refresh,
              onExportPdf: _exportPdf,
              onExportCsv: _exportCsv,
              isExportingPdf: _isExportingPdf,
              isExportingCsv: _isExportingCsv,
            ),
            if (_driverLoadError != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Driver list unavailable. Using All Drivers.',
                style: TextStyle(
                  color: ReportStyles.orange,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (snapshot.hasError && data == null)
              _ReportErrorCard(
                message: snapshot.error.toString(),
                onRetry: _refresh,
              )
            else ...[
              if (data != null)
                ReportMockupDashboard(
                  key: ValueKey<String>(
                    '${_selectedDriver?.userId ?? 'all'}-'
                    '${_startDate.toIso8601String()}-'
                    '${_endDate.toIso8601String()}',
                  ),
                  report: data.report,
                  events: data.events,
                  selectedDriver: _selectedDriver,
                  dateRangeLabel: _dateRangeLabel(_startDate, _endDate),
                  isRefreshing: isLoading,
                )
              else if (isLoading)
                const ReportDashboardSkeleton()
              else
                ReportCard(
                  child: Text(
                    _emptyStateMessage(),
                    style: const TextStyle(
                      color: ReportStyles.textSecondary,
                      fontSize: 13,
                    ),
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

    return 'No drowsiness data found for User #${_selectedDriver!.userId} in the selected period.';
  }

  bool _isActiveRequest(int requestSeq) => requestSeq == _reportRequestSeq;

  Future<_ReportData> _awaitLatestReportData() async {
    return _future;
  }

  void _debugLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[Report] $message');
  }
}

class _ActiveReportFilters {
  const _ActiveReportFilters({
    required this.vehicleId,
    required this.startDate,
    required this.endDate,
    required this.userId,
  });

  final String vehicleId;
  final DateTime startDate;
  final DateTime endDate;
  final int? userId;
}

class _ReportData {
  const _ReportData({required this.report, required this.events});

  final DrowsinessReport report;
  final List<DrowsinessEvent> events;
}

class _ReportErrorCard extends StatelessWidget {
  const _ReportErrorCard({required this.message, required this.onRetry});

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
                      ? Column(children: _calendarChildren(isNarrow: true))
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
                      Navigator.of(
                        context,
                      ).pop(DateTimeRange(start: _startDate, end: _endDate));
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
      return [startCalendar, const SizedBox(height: 12), endCalendar];
    }

    return [
      Expanded(child: startCalendar),
      const SizedBox(width: 12),
      Expanded(child: endCalendar),
    ];
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label, required this.value});

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
            style: const TextStyle(color: ReportStyles.textMuted, fontSize: 10),
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
