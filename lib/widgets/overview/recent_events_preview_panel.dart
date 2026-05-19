import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';

class RecentEventsPreviewPanel extends StatelessWidget {
  const RecentEventsPreviewPanel({
    super.key,
    required this.events,
  });

  final List<Map<String, dynamic>> events;

  @override
  Widget build(BuildContext context) {
    final visibleEvents = events.take(4).toList();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
      decoration: BoxDecoration(
        color: AppTheme.slateGrey,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Recent Events',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all events',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: visibleEvents.isEmpty
                ? const Center(
                    child: Text(
                      'No recent events',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < visibleEvents.length; i++) ...[
                        _PreviewRow(event: visibleEvents[i]),
                        if (i != visibleEvents.length - 1)
                          Divider(
                            color: Colors.white.withOpacity(0.06),
                            height: 12,
                          ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.event,
  });

  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final severity = event['severity']?.toString() ?? 'Low';
    final severityColor = _severityColor(severity);

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: severityColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event['eventType']?.toString() ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${event['driverName'] ?? '-'} · ${event['vehicleLabel'] ?? '-'}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Text(
          _formatTime(event['time']),
          style: TextStyle(
            color: severityColor,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _formatTime(dynamic value) {
    final time = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '')?.toLocal();

    if (time == null) {
      return '--:--';
    }

    return DateFormat('HH:mm').format(time);
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return AppTheme.error;
      case 'medium':
        return AppTheme.warning;
      default:
        return Colors.blueGrey.shade300;
    }
  }
}
