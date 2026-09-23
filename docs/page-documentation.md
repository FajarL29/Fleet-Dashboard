# Page Documentation

## Overview Page

Purpose: provide a quick operational summary of fleet status and safety activity.

### Fleet Health Summary

- Derived from vehicle status summary and alert/warning counts
- Shows a health label such as healthy, warning, or attention required
- Reflects current backend and telemetry state

### Online Vehicles

- Uses `/vehicles/status`
- Displays online versus total vehicles
- Should be interpreted as telemetry-driven status, not a guaranteed device heartbeat

### Drowsy Events Today

- Computed from drowsiness events loaded for the currently resolved overview vehicle
- Counts only events occurring on the current day

### Distraction Today

- Computed from the same event list as the drowsy KPI
- Counts only events classified as distraction on the current day

### High-Risk Drivers

- Built from vehicle status records and safety status ranking
- Ranks drivers or vehicle assignments with the highest alert severity first

### Live Map

- Renders vehicle markers with valid latitude and longitude
- Supports map follow behavior and fullscreen mode from the dashboard shell
- Shows an unavailable state when coordinates are missing

### Safety Snapshot

- Displays compact counts for drowsy, yawn, distraction, and one-hand-off-wheel behavior
- Uses current-day event data, with report summary data as a fallback enhancer

### Recent Log

- Shows recent safety events with time, event type, driver, vehicle, and severity
- Links users to the Safety page for full review

## Vehicles Page

Purpose: manage the vehicle registry and inspect individual vehicle/device state.

### Vehicle List

- Loads the active vehicle registry from `/vehicles`
- Supports search by plate, VIN, or device
- Supports status and vehicle type filters

### Selected Vehicle Detail

- Shows VIN, type, assigned driver, movement status, device status, last seen time, speed, and coordinates
- Selection comes from the current filtered list

### Device/Status Information

- Combines registry data with `/vehicles/status`
- Surfaces linked device indicators, merged online/offline labels, speed, and last update information

### Trip History Placeholder

- The screen includes a trip history panel area
- It currently acts as a UI placeholder rather than a backend-driven trip module

### Add/Edit/Deactivate Behavior

- Add vehicle uses `POST /vehicles`
- Edit vehicle uses `PUT /vehicles/:vehicleId`
- Deactivate vehicle uses `PATCH /vehicles/:vehicleId/deactivate`
- CSV export is generated locally from the loaded vehicle list

## Live Tracking Page

Purpose: provide a dedicated live map and status-centric fleet view.

### Fleet List

- Built from `/vehicles/status`
- Includes search and status filtering
- Shows counts for moving, idle, alert, and offline groups

### Map Markers

- Only vehicles with valid coordinates are rendered on the map
- Marker selection syncs with the fleet list and detail panel

### Selected Vehicle Panel

- Shows the currently selected vehicle's identification, driver, status, speed, location, and timing information

### Auto Refresh

- Refreshes vehicle status approximately every 10 seconds
- Displays refresh feedback without replacing the entire page layout

### Status Colors

- Green: moving or active
- Orange: idle or warning-like attention state
- Red: alert
- Blue-grey: offline or stale

## Safety Page

Purpose: review drowsiness and driver safety events for a selected vehicle and date range.

### Vehicle Selector from Registry

- Loads active vehicles from `/vehicles`
- Uses VIN-based options for event review

### Date Range Filter

- Defaults to the last 30 days
- Reloads events when the selected range changes

### Severity Filter

- Supports `All`, `High`, `Medium`, and `Low`

### Event List

- Loads from `/drowsiness/events/:vehicle_id`
- Supports severity filter, event type filter, and text search
- Defaults to the newest event when no explicit selection exists

### Event Detail

- Shows event metadata, review state, speed and telemetry context, and operator notes when available

### Evidence Image

- Supports preview from server image URL or embedded preview bytes
- Shows an unavailable state if image evidence is missing

### Review Workflow

- Review actions update `/drowsiness/review/:drowsiness_id`
- The UI supports review status updates, review note entry, and follow-up handling
- Updated review state is applied back into the current list after a successful response

## Reports Page

Purpose: present analytical drowsiness reporting and operator export actions.

### Risk Score

- Comes from the report summary model
- Uses API-provided risk summary when available, with frontend fallback logic when needed

### Risk Level

- Shows relative severity such as low, medium, high, or critical

### Total Events

- Uses report summary and event list data

### Unreviewed Events

- Uses report review summary and backlog indicators

### Drowsiness Event Map

- Plots events that include coordinates
- Empty when event location data is absent

### Driver Contribution

- Shows dominant contributors and driver share information based on report data

### Weekly Behavior Trend

- Uses weekday behavior summary data from the report response

### Working-Hour Heatmap

- Uses report event-by-hour data to show concentration across time windows

### Export PDF/CSV

- Calls backend export endpoints and writes files to the Windows Downloads folder when available

Implementation note:

- The current page implementation uses a fixed vehicle ID, `VIN-0001`, for report loading
