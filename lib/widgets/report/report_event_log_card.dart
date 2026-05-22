import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportEventLogCard extends StatelessWidget {
  const ReportEventLogCard({
    super.key,
    required this.events,
  });

  final List<DrowsinessEvent> events;

  @override
  Widget build(BuildContext context) {
    final sortedEvents = List<DrowsinessEvent>.from(events)
      ..sort((a, b) => b.time.compareTo(a.time));

    return ReportCard(
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Recent Event Log',
                style: TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: ReportStyles.surfaceBackground,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ReportStyles.border),
                ),
                child: const Row(
                  children: [
                    Text(
                      'View All Events',
                      style: TextStyle(
                        color: ReportStyles.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _EventHeader(),
          const Divider(color: ReportStyles.border, height: 18),
          Expanded(
            child: events.isEmpty
                ? const Center(
                    child: Text(
                      'No drowsiness events found',
                      style: TextStyle(
                        color: ReportStyles.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    children: sortedEvents
                        .take(5)
                        .map(
                          (event) => Expanded(
                            child: _EventRow(event: event),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventHeader extends StatelessWidget {
  const _EventHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      color: ReportStyles.textMuted,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    );

    return const Row(
      children: [
        Expanded(flex: 22, child: Text('Time', style: style)),
        Expanded(flex: 16, child: Text('Driver', style: style)),
        Expanded(flex: 14, child: Text('Vehicle ID', style: style)),
        Expanded(flex: 14, child: Text('Severity', style: style)),
        Expanded(flex: 18, child: Text('Speed', style: style)),
        Expanded(flex: 24, child: Text('Location', style: style)),
        SizedBox(width: 24),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({
    required this.event,
  });

  final DrowsinessEvent event;

  @override
  Widget build(BuildContext context) {
    final severity = _formatRiskLevel(event.riskLevel);
    final severityColor = _severityColor(event.riskLevel);
    final driver = event.driverLabel;
    final location = _locationLabel(event);

    return Row(
      children: [
        Expanded(
          flex: 22,
          child: Text(
            DateFormat('MMM d, yyyy hh:mm a').format(event.time),
            style: const TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 16,
          child: Row(
            children: [
              _DriverAvatar(name: driver),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  driver,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 14,
          child: Text(
            event.vehicleId.isEmpty ? '-' : event.vehicleId,
            style: const TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 14,
          child: Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: severityColor,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  severity,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 18,
          child: Text(
            event.formattedSpeed ?? '',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          flex: 24,
          child: Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: ReportStyles.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  location,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: ReportStyles.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 24,
          child: Icon(
            Icons.chevron_right_rounded,
            color: ReportStyles.textSecondary,
          ),
        ),
      ],
    );
  }

  String _formatRiskLevel(String value) {
    if (value.isEmpty) return 'Unknown';
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  Color _severityColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return ReportStyles.red;
      case 'medium':
        return ReportStyles.orange;
      case 'low':
        return ReportStyles.yellow;
      default:
        return ReportStyles.textMuted;
    }
  }

  String _locationLabel(DrowsinessEvent event) {
    if (event.location?.isNotEmpty == true) {
      return event.location!;
    }

    if (event.latitude != null && event.longitude != null) {
      return '${event.latitude!.toStringAsFixed(5)}, ${event.longitude!.toStringAsFixed(5)}';
    }

    return 'Unknown location';
  }
}

class _DriverAvatar extends StatelessWidget {
  const _DriverAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final bg = [
      const Color(0xFF3385FF),
      const Color(0xFF4A5A70),
      const Color(0xFF218C74),
      const Color(0xFF7F8FA6),
    ][name.length % 4];

    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        name.substring(0, 1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
