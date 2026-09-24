/// Reads a timestamp from the API as the wall clock that was actually recorded.
///
/// The backend stamps `Z` on values it never converted, so the digits are
/// already local time. Two independent checks in `docs/api` pin this down:
///
///  * every one of the 100 sampled drowsiness events sits exactly seven hours
///    after the real `Date.now()` epoch embedded in its own `img_path`;
///  * an air-monitor row carries `created_time: "13:41:40"` right beside
///    `timestamp: "2026-08-18T13:40:00.000Z"`.
///
/// Honouring that `Z` adds UTC+7 on top, which shows a reading seven hours late
/// and rolls anything after 17:00 onto the next day.
///
/// Every model parses through here rather than keeping its own copy, because
/// the copies had drifted: `last_telemetry_time` rendered as the recorded hour
/// on the high-risk card and seven hours later in the map tooltip, from one
/// field on one page.
///
/// Delete this once the API sends a genuine offset, or the correction inverts.
DateTime? parseApiTimestamp(dynamic value) {
  if (value is DateTime) return value;
  if (value == null) return null;

  final raw = value.toString().trim();
  if (raw.isEmpty) return null;

  final unlabelled = raw.endsWith('Z') ? raw.substring(0, raw.length - 1) : raw;

  // A value that survives only with the marker still attached is one this
  // correction does not understand, so it keeps the old reading.
  return DateTime.tryParse(unlabelled) ?? DateTime.tryParse(raw)?.toLocal();
}
