import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import '../../models/vehicle.dart';
import '../../services/drowsiness_report_service.dart';
import '../report/report_styles.dart';
import 'safety_empty_state.dart';
import 'safety_event_detail_panel.dart';
import 'safety_events_table.dart';
import 'safety_filter_bar.dart';
import 'safety_workflow_stepper.dart';

class SafetyContent extends StatefulWidget {
  const SafetyContent({
    super.key,
    required this.selectedVehicle,
    required this.vehicles,
  });

  final Vehicle? selectedVehicle;
  final List<Vehicle> vehicles;

  @override
  State<SafetyContent> createState() => _SafetyContentState();
}

class _SafetyContentState extends State<SafetyContent> {
  final DrowsinessReportService _service = const DrowsinessReportService();

  late DateTime _endDate;
  late DateTime _startDate;
  late Future<List<DrowsinessEvent>> _future;
  String? _activeVehicleApiId;
  int? _selectedEventId;
  String _severityFilter = 'All';
  String _eventTypeFilter = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
    _activeVehicleApiId = _resolveVehicleApiId();
    _future = _loadEvents();
  }

  @override
  void didUpdateWidget(covariant SafetyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextVehicleApiId = _resolveVehicleApiId();
    if (nextVehicleApiId != _activeVehicleApiId) {
      setState(() {
        _activeVehicleApiId = nextVehicleApiId;
        _selectedEventId = null;
        _future = _loadEvents();
      });
    }
  }

  Future<List<DrowsinessEvent>> _loadEvents() async {
    final vehicleId = _activeVehicleApiId ?? 'VIN-0001';
    final events = await _service.getEventsByVehicle(
      vehicleId: vehicleId,
      startDate: _startDate,
      endDate: _endDate,
      limit: 100,
    );

    events.sort((a, b) => b.time.compareTo(a.time));
    return events;
  }

  String _resolveVehicleApiId() {
    final selectedApiId = widget.selectedVehicle?.apiVehicleId?.trim();
    if (selectedApiId != null && selectedApiId.isNotEmpty) {
      return selectedApiId;
    }

    for (final vehicle in widget.vehicles) {
      final apiVehicleId = vehicle.apiVehicleId?.trim();
      if (apiVehicleId != null && apiVehicleId.isNotEmpty) {
        return apiVehicleId;
      }
    }

    return 'VIN-0001';
  }

  void _refresh() {
    setState(() {
      _future = _loadEvents();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: ReportStyles.blue,
              surface: ReportStyles.cardBackground,
              onSurface: ReportStyles.textPrimary,
            ),
            scaffoldBackgroundColor: ReportStyles.pageBackground,
            dialogTheme: DialogThemeData(
              backgroundColor: ReportStyles.cardBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );

    if (picked == null) {
      return;
    }

    setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
      _future = _loadEvents();
    });
  }

  List<DrowsinessEvent> _applyFilters(List<DrowsinessEvent> events) {
    return events.where((event) {
      if (_severityFilter != 'All' &&
          !_matchesSeverity(event.riskLevel, _severityFilter)) {
        return false;
      }

      if (_eventTypeFilter != 'All' &&
          !_matchesEventType(event, _eventTypeFilter)) {
        return false;
      }

      final query = _searchQuery.trim().toLowerCase();
      if (query.isEmpty) {
        return true;
      }

      final searchable = <String>[
        event.vehicleId,
        event.driverLabel,
        event.status,
        event.behaviorType ?? '',
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DrowsinessEvent>>(
      future: _future,
      builder: (context, snapshot) {
        final allEvents = snapshot.data ?? const <DrowsinessEvent>[];
        final filteredEvents = _applyFilters(allEvents);
        final selectedEvent = _resolveSelectedEvent(filteredEvents);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Safety Events',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: ReportStyles.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Review drowsiness and driver safety events',
              style: TextStyle(
                fontSize: 14,
                color: ReportStyles.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            SafetyFilterBar(
              dateRangeLabel: _dateRangeLabel(_startDate, _endDate),
              severityFilter: _severityFilter,
              eventTypeFilter: _eventTypeFilter,
              searchQuery: _searchQuery,
              eventCount: filteredEvents.length,
              selectedVehicleLabel:
                  widget.selectedVehicle?.apiVehicleId?.trim().isNotEmpty == true
                  ? widget.selectedVehicle!.apiVehicleId!
                  : _activeVehicleApiId ?? 'VIN-0001',
              onDateRangeTap: _pickDateRange,
              onRefresh: _refresh,
              onSeverityChanged: (value) {
                setState(() {
                  _severityFilter = value;
                });
              },
              onEventTypeChanged: (value) {
                setState(() {
                  _eventTypeFilter = value;
                });
              },
              onSearchChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              isLoading: snapshot.connectionState == ConnectionState.waiting,
            ),
            const SizedBox(height: 16),
            const SafetyWorkflowStepper(),
            const SizedBox(height: 16),
            Expanded(
              child: Builder(
                builder: (context) {
                  if (snapshot.hasError) {
                    return _SafetyErrorState(
                      message: snapshot.error.toString(),
                      onRetry: _refresh,
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting &&
                      allEvents.isEmpty) {
                    return const _SafetyLoadingState();
                  }

                  if (filteredEvents.isEmpty) {
                    return SafetyEmptyState(
                      title: allEvents.isEmpty
                          ? 'No safety events found'
                          : 'No events match the current filters',
                      subtitle: allEvents.isEmpty
                          ? 'Try a different vehicle or date range.'
                          : 'Adjust severity, event type, or search terms.',
                    );
                  }

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isCompact = constraints.maxWidth < 1180;
                      if (isCompact) {
                        return Column(
                          children: [
                            Expanded(
                              flex: 12,
                              child: SafetyEventsTable(
                                events: filteredEvents,
                                selectedEventId: selectedEvent?.id,
                                onEventSelected: (event) {
                                  setState(() {
                                    _selectedEventId = event.id;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Expanded(
                              flex: 11,
                              child: SafetyEventDetailPanel(
                                event: selectedEvent,
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 58,
                            child: SafetyEventsTable(
                              events: filteredEvents,
                              selectedEventId: selectedEvent?.id,
                              onEventSelected: (event) {
                                setState(() {
                                  _selectedEventId = event.id;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 42,
                            child: SafetyEventDetailPanel(
                              event: selectedEvent,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _dateRangeLabel(DateTime start, DateTime end) {
    final formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(start)} - ${formatter.format(end)}';
  }

  bool _matchesSeverity(String source, String filter) {
    return source.trim().toLowerCase() == filter.toLowerCase();
  }

  bool _matchesEventType(DrowsinessEvent event, String filter) {
    final eventType = _normalizedEventType(event.behaviorType ?? event.status);
    return eventType == _normalizedEventType(filter);
  }

  DrowsinessEvent? _resolveSelectedEvent(List<DrowsinessEvent> events) {
    for (final event in events) {
      if (event.id == _selectedEventId) {
        return event;
      }
    }

    return events.isEmpty ? null : events.first;
  }

  String _normalizedEventType(String value) {
    final normalized = value.trim().toLowerCase().replaceAll('_', ' ');

    if (normalized.contains('episode')) {
      return 'drowsiness episode';
    }
    if (normalized.contains('drows')) {
      return 'drowsy';
    }
    if (normalized.contains('yawn')) {
      return 'yawn';
    }
    if (normalized.contains('distract')) {
      return 'distraction';
    }

    return normalized;
  }
}

class _SafetyLoadingState extends StatelessWidget {
  const _SafetyLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          SizedBox(height: 14),
          Text(
            'Loading safety events...',
            style: TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyErrorState extends StatelessWidget {
  const _SafetyErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withOpacity(0.65)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: ReportStyles.red,
                size: 28,
              ),
              const SizedBox(height: 12),
              const Text(
                'Unable to load safety events',
                style: TextStyle(
                  color: ReportStyles.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ReportStyles.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
