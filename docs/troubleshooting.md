# Troubleshooting

## Backend Not Running

Symptoms:

- pages stay empty
- error banners appear
- exports fail

Checks:

- verify the backend service is running
- verify the expected API host and port are reachable from the Windows machine
- confirm required authentication is available if the backend is protected

## API Base URL Wrong

Symptoms:

- requests fail immediately
- some pages work while others do not

Checks:

- confirm `API_BASE_URL` matches the intended backend environment
- note that the vehicle services and drowsiness report service currently use different default base URLs
- rebuild or rerun with the correct `--dart-define=API_BASE_URL=...`

## Vehicle Map Empty Due to Null Latitude/Longitude

Symptoms:

- vehicle list loads but no map markers appear

Cause:

- map rendering only includes vehicles with valid coordinates

Checks:

- inspect `/vehicles/status` for missing latitude or longitude
- confirm telemetry is sending location updates

## Vehicle Online Count Is 0 Due to Stale Telemetry

Symptoms:

- all vehicles appear offline or unavailable

Cause:

- online status depends on telemetry freshness from the backend response

Checks:

- inspect `/vehicles/status` summary and `last_seen_minutes`
- confirm device telemetry is still being received by the backend

## Safety Page Shows No Events

Symptoms:

- the Safety page loads but the event table is empty

Checks:

- verify the selected date range
- verify the selected VIN has event data
- clear severity, event type, or search filters
- confirm `/drowsiness/events/:vehicle_id` returns data for the selected vehicle

## Report Map Empty Due to Missing Event Coordinates

Symptoms:

- report summary loads but the event map is blank

Cause:

- the report map requires event coordinates

Checks:

- inspect event payloads for latitude and longitude
- confirm event location enrichment is enabled in the backend

## Export File Not Found

Symptoms:

- export succeeds in the UI but the user cannot locate the file

Checks:

- look in the Windows Downloads folder first
- if Downloads is unavailable, check the current working directory fallback
- confirm the backend returned a successful binary response

## Windows Build Sharing Notes

Symptoms:

- the app fails to start on another laptop

Checks:

- share the entire release folder, not only the executable
- extract the zip fully before running
- ensure the receiving laptop can reach the backend API
- expect SmartScreen or local policy prompts for unsigned binaries
