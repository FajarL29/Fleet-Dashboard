# Fleet Telematics Dashboard Redesign Brief

## Product Context
This is an internal Driver Safety & Telematics dashboard.
Current features:
- GPS tracking
- Drowsiness detection
- Drowsiness event reports

## Design Goal
Redesign the app so it feels like a proper internal safety monitoring control center.

Core flow:
Monitoring → Event Detected → Review → Action → Reporting

## Pages to Redesign
### 1. Overview Dashboard
Required sections:
- KPI cards: Online Vehicles, Drowsy Events Today, Events Need Review, High-Risk Drivers, Device Health
- Live Map panel
- Latest Safety Alerts
- High-Risk Drivers
- Device Status
- Recent Events table

### 2. Live Tracking
Layout:
- Left: Fleet list
- Center: Large live map
- Right: Selected vehicle detail

### 3. Safety Events
Layout:
- Filters
- Workflow strip
- Events table
- Event detail panel
- Action buttons: Confirm Event, Mark False Alarm, Add Follow-up Note

## Design Rules
- Keep dark theme
- Keep white left sidebar
- Reuse existing components where possible
- Do not change backend logic or API contracts
- Do not change database models
- Make small focused changes
- Keep UI responsive

## Dummy Data
Use realistic dummy data only if real data is unavailable:
- Ahmad Fauzi
- Dimas Putra
- Rizky Pratama
- B 7041 UDB
- B 9999 XYZ
- Sunter
- Bekasi
- Karawang