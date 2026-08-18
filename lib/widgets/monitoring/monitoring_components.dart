import 'package:flutter/material.dart';

import '../common/shimmer_skeleton.dart';
import '../report/report_styles.dart';

class MonitoringPageLayout extends StatelessWidget {
  const MonitoringPageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.vehicleLabel,
    required this.icon,
    required this.onRefresh,
    required this.isRefreshing,
    required this.child,
  });

  final String title;
  final String subtitle;
  final String vehicleLabel;
  final IconData icon;
  final VoidCallback onRefresh;
  final bool isRefreshing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ReportStyles.pageBackground,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ReportStyles.blue.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: ReportStyles.blue, size: 23),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: ReportStyles.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: ReportStyles.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: ReportStyles.cardBackground,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: ReportStyles.border),
                    ),
                    child: Text(
                      vehicleLabel,
                      style: const TextStyle(
                        color: ReportStyles.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    tooltip: 'Refresh latest reading',
                    onPressed: isRefreshing ? null : onRefresh,
                    style: IconButton.styleFrom(
                      backgroundColor: ReportStyles.cardBackground,
                      side: const BorderSide(color: ReportStyles.border),
                    ),
                    icon: isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class MonitoringMetricGrid extends StatelessWidget {
  const MonitoringMetricGrid({super.key, required this.metrics});

  final List<MonitoringMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 4
            : constraints.maxWidth >= 720
            ? 3
            : 2;
        final width = (constraints.maxWidth - ((columns - 1) * 14)) / columns;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: metrics
              .map((metric) => SizedBox(width: width, child: _MetricCard(metric: metric)))
              .toList(),
        );
      },
    );
  }
}

class MonitoringMetric {
  const MonitoringMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.metric});

  final MonitoringMetric metric;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 126,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.75)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: ReportStyles.blue, size: 20),
          const Spacer(),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            style: const TextStyle(
              color: ReportStyles.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class MonitoringInfoCard extends StatelessWidget {
  const MonitoringInfoCard({super.key, required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border.withValues(alpha: 0.75)),
      ),
      child: Wrap(
        spacing: 36,
        runSpacing: 12,
        children: rows
            .map(
              (row) => SizedBox(
                width: 280,
                child: Row(
                  children: [
                    Text(
                      '${row.$1}: ',
                      style: const TextStyle(color: ReportStyles.textMuted),
                    ),
                    Expanded(
                      child: Text(
                        row.$2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: ReportStyles.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class MonitoringMessageCard extends StatelessWidget {
  const MonitoringMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: ReportStyles.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: ReportStyles.textMuted, size: 38),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              color: ReportStyles.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: ReportStyles.textSecondary),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class MonitoringLoadingCard extends StatelessWidget {
  const MonitoringLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Wrap(
        spacing: 14,
        runSpacing: 14,
        children: List.generate(
          8,
          (_) => const SizedBox(
            width: 250,
            height: 126,
            child: SkeletonBox(width: 250, height: 126, radius: 16),
          ),
        ),
      ),
    );
  }
}

class MonitoringRefreshError extends StatelessWidget {
  const MonitoringRefreshError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF5A281F),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(message, style: const TextStyle(color: Colors.white)),
    );
  }
}
