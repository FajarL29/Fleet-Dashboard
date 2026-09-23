import 'api_config.dart';
import '../models/live_gps_fix.dart';
import '../models/vehicle_status.dart';
import '../utils/last_seen_format.dart';

/// How stale a fix may be before a page stops treating it as live.
///
/// The rig reports every few seconds; a minute of silence means the device has
/// dropped off. Past this the fix stops counting as "where the vehicle is" and
/// becomes "where it was last seen" — it is still shown, but as a last known
/// position rather than a live one.
const Duration kLiveFixMaxAge = Duration(minutes: 1);

/// The reason text a row carries once its fix has gone stale.
///
/// Prefixed on every last-known row so the wording is identical wherever it
/// surfaces — marker tooltip, vehicle list, detail panel.
const String kLastKnownPrefix = 'Last known position';

/// Whether this row is showing a remembered position rather than a live one.
///
/// The map greys and fades these; lists label them. Keyed off the reason text
/// because that is the one field every page already carries through.
bool isLastKnownPosition(VehicleStatusItem item) =>
    item.statusReason.startsWith(kLastKnownPrefix);

/// Overlays live GPS fixes onto the rows the status endpoint returned.
///
/// The websocket is opened once, by `DashboardBloc`, and every page that shows
/// positions merges through here. That is what keeps Overview, Live Tracking
/// and Vehicle Management from disagreeing about where a vehicle is: they read
/// the same fixes and apply them the same way.
///
/// A fix is never thrown away for being old. When the device goes quiet the
/// marker stays where it last reported, marked offline and labelled with its
/// age — losing the vehicle off the map entirely is worse than showing a
/// position that is plainly, visibly stale.
///
/// [includeUnregistered] decides what happens to a device that is transmitting
/// but is not in [items] — the test rig, typically. A live map wants it
/// (something really is out there moving); a registry does not, because
/// inventing a row would claim the fleet contains a vehicle it does not.
List<VehicleStatusItem> applyLiveFixes(
  List<VehicleStatusItem> items,
  Map<String, LiveGpsFix> fixes, {
  bool includeUnregistered = false,
  DateTime? now,
}) {
  if (fixes.isEmpty && (!includeUnregistered || kStandaloneTrackers.isEmpty)) {
    return items;
  }

  final at = now ?? DateTime.now();
  final claimed = <String>{};

  final merged = items.map((item) {
    final fix = _fixFor(item, fixes);
    if (fix == null) return item;

    claimed.add(fix.vehicleId);
    final age = fix.age(now: at);
    return age <= kLiveFixMaxAge
        ? _withLiveFix(item, fix)
        : _withLastKnownFix(item, fix, age);
  }).toList();

  if (!includeUnregistered) return merged;

  for (final fix in fixes.values) {
    if (claimed.contains(fix.vehicleId)) continue;
    merged.add(_rowForUnregisteredTracker(fix, fix.age(now: at)));
    claimed.add(fix.vehicleId);
  }

  // Configured test devices appear whether or not they are transmitting.
  // Without this a rig that is switched off is simply absent, so there is
  // nothing to select or watch while waiting for it to come up.
  for (final tracker in kStandaloneTrackers) {
    if (claimed.contains(tracker.id)) continue;
    merged.add(_rowForSilentTracker(tracker));
  }

  return merged;
}

/// A row carrying a fix that arrived moments ago: this is where the vehicle is.
VehicleStatusItem _withLiveFix(VehicleStatusItem item, LiveGpsFix fix) {
  final moving = fix.speed > 1;
  return item.copyWith(
    latitude: fix.position.latitude,
    longitude: fix.position.longitude,
    speed: fix.speed,
    heading: fix.heading,
    lastTelemetryTime: fix.receivedAt,
    lastSeenMinutes: 0,
    // A fix this recent means the device is reachable, whatever the status
    // endpoint said the last time it was polled.
    deviceStatus: 'online',
    movementStatus: moving ? 'moving' : 'idle',
    displayStatus: moving ? 'moving' : 'idle',
    statusReason: 'Live GPS',
  );
}

/// A row carrying a fix the device has since stopped following up on.
///
/// The position is kept so the vehicle does not vanish off the map, but
/// everything that would imply it is live is stripped: the status reads
/// offline, the speed is dropped (whatever it was doing, it is not doing it
/// now), and the reason says how long ago this was.
VehicleStatusItem _withLastKnownFix(
  VehicleStatusItem item,
  LiveGpsFix fix,
  Duration age,
) {
  // The status endpoint may have reported a position more recently than this
  // fix arrived — a device that dropped off the socket but is still posting
  // telemetry, say. The newer of the two wins.
  final reported = item.lastTelemetryTime;
  if (item.hasCoordinates &&
      reported != null &&
      reported.isAfter(fix.receivedAt)) {
    return item;
  }

  final minutes = age.inMinutes;
  return item.copyWith(
    latitude: fix.position.latitude,
    longitude: fix.position.longitude,
    speed: 0,
    lastTelemetryTime: fix.receivedAt,
    lastSeenMinutes: minutes,
    deviceStatus: 'offline',
    movementStatus: 'offline',
    displayStatus: 'offline',
    statusReason: '$kLastKnownPrefix · ${formatLastSeen(minutes)}',
  );
}

/// Finds the fix belonging to [item], matching on any of the identifiers the
/// row carries — the device may announce itself by id, VIN or plate.
LiveGpsFix? _fixFor(VehicleStatusItem item, Map<String, LiveGpsFix> fixes) {
  for (final candidate in [
    item.vehicleId,
    item.vehicleIdentificationNumber,
    item.plateNumber,
  ]) {
    final key = candidate.trim();
    if (key.isEmpty) continue;
    final fix = fixes[key];
    if (fix != null) return fix;
  }
  return null;
}

/// A row for a configured device that has never reported in this session.
///
/// Nothing has been heard from it and nothing was remembered from last time,
/// so there is genuinely no position to draw. It still lists, so it can be
/// found and watched while waiting for its first fix.
VehicleStatusItem _rowForSilentTracker(StandaloneTracker tracker) {
  return VehicleStatusItem(
    vehicleId: tracker.id,
    vehicleIdentificationNumber: '',
    plateNumber: tracker.label,
    driverName: 'Live GPS device',
    lastTelemetryTime: null,
    lastSeenMinutes: null,
    latitude: null,
    longitude: null,
    speed: null,
    deviceStatus: 'offline',
    movementStatus: 'offline',
    safetyStatus: 'normal',
    displayStatus: 'offline',
    statusReason: 'Waiting for first GPS fix',
  );
}

/// A row standing in for a device that reported but is not registered.
VehicleStatusItem _rowForUnregisteredTracker(LiveGpsFix fix, Duration age) {
  final label = _labelForTracker(fix.trackerId);
  if (age > kLiveFixMaxAge) {
    final minutes = age.inMinutes;
    return VehicleStatusItem(
      vehicleId: fix.trackerId,
      vehicleIdentificationNumber: '',
      plateNumber: label,
      driverName: 'Live GPS device',
      lastTelemetryTime: fix.receivedAt,
      lastSeenMinutes: minutes,
      latitude: fix.position.latitude,
      longitude: fix.position.longitude,
      speed: 0,
      deviceStatus: 'offline',
      movementStatus: 'offline',
      safetyStatus: 'normal',
      displayStatus: 'offline',
      statusReason: '$kLastKnownPrefix · ${formatLastSeen(minutes)}',
    );
  }

  final moving = fix.speed > 1;
  return VehicleStatusItem(
    vehicleId: fix.trackerId,
    vehicleIdentificationNumber: '',
    plateNumber: label,
    driverName: 'Live GPS device',
    lastTelemetryTime: fix.receivedAt,
    lastSeenMinutes: 0,
    latitude: fix.position.latitude,
    longitude: fix.position.longitude,
    speed: fix.speed,
    heading: fix.heading,
    deviceStatus: 'online',
    movementStatus: moving ? 'moving' : 'idle',
    safetyStatus: 'normal',
    displayStatus: moving ? 'moving' : 'idle',
    statusReason: 'Unregistered tracker',
  );
}

/// The name a standalone device is listed under, so a configured rig keeps the
/// label it was given instead of reverting to a bare id once it goes quiet.
String _labelForTracker(String trackerId) {
  for (final tracker in kStandaloneTrackers) {
    if (tracker.id == trackerId) return tracker.label;
  }
  return 'Tracker $trackerId';
}

/// Whether a row counts as online.
///
/// A device that is moving or idling is, by definition, reporting — the two
/// are movement states of a live device, not alternatives to being online.
/// Only a device that has gone quiet is offline.
bool isVehicleOnline(VehicleStatusItem item) {
  final device = item.deviceStatus.trim().toLowerCase();
  if (device == 'online') return true;
  if (device == 'offline') return false;

  const liveStates = {'moving', 'idle', 'warning', 'alert'};
  return liveStates.contains(item.displayStatus.trim().toLowerCase()) ||
      liveStates.contains(item.movementStatus.trim().toLowerCase());
}

/// The status payload with live fixes applied and its summary recomputed.
///
/// The server's own summary is a snapshot taken when it answered, so it does
/// not know about fixes that arrived over the socket since. Leaving it alone
/// let the KPI read "0 online" while the rows underneath it — and the markers
/// on the map — were plainly moving. Counting the rows that are actually being
/// displayed keeps the headline number and the map telling the same story.
VehicleStatusData mergeVehicleStatus(
  VehicleStatusData? raw,
  Map<String, LiveGpsFix> fixes, {
  bool includeUnregistered = false,
  DateTime? now,
}) {
  final rows = applyLiveFixes(
    raw?.vehicles ?? const <VehicleStatusItem>[],
    fixes,
    includeUnregistered: includeUnregistered,
    now: now,
  );

  var online = 0;
  var moving = 0;
  var idle = 0;
  var warning = 0;
  var alert = 0;

  for (final row in rows) {
    if (isVehicleOnline(row)) online++;

    switch (row.displayStatus.trim().toLowerCase()) {
      case 'moving':
        moving++;
      case 'idle':
        idle++;
      case 'warning':
        warning++;
      case 'alert':
        alert++;
    }

    if (row.safetyStatus.trim().toLowerCase() == 'alert' &&
        row.displayStatus.trim().toLowerCase() != 'alert') {
      alert++;
    }
  }

  return VehicleStatusData(
    summary: VehicleStatusSummary(
      totalVehicles: rows.length,
      onlineVehicles: online,
      moving: moving,
      idle: idle,
      warning: warning,
      offline: rows.length - online,
      alert: alert,
    ),
    vehicles: rows,
  );
}
