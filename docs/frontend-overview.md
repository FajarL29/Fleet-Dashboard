# Frontend Overview

## Frontend Purpose

The FleetSafe dashboard is a Flutter Windows desktop frontend for fleet operations and safety monitoring. It provides a single operator-facing workspace for:

- viewing fleet health and live telemetry
- tracking vehicle location on a map
- reviewing drowsiness and distraction events
- inspecting vehicle registry and device status
- generating drowsiness summary reports and exports

The frontend is data-driven and relies on backend APIs for operational data. Live status depends on telemetry availability and freshness.

## Main Pages

### Overview

Landing dashboard with high-level KPIs, live fleet map, high-risk ranking, safety snapshot, and recent event log.

### Vehicles

Vehicle registry and status view with list, filters, selected vehicle detail, device information, trip history placeholder, CSV export, and vehicle management actions.

### Live Tracking

Real-time fleet visibility page with status-filtered fleet list, map markers, selected vehicle panel, and timed refresh.

### Safety

Drowsiness event review workspace with vehicle selector, date range filter, severity filter, event type filter, searchable event list, detail panel, evidence preview, and review action flow.

### Reports

Drowsiness reporting page with summary metrics, executive risk views, event map, weekly behavior analysis, working-hour heatmap, driver contribution, and export actions.

## Data Source Summary

### HTTP APIs

The frontend uses REST APIs for:

- vehicle registry data
- vehicle live status summaries
- drowsiness event lists
- drowsiness report summaries
- driver filter options for reports
- event review updates
- PDF and CSV exports

### Realtime / Polling

- Live GPS updates are consumed through `GpsSocketService`
- The overview logic also polls a latest drowsiness endpoint to surface recent alert activity

### Local UI State

Each page keeps filter and selection state in the widget layer, while the dashboard shell uses `DashboardBloc` for overview and shared selection behavior.

## General Architecture

### Application Shell

- `lib/main.dart` starts the app and provides `DashboardBloc`
- `lib/screens/dashboard_screen.dart` hosts the sidebar, nested navigator, and overview page

### Presentation Layer

- `lib/screens/` contains top-level pages
- `lib/widgets/` contains reusable UI blocks and page-specific sections
- shimmer and skeleton widgets are used during loading states

### State Layer

- `DashboardBloc` manages overview data, vehicle selection, live GPS updates, and overview refresh behavior
- individual pages such as Safety, Vehicles, and Reports manage their own filters and async loading state locally

### Data Layer

- `VehicleStatusService` fetches `/vehicles/status`
- `VehicleManagementService` fetches and updates `/vehicles`
- `DrowsinessReportService` fetches drowsiness report data, drivers, events, review updates, and exports

### Models

Data models in `lib/models/` normalize API responses into typed structures used by widgets and screens.
