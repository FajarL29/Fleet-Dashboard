import 'package:flutter/material.dart';

import '../../models/drowsiness_report.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';
import 'safety_event_media.dart';
import 'safety_event_table.dart';

/// Footage and context for the event selected in the table.
class SafetyEventDetailPanel extends StatelessWidget {
  const SafetyEventDetailPanel({super.key, required this.event, this.onClose});

  final DrowsinessEvent event;

  /// Clears the selection, hiding this panel again.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _Tile(label: 'Event ID', value: '${event.id}'),
      _Tile(label: 'Event Type', value: safetyEventTypeLabel(event)),
      _Tile(label: 'Speed', value: safetySpeedLabel(event)),
      _Tile(label: 'Location', value: safetyLocationLabel(event)),
      _Tile(label: 'Status', value: _statusLabel),
      _Tile(label: 'Risk Level', value: _riskLabel, emphasis: true),
    ];

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
                  'Event Detail',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              if (onClose != null)
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close_rounded),
                  iconSize: 18,
                  color: AppColors.textMuted,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  tooltip: 'Close',
                ),
            ],
          ),
          const SizedBox(height: 10),
          SafetyEventMedia(event: event),
          const SizedBox(height: 16),
          for (var i = 0; i < tiles.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 8),
            // IntrinsicHeight bounds the stretch, so both tiles in a pair
            // match the taller one instead of demanding infinite height.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tiles[i]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: i + 1 < tiles.length
                        ? tiles[i + 1]
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _statusLabel {
    final status = event.status.trim();
    if (status.isEmpty) return '-';
    return status
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  String get _riskLabel {
    final risk = event.riskLevel.trim();
    if (risk.isEmpty) return '-';
    return '${risk[0].toUpperCase()}${risk.substring(1).toLowerCase()}';
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.label,
    required this.value,
    this.emphasis = false,
  });

  final String label;
  final String value;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: emphasis ? 14.5 : 13.5,
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w700,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
