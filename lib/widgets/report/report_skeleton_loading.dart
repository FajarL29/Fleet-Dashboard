import 'package:flutter/material.dart';

import '../common/shimmer_skeleton.dart';
import 'report_styles.dart';

class ReportDashboardSkeleton extends StatelessWidget {
  const ReportDashboardSkeleton({super.key, this.overlay = false});

  final bool overlay;

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      overlay: overlay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ResponsiveGrid(
            minItemWidth: 220,
            spacing: 12,
            children: const [
              _SkeletonGaugeCard(),
              _SkeletonMetricCard(),
              _SkeletonMetricCard(),
              _SkeletonMetricCard(),
            ].map((card) => _SkeletonPanel(height: 126, child: card)).toList(),
          ),
          const SizedBox(height: 12),
          _ResponsiveColumns(
            spacing: 12,
            leftFlex: 55,
            rightFlex: 45,
            left: const _SkeletonPanel(
              height: 255,
              child: _SkeletonWeeklyCard(),
            ),
            right: const _SkeletonPanel(
              height: 255,
              child: _SkeletonContributionCard(),
            ),
          ),
          const SizedBox(height: 12),
          _ResponsiveColumns(
            spacing: 12,
            leftFlex: 45,
            rightFlex: 55,
            left: const _SkeletonPanel(
              height: 255,
              child: _SkeletonTrendCard(),
            ),
            right: const _SkeletonPanel(
              height: 255,
              child: _SkeletonHeatmapCard(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResponsiveGrid extends StatelessWidget {
  const _ResponsiveGrid({
    required this.minItemWidth,
    required this.spacing,
    required this.children,
  });

  final double minItemWidth;
  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1200
            ? 4
            : ((constraints.maxWidth + spacing) / (minItemWidth + spacing))
                  .floor()
                  .clamp(1, children.length);
        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}

class _ResponsiveColumns extends StatelessWidget {
  const _ResponsiveColumns({
    required this.spacing,
    required this.leftFlex,
    required this.rightFlex,
    required this.left,
    required this.right,
  });

  final double spacing;
  final int leftFlex;
  final int rightFlex;
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 1100) {
          return Column(
            children: [
              left,
              SizedBox(height: spacing),
              right,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: leftFlex, child: left),
            SizedBox(width: spacing),
            Expanded(flex: rightFlex, child: right),
          ],
        );
      },
    );
  }
}

class _SkeletonPanel extends StatelessWidget {
  const _SkeletonPanel({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: SizedBox(height: height, child: child),
    );
  }
}

class _SkeletonGaugeCard extends StatelessWidget {
  const _SkeletonGaugeCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 88, height: 11),
        SizedBox(height: 10),
        Expanded(child: _SkeletonGauge()),
      ],
    );
  }
}

class _SkeletonGauge extends StatelessWidget {
  const _SkeletonGauge();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gaugeWidth = constraints.maxWidth.clamp(230.0, 280.0);
        return Center(
          child: SizedBox(
            width: gaugeWidth,
            height: 88,
            child: Stack(
              alignment: Alignment.center,
              children: const [
                Positioned.fill(child: _SkeletonArc()),
                Positioned(
                  top: 34,
                  child: Column(
                    children: [
                      SkeletonBox(width: 92, height: 28, radius: 10),
                      SizedBox(height: 8),
                      SkeletonBox(width: 72, height: 12, radius: 10),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonArc extends StatelessWidget {
  const _SkeletonArc();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SkeletonArcPainter());
  }
}

class _SkeletonArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ReportStyles.surfaceBackgroundSoft.withValues(alpha: 0.98)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 16;
    final rect = Rect.fromLTWH(16, 14, size.width - 32, (size.height * 1.55));
    canvas.drawArc(rect, 3.14159, 3.14159, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _SkeletonMetricCard extends StatelessWidget {
  const _SkeletonMetricCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        SkeletonBox(width: 84, height: 11),
        Spacer(),
        Row(
          children: [
            SkeletonBox(width: 54, height: 54, isCircle: true),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 96, height: 28, radius: 10),
                  SizedBox(height: 10),
                  SkeletonBox(width: 112, height: 12, radius: 10),
                ],
              ),
            ),
          ],
        ),
        Spacer(),
      ],
    );
  }
}

class _SkeletonWeeklyCard extends StatelessWidget {
  const _SkeletonWeeklyCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            SkeletonBox(width: 170, height: 16, radius: 10),
            Spacer(),
            SkeletonBox(width: 156, height: 28, radius: 10),
          ],
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            SkeletonBox(width: 80, height: 10, radius: 10),
            SizedBox(width: 14),
            SkeletonBox(width: 92, height: 10, radius: 10),
          ],
        ),
        const SizedBox(height: 14),
        const Expanded(child: _SkeletonChartRows()),
      ],
    );
  }
}

class _SkeletonChartRows extends StatelessWidget {
  const _SkeletonChartRows();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 34,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              SkeletonBox(width: 18, height: 9, radius: 10),
              SkeletonBox(width: 18, height: 9, radius: 10),
              SkeletonBox(width: 18, height: 9, radius: 10),
              SkeletonBox(width: 18, height: 9, radius: 10),
              SkeletonBox(width: 18, height: 9, radius: 10),
            ],
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(child: _SkeletonBarChart()),
      ],
    );
  }
}

class _SkeletonBarChart extends StatelessWidget {
  const _SkeletonBarChart();

  @override
  Widget build(BuildContext context) {
    final heights = [86.0, 110.0, 72.0, 124.0, 94.0, 116.0, 84.0];

    return Column(
      children: [
        Expanded(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  5,
                  (_) => Container(
                    height: 1,
                    color: ReportStyles.border.withValues(alpha: 0.72),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: heights
                      .map(
                        (height) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const SkeletonBox(
                                  width: 20,
                                  height: 9,
                                  radius: 8,
                                ),
                                const SizedBox(height: 6),
                                SkeletonBox(
                                  width: 34,
                                  height: height,
                                  radius: 8,
                                ),
                                const SizedBox(height: 7),
                                const SkeletonBox(
                                  width: 24,
                                  height: 10,
                                  radius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonContributionCard extends StatelessWidget {
  const _SkeletonContributionCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 228, height: 13, radius: 10),
        const SizedBox(height: 16),
        Expanded(
          child: Column(
            children: const [
              _SkeletonContributorRow(),
              SizedBox(height: 14),
              _SkeletonContributorRow(),
              SizedBox(height: 14),
              _SkeletonContributorRow(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonContributorRow extends StatelessWidget {
  const _SkeletonContributorRow();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        Row(
          children: [
            SkeletonBox(width: 38, height: 38, isCircle: true),
            SizedBox(width: 10),
            SkeletonBox(width: 34, height: 34, isCircle: true),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SkeletonBox(width: 98, height: 12, radius: 8),
                  SizedBox(height: 6),
                  SkeletonBox(width: 70, height: 10, radius: 8),
                ],
              ),
            ),
            SizedBox(width: 8),
            SkeletonBox(width: 44, height: 14, radius: 8),
          ],
        ),
        SizedBox(height: 8),
        SkeletonBox(width: double.infinity, height: 8, radius: 999),
      ],
    );
  }
}

class _SkeletonTrendCard extends StatelessWidget {
  const _SkeletonTrendCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 126, height: 16, radius: 10),
        const SizedBox(height: 14),
        Expanded(
          child: Stack(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  4,
                  (_) => Container(
                    height: 1,
                    color: ReportStyles.border.withValues(alpha: 0.72),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(
                    7,
                    (index) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const SkeletonBox(width: 22, height: 9, radius: 8),
                            const SizedBox(height: 6),
                            SkeletonBox(
                              width: 28,
                              height: 60 + (index % 4) * 16,
                              radius: 8,
                            ),
                            const SizedBox(height: 7),
                            const SkeletonBox(width: 22, height: 10, radius: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SkeletonHeatmapCard extends StatelessWidget {
  const _SkeletonHeatmapCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            SkeletonBox(width: 214, height: 16, radius: 10),
            Spacer(),
            SkeletonBox(width: 94, height: 11, radius: 10),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const SizedBox(width: 34),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  8,
                  (_) => const SkeletonBox(width: 18, height: 9, radius: 8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              7,
              (_) => Row(
                children: [
                  const SkeletonBox(width: 24, height: 10, radius: 8),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Row(
                      children: List.generate(
                        12,
                        (index) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: SkeletonBox(
                              width: double.infinity,
                              height: 12 + (index % 3).toDouble(),
                              radius: 4,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        const Align(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SkeletonBox(width: 24, height: 10, radius: 8),
              SizedBox(width: 8),
              SkeletonBox(width: 112, height: 10, radius: 999),
              SizedBox(width: 8),
              SkeletonBox(width: 28, height: 10, radius: 8),
            ],
          ),
        ),
      ],
    );
  }
}
