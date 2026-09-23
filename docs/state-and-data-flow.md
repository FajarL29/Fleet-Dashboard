# State and Data Flow

This document summarizes how data moves from backend services into the main frontend pages.

## Overview

### Flow

1. `DashboardBloc` initializes the dashboard shell
2. The bloc fetches `/vehicles/status`
3. Vehicle status items with coordinates are mapped into map-ready vehicle models
4. The bloc resolves a target vehicle identifier set from vehicle ID, VIN, and plate number
5. The bloc fetches:
   - `/drowsiness/report/:vehicle_id`
   - `/drowsiness/events/:vehicle_id`
   - driver behavior data used by overview ranking logic
6. The page renders:
   - KPI cards
   - live map
   - high-risk ranking
   - safety snapshot
   - recent log

### Key Notes

- If no events are found for today, the bloc retries with a wider 30-day range
- If vehicle status is unavailable, overview panels fall back to partial data where possible

## Vehicles

### Flow

1. The Vehicles page fetches `/vehicles` for registry data
2. The page fetches `/vehicles/status` for live status data
3. The screen merges registry and status records using identifiers such as vehicle ID and VIN
4. The merged list is filtered by search, status, and vehicle type
5. The selected vehicle detail panel renders registry and status attributes together

### Key Notes

- CSV export is built locally from the currently loaded and filtered vehicle data
- Trip history is currently presented as a placeholder panel

## Safety

### Flow

1. The page fetches `/vehicles` with active status to populate the vehicle selector
2. The selected vehicle VIN becomes the current event query target
3. The page fetches `/drowsiness/events/:vehicle_id`
4. The page applies:
   - date range filter
   - severity filter
   - event type filter
   - search filter
5. The events table and detail panel render the filtered result
6. On review action, the page sends `PATCH /drowsiness/review/:drowsiness_id`
7. The updated event replaces the previous item in local page state

### Key Notes

- Safety review is VIN-driven in the current page implementation
- Empty results can mean no backend data, an out-of-range date filter, or filters that exclude all items

## Reports

### Flow

1. The Reports page initializes a default 30-day range
2. The page fetches `/drowsiness/drivers/:vehicle_id` for driver options
3. The page fetches:
   - `/drowsiness/report/:vehicle_id`
   - `/drowsiness/events/:vehicle_id`
4. The report widgets render:
   - risk score and level
   - total and unreviewed event indicators
   - map
   - driver contribution
   - weekly behavior trend
   - working-hour heatmap
5. Export actions call:
   - `/drowsiness/report/:vehicle_id/export/pdf`
   - `/drowsiness/report/:vehicle_id/export/csv`

### Key Notes

- The current report page is wired to the fixed vehicle ID `VIN-0001`
- Driver selection is refreshed when the date range changes
- Export files are saved to the Downloads folder when available
