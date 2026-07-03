import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportStatsRow extends StatelessWidget {
  const ReportStatsRow({super.key, this.report, required this.events});

  final DrowsinessReport? report;
  final List<DrowsinessEvent> events;

  @override
  Widget build(BuildContext context) {
    final summary = report?.summary;
    final reviewSummary = report?.reviewSummary;
    final totalEvents = _resolveTotalEvents(summary, reviewSummary, events);
    final highRiskEvents =
        summary?.highRiskEvents ??
        events.where((event) => event.riskLevel.toLowerCase() == 'high').length;
    final peakHour = summary?.peakHour ?? _peakHour(events) ?? 0;
    final peakDate = summary?.peakDate ?? _peakDate(events);
    final highRiskRatio = totalEvents == 0
        ? 0
        : ((highRiskEvents / totalEvents) * 100).round();
    final reviewCompletion = reviewSummary?.reviewCompletionRate ?? 0;
    final cards = [
      _StatCardData(
        title: 'Total Drowsy Events',
        value: _formatCount(totalEvents),
        description: 'Selected vehicle ${summary?.vehicleId ?? '-'}',
        descriptionColor: ReportStyles.green,
        icon: Icons.nightlight_round,
        accentColor: ReportStyles.blue,
      ),
      _StatCardData(
        title: 'High-Severity Events',
        value: _formatCount(highRiskEvents),
        description: '$highRiskRatio% of total events',
        descriptionColor: ReportStyles.red,
        icon: Icons.warning_amber_rounded,
        accentColor: ReportStyles.red,
      ),
      _StatCardData(
        title: 'Peak Hour',
        value: '${peakHour.toString().padLeft(2, '0')}:00',
        description: peakDate == null
            ? 'Peak date unavailable'
            : 'Peak date ${DateFormat('MMM d, yyyy').format(peakDate)}',
        descriptionColor: ReportStyles.green,
        icon: Icons.schedule_rounded,
        accentColor: ReportStyles.purple,
      ),
      _StatCardData(
        title: 'Review Completion',
        value: _formatPercent(reviewCompletion),
        description:
            '${_formatCount(reviewSummary?.reviewedTotal ?? 0)} reviewed of ${_formatCount(reviewSummary?.totalEvents ?? totalEvents)}',
        descriptionColor: ReportStyles.blue,
        icon: Icons.rate_review_outlined,
        accentColor: ReportStyles.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth >= 1320
            ? (constraints.maxWidth - 42) / 4
            : constraints.maxWidth >= 980
            ? (constraints.maxWidth - 14) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards
              .map(
                (card) => SizedBox(
                  width: cardWidth,
                  child: _StatCard(data: card),
                ),
              )
              .toList(),
        );
      },
    );
  }

  int _resolveTotalEvents(
    DrowsinessReportSummary? summary,
    DrowsinessReviewSummary? reviewSummary,
    List<DrowsinessEvent> events,
  ) {
    final summaryTotal = summary?.totalEvents;
    if (summaryTotal != null && summaryTotal > 0) {
      return summaryTotal;
    }

    final reviewTotal = reviewSummary?.totalEvents;
    if (reviewTotal != null && reviewTotal > 0) {
      return reviewTotal;
    }

    return events.length;
  }

  String _formatPercent(double value) {
    final isWhole = value == value.roundToDouble();
    if (isWhole) {
      return '${value.toStringAsFixed(0)}%';
    }
    return '${value.toStringAsFixed(1)}%';
  }

  String _formatCount(int value) => NumberFormat.decimalPattern().format(value);

  int? _peakHour(List<DrowsinessEvent> events) {
    if (events.isEmpty) return null;

    final counts = <int, int>{};
    for (final event in events) {
      counts[event.time.hour] = (counts[event.time.hour] ?? 0) + 1;
    }

    return counts.entries
        .reduce((best, item) => item.value > best.value ? item : best)
        .key;
  }

  DateTime? _peakDate(List<DrowsinessEvent> events) {
    if (events.isEmpty) return null;

    final counts = <DateTime, int>{};
    for (final event in events) {
      final date = DateTime(event.time.year, event.time.month, event.time.day);
      counts[date] = (counts[date] ?? 0) + 1;
    }

    return counts.entries
        .reduce((best, item) => item.value > best.value ? item : best)
        .key;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: data.accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: data.accentColor.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(data.icon, color: data.accentColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.title,
                  style: const TextStyle(
                    color: ReportStyles.textMuted,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.value,
                  style: const TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: data.descriptionColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
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

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.description,
    required this.descriptionColor,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String description;
  final Color descriptionColor;
  final IconData icon;
  final Color accentColor;
}
