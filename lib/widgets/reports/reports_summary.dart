import 'dart:math' as math;

import '../../models/drowsiness_report.dart';

/// Fleet-wide totals rolled up from one report per vehicle.
///
/// The API reports per vehicle (`/drowsiness/report/{vin}`), so "All Vehicle"
/// has to combine them here.
class ReportsSummary {
  const ReportsSummary({
    required this.totalEvents,
    required this.highRiskEvents,
    required this.riskScore,
    required this.eventsByDay,
    required this.vehiclesReported,
  });

  /// Nothing loaded: every figure renders as a dash.
  static const empty = ReportsSummary(
    totalEvents: null,
    highRiskEvents: null,
    riskScore: null,
    eventsByDay: [],
    vehiclesReported: 0,
  );

  final int? totalEvents;
  final int? highRiskEvents;

  /// Worst score across the fleet: one dangerous vehicle should not be
  /// averaged away by a dozen quiet ones.
  final int? riskScore;

  /// Daily counts merged across vehicles, oldest first.
  final List<DrowsinessEventsByDay> eventsByDay;

  /// How many vehicles actually returned a report.
  final int vehiclesReported;

  bool get isEmpty => vehiclesReported == 0;
}

ReportsSummary aggregateReports(List<DrowsinessReport> reports) {
  if (reports.isEmpty) return ReportsSummary.empty;

  var totalEvents = 0;
  var highRiskEvents = 0;
  var riskScore = 0;
  final byDate = <DateTime, int>{};

  for (final report in reports) {
    totalEvents += report.summary.totalEvents;
    highRiskEvents += report.summary.highRiskEvents;
    riskScore = math.max(riskScore, report.riskSummary.riskScore);

    for (final day in report.eventsByDay) {
      final date = DateTime(day.date.year, day.date.month, day.date.day);
      byDate[date] = (byDate[date] ?? 0) + day.totalEvents;
    }
  }

  final days =
      byDate.entries
          .map(
            (entry) => DrowsinessEventsByDay(
              date: entry.key,
              totalEvents: entry.value,
            ),
          )
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  return ReportsSummary(
    totalEvents: totalEvents,
    highRiskEvents: highRiskEvents,
    riskScore: riskScore,
    eventsByDay: days,
    vehiclesReported: reports.length,
  );
}
