import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/drowsiness_report.dart';
import '../../models/vehicle_status.dart';
import '../../theme/app_theme.dart';
import '../common/app_card.dart';

/// Online Vehicle / Safety Event / Vehicle at Risk cards.
class OverviewKpiRow extends StatelessWidget {
  const OverviewKpiRow({
    super.key,
    required this.vehicleStatusData,
    required this.todayEvents,
    required this.report,
    required this.isWide,
  });

  final VehicleStatusData? vehicleStatusData;

  /// Safety events recorded today, newest first.
  final List<DrowsinessEvent> todayEvents;
  final DrowsinessReport? report;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final summary = vehicleStatusData?.summary;
    final items = vehicleStatusData?.vehicles ?? const <VehicleStatusItem>[];
    final hasStatus = vehicleStatusData != null;

    final totalVehicles = summary?.totalVehicles ?? items.length;
    final onlineVehicles = summary?.onlineVehicles ?? 0;
    final atRiskVehicles =
        summary?.alert ??
        items
            .where((item) => item.safetyStatus.trim().toLowerCase() == 'alert')
            .length;

    final behavior = _behaviorCounts();

    final online = _FractionKpiCard(
      title: 'Online Vehicle',
      value: hasStatus ? '$onlineVehicles/$totalVehicles' : '-/-',
      caption: hasStatus
          ? '${_percent(onlineVehicles, totalVehicles)}% of total fleet'
          : 'Vehicle status unavailable',
      icon: Icons.directions_bus_rounded,
    );

    final safety = _SafetyEventCard(
      drowsy: behavior.drowsy,
      yawn: behavior.yawn,
      distraction: behavior.distraction,
    );

    final atRisk = _FractionKpiCard(
      title: 'Vehicle at Risk',
      value: hasStatus ? '$atRiskVehicles/$totalVehicles' : '-/-',
      caption: hasStatus
          ? '${_percent(atRiskVehicles, totalVehicles)}% of total fleet'
          : 'Vehicle status unavailable',
      icon: Icons.engineering_rounded,
    );

    if (!isWide) {
      return Column(
        children: [
          online,
          const SizedBox(height: 12),
          safety,
          const SizedBox(height: 12),
          atRisk,
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 22, child: online),
          const SizedBox(width: 12),
          Expanded(flex: 34, child: safety),
          const SizedBox(width: 12),
          Expanded(flex: 22, child: atRisk),
        ],
      ),
    );
  }

  /// Counts today's events per behavior, topped up with the aggregate report
  /// so the tile still shows numbers when the event feed is thinner than the
  /// daily summary.
  _BehaviorCounts _behaviorCounts() {
    var drowsy = 0;
    var yawn = 0;
    var distraction = 0;

    for (final event in todayEvents) {
      switch (_normalizeBehavior(event)) {
        case 'drowsy':
          drowsy++;
        case 'yawn':
          yawn++;
        case 'distraction':
          distraction++;
      }
    }

    final report = this.report;
    if (report != null) {
      final weekday = DateTime.now().weekday;
      for (final summary in report.weekdayBehaviorSummary) {
        if (summary.weekdayIndex != weekday) continue;
        drowsy = math.max(drowsy, summary.behaviors.drowsiness);
        yawn = math.max(yawn, summary.behaviors.yawn);
        distraction = math.max(distraction, summary.behaviors.distraction);
      }
    }

    return _BehaviorCounts(
      drowsy: drowsy,
      yawn: yawn,
      distraction: distraction,
    );
  }

  String? _normalizeBehavior(DrowsinessEvent event) {
    final raw = '${event.behaviorType ?? ''} ${event.status}'.toLowerCase();
    if (raw.contains('drows')) return 'drowsy';
    if (raw.contains('yawn')) return 'yawn';
    if (raw.contains('distraction')) return 'distraction';
    return null;
  }

  static int _percent(int value, int total) =>
      total <= 0 ? 0 : ((value / total) * 100).round();
}

class _BehaviorCounts {
  const _BehaviorCounts({
    required this.drowsy,
    required this.yawn,
    required this.distraction,
  });

  final int drowsy;
  final int yawn;
  final int distraction;

  int get total => drowsy + yawn + distraction;
}

class _FractionKpiCard extends StatelessWidget {
  const _FractionKpiCard({
    required this.title,
    required this.value,
    required this.caption,
    required this.icon,
  });

  final String title;
  final String value;
  final String caption;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppCardTitle(title),
                const SizedBox(height: 10),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _IconChip(icon: icon),
        ],
      ),
    );
  }
}

class _SafetyEventCard extends StatelessWidget {
  const _SafetyEventCard({
    required this.drowsy,
    required this.yawn,
    required this.distraction,
  });

  final int drowsy;
  final int yawn;
  final int distraction;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.fromLTRB(20, 22, 18, 22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppCardTitle('Safety Event'),
                const SizedBox(height: 10),
                Text(
                  '${drowsy + yawn + distraction}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    letterSpacing: -0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 132,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _BreakdownRow(
                  color: AppColors.red,
                  label: 'Drowsy',
                  count: drowsy,
                ),
                const SizedBox(height: 7),
                _BreakdownRow(
                  color: AppColors.amber,
                  label: 'Yawn',
                  count: yawn,
                ),
                const SizedBox(height: 7),
                _BreakdownRow(
                  color: AppColors.yellow,
                  label: 'Distraction',
                  count: distraction,
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const _IconChip(icon: Icons.dangerous),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10.5,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$count',
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
      ],
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 24, color: AppColors.blue),
    );
  }
}
