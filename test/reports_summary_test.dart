import 'package:flutter_test/flutter_test.dart';

import 'package:fleet_dashboard/models/drowsiness_report.dart';
import 'package:fleet_dashboard/widgets/reports/reports_summary.dart';

DrowsinessReport _report({
  required int total,
  required int highRisk,
  required int riskScore,
  required Map<int, int> eventsByDayOfMonth,
}) {
  return DrowsinessReport(
    summary: DrowsinessReportSummary(
      vehicleId: 'VIN',
      totalEvents: total,
      highRiskEvents: highRisk,
      peakHour: 0,
    ),
    reviewSummary: const DrowsinessReviewSummary(
      totalEvents: 0,
      newEvents: 0,
      confirmed: 0,
      falseAlarm: 0,
      followUpRequired: 0,
      followedUp: 0,
      reviewedTotal: 0,
      reviewCompletionRate: 0,
      falseAlarmRate: 0,
      closureRate: 0,
    ),
    riskSummary: ReportRiskSummary(
      riskLevel: 'high',
      riskScore: riskScore,
      headline: '',
      shortSummary: '',
      primaryFinding: const ReportPrimaryFinding(
        title: '',
        value: '',
        description: '',
      ),
      mainContributor: const ReportMainContributor(
        userId: null,
        driverName: '',
        totalEvents: 0,
        percentage: 0,
        description: '',
      ),
      dominantBehavior: const ReportDominantBehavior(
        key: '',
        label: '',
        description: '',
      ),
      reviewBacklog: const ReportReviewBacklog(
        newEvents: 0,
        reviewCompletionRate: 0,
        description: '',
      ),
      recommendedActions: const [],
      flags: const [],
    ),
    eventsByDay: [
      for (final entry in eventsByDayOfMonth.entries)
        DrowsinessEventsByDay(
          date: DateTime(2026, 8, entry.key),
          totalEvents: entry.value,
        ),
    ],
    eventsByHour: const [],
    weekdayBehaviorSummary: const [],
  );
}

void main() {
  test('no reports leaves every figure blank rather than zero', () {
    final summary = aggregateReports([]);

    expect(summary.isEmpty, isTrue);
    expect(summary.totalEvents, isNull);
    expect(summary.riskScore, isNull);
    expect(summary.eventsByDay, isEmpty);
  });

  test('fleet totals sum across vehicles and share dates merge', () {
    final summary = aggregateReports([
      _report(
        total: 10,
        highRisk: 4,
        riskScore: 60,
        eventsByDayOfMonth: {1: 6, 2: 4},
      ),
      _report(
        total: 5,
        highRisk: 1,
        riskScore: 83,
        eventsByDayOfMonth: {2: 3, 3: 2},
      ),
    ]);

    expect(summary.totalEvents, 15);
    expect(summary.highRiskEvents, 5);
    // Worst vehicle drives fleet risk, not the average.
    expect(summary.riskScore, 83);
    expect(summary.vehiclesReported, 2);

    expect(summary.eventsByDay.map((day) => day.date.day), [1, 2, 3]);
    expect(summary.eventsByDay.map((day) => day.totalEvents), [6, 7, 2]);
  });
}
