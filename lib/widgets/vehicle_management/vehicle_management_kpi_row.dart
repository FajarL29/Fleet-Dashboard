import 'package:flutter/material.dart';

import '../../models/vehicle_management.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// All Vehicle / Online / Offline / Device Linked counters.
class VehicleManagementKpiRow extends StatelessWidget {
  const VehicleManagementKpiRow({
    super.key,
    required this.vehicles,
    required this.isWide,
    this.hasRegistry = true,
  });

  final List<ManagedVehicle> vehicles;
  final bool isWide;

  /// Device linking is a registry field; without it the counter would read
  /// zero and look like nothing is connected.
  final bool hasRegistry;

  @override
  Widget build(BuildContext context) {
    final total = vehicles.length;
    final online = vehicles.where(_isOnline).length;
    final linked = vehicles.where((vehicle) => vehicle.hasLinkedDevice).length;

    final cards = [
      _KpiCard(
        title: 'All Vehicle',
        value: '$total',
        caption: total == 0 ? 'No vehicles registered' : 'Fleet registry',
        icon: Icons.directions_bus_rounded,
      ),
      _KpiCard(
        title: 'Online Vehicles',
        value: total == 0 ? '-' : '$online/$total',
        caption: _percentCaption(online, total),
        icon: Icons.language_rounded,
      ),
      _KpiCard(
        title: 'Offline Vehicles',
        value: total == 0 ? '-' : '${total - online}/$total',
        caption: _percentCaption(total - online, total),
        icon: Icons.public_off_rounded,
      ),
      _KpiCard(
        title: 'Device Linked',
        value: (total == 0 || !hasRegistry) ? '-' : '$linked/$total',
        caption: hasRegistry
            ? _percentCaption(linked, total)
            : 'Needs registry access',
        icon: Icons.memory_rounded,
      ),
    ];

    if (!isWide) {
      return Column(
        children: [
          for (final card in cards) ...[card, const SizedBox(height: 12)],
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 14),
            Expanded(child: cards[i]),
          ],
        ],
      ),
    );
  }

  static bool _isOnline(ManagedVehicle vehicle) {
    switch (vehicle.mergedStatusLabel.toLowerCase()) {
      case 'moving':
      case 'idle':
      case 'online':
      case 'warning':
      case 'alert':
        return true;
      default:
        return false;
    }
  }

  static String _percentCaption(int value, int total) {
    if (total == 0) return 'No vehicles registered';
    return '${((value / total) * 100).round()}% of total fleet';
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.blueSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: AppColors.blue),
          ),
        ],
      ),
    );
  }
}
