import '../../models/drowsiness_report.dart';
import '../common/sortable_header.dart';

/// Columns of the safety event table, in display order.
///
/// Only Time and Severity sort. The rest are labels you read off a row, not
/// orderings anyone asks for, and a header that reorders the table on a click
/// nobody wanted is worse than one that stays put.
enum SafetyEventColumn {
  time('Time', sortable: true, firstDirection: SortDirection.descending),
  vehicle('Vehicle'),
  vin('VIN'),
  eventType('Event Type'),
  severity(
    'Severity',
    sortable: true,
    firstDirection: SortDirection.descending,
  ),
  speed('Speed'),
  location('Location');

  const SafetyEventColumn(
    this.label, {
    this.sortable = false,
    this.firstDirection = SortDirection.ascending,
  });

  final String label;
  final bool sortable;

  /// What a first click on this column should mean. Newest events and the
  /// worst severity are what someone is looking for, so both start descending.
  final SortDirection firstDirection;
}

/// Ranks severity so it sorts by danger rather than alphabetically — "high"
/// coming after "low" in a text sort would be actively misleading.
int _severityRank(String risk) {
  switch (risk.trim().toLowerCase()) {
    case 'high':
    case 'critical':
      return 3;
    case 'medium':
      return 2;
    case 'low':
      return 1;
    default:
      return 0;
  }
}

/// Returns [events] ordered by [sort], leaving the caller's list untouched.
List<DrowsinessEvent> sortSafetyEvents(
  List<DrowsinessEvent> events,
  ColumnSort<SafetyEventColumn> sort,
) {
  final sorted = List<DrowsinessEvent>.from(events);

  int compare(DrowsinessEvent a, DrowsinessEvent b) {
    switch (sort.column) {
      case SafetyEventColumn.time:
        return a.time.compareTo(b.time);
      case SafetyEventColumn.severity:
        return _severityRank(a.riskLevel).compareTo(_severityRank(b.riskLevel));
      // Not sortable: the header does not offer them, so nothing can pick
      // them. Falling back to time keeps the list in a sane order rather
      // than throwing if that ever changes.
      case SafetyEventColumn.vehicle:
      case SafetyEventColumn.vin:
      case SafetyEventColumn.eventType:
      case SafetyEventColumn.speed:
      case SafetyEventColumn.location:
        return a.time.compareTo(b.time);
    }
  }

  sorted.sort((a, b) {
    final result = sort.order(compare(a, b));
    // Ties keep a stable, meaningful order instead of whatever the API sent.
    return result != 0 ? result : b.time.compareTo(a.time);
  });

  return sorted;
}
