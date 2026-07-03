# UI Components

## Sidebar

- Persistent navigation rail inside the dashboard shell
- Used to switch between Overview, Vehicles, Live Tracking, Safety, Reports, and placeholder routes

## KPI Cards

- Used heavily on the Overview and Vehicles pages
- Show compact metrics, labels, icons, and status cues
- Intended for fast operator scanning

## Shimmer/Skeleton Loading

- Used for Overview, Vehicles, Live Tracking, Safety, and Reports
- Keeps page structure stable while async data is loading
- Built from shared shimmer skeleton widgets and page-specific skeleton layouts

## Status Chips

- Used for vehicle state, severity, and review labels
- Communicate state through color and short text
- Common examples include online/offline, alert/warning, and review status

## Map Marker Popup

- Used in map-based views to surface vehicle selection and context
- Supports marker selection without forcing users back to the list

## Report Cards

- Reusable dashboard card style for the Reports page
- Used for risk summary, map, trends, heatmap, and event review summary sections

## Empty States

- Present when no data is available, no vehicles are registered, no map coordinates exist, or filters remove all records
- Usually include a short explanation rather than a hard failure

## Error States

- Present when a backend request fails or returns unusable data
- Typically include retry actions on page-level error banners or cards
