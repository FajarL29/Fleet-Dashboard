import 'package:flutter/material.dart';

import '../../models/vehicle_management.dart';
import '../../theme/app_theme.dart';

/// Dot-and-label pill for a vehicle's merged registry + telemetry status.
class VehicleStatusPill extends StatelessWidget {
  const VehicleStatusPill({super.key, required this.vehicle});

  final ManagedVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final label = vehicle.mergedStatusLabel;
    final (background, foreground) = _colorsFor(label);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: foreground,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  static (Color, Color) _colorsFor(String label) {
    switch (label.toLowerCase()) {
      case 'moving':
      case 'online':
        return (AppColors.greenSoft, AppColors.greenText);
      case 'idle':
      case 'warning':
        return (AppColors.amberSoft, AppColors.amberText);
      case 'alert':
        return (AppColors.redSoft, AppColors.redText);
      case 'offline':
        return (AppColors.redSoft, AppColors.redText);
      default:
        return (AppColors.tileBackground, AppColors.textSecondary);
    }
  }
}
