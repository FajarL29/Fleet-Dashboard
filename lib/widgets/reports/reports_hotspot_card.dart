import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import 'reports_hotspot.dart';

/// Where drowsiness happens: clustered events plotted on the map, each marker
/// sized and coloured by how busy that spot is.
class ReportsHotspotCard extends StatelessWidget {
  const ReportsHotspotCard({
    super.key,
    required this.mapController,
    required this.hotspots,
    required this.emptyMessage,
    this.height = 240,
    this.fill = false,
  });

  final MapController mapController;

  /// Highest event count first.
  final List<ReportsHotspot> hotspots;
  final String emptyMessage;

  /// Height of the map area when [fill] is false.
  final double height;

  /// Take whatever height the parent gives instead, so the page can size
  /// the card to fit one screen.
  final bool fill;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Drowsiness Hotspot',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              if (hotspots.isNotEmpty)
                Text(
                  '${hotspots.length} location'
                  '${hotspots.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Expanded when the page sizes the card; a fixed box otherwise.
          _ChartArea(
            fill: fill,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: hotspots.isEmpty
                  ? Container(
                      color: AppColors.tileBackground,
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  : FlutterMap(
                      mapController: mapController,
                      options: MapOptions(
                        initialCenter: hotspots.first.position,
                        initialZoom: 9,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.fleet.dashboard',
                        ),
                        MarkerLayer(markers: _markers),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  List<Marker> get _markers {
    final busiest = hotspots.first.eventCount;

    return [
      for (final hotspot in hotspots)
        Marker(
          point: hotspot.position,
          width: 72,
          height: 72,
          child: _HotspotMarker(
            hotspot: hotspot,
            intensity: busiest <= 0
                ? 0
                : (hotspot.eventCount / busiest).clamp(0.0, 1.0).toDouble(),
          ),
        ),
    ];
  }
}

/// A warning pin with a soft halo whose reach grows with the event count.
class _HotspotMarker extends StatelessWidget {
  const _HotspotMarker({required this.hotspot, required this.intensity});

  final ReportsHotspot hotspot;

  /// 0 to 1, relative to the busiest hotspot.
  final double intensity;

  @override
  Widget build(BuildContext context) {
    // Busiest reads red, quietest amber, matching the severity colours used
    // everywhere else on this page.
    final colour = Color.lerp(AppColors.amber, AppColors.red, intensity)!;
    final pin = 26 + 8 * intensity;
    final halo = pin + 20 + 22 * intensity;

    final highRisk = hotspot.highRiskCount;

    return Tooltip(
      message:
          '${hotspot.label}\n${hotspot.eventCount} event'
          '${hotspot.eventCount == 1 ? '' : 's'}'
          '${highRisk > 0 ? ', $highRisk high risk' : ''}',
      child: Center(
        child: Container(
          width: halo,
          height: halo,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                colour.withValues(alpha: 0.45),
                colour.withValues(alpha: 0.16),
                colour.withValues(alpha: 0.0),
              ],
              stops: const [0.35, 0.65, 1],
            ),
          ),
          child: Center(
            child: Container(
              width: pin,
              height: pin,
              decoration: BoxDecoration(
                color: colour,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.warning_amber_rounded,
                size: 15,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Gives the map either the height it was told, or whatever is left in the
/// card, depending on how the page laid this card out.
class _ChartArea extends StatelessWidget {
  const _ChartArea({
    required this.fill,
    required this.height,
    required this.child,
  });

  final bool fill;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (fill) return Expanded(child: child);
    return SizedBox(height: height, child: child);
  }
}
