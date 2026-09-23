import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../models/vehicle.dart';
import '../../models/vehicle_status.dart';
import '../map_section.dart';
import '../../theme/app_theme.dart';

/// Live fleet map with the status legend, on the overview's dark basemap.
class OverviewMapCard extends StatelessWidget {
  const OverviewMapCard({
    super.key,
    required this.mapController,
    required this.vehicles,
    required this.selectedVehicleId,
    required this.vehicleStatusData,
    required this.vehicleStatusError,
    required this.onFollowModeChanged,
    required this.onOpenFullscreen,
  });

  final MapController mapController;
  final List<Vehicle> vehicles;
  final String? selectedVehicleId;
  final VehicleStatusData? vehicleStatusData;
  final String? vehicleStatusError;
  final ValueChanged<bool> onFollowModeChanged;
  final VoidCallback onOpenFullscreen;

  /// Why the map has nothing to show, or null when it is healthy.
  String? get _stateMessage {
    if (vehicleStatusError != null && vehicleStatusData == null) {
      return vehicleStatusError;
    }
    if ((vehicleStatusData?.vehicles ?? const []).isEmpty) {
      return 'Vehicle status data unavailable';
    }
    if (vehicles.isEmpty) {
      return 'No vehicle coordinates available';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final stateMessage = _stateMessage;
    final onExpand = vehicles.isEmpty ? null : onOpenFullscreen;
    final map = vehicles.isEmpty
        ? const _MapUnavailableState()
        : MapSection(
            mapController: mapController,
            vehicles: vehicles,
            useLocalSelection: true,
            isFullScreen: false,
            onFullScreenToggle: onOpenFullscreen,
            showVehicleList: false,
            showControls: false,
            selectedVehicleId: selectedVehicleId,
            onFollowModeChanged: onFollowModeChanged,
            tileUrlTemplate: AppMapStyle.tileUrl,
            tileSubdomains: AppMapStyle.tileSubdomains,
            tileMaxNativeZoom: AppMapStyle.tileMaxNativeZoom,
            tileAttribution: AppMapStyle.tileAttribution,
            tileOverlayColor: AppMapStyle.tint,
          );

    return Container(
      decoration: BoxDecoration(
        color: AppMapStyle.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: map),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
              decoration: BoxDecoration(
                color: AppMapStyle.overlayBackground,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MapLegendRow(color: AppColors.green, label: 'Moving'),
                  SizedBox(height: 5),
                  _MapLegendRow(color: AppColors.sky, label: 'Idle'),
                  SizedBox(height: 5),
                  _MapLegendRow(color: AppColors.red, label: 'Emergency'),
                ],
              ),
            ),
          ),
          if (stateMessage != null)
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 210),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppMapStyle.overlayBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  stateMessage,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
          if (onExpand != null)
            Positioned(
              right: 12,
              top: 12,
              child: Material(
                color: AppMapStyle.buttonBackground,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: onExpand,
                  child: const Padding(
                    padding: EdgeInsets.all(7),
                    child: Icon(
                      Icons.open_in_full_rounded,
                      size: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MapLegendRow extends StatelessWidget {
  const _MapLegendRow({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 9.5),
        ),
      ],
    );
  }
}

class _MapUnavailableState extends StatelessWidget {
  const _MapUnavailableState();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppMapStyle.background,
      child: Center(
        child: Text(
          'Vehicle location data unavailable',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ),
    );
  }
}
