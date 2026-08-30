# MAD Development Guide

## Purpose
This guide explains how to work on the EcoPulse app in a consistent way. It covers setup, folder conventions, common feature patterns, and the main development questions to answer before editing code. It also incorporates the newer predictive capability for BantAI and the settings/alert structure added to the product.

## Project overview
EcoPulse is a Flutter app for monitoring pond conditions in real time. The app fetches live sensor data from an ESP32 endpoint and displays:
- dissolved oxygen
- temperature
- algae indicators
- aerator status
- recent trend history
- user profile settings and welcome message
- alert activity including SMS records
- forecasted pond-health risk using BantAI

## Feature focus: BantAI
BantAI analyzes pond temperature, dissolved oxygen, algae indicators, and historical readings to predict possible pond health problems before they become critical.

It uses temperature, dissolved oxygen, green index, and historical readings to predict if the pond may become unhealthy in the next few hours or days.

This gives users an early warning instead of waiting for a critical alert and helps identify patterns that normal thresholds may miss.

The feature includes:
- Pond health prediction
- Early warning
- Explains pond conditions
- Suggests actions
- Predicts future pond conditions

Business value:
- Less fish loss
- Lower operational costs
- Better pond management
- Faster response to problems

## Folder map
- `lib/main.dart`: app bootstrap
- `lib/controllers/dashboard_controller.dart`: central state and polling logic
- `lib/views/dashboard_view.dart`: dashboard UI
- `lib/views/settings_page.dart`: tabbed settings page
- `lib/views/bantai_page.dart`: BantAI alert and forecast interface
- `lib/models/`: domain entities and data models
- `lib/services/temperature_api.dart`: remote sensor API client
- `lib/services/reading_history_database.dart`: local storage for reading history
- `lib/services/alert_service.dart`: SMS and alert data handling
- `lib/services/bantai_service.dart`: prediction logic and health forecasting

## Local setup
From the project root:

```bash
flutter pub get
flutter run -d chrome
```

For local web serving:

```bash
flutter run -d web-server --web-host=0.0.0.0 --web-port=8080
flutter build web
cd build/web
python -m http.server 8080 --bind 0.0.0.0
```

## Standard development flow
1. Read the relevant domain model first.
2. Trace the controller state and update path.
3. Update the service adapter if a new API field is added.
4. Add the UI representation in the relevant view.
5. Update settings or alert models when configuration or alert metadata changes.
6. Run the app and confirm the behavior with real data.

## Adding a new sensor
When adding a new metric, use this pattern:
1. Extend the model in `lib/models`.
2. Add the field to the sensor payload parser in `TemperatureApi`.
3. Update `DashboardController` to store the reading and notify listeners.
4. Add a visual element to `DashboardView`.
5. Decide whether it should also be stored in the history database.
6. Include it in BantAI if it helps forecast future pond health.

## Adding an alert rule
Use this pattern:
1. Add a derived property or helper on the relevant model.
2. Add the alert generation logic in `DashboardController.alerts` or the alert service.
3. Update the alert card display in the dashboard.
4. Ensure the conditions are consistent with the service data contract.
5. If the alert originates from source SMS data, include `sms_alert` and `sms_timestamp` in the payload handling.

## Working with history
The app stores history in `ReadingHistoryDatabase`.

Current scope:
- records timestamp
- stores temperature
- stores dissolved oxygen
- stores green index
- trims older than 24 hours
- supports BantAI trend analysis for near-future forecasting

If a new chart metric or prediction input is required, include it in the schema and in the corresponding model.

## Settings architecture
The settings screen should be structured as tabs instead of a single long page.

Recommended tabs:
- Profile: welcome message, display name, profile image
- Device: sensor endpoint, polling interval, relay settings, calibration values
- Alerts: notification preferences, SMS history, alert messages
- Advanced: raw JSON inspection, diagnostics, stored configuration, debugging data

The raw JSON should live under settings so it is available for inspection and re-use without being lost in transient state.

## Common coding conventions
- Keep business logic in controllers or services, not inside the widgets.
- Prefer small model classes with explicit names.
- Avoid mixing network parsing with UI rendering.
- Keep the dashboard view focused on layout and display.
- Use `notifyListeners()` after state mutation.
- Keep prediction logic separate from rendering logic.
- Store user-facing profile data in settings and hydrate it into the app shell.

## Debugging checklist
When a sensor value is wrong or missing, verify these in order:
1. actual API response body
2. `TemperatureApi.fetchSensors()` parsing logic
3. `DashboardController._pollSensors()` mapping to `PondReading`
4. UI rendering in `DashboardView`
5. local database history if the chart seems stale
6. the BantAI input stream if the forecast is inaccurate or lagging
7. alert payload handling for `sms_alert` and `sms_timestamp`

## Testing advice
This project is small enough that a practical test strategy is:
- unit-test model logic and derived flags
- test API payload parsing for valid/invalid JSON
- verify that controller state updates correctly after a fetch
- validate that history retention logic keeps only recent readings
- test settings tab state and profile rendering
- test alert parsing for SMS payloads
- validate BantAI prediction inputs and risk thresholds

## Quick guide questions
Use these questions before or during a change:
- What is the real-world meaning of the value I am editing?
- Is the value coming from the API, the widget, the local database, or the user profile?
- Where is the source-of-truth state stored?
- Will this affect the dashboard, alerts, historical charts, settings, or BantAI?
- Do I need to update the persistence model as well as the UI?
- Does the change require new validation, new fields, or new tests?
- Does this belong to the profile settings, device configuration, alert layer, or predictive layer?
- Is this a current threshold alert or a future-risk prediction?

## Recommended workflow for new contributors
- Start by reading the model docs and the controller.
- Trace one real value from API to UI.
- Understand how settings and alert data are represented before editing the UI.
- Review the BantAI inputs before adjusting forecast logic.
- Make a single change and verify the rendered output.
- Keep the feature aligned with the existing dashboard patterns.

## Summary
The app is intentionally simple and highly readable. The safest way to extend it is to add the data at the model boundary, update the controller state, and then reflect the value in the view or prediction layer. With the new BantAI feature, EcoPulse is no longer only monitoring the pond; it is also helping users anticipate problems early and act before conditions become critical.
