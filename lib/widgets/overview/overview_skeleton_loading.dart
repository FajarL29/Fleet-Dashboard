import 'package:flutter/material.dart';

import '../common/shimmer_skeleton.dart';
import '../report/report_styles.dart';

class OverviewDashboardSkeleton extends StatelessWidget {
  const OverviewDashboardSkeleton({super.key, this.overlay = false});

  final bool overlay;

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      overlay: overlay,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF05111F), Color(0xFF071427)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final useWideHeader = width >= 960;
              final kpiPerRow = width >= 1200
                  ? 4
                  : width >= 900
                  ? 2
                  : 1;
              final useTwoColumns = width >= 1180;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SkeletonHeader(useWideLayout: useWideHeader),
                  const SizedBox(height: 16),
                  _SkeletonKpiGrid(perRow: kpiPerRow),
                  const SizedBox(height: 16),
                  if (useTwoColumns)
                    Column(
                      children: const [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 11, child: _SkeletonMapCard()),
                            SizedBox(width: 16),
                            Expanded(flex: 10, child: _SkeletonRankingCard()),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _SkeletonSnapshotCard()),
                            SizedBox(width: 16),
                            Expanded(child: _SkeletonRecentLogCard()),
                          ],
                        ),
                      ],
                    )
                  else
                    const Column(
                      children: [
                        _SkeletonMapCard(),
                        SizedBox(height: 16),
                        _SkeletonRankingCard(),
                        SizedBox(height: 16),
                        _SkeletonSnapshotCard(),
                        SizedBox(height: 16),
                        _SkeletonRecentLogCard(),
                      ],
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _SkeletonHeader extends StatelessWidget {
  const _SkeletonHeader({required this.useWideLayout});

  final bool useWideLayout;

  @override
  Widget build(BuildContext context) {
    final statusCard = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.5)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SkeletonCircle(size: 30),
          SizedBox(width: 10),
          SkeletonLine(width: 162, height: 12),
        ],
      ),
    );

    final timestamp = const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SkeletonCircle(size: 16),
        SizedBox(width: 8),
        SkeletonLine(width: 72, height: 10),
      ],
    );

    if (useWideLayout) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 310, height: 24),
                SizedBox(height: 8),
                SkeletonLine(width: 220, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [statusCard, const SizedBox(height: 10), timestamp],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonLine(width: 280, height: 24),
        const SizedBox(height: 8),
        const SkeletonLine(width: 210, height: 12),
        const SizedBox(height: 12),
        statusCard,
        const SizedBox(height: 10),
        timestamp,
      ],
    );
  }
}

class _SkeletonKpiGrid extends StatelessWidget {
  const _SkeletonKpiGrid({required this.perRow});

  final int perRow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = perRow.clamp(1, 4);
        final spacing = 16.0;
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            4,
            (index) => SizedBox(
              width: itemWidth,
              child: const _SkeletonCompactKpiCard(),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonCompactKpiCard extends StatelessWidget {
  const _SkeletonCompactKpiCard();

  @override
  Widget build(BuildContext context) {
    return _OverviewPanel(
      height: 116,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SkeletonLine(width: 92, height: 11),
          Spacer(),
          Row(
            children: [
              SkeletonCircle(size: 42),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 88, height: 20),
                    SizedBox(height: 8),
                    SkeletonLine(width: 74, height: 10),
                  ],
                ),
              ),
              SkeletonCircle(size: 42),
            ],
          ),
          Spacer(),
        ],
      ),
    );
  }
}

class _SkeletonMapCard extends StatelessWidget {
  const _SkeletonMapCard();

  @override
  Widget build(BuildContext context) {
    return _OverviewPanel(
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonCircle(size: 16),
              SizedBox(width: 8),
              SkeletonLine(width: 96, height: 13),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF0A1524),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: ReportStyles.border.withValues(alpha: 0.5),
                ),
              ),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: List.generate(
                          6,
                          (index) => const SkeletonCircle(size: 18),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    left: 16,
                    bottom: 14,
                    child: Row(
                      children: [
                        SkeletonLine(width: 56, height: 10),
                        SizedBox(width: 12),
                        SkeletonLine(width: 56, height: 10),
                        SizedBox(width: 12),
                        SkeletonLine(width: 56, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRankingCard extends StatelessWidget {
  const _SkeletonRankingCard();

  @override
  Widget build(BuildContext context) {
    return _OverviewPanel(
      height: 320,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonCircle(size: 16),
              SizedBox(width: 8),
              SkeletonLine(width: 164, height: 13),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: const Row(
              children: [
                SkeletonLine(width: 28, height: 10),
                SizedBox(width: 12),
                Expanded(
                  child: SkeletonLine(width: double.infinity, height: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 4 ? 0 : 10),
                  child: const _SkeletonRankingRow(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRankingRow extends StatelessWidget {
  const _SkeletonRankingRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: const [
          SkeletonLine(width: 18, height: 12),
          SizedBox(width: 10),
          SkeletonCircle(size: 26),
          SizedBox(width: 8),
          Expanded(child: SkeletonLine(width: 120, height: 12)),
          SizedBox(width: 8),
          SkeletonLine(width: 54, height: 12),
          SizedBox(width: 8),
          SkeletonLine(width: 62, height: 20),
        ],
      ),
    );
  }
}

class _SkeletonSnapshotCard extends StatelessWidget {
  const _SkeletonSnapshotCard();

  @override
  Widget build(BuildContext context) {
    return _OverviewPanel(
      height: 232,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonCircle(size: 16),
              SizedBox(width: 8),
              SkeletonLine(width: 168, height: 13),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: List.generate(
                4,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 3 ? 0 : 10),
                  child: const _SkeletonSnapshotRow(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonSnapshotRow extends StatelessWidget {
  const _SkeletonSnapshotRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SizedBox(
          width: 144,
          child: Row(
            children: [
              SkeletonCircle(size: 18),
              SizedBox(width: 8),
              Expanded(child: SkeletonLine(width: 90, height: 11)),
            ],
          ),
        ),
        Expanded(child: SkeletonLine(width: double.infinity, height: 10)),
        SizedBox(width: 12),
        SkeletonLine(width: 32, height: 12),
      ],
    );
  }
}

class _SkeletonRecentLogCard extends StatelessWidget {
  const _SkeletonRecentLogCard();

  @override
  Widget build(BuildContext context) {
    return _OverviewPanel(
      height: 232,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonCircle(size: 16),
              SizedBox(width: 8),
              Expanded(child: SkeletonLine(width: 88, height: 13)),
              SizedBox(width: 12),
              SkeletonLine(width: 86, height: 12),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Column(
              children: List.generate(
                5,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 4 ? 0 : 10),
                  child: const _SkeletonRecentLogRow(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRecentLogRow extends StatelessWidget {
  const _SkeletonRecentLogRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        SkeletonLine(width: 40, height: 11),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(width: 108, height: 11),
              SizedBox(height: 6),
              SkeletonLine(width: 158, height: 10),
            ],
          ),
        ),
        SizedBox(width: 10),
        SkeletonLine(width: 54, height: 20),
      ],
    );
  }
}

class _OverviewPanel extends StatelessWidget {
  const _OverviewPanel({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.85)),
        boxShadow: ReportStyles.cardShadow,
      ),
      child: child,
    );
  }
}
