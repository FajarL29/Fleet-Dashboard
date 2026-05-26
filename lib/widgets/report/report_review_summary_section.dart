import 'package:flutter/material.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportReviewSummarySection extends StatelessWidget {
  const ReportReviewSummarySection({
    super.key,
    required this.reviewSummary,
  });

  final DrowsinessReviewSummary reviewSummary;

  @override
  Widget build(BuildContext context) {
    final statusCards = [
      _StatusChipData(
        label: 'New / Unreviewed',
        value: reviewSummary.newEvents.toString(),
        color: ReportStyles.textSecondary,
        icon: Icons.mark_email_unread_outlined,
      ),
      _StatusChipData(
        label: 'Confirmed',
        value: reviewSummary.confirmed.toString(),
        color: ReportStyles.green,
        icon: Icons.check_circle_outline_rounded,
      ),
      _StatusChipData(
        label: 'False Alarm',
        value: reviewSummary.falseAlarm.toString(),
        color: ReportStyles.orange,
        icon: Icons.cancel_outlined,
      ),
      _StatusChipData(
        label: 'Follow-up Required',
        value: reviewSummary.followUpRequired.toString(),
        color: ReportStyles.blue,
        icon: Icons.assignment_late_outlined,
      ),
      _StatusChipData(
        label: 'Followed Up',
        value: reviewSummary.followedUp.toString(),
        color: ReportStyles.purple,
        icon: Icons.task_alt_rounded,
      ),
    ];

    final rateCards = [
      _RateMetricData(
        label: 'Review Completion Rate',
        value: _formatPercent(reviewSummary.reviewCompletionRate),
        helper:
            '${reviewSummary.reviewedTotal} reviewed of ${reviewSummary.totalEvents}',
        color: ReportStyles.blue,
      ),
      _RateMetricData(
        label: 'False Alarm Rate',
        value: _formatPercent(reviewSummary.falseAlarmRate),
        helper: 'Of reviewed events',
        color: ReportStyles.orange,
      ),
      _RateMetricData(
        label: 'Closure Rate',
        value: _formatPercent(reviewSummary.closureRate),
        helper: 'Follow-up completion',
        color: ReportStyles.green,
      ),
    ];

    return ReportCard(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1180;

              return Wrap(
                spacing: 16,
                runSpacing: 14,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: isWide ? 250 : 0,
                      maxWidth: isWide ? 280 : constraints.maxWidth,
                    ),
                    child: const _ReviewSummaryHeader(),
                  ),
                  SizedBox(
                    width:
                        isWide ? constraints.maxWidth - 312 : constraints.maxWidth,
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        ...statusCards.map((card) => _StatusSummaryChip(data: card)),
                        ...rateCards.map((card) => _RateSummaryPill(data: card)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatPercent(double value) {
    final isWhole = value == value.roundToDouble();
    if (isWhole) {
      return '${value.toStringAsFixed(0)}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }
}

class _ReviewSummaryHeader extends StatelessWidget {
  const _ReviewSummaryHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Workflow Summary',
          style: TextStyle(
            color: ReportStyles.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Based on operator review status from Safety Events',
          style: TextStyle(
            color: ReportStyles.textSecondary,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _StatusSummaryChip extends StatelessWidget {
  const _StatusSummaryChip({
    required this.data,
  });

  final _StatusChipData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 172, maxWidth: 196),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: data.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(data.icon, color: data.color, size: 16),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 128,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    color: ReportStyles.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RateSummaryPill extends StatelessWidget {
  const _RateSummaryPill({
    required this.data,
  });

  final _RateMetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 172, maxWidth: 228),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: data.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            style: const TextStyle(
              color: ReportStyles.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 112,
                child: Text(
                  data.helper,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChipData {
  const _StatusChipData({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
}

class _RateMetricData {
  const _RateMetricData({
    required this.label,
    required this.value,
    required this.helper,
    required this.color,
  });

  final String label;
  final String value;
  final String helper;
  final Color color;
}
