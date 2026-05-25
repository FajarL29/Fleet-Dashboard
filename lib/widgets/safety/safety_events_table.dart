import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import '../report/report_styles.dart';

class SafetyEventsTable extends StatelessWidget {
  const SafetyEventsTable({
    super.key,
    required this.events,
    required this.selectedEventId,
    required this.onEventSelected,
  });

  final List<DrowsinessEvent> events;
  final int? selectedEventId;
  final ValueChanged<DrowsinessEvent> onEventSelected;

  @override
  Widget build(BuildContext context) {
    final timeFormatter = DateFormat('MMM d, yyyy\nhh:mm:ss a');

    return Container(
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withOpacity(0.65)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Text(
              'Events List (${events.length})',
              style: const TextStyle(
                color: ReportStyles.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const _HeaderRow(),
          const Divider(color: ReportStyles.border, height: 1),
          Expanded(
            child: ListView.separated(
              itemCount: events.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: ReportStyles.border, height: 1),
              itemBuilder: (context, index) {
                final event = events[index];
                final isSelected = event.id == selectedEventId;

                return Material(
                  color: isSelected
                      ? const Color(0xFF162C52)
                      : Colors.transparent,
                  child: InkWell(
                    onTap: () => onEventSelected(event),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          _TableCell(
                            flex: 22,
                            child: Text(
                              timeFormatter.format(event.time),
                              style: const TextStyle(
                                color: ReportStyles.textPrimary,
                                fontWeight: FontWeight.w600,
                                height: 1.35,
                              ),
                            ),
                          ),
                          _TableCell(
                            flex: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _eventTypeLabel(event),
                                  style: const TextStyle(
                                    color: ReportStyles.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _ReviewStatusText(status: event.reviewStatus),
                              ],
                            ),
                          ),
                          _TableCell(
                            flex: 13,
                            child: Text(
                              event.driverLabel,
                              style: const TextStyle(
                                color: ReportStyles.textPrimary,
                              ),
                            ),
                          ),
                          _TableCell(
                            flex: 13,
                            child: Text(
                              event.vehicleId.isEmpty ? '-' : event.vehicleId,
                              style: const TextStyle(
                                color: ReportStyles.textPrimary,
                              ),
                            ),
                          ),
                          _TableCell(
                            flex: 11,
                            child: _SeverityChip(label: _severityLabel(event)),
                          ),
                          _TableCell(
                            flex: 10,
                            child: Text(
                              event.formattedSpeed ?? '-',
                              style: const TextStyle(
                                color: ReportStyles.textPrimary,
                              ),
                            ),
                          ),
                          _TableCell(
                            flex: 18,
                            child: Text(
                              _locationLabel(event),
                              style: const TextStyle(
                                color: ReportStyles.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                          _TableCell(
                            flex: 9,
                            child: Center(
                              child: OutlinedButton(
                                onPressed: () => onEventSelected(event),
                                child: const Icon(
                                  Icons.visibility_outlined,
                                  size: 18,
                                ),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: ReportStyles.textPrimary,
                                  side: const BorderSide(
                                    color: ReportStyles.border,
                                  ),
                                  minimumSize: const Size(40, 40),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static String _eventTypeLabel(DrowsinessEvent event) {
    final source = (event.behaviorType ?? event.status).trim();
    if (source.isEmpty) {
      return '-';
    }

    return source
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }

  static String _locationLabel(DrowsinessEvent event) {
    if (event.latitude != null && event.longitude != null) {
      return '${event.latitude!.toStringAsFixed(5)},\n${event.longitude!.toStringAsFixed(5)}';
    }

    return event.location?.trim().isNotEmpty == true
        ? event.location!
        : 'Unknown';
  }

  static String _severityLabel(DrowsinessEvent event) {
    final label = event.riskLevel.trim();
    return label.isEmpty ? 'Unknown' : _titleCase(label);
  }

  static String _titleCase(String value) {
    return value
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: ReportStyles.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return const Padding(
      padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          _TableCell(flex: 22, child: Text('Time', style: style)),
          _TableCell(flex: 16, child: Text('Event Type', style: style)),
          _TableCell(flex: 13, child: Text('Driver/User', style: style)),
          _TableCell(flex: 13, child: Text('Vehicle', style: style)),
          _TableCell(flex: 11, child: Text('Severity', style: style)),
          _TableCell(flex: 10, child: Text('Speed', style: style)),
          _TableCell(flex: 18, child: Text('Location', style: style)),
          _TableCell(
            flex: 9,
            child: Center(child: Text('Action', style: style)),
          ),
        ],
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  const _TableCell({
    required this.flex,
    required this.child,
  });

  final int flex;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(flex: flex, child: child);
  }
}

class _SeverityChip extends StatelessWidget {
  const _SeverityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final normalized = label.toLowerCase();
    Color color;
    switch (normalized) {
      case 'high':
        color = ReportStyles.red;
        break;
      case 'medium':
        color = ReportStyles.orange;
        break;
      case 'low':
        color = const Color(0xFF3BA55D);
        break;
      default:
        color = ReportStyles.textSecondary;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.16),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _ReviewStatusText extends StatelessWidget {
  const _ReviewStatusText({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'confirmed':
        color = ReportStyles.green;
        break;
      case 'false_alarm':
        color = ReportStyles.orange;
        break;
      case 'follow_up_required':
        color = ReportStyles.blue;
        break;
      case 'followed_up':
        color = ReportStyles.purple;
        break;
      case 'new':
      default:
        color = ReportStyles.textMuted;
        break;
    }

    return Text(
      _reviewStatusLabel(status),
      style: TextStyle(
        color: color,
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  String _reviewStatusLabel(String value) {
    return value
        .replaceAll('_', ' ')
        .split(RegExp(r'[\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}')
        .join(' ');
  }
}
