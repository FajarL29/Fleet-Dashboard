# API Integration

This page documents how the frontend currently uses backend APIs in the Flutter dashboard.

## `/vehicles/status`

- Used by page: Overview, Live Tracking, Vehicles
- Purpose: retrieve live fleet status, summary counts, telemetry freshness, and map coordinates
- Important params: none in the current frontend call
- Main response data used:
  - fleet summary totals such as total, online, offline, warning, and alert
  - vehicle identifiers
  - plate number and VIN
  - driver name
  - display status, movement status, and safety status
  - speed
  - latitude and longitude
  - last telemetry time and last seen minutes

## `/vehicles`

- Used by page: Vehicles, Safety
- Purpose: retrieve vehicle registry data and active vehicle list for selectors and management
- Important params:
  - `status`
  - `limit`
  - `page`
- Main response data used:
  - vehicle ID
  - plate number
  - vehicle identification number
  - vehicle type
  - driver assignment
  - device ID and IMEI
  - notes
  - active/inactive registry state

## `/drowsiness/events/:vehicle_id`

- Used by page: Safety, Reports, Overview
- Purpose: fetch drowsiness and related safety events for a selected vehicle
- Important params:
  - `start_date`
  - `end_date`
  - `user_id`
  - `limit`
- Main response data used:
  - `drowsiness_id`
  - vehicle identifier
  - `user_id`
  - event time
  - status and behavior type
  - risk level
  - image URL or preview image data
  - location name
  - latitude and longitude
  - speed at event
  - telemetry timestamp
  - review status, review note, reviewed by, follow-up fields

## `/drowsiness/report/:vehicle_id`

- Used by page: Reports, Overview
- Purpose: fetch aggregated drowsiness report data and risk summaries
- Important params:
  - `start_date`
  - `end_date`
  - `user_id`
- Main response data used:
  - summary totals
  - high-risk event count
  - review summary
  - risk score and risk level
  - main contributor and dominant behavior
  - events by day
  - events by hour
  - weekday behavior summary

## `/drowsiness/report/:vehicle_id/export/pdf`

- Used by page: Reports
- Purpose: export the current report filter selection to PDF
- Important params:
  - `start_date`
  - `end_date`
  - `user_id`
- Main response data used:
  - binary file body
  - optional `content-disposition` filename

## `/drowsiness/report/:vehicle_id/export/csv`

- Used by page: Reports
- Purpose: export the current report filter selection to CSV
- Important params:
  - `start_date`
  - `end_date`
  - `user_id`
- Main response data used:
  - binary file body
  - optional `content-disposition` filename

## `/drowsiness/drivers/:vehicle_id`

- Used by page: Reports
- Purpose: load available driver filter options for the selected vehicle and date range
- Important params:
  - `start_date`
  - `end_date`
- Main response data used:
  - `user_id`
  - driver name
  - driver option labels used in the report filter

## `/drowsiness/review/:drowsiness_id`

- Used by page: Safety
- Purpose: update the review result of a drowsiness event
- Important params:
  - path param `drowsiness_id`
- Request fields used:
  - `review_status`
  - `review_note`
  - `follow_up_note`
  - `reviewed_by`
- Main response data used:
  - updated event review status
  - updated notes and reviewer fields
  - updated follow-up fields

## Additional Implementation Notes

- API base URL is supplied through `API_BASE_URL` in most services
- Vehicle services default to `http://localhost:3000/api/v1`
- Drowsiness report service currently defaults to `http://203.100.57.59:3000/api/v1`
- Authorization is attached as a bearer token when `API_AUTH_TOKEN` is provided
- Live status quality depends on backend telemetry freshness and coordinate availability
