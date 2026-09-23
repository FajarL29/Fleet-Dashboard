import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import 'air_quality_level.dart';
import 'air_quality_reading.dart';

/// Route the vehicle travelled, coloured by the AQI measured along the way.
class AirQualityMapCard extends StatelessWidget {
  const AirQualityMapCard({
    super.key,
    required this.mapController,
    required this.readings,
    required this.emptyMessage,
    this.height = 300,
    this.expandMap = false,
  });

  final MapController mapController;

  /// Samples with a position, oldest first.
  final List<AirQualityReading> readings;
  final String emptyMessage;
  final double height;
  final bool expandMap;

  @override
  Widget build(BuildContext context) {
    final located = readings
        .where((reading) => reading.position != null)
        .toList();

    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Air Quality Map Tracking',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              const _Legend(),
            ],
          ),
          const SizedBox(height: 16),
          if (expandMap)
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: located.isEmpty
                    ? _EmptyMap(message: emptyMessage)
                    : _RouteMap(
                        mapController: mapController,
                        readings: located,
                      ),
              ),
            )
          else
            SizedBox(
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: located.isEmpty
                    ? _EmptyMap(message: emptyMessage)
                    : _RouteMap(
                        mapController: mapController,
                        readings: located,
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RouteMap extends StatelessWidget {
  const _RouteMap({required this.mapController, required this.readings});

  final MapController mapController;
  final List<AirQualityReading> readings;

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: readings.first.position!,
        initialZoom: 11,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.fleet.dashboard',
        ),
        PolylineLayer(polylines: _segments),
        MarkerLayer(markers: _markers),
      ],
    );
  }

  /// One polyline per pair of samples, coloured by the AQI at its start, so
  /// the route shifts colour as air quality changes along the way.
  List<Polyline> get _segments {
    final segments = <Polyline>[];
    for (var i = 0; i < readings.length - 1; i++) {
      final from = readings[i];
      final to = readings[i + 1];
      segments.add(
        Polyline(
          points: [from.position!, to.position!],
          strokeWidth: 5,
          color: from.level?.color ?? AppColors.textMuted,
        ),
      );
    }
    return segments;
  }

  List<Marker> get _markers {
    return [
      for (final reading in readings)
        Marker(
          point: reading.position!,
          width: 14,
          height: 14,
          child: Container(
            decoration: BoxDecoration(
              color: reading.level?.color ?? AppColors.textMuted,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
    ];
  }
}

class _EmptyMap extends StatelessWidget {
  const _EmptyMap({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.tileBackground,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final level in AirQualityLevel.values) _LegendItem(level: level),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.level});

  final AirQualityLevel level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: level.color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              level.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10.5,
                height: 1.2,
              ),
            ),
            Text(
              level.range,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 8.5,
                height: 1.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
