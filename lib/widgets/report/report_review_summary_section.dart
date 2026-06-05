import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportReviewSummarySection extends StatelessWidget {
  const ReportReviewSummarySection({super.key, required this.reviewSummary});

  final DrowsinessReviewSummary reviewSummary;

  @override
  Widget build(BuildContext context) {
    final statusCards = [
      _StatusChipData(
        label: 'New / Unreviewed',
        value: _formatCount(reviewSummary.newEvents),
        color: ReportStyles.textSecondary,
        icon: Icons.mark_email_unread_outlined,
      ),
      _StatusChipData(
        label: 'Confirmed',
        value: _formatCount(reviewSummary.confirmed),
        color: ReportStyles.green,
        icon: Icons.check_circle_outline_rounded,
      ),
      _StatusChipData(
        label: 'False Alarm',
        value: _formatCount(reviewSummary.falseAlarm),
        color: ReportStyles.orange,
        icon: Icons.cancel_outlined,
      ),
      _StatusChipData(
        label: 'Follow-up Required',
        value: _formatCount(reviewSummary.followUpRequired),
        color: ReportStyles.blue,
        icon: Icons.assignment_late_outlined,
      ),
      _StatusChipData(
        label: 'Followed Up',
        value: _formatCount(reviewSummary.followedUp),
        color: ReportStyles.purple,
        icon: Icons.task_alt_rounded,
      ),
    ];

    final rateCards = [
      _RateMetricData(
        label: 'Review Completion Rate',
        value: _formatPercent(reviewSummary.reviewCompletionRate),
        helper:
            '${_formatCount(reviewSummary.reviewedTotal)} reviewed of ${_formatCount(reviewSummary.totalEvents)}',
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
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 1180;

          return Wrap(
            spacing: 10,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: isWide ? 228 : constraints.maxWidth,
                child: const _ReviewSummaryHeader(),
              ),
              SizedBox(
                width: isWide
                    ? constraints.maxWidth - 238
                    : constraints.maxWidth,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...statusCards.map(
                      (card) => _StatusSummaryChip(data: card),
                    ),
                    ...rateCards.map((card) => _RateSummaryPill(data: card)),
                  ],
                ),
              ),
            ],
          );
        },
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

  String _formatCount(int value) => NumberFormat.decimalPattern().format(value);
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
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        SizedBox(height: 2),
        Text(
          'Based on operator review status from Safety Events',
          style: TextStyle(
            color: ReportStyles.textSecondary,
            fontSize: 9,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _StatusSummaryChip extends StatelessWidget {
  const _StatusSummaryChip({required this.data});

  final _StatusChipData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 132, maxWidth: 164),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: ReportStyles.surfaceBackgroundSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ReportStyles.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(data.icon, color: data.color, size: 11),
          ),
          const SizedBox(width: 7),
          SizedBox(
            width: 102,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.label,
                  style: const TextStyle(
                    color: ReportStyles.textMuted,
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 13.5,
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
  const _RateSummaryPill({required this.data});

  final _RateMetricData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 144, maxWidth: 188),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: data.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            data.label,
            style: const TextStyle(
              color: ReportStyles.textMuted,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.value,
                style: const TextStyle(
                  color: ReportStyles.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 7),
              SizedBox(
                width: 90,
                child: Text(
                  data.helper,
                  style: TextStyle(
                    color: data.color,
                    fontSize: 7.7,
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
