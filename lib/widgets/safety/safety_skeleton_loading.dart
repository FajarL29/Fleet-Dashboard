import 'package:flutter/material.dart';

import '../common/shimmer_skeleton.dart';
import '../report/report_styles.dart';

class SafetyContentSkeleton extends StatelessWidget {
  const SafetyContentSkeleton({
    super.key,
    this.overlay = false,
    this.contentOnly = false,
  });

  final bool overlay;
  final bool contentOnly;

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      overlay: overlay,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 1180;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!contentOnly) ...[
                const SkeletonLine(width: 170, height: 26),
                const SizedBox(height: 8),
                const SkeletonLine(width: 240, height: 12),
                const SizedBox(height: 18),
                const _SafetyFilterSkeleton(),
                const SizedBox(height: 16),
                const _SafetyWorkflowSkeleton(),
                const SizedBox(height: 16),
              ],
              Expanded(
                child: isCompact
                    ? const Column(
                        children: [
                          Expanded(flex: 12, child: _SafetyTableSkeleton()),
                          SizedBox(height: 16),
                          Expanded(flex: 11, child: _SafetyDetailSkeleton()),
                        ],
                      )
                    : const Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 58, child: _SafetyTableSkeleton()),
                          SizedBox(width: 16),
                          Expanded(flex: 42, child: _SafetyDetailSkeleton()),
                        ],
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SafetyFilterSkeleton extends StatelessWidget {
  const _SafetyFilterSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.72)),
      ),
      child: const Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          SkeletonBox(width: 220, height: 46, radius: 12),
          SkeletonBox(width: 180, height: 46, radius: 12),
          SkeletonBox(width: 180, height: 46, radius: 12),
          SkeletonBox(width: 220, height: 46, radius: 12),
          SkeletonBox(width: 120, height: 46, radius: 12),
        ],
      ),
    );
  }
}

class _SafetyWorkflowSkeleton extends StatelessWidget {
  const _SafetyWorkflowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.72)),
      ),
      child: const Row(
        children: [
          Expanded(child: _WorkflowStep()),
          SizedBox(width: 12),
          Expanded(child: _WorkflowStep()),
          SizedBox(width: 12),
          Expanded(child: _WorkflowStep()),
        ],
      ),
    );
  }
}

class _WorkflowStep extends StatelessWidget {
  const _WorkflowStep();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        SkeletonCircle(size: 30),
        SizedBox(width: 10),
        Expanded(child: SkeletonLine(width: double.infinity, height: 12)),
      ],
    );
  }
}

class _SafetyTableSkeleton extends StatelessWidget {
  const _SafetyTableSkeleton();

  @override
  Widget build(BuildContext context) {
    return _SafetyPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonLine(width: 120, height: 14),
              Spacer(),
              SkeletonLine(width: 84, height: 12),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: SkeletonLine(width: double.infinity, height: 10),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SkeletonLine(width: double.infinity, height: 10),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: SkeletonLine(width: double.infinity, height: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Column(
              children: List.generate(
                7,
                (index) => Padding(
                  padding: EdgeInsets.only(bottom: index == 6 ? 0 : 10),
                  child: const _SafetyTableRowSkeleton(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyTableRowSkeleton extends StatelessWidget {
  const _SafetyTableRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.52)),
      ),
      child: const Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(width: 86, height: 11),
                SizedBox(height: 6),
                SkeletonLine(width: 64, height: 10),
              ],
            ),
          ),
          Expanded(child: SkeletonLine(width: 74, height: 11)),
          SizedBox(width: 10),
          Expanded(child: SkeletonLine(width: 68, height: 20)),
          SizedBox(width: 10),
          Expanded(child: SkeletonLine(width: 72, height: 20)),
        ],
      ),
    );
  }
}

class _SafetyDetailSkeleton extends StatelessWidget {
  const _SafetyDetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return _SafetyPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              SkeletonLine(width: 118, height: 14),
              Spacer(),
              SkeletonLine(width: 72, height: 20),
            ],
          ),
          const SizedBox(height: 12),
          const SkeletonLine(width: 180, height: 12),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ReportStyles.surfaceBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ReportStyles.border.withValues(alpha: 0.52),
                ),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 6,
                    child: Container(
                      margin: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A1524),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: SkeletonBox(width: 160, height: 96, radius: 16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                    child: Column(
                      children: const [
                        SkeletonLine(width: double.infinity, height: 12),
                        SizedBox(height: 10),
                        SkeletonLine(width: double.infinity, height: 12),
                        SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: SkeletonBox(
                                width: double.infinity,
                                height: 42,
                                radius: 12,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: SkeletonBox(
                                width: double.infinity,
                                height: 42,
                                radius: 12,
                              ),
                            ),
                          ],
                        ),
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

class _SafetyPanel extends StatelessWidget {
  const _SafetyPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        gradient: ReportStyles.cardGradient,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.72)),
      ),
      child: child,
    );
  }
}
