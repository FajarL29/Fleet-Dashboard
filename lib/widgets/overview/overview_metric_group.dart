import 'package:flutter/material.dart';

import 'overview_metric_tile.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Card layout shared by [OverviewVitalSignCard] and
/// [OverviewAirQualityCard]: a title over a row of equal-width value tiles.
class OverviewMetricGroup extends StatelessWidget {
  const OverviewMetricGroup({
    super.key,
    required this.title,
    required this.tiles,
  });

  final String title;
  final List<OverviewMetricTileData> tiles;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: OverviewMetricTile(tile: tiles[i])),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
