# FleetSafe Telematics Flutter Dashboard

FleetSafe Telematics Flutter Dashboard is a Flutter Windows desktop application for monitoring fleet safety, vehicle telemetry, live location, safety events, and drowsiness reporting.

Live status, online counts, map markers, and safety analytics depend on backend API responses and telemetry availability.

## Key Features

- Overview dashboard for fleet health, online vehicles, daily safety indicators, high-risk driver ranking, live map, and recent safety log
- Vehicle management page for registry browsing, status inspection, CSV export, and add/edit/deactivate flows
- Live tracking page with fleet list, status filters, map markers, selected vehicle detail, and automatic refresh
- Safety page for drowsiness event review with vehicle selector, date range, severity filter, event list, detail panel, evidence preview, and review workflow
- Reports page for risk score, risk level, review backlog, drowsiness event map, driver contribution, weekly behavior trend, working-hour heatmap, and PDF/CSV export
- Loading skeletons, empty states, and error states across major pages

## Tech Stack

- Flutter
- Dart
- `flutter_bloc` and `provider`
- `http`
- `flutter_map` and `latlong2`
- `fl_chart`
- `shimmer`

## Supported Platform

- Windows Desktop

## Folder Structure

```text
fleet_dashboard/
|-- lib/
|   |-- bloc/                # Dashboard state and events
|   |-- constants/           # Menu and UI constants
|   |-- models/              # API and UI data models
|   |-- screens/             # Top-level pages
|   |-- services/            # Backend API and socket services
|   |-- theme/               # App theme definitions
|   |-- utils/               # Layout helpers
|   |-- widgets/             # Reusable UI and page widgets
|-- docs/                    # Project documentation and reference assets
|-- windows/                 # Windows runner and build configuration
|-- test/                    # Flutter tests
|-- pubspec.yaml             # Dependencies and project metadata
```

## Setup

### Prerequisites

- Flutter SDK installed with Windows desktop support enabled
- Dart SDK included with Flutter
- A reachable backend API that serves vehicle, telemetry, and drowsiness endpoints

### Install Dependencies

```bash
flutter pub get
```

### Configure Backend Dependency

The frontend reads API settings from compile-time Dart defines used by the service layer.

- `API_BASE_URL`
- `API_AUTH_TOKEN`

Examples:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3000/api/v1
```

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://203.100.57.59:3000/api/v1 --dart-define=API_AUTH_TOKEN=YOUR_TOKEN
```

Notes:

- `VehicleStatusService` and `VehicleManagementService` default to `http://localhost:3000/api/v1`
- `DrowsinessReportService` currently defaults to `http://203.100.57.59:3000/api/v1`
- The overview flow also polls a hardcoded latest drowsiness endpoint on `http://localhost:3000/api/v1/drowsiness/latest/:vin`
- The reports page currently loads report data for the fixed vehicle ID `VIN-0001`

## How to Run

```bash
flutter run -d windows
```

Optionally include backend defines:

```bash
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:3000/api/v1 --dart-define=API_AUTH_TOKEN=YOUR_TOKEN
```

## How to Analyze

```bash
flutter analyze
```

## How to Build Release

```bash
flutter build windows --release
```

Release output:

```text
build/windows/x64/runner/Release
```

## Backend API Dependency

This frontend depends on backend services for:

- Vehicle registry
- Vehicle live status and telemetry-derived online/offline state
- Drowsiness event lists and review updates
- Drowsiness report summaries and charts
- Report export files

If the backend is unavailable, the dashboard can still render shell UI, but live data panels, counts, maps, and exports may be empty or show error states.

## Documentation

Additional documentation is available in [docs/](docs/):

- [Frontend Overview](docs/frontend-overview.md)
- [Page Documentation](docs/page-documentation.md)
- [API Integration](docs/api-integration.md)
- [State and Data Flow](docs/state-and-data-flow.md)
- [Build and Release](docs/build-and-release.md)
- [UI Components](docs/ui-components.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Feature Summary](docs/feature-summary.md)
