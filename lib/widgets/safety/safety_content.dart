import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import '../../models/vehicle.dart';
import '../../services/drowsiness_report_service.dart';
import '../../services/vehicle_management_service.dart';
import '../report/report_styles.dart';
import 'safety_skeleton_loading.dart';
import 'safety_empty_state.dart';
import 'safety_event_detail_panel.dart';
import 'safety_events_table.dart';
import 'safety_filter_bar.dart';
import 'safety_workflow_stepper.dart';

class SafetyContent extends StatefulWidget {
  const SafetyContent({super.key, this.initialSelectedVehicle});

  final Vehicle? initialSelectedVehicle;

  @override
  State<SafetyContent> createState() => _SafetyContentState();
}

class _SafetyContentState extends State<SafetyContent> {
  final DrowsinessReportService _service = const DrowsinessReportService();
  final VehicleManagementService _vehicleService =
      const VehicleManagementService();

  late DateTime _endDate;
  late DateTime _startDate;
  List<SafetyVehicleOption> _vehicleOptions = const [];
  String? _activeVehicleVin;
  int? _selectedEventId;
  String _severityFilter = 'All';
  String _eventTypeFilter = 'All';
  String _searchQuery = '';
  List<DrowsinessEvent> _events = const [];
  bool _isVehicleLoading = true;
  bool _isEventsLoading = false;
  bool _isReviewUpdating = false;
  String? _errorMessage;
  String? _vehicleErrorMessage;

  @override
  void initState() {
    super.initState();
    _endDate = DateTime.now();
    _startDate = _endDate.subtract(const Duration(days: 30));
    _loadVehicles();
  }

  @override
  void didUpdateWidget(covariant SafetyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previousVin = _preferredVehicleVin(oldWidget.initialSelectedVehicle);
    final nextVin = _preferredVehicleVin(widget.initialSelectedVehicle);
    if (nextVin != previousVin && nextVin != null) {
      final nextOption = _vehicleOptions.where(
        (option) => option.vin == nextVin,
      );
      if (nextOption.isNotEmpty && nextVin != _activeVehicleVin) {
        _handleVehicleChanged(nextVin);
      }
    }
  }

  Future<void> _loadVehicles({bool reloadEventsAfterLoad = true}) async {
    setState(() {
      _isVehicleLoading = true;
      _vehicleErrorMessage = null;
    });

    try {
      final registryData = await _vehicleService.getVehicles(
        status: 'active',
        limit: 100,
      );
      final options = registryData.vehicles
          .where(
            (vehicle) => vehicle.vehicleIdentificationNumber.trim().isNotEmpty,
          )
          .map(
            (vehicle) => SafetyVehicleOption(
              vin: vehicle.vehicleIdentificationNumber.trim(),
              label: _vehicleLabel(
                vin: vehicle.vehicleIdentificationNumber,
                plateNumber: vehicle.plateNumber,
              ),
            ),
          )
          .toList();

      if (kDebugMode) {
        debugPrint(
          '[Safety] Loaded vehicles: count=${options.length}, vins=${options.map((option) => option.vin).join(', ')}',
        );
      }

      if (!mounted) {
        return;
      }

      final nextSelectedVin = _resolveSelectedVehicleVin(options);
      final shouldReloadEvents =
          reloadEventsAfterLoad && nextSelectedVin != null;

      setState(() {
        _vehicleOptions = options;
        _activeVehicleVin = nextSelectedVin;
        _selectedEventId = shouldReloadEvents ? null : _selectedEventId;
        _isVehicleLoading = false;
        _vehicleErrorMessage = null;
      });

      if (options.isEmpty) {
        setState(() {
          _events = const [];
          _errorMessage = null;
          _isEventsLoading = false;
        });
        return;
      }

      if (shouldReloadEvents) {
        if (kDebugMode) {
          debugPrint('[Safety] Selected vehicle=$nextSelectedVin');
        }
        await _loadEvents();
      }
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _vehicleOptions = const [];
        _activeVehicleVin = null;
        _events = const [];
        _isVehicleLoading = false;
        _isEventsLoading = false;
        _vehicleErrorMessage = error.toString();
      });
    }
  }

  Future<void> _loadEvents() async {
    final vehicleVin = _activeVehicleVin;
    if (vehicleVin == null || vehicleVin.isEmpty) {
      setState(() {
        _events = const [];
        _errorMessage = null;
        _isEventsLoading = false;
      });
      return;
    }

    setState(() {
      _isEventsLoading = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        debugPrint('[Safety] Fetch events for vehicle=$vehicleVin');
      }
      final events = await _service.getEventsByVehicle(
        vehicleId: vehicleVin,
        startDate: _startDate,
        endDate: _endDate,
        limit: 100,
      );

      events.sort((a, b) => b.time.compareTo(a.time));

      if (!mounted) {
        return;
      }

      setState(() {
        _events = events;
        _isEventsLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isEventsLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  void _refresh() {
    _loadVehicles(reloadEventsAfterLoad: true);
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
    });
    _loadEvents();
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
        event.reviewStatus,
        event.reviewedBy ?? '',
      ].join(' ').toLowerCase();

      return searchable.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredEvents = _applyFilters(_events);
    final selectedEvent = _resolveSelectedEvent(filteredEvents);
    final showInitialSkeleton =
        (_isVehicleLoading || _isEventsLoading) &&
        _vehicleOptions.isEmpty &&
        _events.isEmpty &&
        _vehicleErrorMessage == null;

    if (showInitialSkeleton) {
      return const SafetyContentSkeleton();
    }

    final content = Column(
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
          style: TextStyle(fontSize: 14, color: ReportStyles.textSecondary),
        ),
        const SizedBox(height: 18),
        SafetyFilterBar(
          dateRangeLabel: _dateRangeLabel(_startDate, _endDate),
          severityFilter: _severityFilter,
          eventTypeFilter: _eventTypeFilter,
          searchQuery: _searchQuery,
          eventCount: filteredEvents.length,
          vehicleOptions: _vehicleOptions,
          selectedVehicleVin: _activeVehicleVin,
          selectedVehicleLabel: _selectedVehicleLabel,
          onDateRangeTap: _pickDateRange,
          onRefresh: _refresh,
          onVehicleChanged: _handleVehicleChanged,
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
          isLoading: _isVehicleLoading || _isEventsLoading,
          isVehicleLoading: _isVehicleLoading,
        ),
        const SizedBox(height: 16),
        const SafetyWorkflowStepper(),
        const SizedBox(height: 16),
        Expanded(
          child: Builder(
            builder: (context) {
              if (_vehicleErrorMessage != null) {
                return _SafetyErrorState(
                  message: _vehicleErrorMessage!,
                  onRetry: _refresh,
                );
              }

              if (_vehicleOptions.isEmpty) {
                return const SafetyEmptyState(
                  title: 'No registered vehicles available.',
                  subtitle:
                      'Add or activate a vehicle to review safety events.',
                );
              }

              if (_errorMessage != null) {
                return _SafetyErrorState(
                  message: _errorMessage!,
                  onRetry: _refresh,
                );
              }

              if (filteredEvents.isEmpty) {
                return SafetyEmptyState(
                  title: _events.isEmpty
                      ? 'No safety events found'
                      : 'No events match the current filters',
                  subtitle: _events.isEmpty
                      ? 'Try a different date range or keep this vehicle selected while events are still empty.'
                      : 'Adjust severity, event type, or search terms.',
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 1180;
                  final body = isCompact
                      ? Column(
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
                                isUpdatingReview: _isReviewUpdating,
                                onReviewAction: _handleReviewAction,
                              ),
                            ),
                          ],
                        )
                      : Row(
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
                                isUpdatingReview: _isReviewUpdating,
                                onReviewAction: _handleReviewAction,
                              ),
                            ),
                          ],
                        );

                  if (!_isEventsLoading) {
                    return body;
                  }

                  return Stack(
                    children: [
                      AbsorbPointer(
                        absorbing: true,
                        child: AnimatedOpacity(
                          opacity: 0.62,
                          duration: const Duration(milliseconds: 180),
                          child: body,
                        ),
                      ),
                      const IgnorePointer(
                        child: SafetyContentSkeleton(
                          overlay: true,
                          contentOnly: true,
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

    return content;
  }

  Future<void> _handleVehicleChanged(String? vin) async {
    if (vin == null || vin == _activeVehicleVin) {
      return;
    }

    if (kDebugMode) {
      debugPrint('[Safety] Selected vehicle=$vin');
    }

    setState(() {
      _activeVehicleVin = vin;
      _selectedEventId = null;
    });

    await _loadEvents();
  }

  Future<void> _handleReviewAction(SafetyReviewActionRequest request) async {
    setState(() {
      _isReviewUpdating = true;
    });

    try {
      final updatedEvent = await _service.updateDrowsinessReview(
        drowsinessId: request.eventId,
        reviewStatus: request.reviewStatus,
        reviewNote: request.reviewNote,
        followUpNote: request.followUpNote,
        reviewedBy: 'operator',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _events = _events
            .map((event) => event.id == updatedEvent.id ? updatedEvent : event)
            .toList();
        _selectedEventId = updatedEvent.id;
        _isReviewUpdating = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Review updated')));
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isReviewUpdating = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to update review')));
    }
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

  String? _resolveSelectedVehicleVin(List<SafetyVehicleOption> options) {
    if (options.isEmpty) {
      return null;
    }

    if (_activeVehicleVin != null &&
        options.any((option) => option.vin == _activeVehicleVin)) {
      return _activeVehicleVin;
    }

    final preferredVin = _preferredVehicleVin(widget.initialSelectedVehicle);
    if (preferredVin != null &&
        options.any((option) => option.vin == preferredVin)) {
      return preferredVin;
    }

    if (options.any((option) => option.vin == 'VIN-0001')) {
      return 'VIN-0001';
    }

    return options.first.vin;
  }

  String? _preferredVehicleVin(Vehicle? vehicle) {
    final apiVehicleId = vehicle?.apiVehicleId?.trim();
    if (apiVehicleId != null && apiVehicleId.isNotEmpty) {
      return apiVehicleId;
    }

    final vehicleId = vehicle?.id;
    if (vehicleId != null &&
        vehicleId.trim().isNotEmpty &&
        vehicleId.startsWith('VIN-')) {
      return vehicleId.trim();
    }

    return null;
  }

  String _vehicleLabel({required String vin, required String plateNumber}) {
    final trimmedVin = vin.trim();
    final trimmedPlate = plateNumber.trim();
    if (trimmedPlate.isEmpty) {
      return trimmedVin;
    }
    return '$trimmedPlate · $trimmedVin';
  }

  String get _selectedVehicleLabel {
    final selectedOption = _vehicleOptions.where(
      (option) => option.vin == _activeVehicleVin,
    );
    if (selectedOption.isNotEmpty) {
      return selectedOption.first.label;
    }
    return _activeVehicleVin ?? 'No registered vehicles available.';
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

class _SafetyErrorState extends StatelessWidget {
  const _SafetyErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.65)),
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
