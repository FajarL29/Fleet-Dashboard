import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';

class LatestSafetyAlertsPanel extends StatelessWidget {
  const LatestSafetyAlertsPanel({super.key, required this.alerts});

  final List<Map<String, dynamic>> alerts;

  @override
  Widget build(BuildContext context) {
    final visibleAlerts = alerts.take(3).toList();

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
          const Row(
            children: [
              Text(
                'Latest Safety Alerts',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                'Live feed',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: visibleAlerts.isEmpty
                ? const Center(
                    child: Text(
                      'No drowsiness events found',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: visibleAlerts.length,
                    separatorBuilder: (_, __) => Divider(
                      color: Colors.white.withOpacity(0.06),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final alert = visibleAlerts[index];
                      final severityColor = _severityColor(
                        alert['severity']?.toString() ?? 'Low',
                      );
                      final time = _formatTime(alert['time']);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: severityColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.warning_rounded,
                                color: severityColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert['eventType']?.toString() ??
                                        'Safety Alert',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 10,
                                    runSpacing: 4,
                                    children: [
                                      _MetaText(
                                        alert['driverName']?.toString() ?? '-',
                                      ),
                                      _MetaText(
                                        alert['vehicleLabel']?.toString() ??
                                            '-',
                                      ),
                                      _MetaText(
                                        alert['location']?.toString() ?? '-',
                                      ),
                                      if ((alert['speedLabel']?.toString() ??
                                              '')
                                          .isNotEmpty)
                                        _MetaText(
                                          'Speed: ${alert['speedLabel']}',
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              time,
                              style: TextStyle(
                                color: severityColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatTime(dynamic value) {
    final time = value is DateTime
        ? value
        : DateTime.tryParse(value?.toString() ?? '')?.toLocal();

    if (time == null) {
      return '--:--';
    }

    final now = DateTime.now();
    final isToday =
        time.year == now.year && time.month == now.month && time.day == now.day;

    return isToday
        ? DateFormat('HH:mm').format(time)
        : DateFormat('MMM d, HH:mm').format(time);
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

class _MetaText extends StatelessWidget {
  const _MetaText(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
    );
  }
}
