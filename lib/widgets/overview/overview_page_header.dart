import 'package:flutter/material.dart';

import '../../models/vehicle_status.dart';
import '../../theme/app_theme.dart';
import '../common/last_updated_label.dart';

/// Page title, last-updated line and the fleet status pill.
class OverviewPageHeader extends StatelessWidget {
  const OverviewPageHeader({
    super.key,
    required this.lastUpdated,
    required this.vehicleStatusData,
    required this.isWide,
  });

  final DateTime lastUpdated;
  final VehicleStatusData? vehicleStatusData;
  final bool isWide;

  /// Fleet is healthy unless the status feed reports alerts or warnings.
  _FleetStatus get _status {
    final summary = vehicleStatusData?.summary;
    final items = vehicleStatusData?.vehicles ?? const <VehicleStatusItem>[];

    final alert =
        summary?.alert ??
        items
            .where((item) => item.safetyStatus.trim().toLowerCase() == 'alert')
            .length;
    final warning =
        summary?.warning ??
        items
            .where(
              (item) => item.displayStatus.trim().toLowerCase() == 'warning',
            )
            .length;

    if (alert > 0) {
      return const _FleetStatus('Attention', AppColors.red);
    }
    if (warning > 0) {
      return const _FleetStatus('Warning', AppColors.amber);
    }
    return const _FleetStatus('Normal', AppColors.green);
  }

  @override
  Widget build(BuildContext context) {
    final status = _status;

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Telematics Overview',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 6),
        LastUpdatedLabel(timestamp: lastUpdated),
      ],
    );

    final pill = _FleetStatusPill(label: status.label, color: status.color);

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 14), pill],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        pill,
      ],
    );
  }
}

class _FleetStatus {
  const _FleetStatus(this.label, this.color);

  final String label;
  final Color color;
}

class _FleetStatusPill extends StatelessWidget {
  const _FleetStatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 9, 20, 9),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            color.withValues(alpha: 0.18),
            color.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.28),
            ),
            child: Center(
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Fleet Status',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  color: _readableOn(color),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _readableOn(Color color) {
    if (color == AppColors.green) return AppColors.greenText;
    if (color == AppColors.amber) return AppColors.amberText;
    if (color == AppColors.red) return AppColors.redText;
    return AppColors.textPrimary;
  }
}
