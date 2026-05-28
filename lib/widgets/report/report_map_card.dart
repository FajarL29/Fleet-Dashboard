import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportMapCard extends StatelessWidget {
  const ReportMapCard({
    super.key,
    required this.events,
  });

  final List<DrowsinessEvent> events;

  @override
  Widget build(BuildContext context) {
    final markerEvents = events
        .where((event) => event.latitude != null && event.longitude != null)
        .toList();
    final center = _mapCenter(markerEvents);

    return ReportCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned.fill(
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: center,
                  initialZoom: markerEvents.isEmpty ? 9.5 : 10.5,
                  minZoom: 4,
                  maxZoom: 18,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.fleet.dashboard',
                  ),
                  MarkerLayer(
                    markers: markerEvents
                        .map(
                          (event) => Marker(
                            point: LatLng(event.latitude!, event.longitude!),
                            width: 54,
                            height: 54,
                            child: _DrowsinessMapMarker(event: event),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 16,
              top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ReportStyles.cardBackground.withValues(alpha: 0.86),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ReportStyles.border),
                  ),
                child: const Text(
                  'Drowsiness Event Map',
                  style: TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (markerEvents.isEmpty)
              Positioned(
                right: 16,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: ReportStyles.cardBackground.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ReportStyles.border),
                  ),
                  child: const Text(
                    'Waiting for event history coordinates',
                    style: TextStyle(
                      color: ReportStyles.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              bottom: 12,
              child: Container(
                width: 104,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: ReportStyles.cardBackground.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: ReportStyles.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Event Density',
                      style: TextStyle(
                        color: ReportStyles.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${markerEvents.length} mapped',
                      style: const TextStyle(
                        color: ReportStyles.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [
                            ReportStyles.yellow,
                            ReportStyles.orange,
                            ReportStyles.red,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Row(
                      children: [
                        Text(
                          'Low',
                          style: TextStyle(
                            color: ReportStyles.textMuted,
                            fontSize: 9,
                          ),
                        ),
                        Spacer(),
                        Text(
                          'High',
                          style: TextStyle(
                            color: ReportStyles.textMuted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLng _mapCenter(List<DrowsinessEvent> markerEvents) {
    if (markerEvents.isEmpty) {
      return const LatLng(-6.3054, 107.3057);
    }

    final total = markerEvents.fold<({double lat, double lng})>(
      (lat: 0.0, lng: 0.0),
      (sum, event) => (
        lat: sum.lat + event.latitude!,
        lng: sum.lng + event.longitude!,
      ),
    );

    return LatLng(
      total.lat / markerEvents.length,
      total.lng / markerEvents.length,
    );
  }
}

class _DrowsinessMapMarker extends StatelessWidget {
  const _DrowsinessMapMarker({
    required this.event,
  });

  final DrowsinessEvent event;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(event.riskLevel);
    final title = event.location?.isNotEmpty == true
        ? event.location!
        : '${event.latitude?.toStringAsFixed(5)}, ${event.longitude?.toStringAsFixed(5)}';

    return Tooltip(
      message:
          '${event.driverLabel}\n${DateFormat('MMM d, hh:mm a').format(event.time)}\n$title',
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.22),
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: 0.92),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return ReportStyles.red;
      case 'medium':
        return ReportStyles.orange;
      case 'low':
        return ReportStyles.yellow;
      default:
        return ReportStyles.blue;
    }
  }
}
