import 'package:flutter/material.dart';

import '../common/shimmer_skeleton.dart';
import '../report/report_styles.dart';

class LiveTrackingSkeleton extends StatelessWidget {
  const LiveTrackingSkeleton({super.key, this.overlay = false});

  final bool overlay;

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      overlay: overlay,
      child: Container(
        color: ReportStyles.pageBackground,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          children: [
            _Card(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: const [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(width: 180, height: 24),
                        SizedBox(height: 8),
                        SkeletonLine(width: 260, height: 12),
                      ],
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: SkeletonBox(
                      width: double.infinity,
                      height: 44,
                      radius: 12,
                    ),
                  ),
                  SizedBox(width: 16),
                  SkeletonBox(width: 120, height: 44, radius: 12),
                  SizedBox(width: 12),
                  SkeletonLine(width: 56, height: 18),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: const [
                  SizedBox(width: 320, child: _FleetPanelSkeleton()),
                  SizedBox(width: 16),
                  Expanded(child: _MapPanelSkeleton()),
                  SizedBox(width: 16),
                  SizedBox(width: 320, child: _DetailPanelSkeleton()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _Card(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: const [
                  SkeletonLine(width: 110, height: 12),
                  SizedBox(width: 12),
                  SkeletonBox(width: 56, height: 28, radius: 10),
                  Spacer(),
                  SkeletonLine(width: 180, height: 12),
                  Spacer(),
                  SkeletonLine(width: 150, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FleetPanelSkeleton extends StatelessWidget {
  const _FleetPanelSkeleton();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 90, height: 18),
          const SizedBox(height: 14),
          const Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SkeletonBox(width: 120, height: 58, radius: 14),
              SkeletonBox(width: 120, height: 58, radius: 14),
              SkeletonBox(width: 120, height: 58, radius: 14),
              SkeletonBox(width: 120, height: 58, radius: 14),
            ],
          ),
          const SizedBox(height: 14),
          const SkeletonBox(width: double.infinity, height: 42, radius: 12),
          const SizedBox(height: 14),
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => const _FleetRowSkeleton(),
            ),
          ),
        ],
      ),
    );
  }
}

class _FleetRowSkeleton extends StatelessWidget {
  const _FleetRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.65)),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              SkeletonCircle(size: 12),
              SizedBox(width: 10),
              SkeletonCircle(size: 34),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 88, height: 12),
                    SizedBox(height: 6),
                    SkeletonLine(width: 112, height: 10),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SkeletonLine(width: 54, height: 12),
                  SizedBox(height: 6),
                  SkeletonBox(width: 52, height: 20, radius: 999),
                ],
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              SkeletonLine(width: 120, height: 10),
              Spacer(),
              SkeletonLine(width: 48, height: 10),
            ],
          ),
        ],
      ),
    );
  }
}

class _MapPanelSkeleton extends StatelessWidget {
  const _MapPanelSkeleton();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(12),
      child: Stack(
        children: const [
          Positioned.fill(
            child: SkeletonBox(
              width: double.infinity,
              height: double.infinity,
              radius: 18,
            ),
          ),
          Positioned(
            left: 14,
            top: 14,
            child: SkeletonBox(width: 140, height: 34, radius: 10),
          ),
          Positioned(
            right: 14,
            top: 14,
            child: Column(
              children: [
                SkeletonBox(width: 38, height: 38, radius: 10),
                SizedBox(height: 10),
                SkeletonBox(width: 38, height: 38, radius: 10),
              ],
            ),
          ),
          Positioned(
            left: 14,
            bottom: 14,
            child: SkeletonBox(width: 110, height: 98, radius: 12),
          ),
        ],
      ),
    );
  }
}

class _DetailPanelSkeleton extends StatelessWidget {
  const _DetailPanelSkeleton();

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLine(width: 120, height: 18),
          const SizedBox(height: 16),
          const Row(
            children: [
              SkeletonCircle(size: 54),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 92, height: 18),
                    SizedBox(height: 8),
                    SkeletonLine(width: 132, height: 12),
                  ],
                ),
              ),
              SkeletonBox(width: 62, height: 24, radius: 999),
            ],
          ),
          const SizedBox(height: 18),
          Expanded(
            child: ListView.separated(
              itemCount: 7,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) => const Row(
                children: [
                  SkeletonCircle(size: 18),
                  SizedBox(width: 10),
                  Expanded(child: SkeletonLine(width: 92, height: 12)),
                  SizedBox(width: 10),
                  SkeletonLine(width: 82, height: 12),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          const SkeletonBox(width: double.infinity, height: 44, radius: 12),
          const SizedBox(height: 10),
          const SkeletonBox(width: double.infinity, height: 44, radius: 12),
          const SizedBox(height: 10),
          const SkeletonBox(width: double.infinity, height: 44, radius: 12),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, required this.padding});

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.72)),
      ),
      child: child,
    );
  }
}
