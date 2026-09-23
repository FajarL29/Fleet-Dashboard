import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../common/subscript_label.dart';

/// One value tile inside a metric group card (e.g. "80 BPM / Average Heart
/// Rate").
class OverviewMetricTile extends StatelessWidget {
  const OverviewMetricTile({super.key, required this.tile});

  final OverviewMetricTileData tile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.tileBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.tileBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  tile.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (tile.unit != null) ...[
                const SizedBox(width: 4),
                Text(
                  tile.unit!,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          if (tile.labelSubscript == null)
            Text(
              tile.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: _labelStyle,
            )
          else
            SubscriptLabel(
              text: tile.label,
              subscript: tile.labelSubscript!,
              style: _labelStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

const _labelStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 10,
  height: 1.25,
);

class OverviewMetricTileData {
  const OverviewMetricTileData({
    required this.value,
    required this.label,
    this.unit,
    this.labelSubscript,
  });

  final String value;
  final String label;
  final String? unit;

  /// Rendered as a typographic subscript after [label] (e.g. the 2 in CO₂),
  /// which the bundled fonts do not reliably provide as a single glyph.
  final String? labelSubscript;
}
