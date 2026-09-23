import 'package:flutter/foundation.dart';

/// The API as reached from a native build, or a deployed web build.
const String kProductionApiBaseUrl = 'http://203.100.57.59:3000/api/v1';

/// The CORS proxy `.vscode/tasks.json` starts for you.
const String kDevProxyApiBaseUrl = 'http://localhost:4000/api/v1';

/// Single source of truth for how the app talks to the backend.
///
/// A debug web build defaults to the proxy, everything else to the API
/// directly. That split exists because the API sends no `Access-Control-*`
/// headers at all: a browser's preflight comes back 200 without permission,
/// so the real request is never sent and the failure reads as "could not
/// reach the server" while the server log shows a healthy 200 for the
/// OPTIONS. Native builds are not subject to CORS and need no help.
///
/// Choosing here rather than in a launch configuration is deliberate — a
/// `--dart-define` only applies when the configuration carrying it happens to
/// be the one selected, and silently vanishes otherwise.
///
/// Override at build time when deploying:
///   flutter build web --dart-define=API_BASE_URL=https://api.example.com/api/v1
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kIsWeb && kDebugMode
      ? kDevProxyApiBaseUrl
      : kProductionApiBaseUrl,
);

/// A ready-made token. Skips login entirely when set, but expires on its own
/// schedule — prefer the credentials below.
const String kApiAuthToken = String.fromEnvironment(
  'API_AUTH_TOKEN',
  defaultValue: '',
);

/// Credentials for a service account, used only when nobody is signed in.
///
/// Both default to empty on purpose. A real account name left here would be
/// baked into every build, and the moment someone set a password at build time
/// the whole app would quietly query as that account instead of the person
/// using it — the kind of thing that looks fine until an audit asks who did
/// what. Signing in is the normal path; this is an escape hatch for a kiosk or
/// a screen with no keyboard.
///
///   flutter build web --dart-define=API_USERNAME=... --dart-define=API_PASSWORD=...
const String kApiUsername = String.fromEnvironment('API_USERNAME');
const String kApiPassword = String.fromEnvironment('API_PASSWORD');

/// How long an API request may run before it is treated as a failure.
///
/// Without this, a request to an unreachable host hangs until the OS-level TCP
/// timeout (over a minute), which leaves pages stuck on their loading skeleton
/// instead of showing an error the user can act on.
const Duration kApiRequestTimeout = Duration(seconds: 12);

/// Which fleet vehicle each GPS tracker is bolted to.
///
/// A tracker announces its own id, which is not the same number space as the
/// vehicle ids `/vehicles/status` returns (5..11). An entry here makes that
/// tracker's live fix drive an existing vehicle's marker.
///
/// Deliberately empty. Tracker 1210 is the Raspberry Pi test rig, which is not
/// fitted to any vehicle in the fleet — mapping it onto one would overwrite
/// that vehicle's real position with test coordinates. With no entry it gets a
/// marker of its own instead, so live testing never touches production data.
///
/// Add a row only for a device genuinely mounted on a fleet vehicle:
///   const kTrackerToVehicleId = {'tracker id': 'vehicle id'};
const Map<String, String> kTrackerToVehicleId = <String, String>{};

/// A GPS device shown as a vehicle even when it is not transmitting.
///
/// `/vehicles/status` does not list the test rig, so without this it only
/// appears while fixes are arriving and vanishes the moment it goes quiet.
/// That makes it impossible to line a test up before switching the device on —
/// the thing you want to watch is simply not there yet.
///
/// Listed here it is always present: offline and without a position until a
/// fix lands, then live. Remove the entry once the device is registered in the
/// fleet properly, at which point `/vehicles/status` carries it and
/// [kTrackerToVehicleId] is the right tool instead.
class StandaloneTracker {
  const StandaloneTracker({required this.id, required this.label});

  /// The id the device announces itself by, over the websocket.
  final String id;

  /// What to call it in vehicle lists and on the map.
  final String label;
}

const List<StandaloneTracker> kStandaloneTrackers = <StandaloneTracker>[
  StandaloneTracker(id: '1210', label: 'Tracker 1210 (test rig)'),
];

/// Which tracker the dashboard's GPS websocket subscribes to.
///
/// The device announces itself by its own id, which is not the same number
/// space as the vehicle ids `/vehicles/status` returns — tracker 1210 is the
/// Raspberry Pi rig, not vehicle 1210.
///
///   flutter run --dart-define=GPS_TRACKER_ID=1210
const String kGpsTrackerId = String.fromEnvironment(
  'GPS_TRACKER_ID',
  defaultValue: '1210',
);

/// Where the GPS websocket lives. Separate host and port from [kApiBaseUrl]:
/// the REST API is on :3000, the socket on :3300.
///
///   flutter run --dart-define=GPS_SOCKET_URL=ws://host:3300
const String kGpsSocketUrl = String.fromEnvironment(
  'GPS_SOCKET_URL',
  defaultValue: 'ws://203.100.57.59:3300',
);
