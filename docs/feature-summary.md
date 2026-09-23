# Feature Summary

| Feature | Page | Backend Endpoint | Status | Notes |
| --- | --- | --- | --- | --- |
| Vehicle live status | Overview, Vehicles, Live Tracking | `/vehicles/status` | Implemented | Live status depends on telemetry availability and backend freshness |
| Vehicle registry | Vehicles, Safety | `/vehicles` | Implemented | Safety uses active vehicles to populate the selector |
| Live tracking | Live Tracking | `/vehicles/status` plus GPS socket updates | Implemented | Auto refresh runs on an interval and map markers require coordinates |
| Safety event review | Safety | `/drowsiness/events/:vehicle_id`, `/drowsiness/review/:drowsiness_id` | Implemented | Includes detail panel, evidence preview, and review workflow |
| Drowsiness report | Reports, Overview | `/drowsiness/report/:vehicle_id` | Implemented | Reports page is currently wired to fixed vehicle ID `VIN-0001` |
| Drowsiness event map | Reports | `/drowsiness/events/:vehicle_id` | Implemented | Requires event coordinates to render markers |
| Working-hour heatmap | Reports | `/drowsiness/report/:vehicle_id` | Implemented | Uses report time-distribution data |
| PDF/CSV export | Reports | `/drowsiness/report/:vehicle_id/export/pdf`, `/drowsiness/report/:vehicle_id/export/csv` | Implemented | Files are saved locally, typically to Downloads |
| Shimmer loading | Overview, Vehicles, Live Tracking, Safety, Reports | N/A | Implemented | Used to preserve layout during async loads |
