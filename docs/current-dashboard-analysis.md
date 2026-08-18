# Current Dashboard Analysis

## 1. Scope and executive summary

This document is a read-only architecture assessment of the repository as inspected on 2026-08-14. No application source code was changed as part of this analysis.

The project is a Flutter/Dart application whose implemented core is fleet vehicle visibility plus drowsiness monitoring. It already uses the product name “Fleet Management”/“FleetSafe Telematics,” but its safety analytics, event workflow, reporting, and part of its root state are specifically shaped around drowsiness.

The application is a viable base for a unified Fleet Management Dashboard because it already contains:

- a persistent desktop dashboard shell and sidebar;
- vehicle registry and live vehicle-status modules;
- map, filter, table, export, loading, empty, and error-state patterns;
- a typed REST service/model layer for vehicles and drowsiness;
- a WebSocket path for GPS and image events;
- placeholder/model concepts for driver health and air quality.

It is not yet modular by monitoring domain. `DashboardBloc` combines navigation state, GPS connectivity, drowsiness polling, drowsiness analytics, vehicle selection, mock Vital Sign data, and mock AQI data. Safety and Reports instantiate services directly and manage async state locally. Adding Vital Sign and Air Quality in this shape would increase duplication, inconsistent refresh behavior, and cross-domain coupling.

The recommended direction is a feature-first modular architecture with a small application shell, shared fleet identity/context, separate Drowsiness, Vital Sign, and Air Quality modules, a centralized API configuration/authentication layer, and repositories that isolate REST/WebSocket transport from UI state.

## 2. Technology and project architecture

### Language and framework

- Language: Dart, SDK constraint `^3.10.7`.
- Frontend: Flutter with Material 3 and a custom dark theme.
- Declared package version: `1.0.0+1`.
- Primary documented/runtime target: Windows desktop. Flutter runner scaffolding is also present for Android, iOS, web, Linux, macOS, and Windows.
- Application style: single Flutter executable with a persistent shell, nested `Navigator`, BLoC for root/overview state, and local `StatefulWidget` state for feature pages.

### Architectural layers currently present

| Layer | Location | Current responsibility |
|---|---|---|
| Bootstrap | `lib/main.dart` | Starts Flutter, creates `DashboardBloc`, applies theme, opens `DashboardScreen`. |
| Shell/navigation | `lib/screens/dashboard_screen.dart`, `lib/widgets/sidebar.dart`, `lib/constants/menu_items.dart` | Persistent sidebar, nested navigation, overview map fullscreen behavior. |
| Pages | `lib/screens/` | Top-level Overview shell, Vehicles, Live Tracking, Safety, Reports, and placeholders. |
| Presentation components | `lib/widgets/` | Shared and feature-specific dashboard UI. |
| State | `lib/bloc/dashboard/`; local widget state | Root/Overview state in BLoC; Vehicles, Live Tracking, Safety, and Reports mostly use `setState`. |
| Models | `lib/models/` | Vehicle, status/registry, drowsiness report/events, driver behavior, driver health, and AQI structures. |
| Services | `lib/services/` | REST calls, local exports, and GPS WebSocket connection. |
| Cross-cutting UI | `lib/theme/`, `lib/utils/`, `lib/widgets/common/` | Theme, desktop responsiveness, skeleton primitives. |

There is no explicit repository/use-case/domain layer, dependency-injection container, route package, session store, or centralized API client. Services are directly constructed by BLoC/page classes.

## 3. Folder structure

```text
fleet_dashboard/
├── lib/
│   ├── main.dart                         # Flutter entry point
│   ├── bloc/dashboard/                   # Root/Overview BLoC, events, state
│   ├── constants/                        # Sidebar menu definitions
│   ├── models/                           # API and UI data structures
│   ├── screens/                          # Top-level pages
│   ├── services/                         # HTTP, export, and WebSocket access
│   ├── theme/                            # Material theme/colors
│   ├── utils/                            # Desktop responsive wrapper
│   ├── widgets/
│   │   ├── common/                       # Skeleton primitives
│   │   ├── live_tracking/                # Tracking loading UI
│   │   ├── overview/                     # Overview panels/dashboard
│   │   ├── report/                       # Reporting UI and visualizations
│   │   ├── safety/                       # Event review UI
│   │   └── vehicles/                     # Vehicle loading UI
│   ├── gps_simulator.js                  # Node-based GPS simulator/helper
│   ├── package.json / package-lock.json  # Node helper dependency metadata
│   └── node_modules/ws/                  # Vendored/generated Node dependency
├── docs/                                 # Existing documentation, screenshots, API samples
│   └── api/                              # Swagger and example drowsiness responses
├── test/widget_test.dart                 # Default stale counter test
├── android/, ios/, linux/, macos/, web/, windows/
│                                          # Flutter platform runners
├── pubspec.yaml / pubspec.lock           # Dart/Flutter dependencies
├── analysis_options.yaml                 # Lint configuration
└── README.md                              # Setup and feature summary
```

The checked-in `lib/node_modules/` is outside normal Flutter source organization and should not become part of the application architecture. The JavaScript GPS simulator is a development utility, not a Flutter runtime service.

## 4. Entry point, shell, and routing/navigation

### Entry point

`lib/main.dart` calls `runApp(const MyApp())`. `MyApp` creates one root `BlocProvider<DashboardBloc>`, immediately dispatches `DashboardInitialized`, and returns a `MaterialApp` with:

- `home: DashboardScreen()`;
- title `Fleet Management`;
- `AppTheme.darkTheme`;
- no top-level named route table and no route parser/deep-link configuration.

### Shell

`DashboardScreen` is the persistent application shell. It owns:

- the sidebar;
- a nested `Navigator`;
- a shared `MapController` used by the Overview map/fullscreen overlay;
- local fullscreen/follow-map flags;
- coordination between sidebar selection and BLoC menu state.

### Nested routes

Routes are declared manually inside `DashboardScreen.onGenerateRoute`:

| Sidebar label | Declared route | Actual destination |
|---|---|---|
| Overview | `/` | Overview content built inside `DashboardScreen`. |
| Vehicles | `/vehicles` | `VehiclesScreen`. |
| Live Tracking | `/drivers` | `LiveTrackingScreen`; the route name is misleading. |
| Safety | `/safety` | `SafetyScreen`. |
| Reports | `/reports` | `ReportScreen`. |
| Settings | `/settings` | Inline “Coming Soon” placeholder, not `SettingScreen`. |

Unknown routes also show an inline placeholder. Selecting Overview pops the nested navigator to its first route; other selections use `pushNamed`, so repeated clicks can stack duplicate pages. Browser URLs/deep links and back-stack synchronization with the selected sidebar index are not implemented.

`lib/screens/driver_screen.dart` and `lib/screens/setting_screen.dart` exist but are not used by the active navigation.

## 5. Current pages and layout components

### Overview

Implemented primarily by `DashboardScreen`, `OverviewDashboard`, and `DashboardBloc`. It displays fleet health/online KPIs, drowsy and distraction counts, a live map, driver/safety ranking, behavior snapshot, recent event log, and loading/empty/error states. Its data combines `/vehicles/status` with drowsiness report, event, and driver-behavior calls for one resolved vehicle.

The root shell also has a fullscreen Overview map overlay with `DriverMonitoring`. That driver panel currently uses seeded `DriverHealth` data and drowsiness alerts rather than a Vital Sign backend module.

### Vehicles

`VehiclesScreen` loads registry and status data, merges them into `ManagedVehicle` records, supports search/filter/selection, add/edit/deactivate operations, local CSV export, and detail/device panels. Its trip-history area is a UI placeholder only.

### Live Tracking

`LiveTrackingScreen` loads `/vehicles/status`, provides fleet search/status filtering, map/list/detail synchronization, and refreshes approximately every 10 seconds. It uses page-local state and a timer, not the root GPS WebSocket state.

### Safety

`SafetyScreen` passes the root selected vehicle into `SafetyContent`. `SafetyContent` loads active vehicle options, queries drowsiness events, filters by date/severity/event type/search, renders an event table and detail/evidence panel, performs review updates, and supports single/batch AI suggestion requests.

### Reports

`ReportScreen` hosts `ReportContent`. The page queries drowsiness report data, event data, and driver options; renders risk, review, event-map, driver contribution, weekly trend, and hourly/heatmap visualizations; and downloads backend-generated CSV/PDF files. It is currently fixed to `VIN-0001`.

### Settings and Drivers

Settings is a navigation placeholder. `DriverScreen` is an unused Flutter `Placeholder`. There is no implemented driver registry/detail page.

### Shared layout and styling

- `Sidebar` is the persistent desktop navigation rail.
- `ResponsiveLayout` blocks widths below 1024 px and enforces a 1440 px minimum content width with horizontal/vertical scrolling.
- `AppTheme` defines the Material dark theme and base palette.
- `ReportStyles`/`ReportCard` are report-originated design primitives that are also imported by Sidebar, Vehicles, and Live Tracking, making general shell styling depend on the report feature.
- `ShimmerSkeleton`, `SkeletonBox`, `SkeletonLine`, `SkeletonCircle`, and `SkeletonListRow` are genuinely shared loading primitives.
- Page-specific skeletons exist for Overview, Vehicles, Live Tracking, Safety, and Reports.

Some older general widgets appear unused or superseded, including `header.dart` (fully commented), `statistics_cards.dart`, several standalone Overview panels, and `ReportExecutiveDashboard`. They should be confirmed through tests/manual comparison before removal in any later phase.

## 6. Drowsiness pages and components

The explicitly drowsiness-oriented user flows are:

- Overview drowsy/distraction KPIs, safety snapshot, latest events, driver-risk summaries, latest-event polling, and alert log;
- Safety event selection, filtering, evidence, review workflow, and AI suggestions;
- Reports risk summary, event map, review summary, behavior trend, working-hour concentration, contributors, and exports;
- fullscreen `DriverMonitoring` alert cards fed by drowsiness events/stream images.

Primary files are:

- `lib/bloc/dashboard/dashboard_bloc.dart`
- `lib/bloc/dashboard/dashboard_event.dart`
- `lib/bloc/dashboard/dashboard_state.dart`
- `lib/models/drowsiness_model.dart`
- `lib/models/drowsiness_report.dart`
- `lib/models/drowsiness_driver_option.dart`
- `lib/models/driver_behavior_summary.dart`
- `lib/services/drowsiness_report_service.dart`
- `lib/widgets/safety/*`
- `lib/widgets/report/*`
- drowsiness-derived sections within `lib/widgets/overview/overview_dashboard.dart`
- `lib/widgets/driver_monitoring.dart`

The separate `lib/models/drowsiness_event.dart` file is present in the tree, while the actively imported rich event type is `DrowsinessEvent` declared inside `drowsiness_report.dart`. This is a naming/ownership ambiguity to resolve later, not during this documentation phase.

## 7. State management and data flow

### Root BLoC

`DashboardBloc` plus Equatable event/state classes handles:

- initialization and Overview loading;
- sidebar selected index;
- selected map vehicle;
- vehicle-status retrieval and conversion to map `Vehicle` objects;
- drowsiness report/events/driver behavior for Overview;
- GPS WebSocket messages and marker updates;
- image-stream alerts;
- latest-drowsiness polling and alert logs;
- seeded driver health, AQI, online driver, and high-risk values.

`DashboardState` is a broad mixed-domain state object. It contains vehicle data, drowsiness data, raw `Map<String, dynamic>` alerts, `DriverHealth`, and `AQIData` together.

### Page-local state

Vehicles, Live Tracking, Safety, Reports, map interactions, and report subcomponents use `StatefulWidget`/`setState` for selections, filters, loading, error, request sequencing, timers, and mutations. These pages instantiate concrete services directly.

### Declared but unused approach

`provider` is declared in `pubspec.yaml` but no active Dart import uses it. `flutter_bloc` and local widget state are the actual state mechanisms.

### Consequences

- State lifecycles and refresh rules differ per page.
- Vehicle status is fetched independently by Overview, Vehicles, and Live Tracking.
- Testing requires concrete networking unless services are manually constructed with injected `http.Client`; widgets do not receive repositories/interfaces.
- Cross-module data such as selected vehicle is only partly shared.
- Broad BLoC rebuild criteria and raw maps reduce type safety.

## 8. API/service layer and endpoints consumed

### Configuration

`VehicleStatusService` and `VehicleManagementService` read compile-time `API_BASE_URL` and `API_AUTH_TOKEN`, defaulting to `http://localhost:3000/api/v1`. `DrowsinessReportService` reads the same names but defaults to `http://203.100.57.59:3000/api/v1`. The latest-drowsiness poll and GPS socket bypass these settings with hardcoded URLs.

### REST endpoints used by executable Dart code

| Method and endpoint | Consumer/purpose |
|---|---|
| `GET /vehicles/status` | Overview, Vehicles, Live Tracking: fleet summary, telemetry freshness, status, speed, coordinates. |
| `GET /vehicles` | Vehicles and Safety: registry/selector; optional `status`, `limit`, `page`. |
| `POST /vehicles` | Create vehicle. |
| `PUT /vehicles/:vehicleId` | Update vehicle. |
| `PATCH /vehicles/:vehicleId/deactivate` | Deactivate vehicle. |
| `GET /drowsiness/latest/:vin` | Root BLoC polling every 10 seconds; hardcoded localhost base and bearer token. |
| `GET /drowsiness/report/:vehicleId` | Overview and Reports; optional `start_date`, `end_date`, `user_id`. |
| `GET /drowsiness/report/:vehicleId/export/csv` | Report CSV download. |
| `GET /drowsiness/report/:vehicleId/export/pdf` | Report PDF download. |
| `GET /drowsiness/drivers/:vehicleId` | Report driver filter options. |
| `GET /drowsiness/events/:vehicleId` | Overview, Safety, Reports; optional dates, user and `limit`. |
| `GET /drowsiness/driver-behavior` | Overview driver behavior; supports `vehicle_id` and `limit`. |
| `PATCH /drowsiness/review/:drowsinessId` | Review status/notes/follow-up/operator. |
| `POST /drowsiness/ai-suggestion/:drowsinessId` | Generate one AI review suggestion. |
| `POST /drowsiness/ai-suggestion/batch` | Generate suggestions for a filtered batch. |

Vehicle CSV export is generated locally; report CSV/PDF exports are downloaded from the backend and written to the user's Downloads directory when available.

### Service limitations

- Three services duplicate URL construction, header creation, client ownership, JSON validation, and error handling.
- Default base URLs are inconsistent.
- There is no timeout/retry/cancellation policy or typed shared error hierarchy (except `ApiRequestException` inside the drowsiness service).
- API version/configuration, credentials, and WebSocket URL are not represented by one environment object.
- Identifier fallback tries VIN, internal ID, and plate sequentially, which masks an unclear backend identity contract and can multiply requests.

## 9. Data models and entities

### Vehicle entities

There are three related representations:

- `Vehicle`: map/UI model with ID, optional VIN-like API ID, plate, type, driver name, activity label, coordinates, status enum, heading, speed, display reason, telemetry time, and last-seen minutes.
- `VehicleRegistryItem`: persistent registry fields including internal ID, VIN, plate, type, driver ID/name, device ID, IMEI, active flag, notes, created/updated timestamps.
- `VehicleStatusItem`: live status fields including identifiers, driver, telemetry time/freshness, coordinates, speed, device/movement/safety/display status and reason.
- `ManagedVehicle`: view adapter that merges registry and status records and derives labels/assignment/device flags.

The model split is useful, but identity matching is string-based and not centralized.

### Driver entities

There is no complete canonical Driver entity or driver service.

- `DriverHealth` contains driver ID/name/image, heart rate, temperature, status, and activity, but current instances are hardcoded mock data.
- `DrowsinessDriverOption` is a report filter projection.
- `DriverContributor` and `DriverBehaviorSummary` are drowsiness analytics projections.
- Vehicle responses duplicate `driverId`/`driverName` fields.

This is insufficient for a general driver profile, assignment history, permissions, or longitudinal vital-sign record.

### Trip entities

No Trip class, trip service, trip endpoint call, or trip page is implemented. `DrowsinessEvent` can carry `tripId`, and Vehicles contains a trip-history placeholder. A proper trip aggregate will need to be introduced later after confirming the shared backend contract.

### Drowsiness event and reporting entities

The active `DrowsinessEvent` is rich and includes:

- event/vehicle/user IDs, time, status, behavior and risk level;
- image URL/base64 evidence;
- location/coordinates;
- speed and telemetry context;
- optional trip and telemetry-status IDs;
- review state, notes, operator and timestamps;
- follow-up state;
- AI suggestion, confidence, reason, corrected label, evidence quality, and review time.

`DrowsinessReport` aggregates summary, review summary, risk summary, daily/hourly event counts, weekday behavior counts, dominant behavior, contributors, recommendations, and flags. `DriverBehaviorSummary` provides per-driver behavior/risk counts and frontend-computed scoring.

`DrowsinessModel` is a smaller legacy/latest-event representation and appears separate from the richer active event model.

### Vital Sign entities

Only `DriverHealth` exists. It has heart rate and temperature but lacks timestamp, units/measurement metadata, device ID, sampling quality, oxygen saturation, blood pressure, history, thresholds, or API parsing. It should be treated as a mock UI model, not an integrated domain model.

### Air Quality entities

Only `AQIData` exists, with AQI index, PM2.5, CO2, and NO2 plus display helpers. It is seeded in initial state and has no `fromJson`, timestamps, vehicle/device identity, units, sensor health, history, or service. It is not an implemented Air Quality module.

## 10. Authentication and authorization

There is no login page, refresh-token flow, authenticated user/session model, secure credential storage, logout, role/permission model, or route guard.

Service calls optionally attach `Authorization: Bearer <API_AUTH_TOKEN>` from a compile-time Dart define. Separately, `DashboardBloc` contains a hardcoded bearer token for the latest-drowsiness poll and uses hardcoded user/driver identifiers. Safety review sends the fixed reviewer string `operator`.

This is transport-level token attachment, not application authentication/authorization. Before adding sensitive Vital Sign data, authentication, role-based access, audit identity, token lifecycle, and privacy controls should be first-class cross-cutting capabilities. The hardcoded token should be considered exposed and rotated by the backend owner.

## 11. Real-time and refresh mechanisms

- `GpsSocketService` opens `ws://203.100.57.59:3300/?vehicle_id=<id>&device=<type>`.
- `DashboardBloc` connects with hardcoded vehicle ID `1210` and device type `DASHBOARD`.
- GPS messages containing `gps_lat`/`gps_lng` update matching Overview vehicles; `STREAM_IMAGE` messages become current alerts/log entries.
- There is no reconnection/backoff, heartbeat, authentication, subscription multiplexing, connection health abstraction, schema validation, or multi-vehicle subscription management.
- Latest drowsiness is polled by the root BLoC every 10 seconds.
- Live Tracking independently polls `/vehicles/status` about every 10 seconds.
- Overview vehicle status is loaded during initialization, not continuously refreshed through the status service.

The current mechanisms can demonstrate live behavior but are not a unified real-time platform for three monitoring domains.

## 12. Maps, charts, tables, and visualizations

### Maps

- `flutter_map` with `latlong2`.
- OpenStreetMap raster tiles at `https://tile.openstreetmap.org/{z}/{x}/{y}.png`.
- Used by Overview/Live Tracking through `MapSection` and by Reports through `ReportMapCard`.
- `flutter_map_animations` is declared but no active import was found; custom marker animation is implemented in `map_section.dart`.

### Charts

- `fl_chart` is used by the weekly behavior trend and the older `StatisticsCards` widget.
- Several report graphics use custom Flutter painting/layout (`CustomPainter`, bars, heatmaps, gauge/trend painters) rather than a chart package.

### Tables and lists

- Safety uses custom table widgets.
- Vehicles and Live Tracking use custom cards/lists and detail rails.
- Overview and Reports use custom rows/cards rather than a shared data-grid abstraction.

### Images/loading

- Network/base64 evidence is displayed through Flutter image widgets.
- `shimmer` is declared, while the common skeleton implementation uses custom animation/gradient primitives. Active use of the package itself was not found.

## 13. Current dependencies

Runtime dependencies declared in `pubspec.yaml`:

| Dependency | Declared version | Observed role |
|---|---:|---|
| `flutter` | SDK | UI/runtime. |
| `cupertino_icons` | `^1.0.8` | Declared; no material architectural role found. |
| `provider` | `^6.1.2` | Declared but no active imports found. |
| `flutter_bloc` | `^8.1.6` | Root/Overview BLoC and consumers. |
| `equatable` | `^2.0.5` | BLoC event/state equality. |
| `flutter_map` | `8.3.0` | Vehicle/event maps. |
| `flutter_map_animations` | `^0.10.0` | Declared; no active imports found. |
| `latlong2` | `^0.9.0` | Coordinates. |
| `fl_chart` | `^0.66.2` | Report/legacy charts. |
| `intl` | `^0.19.0` | Date/time formatting. |
| `http` | `^1.2.2` | REST transport. |
| `web_socket_channel` | `^3.0.1` | GPS/image WebSocket transport. |
| `shimmer` | `^3.0.0` | Declared; active package import not found. |

Development dependencies are `flutter_test` and `flutter_lints ^6.0.0`. The Node helper under `lib/` separately depends on `ws` according to its npm metadata.

## 14. Coupling and reuse assessment

### Tightly coupled to Drowsiness

- Most fields and initialization behavior in `DashboardBloc`/`DashboardState` beyond vehicle status/navigation.
- Safety and all `widgets/safety/` components.
- Reports and nearly all `widgets/report/` components except generic style/card primitives.
- Overview event KPIs, safety snapshot, event log, risk ranking inputs, and report-derived fallbacks.
- Driver alert maps/raw alert log and `DriverMonitoring` behavior.
- Current export naming, filters, review states, severity/behavior normalization, and AI suggestion workflow.
- Fixed `VIN-0001`, driver ID `3034`, WebSocket vehicle `1210`, and drowsiness endpoint assumptions.

### Reusable for general Fleet Management

- Flutter bootstrap/theme concept, after separating feature registration from root initialization.
- Persistent shell/sidebar and menu metadata, after correcting routes and making modules declarative.
- Vehicle registry, vehicle status, `ManagedVehicle` merge concept, Vehicles page, and Live Tracking page.
- `MapSection` concepts, OSM integration, marker/list/detail interactions, and map empty states; the widget should become less tied to the current `Vehicle` projection.
- Loading skeleton primitives and page-level loading/error/empty patterns.
- Search fields, filter controls, status chips, cards, detail rows, date-range interaction patterns, tables, exports, and responsive grids, though many are private duplicated classes today.
- API model parsing helpers and injectable `http.Client` pattern, if moved into a shared client/repository layer.
- Review/audit workflow concepts, which could generalize to cross-domain alerts without forcing all alerts into a drowsiness schema.

## 15. Architectural limitations for Vital Sign and Air Quality

### Shared limitations

1. **No feature boundaries.** Root state already mixes vehicles, drowsiness, health, and AQI. Adding full time-series streams would make it a god BLoC.
2. **No canonical fleet context.** Vehicle, VIN, internal ID, plate, device, and driver identity are resolved ad hoc. Both new domains need reliable vehicle/driver/device linkage.
3. **No common telemetry/event envelope.** GPS, drowsiness, future vital readings, and AQI readings have different timing, quality, unit, and source semantics.
4. **Fragmented refresh behavior.** BLoC WebSocket, BLoC polling, and local page timers are not coordinated and can duplicate requests or show inconsistent freshness.
5. **No authentication/authorization.** Vital Sign data especially requires protected access, role-aware UI, and auditability.
6. **Concrete service construction in UI.** Feature tests and backend migration become costly.
7. **Desktop-only layout assumptions.** Widths below 1024 are blocked and 1440 is forced, limiting future tablet/mobile/web operations use.
8. **Weak automated safety net.** The only widget test is the default counter test and does not match this app.
9. **Hardcoded configuration and identities.** Current URLs/token/vehicle/user/reviewer values cannot scale across tenants, environments, or fleets.
10. **No persistence/cache/offline strategy.** Historical monitoring screens and reconnecting streams need defined freshness and retention behavior.

### Vital Sign-specific gaps

- No API/service, parser, real-time channel, time-series model, unit/threshold configuration, sensor/device state, or historical chart.
- Current `DriverHealth` is snapshot-only and seeded; it cannot distinguish driver identity, measurement time, stale data, or clinical/safety thresholds.
- No privacy classification, consent/access rules, or audit trail for personal health data.

### Air Quality-specific gaps

- No API/service, parser, real-time channel, measurement timestamp/history, units, sensor calibration/health, or vehicle association.
- `AQIData.getProgressValue` divides heterogeneous pollutants by the same value, which is only a display placeholder and not a sound domain normalization rule.
- No configurable standards/threshold source or distinction between cabin, cargo, and ambient measurements.

## 16. Recommended high-level modular architecture

Adopt feature-first modules around a small shared Fleet core:

```text
lib/
├── app/
│   ├── bootstrap/             # Environment/configuration and dependency setup
│   ├── navigation/            # Route definitions, guards, module menu
│   └── shell/                 # Sidebar/top bar/content shell
├── core/
│   ├── api/                   # Shared HTTP client, auth headers, errors, retry/timeout
│   ├── auth/                  # Session, roles, token lifecycle, secure storage adapter
│   ├── realtime/              # Socket lifecycle, reconnect, subscriptions, typed envelopes
│   ├── models/                # IDs, pagination, time range, measurement/unit primitives
│   ├── theme/                 # Design tokens and shared components
│   └── widgets/               # Truly cross-feature cards, tables, filters, states
├── features/
│   ├── fleet/                 # Vehicles, drivers, assignments, devices, trips
│   ├── tracking/              # GPS/live map and telemetry freshness
│   ├── drowsiness/            # Events, review, analytics, reports
│   ├── vital_signs/           # Readings, alerts, trends, thresholds
│   └── air_quality/           # Readings, alerts, trends, sensor state
└── main.dart
```

Each feature should contain its own `data/`, `domain/`, and `presentation/` folders when complexity warrants it:

- **Data:** DTOs, remote data source, repository implementation.
- **Domain:** stable entities/repository interfaces and feature rules.
- **Presentation:** page state (BLoC/Cubit or another single agreed approach), pages, widgets.

Recommended cross-feature concepts:

- `FleetContext`/selection state with canonical `vehicleId`, `vin`, `driverId`, `deviceId`, and optional `tripId`.
- Separate `Vehicle`, `Driver`, `Device`, `Trip`, and `Assignment` entities owned by the Fleet feature.
- A typed `MonitoringReading<T>` for timestamp/source/freshness/quality metadata, while keeping pollutant and vital values as domain-specific payloads rather than one universal map.
- A common `MonitoringAlert` summary for unified alert feeds, with domain-specific detail references (`drowsiness`, `vital_sign`, `air_quality`).
- A socket coordinator that authenticates once, reconnects with backoff, exposes typed streams by vehicle/domain, and permits REST polling fallback.
- One API configuration and authentication client used by every service.
- Repositories injected into feature state objects; no direct concrete service construction in widgets.
- Feature-specific routes such as `/monitoring/drowsiness`, `/monitoring/vital-signs`, and `/monitoring/air-quality`, plus general `/fleet/vehicles`, `/fleet/drivers`, `/fleet/trips`, and `/tracking` routes.

### Suggested migration sequence

1. Add characterization tests for current Overview, Vehicles, Live Tracking, Safety, and Reports behavior.
2. Centralize environment/API/auth configuration without changing user-visible behavior.
3. Extract Fleet identity, vehicle status, selection, and shared real-time infrastructure.
4. Move existing Drowsiness functionality behind a feature repository/state boundary while preserving it as the base module.
5. Integrate the existing multimedia application's backend contracts into separate Vital Sign and Air Quality modules.
6. Add a unified Overview that composes read-only summaries from all three modules rather than owning their data logic.
7. Introduce unified alerts and cross-domain reporting only after individual feature contracts are stable.

## 17. Files likely to need modification later

These are expected migration touchpoints, not instructions to change them now:

| File/area | Likely future reason |
|---|---|
| `lib/main.dart` | Dependency setup, auth/session gate, modular routes. |
| `lib/screens/dashboard_screen.dart` | Slimmer shell, route outlet, feature-neutral map/fullscreen ownership. |
| `lib/constants/menu_items.dart` | Correct Live Tracking route and add monitoring/fleet modules. |
| `lib/widgets/sidebar.dart` | Module grouping, permission-aware entries, route synchronization. |
| `lib/bloc/dashboard/*` | Split shell/overview/vehicle/drowsiness state; remove mock and hardcoded runtime data. |
| `lib/widgets/overview/overview_dashboard.dart` | Compose Drowsiness, Vital Sign, and Air Quality summaries. |
| `lib/services/*` | Shared API client/config/auth, repositories, socket lifecycle. |
| `lib/models/vehicle*.dart` | Canonical identity/value objects and cleaner API/UI mapping. |
| `lib/models/driver_health.dart`, `lib/models/aqi_data.dart` | Replace mock snapshot types with timestamped backend domain/DTO models. |
| `lib/screens/safety_screen.dart`, `lib/widgets/safety/*` | Relocate under Drowsiness feature and inject state/repository. |
| `lib/screens/report_screen.dart`, `lib/widgets/report/*` | Remove fixed VIN, define Drowsiness reporting boundary, separate shared visualization primitives. |
| `lib/screens/vehicles_screen.dart`, `lib/screens/live_tracking_screen.dart` | Consume shared fleet repositories/state and remove duplicate status fetches. |
| `lib/theme/app_theme.dart`, `lib/widgets/report/report_styles.dart` | Consolidate general design tokens outside Reports. |
| `test/` | Replace stale counter test with characterization, model, service, state, and navigation tests. |
| `pubspec.yaml` | Later remove confirmed-unused packages and add only required routing/storage/security tooling. |
| Platform config (`windows/`, `web/`, mobile runners) | Secure storage, networking permissions, deployment configuration if those targets are supported. |

New feature folders/files will also be required later; none should be generated until backend contracts and module boundaries are agreed.

## 18. Files/areas that should preferably remain untouched

“Untouched” here means avoid editing unless a concrete platform/build requirement exists:

- generated Flutter runner/plugin files, including `generated_plugin_registrant.*` and `generated_plugins.cmake`;
- `.dart_tool/` and `build/` generated output;
- `pubspec.lock` except as the natural result of an intentional dependency change;
- platform runner boilerplate under Android/iOS/Linux/macOS/Windows when the work is application architecture only;
- existing screenshots and API response samples under `docs/`, which are useful migration baselines;
- `docs/api/swagger_drowsiness.json` as a historical/backend contract artifact unless a newly supplied canonical spec replaces it;
- existing working vehicle registry/status parsing and export behavior until characterization tests protect it;
- map marker animation behavior and drowsiness review/report parsing until equivalent tests and backend samples cover all variants.

The crash logs, build output, `.dart_tool`, IDE settings, and checked-in Node dependency folder are repository-hygiene candidates, but cleanup should be a separate, explicitly approved task to avoid deleting diagnostic or user-owned artifacts.

## 19. Regression risks

### High risk

- Splitting `DashboardBloc` can break Overview loading, selected-vehicle behavior, map following, timer/socket cleanup, and event-derived KPIs.
- Normalizing vehicle identity can change which VIN/internal ID/plate succeeds against drowsiness endpoints.
- Changing navigation can break the nested back stack, sidebar selected state, or persistence of page-local filters.
- Centralizing base URLs/auth can unintentionally redirect some calls because vehicle and drowsiness services currently have different defaults.
- Replacing the fixed report VIN can expose empty/error states previously hidden by `VIN-0001`.
- Generalizing `DrowsinessEvent` into a universal event can lose review, AI, evidence, or telemetry-specific fields.

### Medium risk

- Sharing vehicle-status state may alter current 10-second Live Tracking refresh timing and loading feedback.
- Moving private page widgets into shared components can subtly alter table widths, scrolling, desktop layout, colors, or filtering behavior.
- Socket reconnection/multiplexing changes can duplicate events unless message IDs/deduplication are defined.
- Introducing driver/vehicle/trip entities can reveal backend nullability and inconsistent identifier formats.
- Auth guards can block currently anonymous development flows unless development configuration is explicit.

### Existing risks to preserve visibility of during migration

- Hardcoded bearer token, user ID, vehicle IDs, reviewer identity, HTTP/WS hosts, and unencrypted `ws://` transport.
- Multiple 10-second mechanisms with no coordinated freshness model.
- Root mock Vital Sign/AQI data may be mistaken for live backend data.
- The test suite does not describe current behavior; the default counter test should fail conceptually against this app.
- Many widgets are large/private and duplicate common UI patterns, increasing visual-regression surface.
- Network images and OSM tiles introduce external availability/privacy/CORS considerations.
- Report export writes to local filesystem and is desktop-oriented.
- No explicit API timeouts, retry policy, cancellation, offline state, or schema version handling.

## 20. Decision summary

Keep the Drowsiness application as the first fully implemented monitoring feature, but do not keep Drowsiness as the owner of the application shell or shared fleet state. Preserve working Vehicles, Live Tracking, Safety, and Reports behavior behind tests; establish canonical vehicle/driver/device/trip identity and shared infrastructure; then add Vital Sign and Air Quality as sibling modules. The unified Overview should aggregate summaries from those modules while detailed pages, models, services, streams, permissions, and histories remain independently evolvable.
