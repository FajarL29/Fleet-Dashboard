import 'package:flutter/material.dart';

import '../common/shimmer_skeleton.dart';
import '../report/report_styles.dart';

class VehiclesScreenSkeleton extends StatelessWidget {
  const VehiclesScreenSkeleton({super.key, this.overlay = false});

  final bool overlay;

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      overlay: overlay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 260, height: 28),
          const SizedBox(height: 10),
          const SkeletonLine(width: 420, height: 12),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              SkeletonBox(width: 140, height: 44, radius: 12),
              SkeletonBox(width: 150, height: 44, radius: 12),
              SkeletonBox(width: 120, height: 48, radius: 12),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(4, (_) => const _SkeletonKpiCard()),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(flex: 55, child: _SkeletonRegistryCard()),
                SizedBox(width: 16),
                Expanded(flex: 45, child: _SkeletonRightRail()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonKpiCard extends StatelessWidget {
  const _SkeletonKpiCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 108,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.82)),
      ),
      child: const Row(
        children: [
          SkeletonCircle(size: 52),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SkeletonLine(width: 90, height: 11),
                SizedBox(height: 10),
                SkeletonLine(width: 72, height: 22),
                SizedBox(height: 10),
                SkeletonLine(width: 96, height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRegistryCard extends StatelessWidget {
  const _SkeletonRegistryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.82)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonLine(width: 110, height: 18),
              Spacer(),
              SkeletonLine(width: 82, height: 12),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              SkeletonBox(width: 250, height: 44, radius: 12),
              SkeletonBox(width: 150, height: 44, radius: 12),
              SkeletonBox(width: 150, height: 44, radius: 12),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => Container(
                height: 82,
                decoration: BoxDecoration(
                  color: ReportStyles.surfaceBackgroundSoft.withValues(
                    alpha: 0.95,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRightRail extends StatelessWidget {
  const _SkeletonRightRail();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Expanded(flex: 62, child: _SkeletonPanel(detailMode: true)),
        SizedBox(height: 16),
        Expanded(flex: 38, child: _SkeletonPanel(detailMode: false)),
      ],
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel({required this.detailMode});

  final bool detailMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.82)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 160, height: 16),
          const SizedBox(height: 16),
          if (detailMode) ...[
            const Row(
              children: [
                SkeletonBox(width: 112, height: 112, radius: 22),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(width: 160, height: 22),
                      SizedBox(height: 10),
                      SkeletonLine(width: 120, height: 20),
                      SizedBox(height: 10),
                      SkeletonLine(width: 210, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: detailMode ? 6 : 5,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) => SkeletonBox(
                width: double.infinity,
                height: detailMode ? 52 : 58,
                radius: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
