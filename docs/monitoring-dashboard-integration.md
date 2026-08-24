# Monitoring Dashboard Integration

## Summary

This MVP adds standalone Vital Sign and Air Quality monitoring pages to the existing Fleet Dashboard. The integration intentionally preserves the current Overview, Vehicles, Live Tracking, Drowsiness/Safety, and Reports implementations and does not expand `DashboardBloc` with new monitoring state.

## Files modified

Existing files changed:

- `lib/constants/menu_items.dart`
- `lib/screens/dashboard_screen.dart`
- `test/widget_test.dart`

Files added:

- `lib/models/vital_sign_reading.dart`
- `lib/models/air_quality_reading.dart`
- `lib/services/vital_sign_service.dart`
- `lib/services/air_quality_service.dart`
- `lib/screens/vital_sign_screen.dart`
- `lib/screens/air_quality_screen.dart`
- `lib/widgets/monitoring/monitoring_components.dart`
- `test/monitoring_services_test.dart`
- `docs/monitoring-dashboard-integration.md`

No backend, multimedia application, Drowsiness service/page, vehicle feature, Live Tracking feature, Reports feature, Overview widget, or `DashboardBloc` implementation was changed.

## New models

### `VitalSignReading`

Nullable backend fields:

- `healthReportId`
- `userId`
- `vehicleId`
- `deviceId`
- `time`
- `heartRate`
- `spo2`
- `bodyTemperature`
- `systolicBp`
- `diastolicBp`
- `respiratoryRate`

### `AirQualityReading`

Nullable backend fields:

- `airConditionId`
- `vehicleId`
- `deviceId`
- `timestamp`
- `co`
- `co2`
- `pm25`
- `pm10`
- `temperature`
- `o2`
- `humidity`
- `aqi`

Numeric parsers accept JSON numbers or numeric strings. Missing, null, empty, or unparseable measurements remain `null` and display as `Not available`.

## New services and endpoints

`VitalSignService` supports:

- `getLatestByVehicle(vehicleId)` → `GET /health/latest/:vehicle_id`
- `getHistoryByVehicle(vehicleId, startDate?, endDate?)` → `GET /health/history/:vehicle_id?start_date=&end_date=`

`AirQualityService` supports:

- `getLatestByVehicle(vehicleId)` → `GET /air-monitor/latest/:vehicle_id`
- `getHistoryByVehicle(vehicleId, startDate?, endDate?)` → `GET /air-monitor/history/:vehicle_id?start_date=&end_date=`

Both services follow the existing compile-time configuration pattern:

- `API_BASE_URL`, defaulting to `http://localhost:3000/api/v1`
- `API_AUTH_TOKEN`, attached as a Bearer token when non-empty

Both accept an optional `http.Client` for isolated testing. They support the existing API envelope pattern (`status` plus `data`), direct JSON objects/lists, empty response bodies, non-2xx failures, and invalid response formats. History methods are implemented for backend access but are not displayed in this first UI iteration.

## Routes and pages

New sidebar routes:

| Sidebar item | Route | Page |
|---|---|---|
| Vital Sign | `/vital-sign` | `VitalSignScreen` |
| Air Quality | `/air-quality` | `AirQualityScreen` |

The items are placed after Safety and before Reports to keep the monitoring functions adjacent without redesigning or grouping the existing sidebar.

Each page provides:

- Fleet Dashboard card, typography, color, loading, empty, and error patterns;
- selected vehicle label;
- latest measurement cards;
- measurement timestamp and device ID;
- manual refresh;
- non-blocking refresh-failure banner when older data is available;
- a clear instruction when no Fleet vehicle is selected.

No pollutant thresholds, medical interpretations, alert rules, WebSocket, MQTT, charts, or historical analytics were introduced.

## Vehicle ID mapping

The monitoring endpoints receive `selectedVehicle.id`.

This is the current internal Fleet vehicle ID mapping:

1. `/vehicles/status` returns `VehicleStatusItem.vehicleId` and `vehicleIdentificationNumber`.
2. `DashboardBloc._mapVehiclesWithCoordinates` maps `VehicleStatusItem.vehicleId` to `Vehicle.id`.
3. VIN is stored separately as `Vehicle.apiVehicleId`.
4. The new APIs are defined with a `:vehicle_id` parameter, so the integration uses `Vehicle.id`, not VIN or plate number.

No fallback to `VIN-0001`, `1210`, plate number, or another hardcoded identifier exists in the new modules.

The selected vehicle currently comes from Overview map selection. Vehicles and Live Tracking maintain their own page-local selections and do not update the root Fleet selection; changing that would require broader selection-state work outside this MVP.

## State and refresh mechanism

Each monitoring page owns isolated local state:

- latest reading;
- initial loading state;
- refresh state;
- initial error;
- refresh error;
- in-flight request guard.

The latest endpoint is called when a selected-vehicle page is created and every 8 seconds afterward. A request is skipped when another request is still running. Periodic refresh is also skipped while the nested route is not current. The timer is cancelled in `dispose`.

When the root selected vehicle ID changes, the page content receives a vehicle-specific key. Flutter disposes the old state/timer and creates a new state that queries the new internal vehicle ID.

## Failure and empty handling

- No selected vehicle: no request; selection instruction is shown.
- Empty response body, null `data`, empty object, or empty list: no-reading state.
- Partial sensor record: available values render; missing fields show `Not available`.
- Non-2xx or invalid JSON/shape: isolated page error with Retry.
- Refresh failure after a successful reading: previous reading remains visible with a warning banner.
- Monitoring failures do not emit root BLoC state or affect other routes.

## Overview integration status

Overview integration is intentionally deferred.

At the end of the standalone-page MVP, `DashboardState.initial()` still contained mock `DriverHealth` and `AQIData` values. The Overview phase below removes those seeded values and keeps the new loading/error/refresh concerns outside the root BLoC.

## Tests and verification

Added focused tests cover:

- nullable and numeric-string parsing for both models;
- Vital Sign latest endpoint URL and API-envelope parsing;
- Air Quality history date query construction and list parsing;
- empty latest response handling;
- invalid Air Quality response failure isolation;
- presence of the two new sidebar routes and preservation of existing key routes.

Verification performed in this environment:

- `dart format` completed for all changed Dart files.
- `git diff --check` completed without whitespace errors.
- source-level review confirmed timer cancellation, in-flight guards, route-current checks, nullable display handling, internal vehicle ID usage, and navigation registration.

Environment limitation:

- `flutter analyze` timed out after 120 seconds without emitting analyzer results.
- targeted `dart analyze` timed out after 180 seconds without emitting analyzer results.
- targeted `flutter test --no-pub` timed out after 120 seconds without emitting test results.
- Stale Dart processes created by the attempted verification commands were stopped by exact process ID; pre-existing Dart/IDE processes were left untouched.

Consequently, a successful analyzer/test/build run is not claimed here. The following should be rerun in a healthy Flutter tool session:

```bash
flutter analyze
flutter test
flutter run -d windows --dart-define=API_BASE_URL=<backend-api-v1> --dart-define=API_AUTH_TOKEN=<token>
```

Manual runtime verification should confirm every existing route still opens, select a vehicle on Overview, then confirm both new pages request and display that vehicle's real backend readings.

## Known limitations

- A vehicle must first be selected on the Overview map.
- Root vehicle selection is not synchronized with Vehicles or Live Tracking page-local selection.
- Only latest readings are displayed; history service methods are ready but no history UI is included.
- No timestamps/freshness policy beyond displaying the backend timestamp.
- No unit metadata is supplied by the described API. The UI labels only established vital units (`bpm`, `%`, `°C`, `mmHg`, `breaths/min`). Air Quality values are shown without invented units except temperature and humidity.
- No threshold classification, health interpretation, alerting, socket stream, MQTT, caching, or offline persistence.
- The existing Overview health/AQI mocks remain visible in the legacy fullscreen/unused mock areas until a separate integration phase.
- The API response implementation assumes the same `status`/`data` convention as existing APIs or a direct object/list. If the backend wraps history under a field other than `items`, `history`, or `records`, the service parser will need the actual response sample.

## Next recommended step

The next broader phase can add a shared Fleet vehicle selector/context so Overview, Vehicles, and Live Tracking use the same root selection. Real backend samples should also be manually validated against both latest endpoints in the deployed environment.

## Overview Real Data Integration

### Files modified

- `lib/widgets/overview/overview_monitoring_summary.dart` (new): isolated Overview polling and summary UI.
- `lib/widgets/overview/overview_dashboard.dart`: places the two monitoring summaries below the existing KPI row.
- `lib/bloc/dashboard/dashboard_state.dart`: removes the now-unused seeded `DriverHealth` and `AQIData` fields.
- `lib/screens/dashboard_screen.dart`: replaces the fullscreen panel's seeded driver-health cards with the same backend-driven monitoring summary.
- `test/overview_monitoring_summary_test.dart` (new): verifies vehicle ID propagation, vehicle changes, and failure isolation.
- `docs/monitoring-dashboard-integration.md`: records this integration phase.

### Old mock flow

`DashboardState.initial()` previously created three fixed `DriverHealth` objects and an `AQIData(index: 42, pm25: 72, co2: 22, no2: 15)`. `DashboardScreen` passed the health list into the Overview and rendered it in the fullscreen map's `DriverMonitoring` panel. That panel now uses the real monitoring summary. The legacy `StatisticsCards` AQI consumer is no longer active in the current Overview, but its non-zero state value was still mock data.

### New real-data flow

`OverviewDashboard` receives `DashboardState.selectedVehicle` as before and passes it to `OverviewMonitoringSummary`. The summary reuses `VitalSignService.getLatestByVehicle` and `AirQualityService.getLatestByVehicle`; it does not add either feature's state to `DashboardBloc` and does not introduce duplicate models or API clients.

The exact selected `Vehicle.id` is supplied to both latest endpoints. This is the Fleet internal `vehicle_id` established by the existing vehicle-status mapping. Overview map selection dispatches the existing `VehicleSelected`/`SelectionCleared` events, so the map and monitoring summaries share the root selection. When the selected ID changes, the widget clears the prior readings, invalidates any old responses, and immediately starts both requests for the new ID.

### Displayed fields

- Vital Sign: Heart Rate, SpO2, Body Temperature, and measurement time when available.
- Air Quality: AQI, PM2.5, CO2, and measurement time when available.

Blood Pressure, Respiratory Rate, and the additional air measurements remain on their standalone detail pages. The Overview applies no medical or air-quality thresholds or interpretations.

### Refresh and lifecycle behavior

Both summaries load immediately and poll approximately every eight seconds. Each domain has a separate in-flight guard, so timer ticks cannot overlap a request. Polling ticks are skipped while the Overview route is not current. The periodic timer is cancelled on disposal. A generation token prevents late responses for a disposed widget or previously selected vehicle from updating current state. No WebSocket or MQTT connection was added.

### Loading, empty, and error handling

Vital Sign and Air Quality render independently. Each card has its own loading indicator, no-selection message, no-data message, retry action, initial error, and non-destructive refresh error. A failure in either service leaves the other card and every existing Overview section renderable. Monitoring errors never enter the global Dashboard error state.

### Testing results

The widget tests cover:

- use of the selected internal vehicle ID by both services;
- immediate Vital Sign refresh after vehicle selection changes;
- Vital Sign failure while Air Quality still renders successfully.

In this workspace, `dart format` produced no output and timed out after 30 seconds. `flutter analyze` and the focused `flutter test test/overview_monitoring_summary_test.dart test/monitoring_services_test.dart` command likewise produced no result before their 120-second limits. They were not reported as passing. Source inspection and `git diff --check` completed successfully; runtime/API validation still needs an environment where the Flutter tool starts reliably.

### Remaining limitations

- Polling pauses based on nested-route visibility; there is no application-lifecycle observer for background/minimized desktop windows.
- Vehicles and Live Tracking retain their existing page-local selection behavior. The monitoring cards follow the root Fleet selection used by Overview.
- The old `DriverHealth`, `AQIData`, `DriverMonitoring`, and `StatisticsCards` classes remain because they are still valid standalone code; only their unused Dashboard state and seeded Overview display path were removed.

## Overview Vehicle Selection Fix

### Root cause

`MapSection._fitAllVehicles()` called `_clearSelection()` before fitting the viewport. `_fitAllVehicles()` runs when the loaded vehicle count changes, when the Overview map first becomes ready, and when the user presses the fit-all control. Because the Overview map was connected to the root callbacks, this internal viewport operation incorrectly dispatched `SelectionCleared`. The immediate reason the monitoring context remained empty was initialization: `_resolveSelectedVehicle()` returned null whenever there was no prior ID, even when usable Fleet vehicles were available. The clear handler also passed a nullable value through `copyWith` instead of its explicit clear flag, so deliberate clear behavior was internally inconsistent.

### Selection flow before and after

Before the fix, the BLoC could resolve a prior selected ID, marker selection could dispatch `VehicleSelected`, and map background taps could deliberately dispatch `SelectionCleared`. A later automatic map fit could then clear that valid selection. There was no explicit Overview selector and the first vehicle was used only as a Drowsiness request fallback, not persisted as the root selection.

After the fix, `DashboardState.selectedVehicle` remains the single source of truth:

1. Vehicle status loads and maps backend `vehicle_id` to `Vehicle.id`.
2. A still-valid selected ID is preserved; otherwise the first mapped Fleet vehicle is selected for the MVP.
3. The Overview header selector and map markers both dispatch the existing `VehicleSelected` event.
4. The selector, marker highlighting/map focus, Drowsiness loading, Vital Sign, and Air Quality all rebuild from the same root selection.
5. Only a deliberate map-background/close action uses `SelectionCleared`; viewport fitting, map rebuilds, and monitoring refreshes do not. The handler now uses `clearSelectedVehicle: true` so that deliberate action has its documented effect.

Changing the selector also triggers the existing Dashboard map listener. The listener now compares the selected ID as well as position, so it focuses a newly selected marker even when two vehicles happen to share coordinates. Concise debug messages identify `default`, `selector`, and `map` selection sources.

### API configuration and resolved URLs

Vehicle, Drowsiness, Vital Sign, and Air Quality now use the compile-time `API_BASE_URL` configuration. With no `--dart-define` override, the shared fallback is `http://localhost:3000/api/v1`:

- Vehicle status: `http://localhost:3000/api/v1/vehicles/status`
- Drowsiness reports/events and latest polling: `http://localhost:3000/api/v1/drowsiness/...`
- Vital Sign latest: `http://localhost:3000/api/v1/health/latest/{vehicle_id}`
- Air Quality latest: `http://localhost:3000/api/v1/air-monitor/latest/{vehicle_id}`

The monitoring services log their fully resolved GET URI in debug builds. No vehicle ID, VIN, or plate is hardcoded.

### Runtime verification

On 18 August 2026, direct requests to the configured local backend returned HTTP 200 for all three verification endpoints. `/vehicles/status` included `vehicle_id=11`, VIN `VIN-0001`, and plate `B 7041 UDB`. `/health/latest/11` returned Heart Rate 82, SpO2 98, and Body Temperature 36.6. `/air-monitor/latest/11` returned the existing record including AQI 55, PM2.5 18, and CO2 620. This verifies the service inputs and model fields against the live test data; interactive dropdown/marker behavior still requires launching the Flutter UI.

The focused `flutter test test/monitoring_services_test.dart test/overview_monitoring_summary_test.dart` command was attempted after terminating the formatter process created by the earlier timed-out run, but it again produced no output before the 120-second limit. It is not reported as passing. `git diff --check` and source-level selection/API tracing completed successfully.

## Fleet Management Overview Redesign

### Approved UX objective

The Overview now follows the approved operational hierarchy while retaining FleetSafe's dark navy surfaces, blue accent, typography, card radii, sidebar, and map. Fleet-wide visibility is presented before the selected vehicle context, followed by map/risk detail, safety events, and concise deterministic insights.

### Files modified

- `lib/widgets/overview/overview_dashboard.dart`: new information hierarchy, fleet KPIs, selected-vehicle status/safety cards, vehicle ranking, recent events, status semantics, and insights.
- `lib/widgets/overview/overview_monitoring_summary.dart`: preserves isolated polling while presenting Vital Sign and Cabin Environment as equal selected-vehicle cards with WIB timestamps.
- `lib/widgets/overview/overview_skeleton_loading.dart`: adds placeholders for the selected-vehicle divider and monitoring-card tier.
- `docs/monitoring-dashboard-integration.md`: documents the approved redesign and verification.

No backend, database, multimedia, API contract, detailed monitoring page, route, or sidebar behavior was changed.

### Information hierarchy

The previous Overview mixed online vehicles, selected Drowsiness values, monitoring readings, map content, driver ranking, and logs without a strong fleet/vehicle boundary. The redesigned order is:

1. Fleet Management Overview header and data-derived status.
2. Fleet Summary: Fleet Online, Offline Vehicles, Safety Events Today, and Vehicles at Risk.
3. Selected Vehicle bar using the existing root selector and internal `Vehicle.id`.
4. Equal-priority Vehicle Status, Driver Safety, Vital Sign, and Cabin Environment cards.
5. Existing Live Map and Vehicle Risk Ranking.
6. Safety Events Breakdown and selected-context Recent Events.
7. Key Insights derived deterministically from current counts and telemetry availability.

The selector, map marker, Drowsiness context, and both monitoring services continue to use `DashboardState.selectedVehicle`. Vital Sign and Air Quality remain isolated from `DashboardBloc` and from one another.

### Status and timestamp semantics

- The fleet badge no longer claims that an entirely offline or partially unavailable fleet is healthy. It displays `LIVE DATA LIMITED` when vehicle status is missing or vehicles are offline, `ATTENTION REQUIRED` for current alert/warning data, and `NORMAL` only when current status supports it.
- Offline vehicle ranking rows use `Unavailable` rather than presenting a fabricated low risk.
- Selected-vehicle speed is labeled `Last recorded speed` when telemetry is missing or more than 15 minutes old.
- Empty recent events say that no recent live events were received; they do not claim “All clear”.
- Dashboard and monitoring timestamps are converted for display to UTC+7 and labeled `WIB`. Backend timestamps are unchanged.

### Reused and new components

Reused components include `MapSection`, the root vehicle selector flow, `_CompactKpiCard`, the live-map card, safety progress rows, event severity chips, `VitalSignService`, `AirQualityService`, and `OverviewMonitoringSummary` polling/failure isolation.

New Overview-local components include the fleet/selected section labels, selected-vehicle bar, Vehicle Status card, Driver Safety card, Vehicle Risk Ranking presentation, and Fleet Insights. They are deliberately local to the Overview rather than a project-wide design-system refactor.

### Checks and limitations

The live backend values previously verified for vehicle 11 continue to map to the unchanged model/service fields; no mock values were added. `dart format` was attempted for the changed Overview/test files but produced no output before the 45-second timeout. `flutter analyze` and `flutter test test/overview_monitoring_summary_test.dart test/monitoring_services_test.dart test/widget_test.dart` likewise produced no output before their 120-second limits. None of those commands is reported as successful. `git diff --check` and source-level reference/semantics checks completed successfully.

Remaining limitations:

- The current Drowsiness Overview state is loaded through the existing selected/fallback vehicle architecture; the Fleet Summary safety count reflects the currently available Overview safety feed rather than a newly aggregated fleet endpoint.
- Vehicle status data does not expose a true vehicle type, so the selector shows plate and VIN instead of mislabeling movement status as vehicle type.
- Insights are intentionally simple rules over current frontend data, not AI recommendations.

## One-Screen Overview Layout Correction

The first redesign preserved functionality but its fixed-height stack exceeded a normal desktop viewport. The selected cards were 190 px high, map/ranking panels were 320 px, operational panels were 232 px, insights wrapped as large cards, and repeated 16–24 px gaps pushed the lower sections below the fold.

This visual-fidelity pass changes presentation only:

- desktop content padding is 20 px horizontally and 12 px vertically;
- fleet KPI cards are 74 px high and remain four-across from 1000 px of content width;
- the selected-vehicle bar is 48 px high;
- Vehicle Status, Driver Safety, Vital Sign, and Cabin Environment are 126 px high and remain four-across at the desktop breakpoint;
- Live Map and Vehicle Risk Ranking are 218 px high and remain in one row;
- Safety Events Breakdown, Recent Events, and Recent Log are restored as three 148 px panels in one desktop row;
- ranking and event previews are limited to the three most useful rows;
- Key Insights use a 52 px horizontal tile strip rather than wrapping large cards;
- the loading skeleton uses the same compact desktop proportions.

The resulting fixed desktop content budget is approximately 820 px including page padding. `SingleChildScrollView` remains as a fallback for meaningfully smaller windows, but it is no longer required by the normal desktop composition. No service, model, selected-vehicle, map, monitoring, navigation, or API logic changed in this pass.

Source checks confirmed that the old 190/320/232 px Overview panel heights and 1180 px desktop breakpoint are no longer present, every compact tier is wired into the expected desktop row, and `git diff --check` passes. The focused `flutter test test/overview_monitoring_summary_test.dart` command produced no output before its 90-second timeout and is not reported as passing. A literal screenshot-to-mockup overlay was not possible because neither screenshot image was included with the correction brief; final pixel validation remains a runtime review step.

## Approved Image Fidelity Correction

`docs/dashboard_revisi.png` was subsequently supplied and inspected directly. It supersedes the earlier textual assumption that Key Insights belonged in the approved Overview; the image contains five tiers only: Fleet Summary, Selected Vehicle, four monitoring cards, map/ranking, and the three-column operational row. Key Insights were therefore removed from the Overview without removing any underlying data or service.

The image comparison drove these targeted presentation changes:

- Fleet Safety Events now includes a compact Drowsy/Yawn/Distraction breakdown beside the primary total.
- The selected-vehicle bar now includes previous/next controls. Dropdown, navigation controls, and map markers all call the same existing `onVehicleSelected` callback and retain `DashboardState.selectedVehicle` as the sole selection source.
- Vehicle Status now uses icon/title hierarchy, a prominent online/offline state, telemetry age, and stale-safe “Last recorded speed” wording.
- Driver Safety now uses icon/title/context hierarchy and colored metric emphasis matching the reference without adding severity calculations.
- Vital Sign and Cabin Environment now use vertical label/value rows, strong values, `(Latest)` context, and a bottom WIB timestamp. No trend is drawn because Overview history is not loaded.
- Map/ranking and Safety Events/Recent Events/Recent Log retain the compact one-screen proportions established in the previous pass.

Files changed for this correction are `overview_dashboard.dart`, `overview_monitoring_summary.dart`, the focused monitoring widget test where reference text is asserted, and this document. The loading skeleton remains structurally compatible with the unchanged five-tier silhouette. No service, BLoC, route, API, backend, database, or multimedia code changed.

Verification commands were bounded because of the existing Flutter tool issue: `dart format` produced no output before 45 seconds, while `flutter analyze` and `flutter test test/overview_monitoring_summary_test.dart` each produced no output before 90 seconds. None is reported as passing. Direct image inspection, source-level hierarchy/selection tracing, and `git diff --check` completed successfully. Capturing a newly rendered runtime screenshot was not possible while the Flutter runner remained blocked, so final pixel comparison in the live application remains outstanding.

## Final Overview Polish

The final polish retains the approved five-tier structure and fixed heights. It adds `assets/images/generic_fleet_van.png`, a local transparent generic silver delivery-van cutout generated for the Vehicle Status card. The asset is registered in `pubspec.yaml`, uses no network dependency or vehicle-specific branding, and is displayed for every selected vehicle as the default fleet visual. The current vehicle model does not provide a reliable vehicle-type field—its `type` value is populated from movement status—so type-specific image mapping would be misleading and was intentionally omitted.

Vehicle Status keeps its 126 px card height. The visual occupies an 88 × 68 px area beside a compact online/offline pill, telemetry age, and current-or-last-recorded speed. This follows the approved hierarchy without introducing additional page height.

The selector’s source list is the coordinate-mapped `vehicles` list produced by `DashboardBloc._mapVehiclesWithCoordinates`, not all items in `VehicleStatusData`. Its count is therefore labeled `Mapped Vehicle X of Y`; Fleet Summary remains the truthful full-fleet count. Dropdown, previous/next controls, and map markers continue to update the same root selection.

Cabin Environment now presents AQI without a unit, PM2.5 in `µg/m³`, and CO2 in `ppm`. Both monitoring cards use the same `Latest: HH:mm WIB` formatter. The current monitoring backend emits its intended WIB wall-clock components with a `Z` suffix; the frontend preserves those clock components rather than applying UTC+7 a second time. Backend timestamps and API contracts are unchanged.

Files modified in this pass are `pubspec.yaml`, `assets/images/generic_fleet_van.png`, `overview_dashboard.dart`, `overview_monitoring_summary.dart`, `overview_monitoring_summary_test.dart`, and this document.

Asset validation confirmed a 1536 × 1024 `Format32bppArgb` PNG with transparent corner pixels (`alpha=0`). `git diff --check` passed. The requested tooling remained blocked without output: `dart format` timed out after 45 seconds, and `flutter analyze` plus `flutter test test/overview_monitoring_summary_test.dart` each timed out after 90 seconds. None is reported as passing.
