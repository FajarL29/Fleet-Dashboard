import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportEventLogCard extends StatelessWidget {
  const ReportEventLogCard({
    super.key,
    required this.events,
    this.emptyMessage = 'No drowsiness events found',
  });

  final List<DrowsinessEvent> events;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final sortedEvents = List<DrowsinessEvent>.from(events)
      ..sort((a, b) => b.time.compareTo(a.time));

    return ReportCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Recent Event Log',
                style: TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                height: 34,
                padding: const EdgeInsets.symmetric(horizontal: 11),
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
                        fontSize: 11,
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
          const SizedBox(height: 10),
          const _EventHeader(),
          const Divider(color: ReportStyles.border, height: 14),
          Expanded(
            child: events.isEmpty
                ? Center(
                    child: Text(
                      emptyMessage,
                      style: const TextStyle(
                        color: ReportStyles.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    children: sortedEvents.take(5).map(_EventRow.new).toList(),
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
        Expanded(flex: 24, child: Text('Time', style: style)),
        Expanded(flex: 15, child: Text('Driver', style: style)),
        Expanded(flex: 13, child: Text('Vehicle ID', style: style)),
        Expanded(flex: 12, child: Text('Severity', style: style)),
        Expanded(flex: 12, child: Text('Speed', style: style)),
        Expanded(flex: 20, child: Text('Location', style: style)),
        Expanded(flex: 16, child: Text('Review Status', style: style)),
        SizedBox(width: 24),
      ],
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow(this.event);

  final DrowsinessEvent event;

  @override
  Widget build(BuildContext context) {
    final severity = _formatRiskLevel(event.riskLevel);
    final severityColor = _severityColor(event.riskLevel);
    final driver = event.driverLabel;
    final location = _locationLabel(event);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: ReportStyles.border.withValues(alpha: 0.45),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 24,
            child: Text(
              DateFormat('MMM d, yyyy hh:mm a').format(event.time),
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 15,
            child: Row(
              children: [
                _DriverAvatar(name: driver),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    driver,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ReportStyles.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 13,
            child: Text(
              event.vehicleId.isEmpty ? '-' : event.vehicleId,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 12,
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: severityColor,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    severity,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 12,
            child: Text(
              event.formattedSpeed ?? '',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: ReportStyles.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 20,
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 14,
                  color: ReportStyles.textMuted,
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: ReportStyles.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 16,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _ReviewStatusChip(status: event.reviewStatus),
            ),
          ),
          const SizedBox(
            width: 24,
            child: Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: ReportStyles.textSecondary,
            ),
          ),
        ],
      ),
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
      width: 24,
      height: 24,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        name.substring(0, 1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReviewStatusChip extends StatelessWidget {
  const _ReviewStatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final palette = _statusPalette(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: palette.color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        palette.label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: palette.color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPalette {
  const _StatusPalette({required this.label, required this.color});

  final String label;
  final Color color;
}

_StatusPalette _statusPalette(String status) {
  switch (status.trim().toLowerCase()) {
    case 'confirmed':
      return const _StatusPalette(
        label: 'Confirmed',
        color: ReportStyles.green,
      );
    case 'false_alarm':
      return const _StatusPalette(
        label: 'False Alarm',
        color: ReportStyles.orange,
      );
    case 'follow_up_required':
      return const _StatusPalette(
        label: 'Follow-up Required',
        color: ReportStyles.blue,
      );
    case 'followed_up':
      return const _StatusPalette(
        label: 'Followed Up',
        color: ReportStyles.purple,
      );
    default:
      return const _StatusPalette(
        label: 'New / Unreviewed',
        color: ReportStyles.textSecondary,
      );
  }
}
