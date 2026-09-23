/// Renders "minutes since last telemetry" in units a person can read.
///
/// The raw figure was printed as-is, which produced lines like
/// "Last seen 166661 min ago" — that is nearly four months, but nobody reads
/// it as four months without doing the arithmetic. And "how stale is this?" is
/// exactly the question being asked when a vehicle is sitting motionless on
/// the map: a device that last reported in May is a very different thing from
/// one that missed the last poll.
String formatLastSeen(int minutes) {
  if (minutes < 0) return 'just now';
  if (minutes < 1) return 'just now';
  if (minutes < 60) return '$minutes min ago';

  final hours = minutes ~/ 60;
  if (hours < 24) {
    final restMinutes = minutes % 60;
    return restMinutes == 0 ? '$hours h ago' : '$hours h $restMinutes min ago';
  }

  final days = hours ~/ 24;
  if (days < 7) {
    final restHours = hours % 24;
    return restHours == 0 ? '$days d ago' : '$days d $restHours h ago';
  }

  if (days < 30) {
    final weeks = days ~/ 7;
    return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
  }

  final months = days ~/ 30;
  if (months < 12) {
    return months == 1 ? '1 month ago' : '$months months ago';
  }

  final years = days ~/ 365;
  return years == 1 ? 'over a year ago' : 'over $years years ago';
}
