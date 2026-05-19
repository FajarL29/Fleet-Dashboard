import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DeviceStatusPanel extends StatelessWidget {
  const DeviceStatusPanel({
    super.key,
    required this.totalDevices,
    required this.onlineDevices,
    required this.warningDevices,
    required this.errorDevices,
    required this.healthPercentage,
    required this.lastUpdatedLabel,
  });

  final int totalDevices;
  final int onlineDevices;
  final int warningDevices;
  final int errorDevices;
  final int healthPercentage;
  final String lastUpdatedLabel;

  @override
  Widget build(BuildContext context) {
    final progress = totalDevices == 0 ? 0.0 : onlineDevices / totalDevices;

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
          const Text(
            'Device Status',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 120,
                        height: 120,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 12,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.success,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$healthPercentage%',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$totalDevices devices',
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatusRow(
                        label: 'Online',
                        count: onlineDevices,
                        color: AppTheme.success,
                      ),
                      const SizedBox(height: 12),
                      _StatusRow(
                        label: 'Warning',
                        count: warningDevices,
                        color: AppTheme.warning,
                      ),
                      const SizedBox(height: 12),
                      _StatusRow(
                        label: 'Error',
                        count: errorDevices,
                        color: AppTheme.error,
                      ),
                      const SizedBox(height: 12),
                      _StatusRow(
                        label: 'Inactive',
                        count: (totalDevices -
                                onlineDevices -
                                warningDevices -
                                errorDevices)
                            .clamp(0, totalDevices)
                            .toInt(),
                        color: Colors.blueGrey.shade400,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Last updated: $lastUpdatedLabel',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          '$count',
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
