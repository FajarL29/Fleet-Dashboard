import 'package:flutter/material.dart';

import '../../models/vehicle_management.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import 'vehicle_status_pill.dart';

/// Detail for the vehicle selected in the list: photo, identity, trip totals
/// and the registry / telemetry fields behind them.
class VehicleDetailPanel extends StatelessWidget {
  const VehicleDetailPanel({
    super.key,
    required this.vehicle,
    this.onClose,
    this.onEdit,
    this.onDeactivate,
    this.totalTrips,
    this.totalDistanceKm,
    this.totalDuration,
  });

  final ManagedVehicle vehicle;

  /// Clears the selection, hiding this panel again.
  final VoidCallback? onClose;

  /// Opens the edit form for this vehicle. Null hides the action, which is
  /// how a read-only role will be handled once roles are enforced.
  final VoidCallback? onEdit;

  /// Retires this vehicle from the active fleet. Null hides the action, and
  /// it is already null for a vehicle that is not active.
  final VoidCallback? onDeactivate;

  /// Trip totals from the trips API. Null renders a dash rather than a zero,
  /// so an unwired backend never looks like a vehicle that never moved.
  final int? totalTrips;
  final double? totalDistanceKm;
  final Duration? totalDuration;

  @override
  Widget build(BuildContext context) {
    final selected = vehicle;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Vehicle Detail',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              if (onEdit != null)
                _PanelAction(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit vehicle',
                  onPressed: onEdit,
                ),
              if (onDeactivate != null)
                _PanelAction(
                  icon: Icons.block_rounded,
                  tooltip: 'Deactivate vehicle',
                  color: AppColors.redText,
                  onPressed: onDeactivate,
                ),
              if (onClose != null)
                _PanelAction(
                  icon: Icons.close_rounded,
                  tooltip: 'Close',
                  onPressed: onClose,
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...[
            _Hero(vehicle: selected),
            const SizedBox(height: 14),
            _StatTile(label: 'Total Trips', value: _tripsLabel),
            const SizedBox(height: 8),
            _StatTile(label: 'Total Distance', value: _distanceLabel),
            const SizedBox(height: 8),
            _StatTile(label: 'Total Duration', value: _durationLabel),
            const SizedBox(height: 14),
            _InfoRow(label: 'Driver', value: selected.assignedDriverLabel),
            _InfoRow(label: 'Device ID', value: _orDash(selected.deviceId)),
            _InfoRow(label: 'IMEI', value: _orDash(selected.imei)),
            _InfoRow(label: 'Last Position', value: _positionLabel(selected)),
            _InfoRow(label: 'Last Speed', value: _speedLabel(selected)),
          ],
        ],
      ),
    );
  }

  String get _tripsLabel => totalTrips?.toString() ?? '-';

  String get _distanceLabel {
    final distance = totalDistanceKm;
    if (distance == null) return '-';
    final rounded = distance.roundToDouble() == distance
        ? distance.toStringAsFixed(0)
        : distance.toStringAsFixed(1);
    return '$rounded KM';
  }

  String get _durationLabel {
    final duration = totalDuration;
    if (duration == null) return '-';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) return '$minutes Minutes';
    return minutes == 0 ? '$hours Hours' : '$hours Hours $minutes Minutes';
  }

  static String _orDash(String value) =>
      value.trim().isEmpty ? '-' : value.trim();

  static String _positionLabel(ManagedVehicle vehicle) {
    if (!vehicle.hasCoordinates) return '-';
    return '${vehicle.latitude!.toStringAsFixed(4)}, '
        '${vehicle.longitude!.toStringAsFixed(4)}';
  }

  static String _speedLabel(ManagedVehicle vehicle) {
    final speed = vehicle.speed;
    if (speed == null) return '-';
    return speed == speed.roundToDouble()
        ? '${speed.toInt()} km/h'
        : '${speed.toStringAsFixed(1)} km/h';
  }
}

/// One icon button in the panel's header row, sized to sit level with the
/// others rather than each call site repeating the same constraints.
class _PanelAction extends StatelessWidget {
  const _PanelAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 18,
      color: color ?? AppColors.textMuted,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      tooltip: tooltip,
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.vehicle});

  final ManagedVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _VehiclePhoto(vehicle: vehicle),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vehicle.plateNumber.isEmpty ? '-' : vehicle.plateNumber,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Flexible(child: VehicleStatusPill(vehicle: vehicle)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tileBackground,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        vehicle.lastSeenLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehiclePhoto extends StatelessWidget {
  const _VehiclePhoto({required this.vehicle});

  final ManagedVehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final url = vehicle.imageUrl.trim();

    return Container(
      width: 92,
      height: 62,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.tileBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: url.isEmpty
          ? const _FleetVanPhoto()
          : Image.network(
              url,
              fit: BoxFit.cover,
              // A broken URL is common while the fleet is being registered, so
              // it falls back to the same stock photo rather than an error box.
              errorBuilder: (context, error, stackTrace) =>
                  const _FleetVanPhoto(),
            ),
    );
  }
}

/// Stand-in photo for a vehicle that has none of its own.
///
/// A real photo reads as a vehicle at a glance where the old glyph did not,
/// and every row is the same silhouette, so a vehicle that *does* have a photo
/// stands out instead of blending into a wall of icons.
class _FleetVanPhoto extends StatelessWidget {
  const _FleetVanPhoto();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/generic_fleet_van.png',
      fit: BoxFit.cover,
      // The asset is bundled, so this only fires if it is ever removed —
      // better a glyph than a broken-image box in the middle of the table.
      errorBuilder: (context, error, stackTrace) =>
          const _TypeIcon(vehicleType: ''),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.vehicleType});

  final String vehicleType;

  @override
  Widget build(BuildContext context) {
    return Icon(_iconFor(vehicleType), size: 30, color: AppColors.blue);
  }

  static IconData _iconFor(String vehicleType) {
    final type = vehicleType.trim().toLowerCase();
    if (type.contains('truck')) return Icons.local_shipping_rounded;
    if (type.contains('bus')) return Icons.directions_bus_rounded;
    if (type.contains('car') || type.contains('sedan')) {
      return Icons.directions_car_rounded;
    }
    if (type.contains('motor')) return Icons.two_wheeler_rounded;
    return Icons.airport_shuttle_rounded;
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.tileBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
