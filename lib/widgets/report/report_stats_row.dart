import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/drowsiness_report.dart';
import 'report_styles.dart';

class ReportStatsRow extends StatelessWidget {
  const ReportStatsRow({
    super.key,
    this.report,
    required this.events,
  });

  final DrowsinessReport? report;
  final List<DrowsinessEvent> events;

  @override
  Widget build(BuildContext context) {
    final summary = report?.summary;
    final totalEvents = summary?.totalEvents ?? events.length;
    final highRiskEvents = summary?.highRiskEvents ?? events
        .where((event) => event.riskLevel.toLowerCase() == 'high')
        .length;
    final peakHour = summary?.peakHour ?? _peakHour(events) ?? 0;
    final peakDate = summary?.peakDate ?? _peakDate(events);
    final highRiskRatio = totalEvents == 0
        ? 0
        : ((highRiskEvents / totalEvents) * 100).round();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total Drowsy Events',
            value: totalEvents.toString(),
            description: 'Selected vehicle ${summary?.vehicleId ?? '-'}',
            descriptionColor: ReportStyles.green,
            icon: Icons.nightlight_round,
            accentColor: ReportStyles.blue,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'High-Severity Events',
            value: highRiskEvents.toString(),
            description: '$highRiskRatio% of total events',
            descriptionColor: ReportStyles.red,
            icon: Icons.warning_amber_rounded,
            accentColor: ReportStyles.red,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _StatCard(
            title: 'Peak Hour',
            value: '${peakHour.toString().padLeft(2, '0')}:00',
            description: peakDate == null
                ? 'Peak date unavailable'
                : 'Peak date ${DateFormat('MMM d, yyyy').format(peakDate)}',
            descriptionColor: ReportStyles.green,
            icon: Icons.schedule_rounded,
            accentColor: ReportStyles.purple,
          ),
        ),
      ],
    );
  }

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
  const _StatCard({
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

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accentColor, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: ReportStyles.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: ReportStyles.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: descriptionColor,
                    fontSize: 11,
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
