import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportMapCard extends StatefulWidget {
  const ReportMapCard({super.key, required this.events});

  final List<DrowsinessEvent> events;

  @override
  State<ReportMapCard> createState() => _ReportMapCardState();
}

class _ReportMapCardState extends State<ReportMapCard> {
  DrowsinessEvent? _selectedEvent;

  @override
  void didUpdateWidget(covariant ReportMapCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selectedEvent = _selectedEvent;
    if (selectedEvent == null) {
      return;
    }

    final stillExists = widget.events.any(
      (event) =>
          identical(event, selectedEvent) || event.id == selectedEvent.id,
    );
    if (!stillExists) {
      _selectedEvent = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final markerEvents = widget.events.where(_hasValidCoordinates).toList();
    final center = _mapCenter(markerEvents);
    final selectedEvent =
        markerEvents.any(
          (event) =>
              identical(event, _selectedEvent) ||
              event.id == _selectedEvent?.id,
        )
        ? _selectedEvent
        : null;

    return ReportCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 255,
          child: Stack(
            children: [
              if (markerEvents.isEmpty)
                Positioned.fill(
                  child: _MapEmptyState(totalEvents: widget.events.length),
                )
              else
                Positioned.fill(
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: center,
                      initialZoom: _initialZoom(markerEvents.length),
                      minZoom: 4,
                      maxZoom: 18,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.fleet.dashboard',
                      ),
                      MarkerLayer(
                        markers: markerEvents
                            .map(
                              (event) => Marker(
                                point: LatLng(
                                  event.latitude!,
                                  event.longitude!,
                                ),
                                width: 56,
                                height: 56,
                                child: _DrowsinessMapMarker(
                                  event: event,
                                  isSelected: identical(event, selectedEvent),
                                  onTap: () {
                                    setState(() {
                                      _selectedEvent =
                                          identical(_selectedEvent, event)
                                          ? null
                                          : event;
                                    });
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              Positioned(
                left: 16,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: ReportStyles.cardBackground.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: ReportStyles.border),
                  ),
                  child: const Text(
                    'Drowsiness Event Map',
                    style: TextStyle(
                      color: ReportStyles.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                top: 52,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: ReportStyles.cardBackground.withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: ReportStyles.border),
                  ),
                  child: Text(
                    markerEvents.isEmpty
                        ? 'No mapped events in current filter'
                        : '${markerEvents.length} mapped event${markerEvents.length == 1 ? '' : 's'}',
                    style: const TextStyle(
                      color: ReportStyles.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (selectedEvent != null)
                Positioned(
                  right: 16,
                  bottom: 14,
                  child: SizedBox(
                    width: 220,
                    child: _EventInfoCard(event: selectedEvent),
                  ),
                )
              else if (markerEvents.isNotEmpty)
                Positioned(
                  right: 16,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: ReportStyles.cardBackground.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ReportStyles.border),
                    ),
                    child: const Text(
                      'Tap a marker for event details',
                      style: TextStyle(
                        color: ReportStyles.textSecondary,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _hasValidCoordinates(DrowsinessEvent event) {
    final lat = event.latitude;
    final lng = event.longitude;
    return lat != null &&
        lng != null &&
        lat >= -90 &&
        lat <= 90 &&
        lng >= -180 &&
        lng <= 180;
  }

  double _initialZoom(int markerCount) {
    if (markerCount <= 1) return 12.5;
    if (markerCount <= 5) return 11.2;
    if (markerCount <= 20) return 10.5;
    return 9.6;
  }

  LatLng _mapCenter(List<DrowsinessEvent> markerEvents) {
    if (markerEvents.isEmpty) {
      return const LatLng(-6.2000, 106.8167);
    }

    final total = markerEvents.fold<({double lat, double lng})>(
      (lat: 0.0, lng: 0.0),
      (sum, event) =>
          (lat: sum.lat + event.latitude!, lng: sum.lng + event.longitude!),
    );

    return LatLng(
      total.lat / markerEvents.length,
      total.lng / markerEvents.length,
    );
  }
}

class _MapEmptyState extends StatelessWidget {
  const _MapEmptyState({required this.totalEvents});

  final int totalEvents;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF111A28), Color(0xFF0C1420)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: ReportStyles.surfaceBackgroundSoft,
                  border: Border.all(color: ReportStyles.borderStrong),
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: ReportStyles.textSecondary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'No event location data available for this period.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                totalEvents == 0
                    ? 'No filtered events were returned for the current selection.'
                    : 'The current filtered events do not include valid latitude and longitude values.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: ReportStyles.textSecondary,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventInfoCard extends StatelessWidget {
  const _EventInfoCard({required this.event});

  final DrowsinessEvent event;

  @override
  Widget build(BuildContext context) {
    final eventType = _eventTypeLabel(event);
    final locationLabel = _locationLabel(event);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.borderStrong),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _severityColor(event.riskLevel),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  eventType,
                  style: TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _severityColor(
                    event.riskLevel,
                  ).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _severityLabel(event.riskLevel),
                  style: TextStyle(
                    color: _severityColor(event.riskLevel),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.schedule_rounded,
            label: DateFormat('MMM d, yyyy - hh:mm a').format(event.time),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.person_outline_rounded,
            label: event.driverLabel,
          ),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.place_outlined, label: locationLabel),
          const SizedBox(height: 8),
          _InfoRow(
            icon: Icons.my_location_rounded,
            label:
                '${event.latitude!.toStringAsFixed(5)}, ${event.longitude!.toStringAsFixed(5)}',
          ),
        ],
      ),
    );
  }

  String _eventTypeLabel(DrowsinessEvent event) {
    final value = event.behaviorType?.trim();
    if (value == null || value.isEmpty) {
      return 'Drowsiness Event';
    }

    return value
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String _locationLabel(DrowsinessEvent event) {
    final location = event.location?.trim();
    if (location != null && location.isNotEmpty) {
      return location;
    }
    return 'Location not provided';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ReportStyles.textMuted, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _DrowsinessMapMarker extends StatelessWidget {
  const _DrowsinessMapMarker({
    required this.event,
    required this.isSelected,
    required this.onTap,
  });

  final DrowsinessEvent event;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(event.riskLevel);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: isSelected ? 52 : 46,
            height: isSelected ? 52 : 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: isSelected ? 0.28 : 0.18),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: isSelected ? 30 : 24,
            height: isSelected ? 30 : 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
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
              size: 15,
            ),
          ),
        ],
      ),
    );
  }
}

Color _severityColor(String value) {
  switch (value.toLowerCase()) {
    case 'critical':
    case 'critical_risk':
    case 'high':
    case 'high_risk':
      return ReportStyles.redSoft;
    case 'medium':
    case 'medium_risk':
      return ReportStyles.orange;
    case 'low':
    case 'low_risk':
      return ReportStyles.yellow;
    default:
      return ReportStyles.blue;
  }
}

String _severityLabel(String value) {
  switch (value.toLowerCase()) {
    case 'critical':
    case 'critical_risk':
      return 'Critical';
    case 'high':
    case 'high_risk':
      return 'High';
    case 'medium':
    case 'medium_risk':
      return 'Medium';
    case 'low':
    case 'low_risk':
      return 'Low';
    default:
      return 'Unknown';
  }
}
