# MAD Architecture

## Purpose
This document describes the software architecture of the EcoPulse Flutter application. It explains the high-level structure, responsibilities, and how each layer communicates, including the new predictive BantAI feature, settings domain, and alert history flow.

## Architectural style
The project currently follows a lightweight layered pattern similar to MVC:
- UI layer: widgets in `lib/views`
- Controller layer: logic and state in `lib/controllers`
- Model layer: data contracts in `lib/models`
- Service layer: API and persistence code in `lib/services`
- Settings and profile layer: configuration state and app metadata
- Prediction layer: forecast logic for pond-health risk
- App entry: `lib/main.dart`

This is intentionally simple and easy to maintain for a dashboard monitoring app with proactive pond-health analysis.

## High-level system diagram

```text
Flutter App
  ├── main.dart
  │     └── creates EcoPulseApp, DashboardController, Settings, and BantAI analysis flow
  │
  ├── Views
  │     ├── DashboardView
  │     ├── AlertsPage
  │     ├── SettingsPage with tab navigation
  │     └── BantAI page
  │
  ├── Controllers
  │     ├── DashboardController
  │     ├── SettingsController / settings state
  │     └── BantAI coordinator
  │
  ├── Models
  │     ├── PondReading
  │     ├── SensorSnapshot
  │     ├── ReadingHistoryPoint
  │     ├── PondAlert
  │     ├── Settings
  │     ├── UserProfile
  │     └── BantAIInsight
  │
  └── Services
        ├── TemperatureApi (HTTP client to ESP32 endpoint)
        ├── ReadingHistoryDatabase (local SQLite history)
        ├── AlertService (SMS and alert ingestion)
        └── BantAI service / predictor
```

## Layer responsibilities

### Presentation layer
Location: `lib/views`

Responsibilities:
- renders the dashboard layout
- shows overview metrics and sensor details
- exposes navigation between tabs such as Overview, Temperature, Alerts, Settings, Raw JSON, and BantAI
- displays status pills, charts, alert cards, prediction summaries, and guidance actions
- renders user profile data such as welcome message and profile image

Key design note:
The view remains state-driven and readable. Settings are structured in tabs so profile, device, alerts, and debugging configuration are easier to scan.

### Controller layer
Location: `lib/controllers`

Responsibilities:
- owns application state
- creates the timer for periodic refresh
- loads history from the database
- polls the ESP32 sensors endpoint
- updates the live `PondReading`
- manages settings state and profile metadata
- evaluates alert conditions and source SMS notifications
- runs the BantAI risk analysis using recent and current data
- notifies listeners when state changes

This is the main coordination layer. It acts as the adapter between:
- the HTTP API response
- the domain model
- the database history
- the settings metadata
- the prediction engine
- the widget UI

### Model layer
Location: `lib/models`

Responsibilities:
- define the actual business entities
- capture semantic meaning of sensor data, settings state, alerts, and predictions
- support data validation and derived properties
- model raw source data and user-facing UI metadata

### Service layer
Location: `lib/services`

Responsibilities:
- fetch data from external systems
- persist short-term history
- encapsulate transport-specific code away from the UI
- handle alert ingestion including `sms_alert` and `sms_timestamp`
- perform predictive analysis based on live and historical readings

Key services include:
- `TemperatureApi`: reads the ESP32 JSON API
- `ReadingHistoryDatabase`: stores recent sensor readings for charts and prediction inputs
- `AlertService`: normalizes source-originated SMS alerts
- `BantAIService`: evaluates temperature, oxygen, algae indicator, and historical trends

## Runtime flow
1. `main()` launches the app.
2. `EcoPulseApp` creates the controller layer and settings state.
3. `DashboardController` initializes a default `PondReading`.
4. `Settings` loads the stored profile metadata and raw JSON payload.
5. It starts a timer to poll sensors every few seconds.
6. `TemperatureApi.fetchSensors()` makes the HTTP request.
7. The controller converts the result into a `PondReading`.
8. The alert flow checks for source SMS messages and timestamps.
9. `BantAI` reads current readings and historical data to estimate future pond health risk.
10. `DashboardView` and the BantAI page rebuild with the latest values and early-warning insights.

## Architectural decisions

### 1. Split by responsibility
The app separates state, data, UI, services, and prediction logic. This keeps code easier to trace and less brittle when adding sensors or risk analysis.

### 2. Centralized controller state
`DashboardController` remains the authority for what the UI displays, while settings and prediction flows are handled through dedicated app state.

### 3. Simple API adapter
`TemperatureApi` isolates the HTTP protocol details. If the endpoint format changes, only the adapter layer needs adjustment.

### 4. Local persistence for trend visualization and prediction
History is stored locally in a simple database to support both charts and future-risk evaluation.

### 5. Settings as a structured configuration domain
The raw JSON payload is stored in the settings domain because it is now a valid part of configuration and analysis, not just a debugging artifact.

### 6. Predictive warning before critical failure
BantAI is designed to warn users earlier than conventional thresholds. It uses temperature, dissolved oxygen, green index, and historical readings to detect a likely unhealthy pond state before it becomes critical.

## BantAI feature definition
BantAI analyzes pond temperature, dissolved oxygen, algae indicators, and historical readings to predict possible pond health problems before they become critical.

It uses:
- temperature
- dissolved oxygen
- green index
- historical readings

It predicts whether the pond may become unhealthy in the next few hours or days. This gives users an early warning instead of waiting for a critical alert and helps identify patterns that normal thresholds may miss.

This is a very high-value feature because EcoPulse already stores temperature, oxygen, green index, and historical data. These are ideal inputs for prediction.

Expected business value:
- less fish loss
- lower operational costs
- better pond management
- faster response to problems
- pond health prediction
- early warning
- explains pond conditions
- suggests actions
- predicts future pond conditions

## Alert and settings requirements
- The settings page is tab-based to group profile, device, alerts, and advanced controls.
- The profile tab includes the welcome message and profile image.
- The alert stream can include source-backed SMS records with `sms_alert` and `sms_timestamp`.
- The settings model owns raw API payload data for debugging, review, and rehydration.

## Potential improvement areas
- Introduce explicit repositories for domain/data access
- Move polling and prediction logic into dedicated services
- Add a typed state-management approach like Riverpod or Bloc if the app grows
- Split large dashboard view into dedicated screen widgets
- Add dependency injection and mockable services for tests
- Add a forecast confidence model and recommended actions panel

## Quick guide questions
- Which layer should own a new feature: view, controller, model, service, or predictor?
- Is the behavior UI-only, state-related, network/data-related, or predictive?
- Does this code belong in a widget, controller, or forecast service?
- When should a value be stored in the database instead of kept in memory only?
- If the API format changes, which class is the adapter boundary?
- Does this new requirement cross a layer boundary and need a contract change?
- Is the feature a threshold alert, a source SMS event, or a predictive forecast?
- Does this value belong in the profile, device, alert, or BantAI domain?

## Summary
The current architecture remains intentionally compact, but it now includes a predictive intelligence layer for early pond-health warnings. A single controller coordinates state, API and persistence services handle external systems, settings own app metadata and raw payloads, and the BantAI subsystem predicts future health risk before conditions become critical. This keeps the app readable, extendable, and aligned with proactive pond management.
