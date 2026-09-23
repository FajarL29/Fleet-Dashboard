import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../models/vehicle.dart';
import '../map_section.dart';
import '../../theme/app_theme.dart';

/// Fleet map on the overview's dark basemap, with a status legend.
class LiveTrackingMapCard extends StatelessWidget {
  const LiveTrackingMapCard({
    super.key,
    required this.mapController,
    required this.vehicles,
    required this.selectedVehicleId,
    required this.onVehicleSelected,
    required this.stateMessage,
  });

  final MapController mapController;
  final List<Vehicle> vehicles;
  final String? selectedVehicleId;
  final ValueChanged<Vehicle> onVehicleSelected;
  final String? stateMessage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppMapStyle.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: vehicles.isEmpty
                ? const _MapUnavailableState()
                : MapSection(
                    mapController: mapController,
                    vehicles: vehicles,
                    isFullScreen: false,
                    showVehicleList: false,
                    showInfoWindow: false,
                    showControls: false,
                    selectedVehicleId: selectedVehicleId,
                    onVehicleSelected: onVehicleSelected,
                    tileUrlTemplate: AppMapStyle.tileUrl,
                    tileSubdomains: AppMapStyle.tileSubdomains,
                    tileMaxNativeZoom: AppMapStyle.tileMaxNativeZoom,
                    tileAttribution: AppMapStyle.tileAttribution,
                    tileOverlayColor: AppMapStyle.tint,
                  ),
          ),
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
                  _LegendRow(color: AppColors.green, label: 'Moving'),
                  SizedBox(height: 5),
                  _LegendRow(color: AppColors.sky, label: 'Idle'),
                  SizedBox(height: 5),
                  _LegendRow(color: AppColors.red, label: 'Emergency'),
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
                  stateMessage!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label});

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
