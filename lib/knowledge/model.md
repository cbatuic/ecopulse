# MAD Model

## Purpose
This model describes the business and data meaning of the EcoPulse pond-monitoring application. It explains the core entities, relationships, and invariants used by the Flutter dashboard, settings center, alerts stream, and the new BantAI prediction feature.

## Domain summary
EcoPulse watches a pond using sensor inputs from an ESP32-driven API. It surfaces live readings for:
- dissolved oxygen
- water temperature
- RGB/color sensor data
- aerator relay state
- derived algae and temperature alerts
- user-facing settings and profile metadata

The system stores recent readings for trend analysis, displays them in a dashboard, exposes alert activity, and predicts likely future health issues before thresholds become critical.

## Core entities

### 1. PondReading
Defined in `lib/models/pond_reading.dart`.

Responsibilities:
- Represents the latest sensor snapshot for a pond at a specific time.
- Contains the normalized reading values displayed in the UI.
- Includes derived booleans such as low oxygen, algae risk, and thermal alerts.

Key fields:
- `dissolvedOxygen`: dissolved oxygen in mg/L
- `temperature`: water temperature in °C
- `red`, `green`, `blue`, `clear`: RGB values from the color sensor
- `greenIndex`: algae-risk indicator derived from the color sensor
- `oxygenRaw`, `oxygenVoltage`: raw analog oxygen signal
- `algaeStatus`: textual status, such as NORMAL or elevated conditions
- `aeratorOn`: whether the aerator relay is active
- `temperatureHighAlert`, `temperatureLowAlert`: threshold warnings
- `recordedAt`: timestamp for the reading

Derived logic:
- `lowOxygen` when dissolved oxygen is below 5.0
- `algaeRisk` when the green index is 0.40 or above
- `highTemperature` when temperature is 32.0°C or more
- `lowTemperature` when temperature is 20.0°C or less

### 2. SensorSnapshot
Defined in `lib/models/sensor_snapshot.dart`.

Responsibilities:
- Represents the raw payload returned by the ESP32 endpoint.
- Acts as the API contract between the remote sensor server and the client.
- Carries both numeric values and alert flags.

Important fact:
This is the inbound model from the HTTP API. It is converted into `PondReading` inside the controller before use in the UI.

### 3. ReadingHistoryPoint
Defined in `lib/models/reading_history_point.dart`.

Responsibilities:
- Stores a compact historical record used for graphing trends.
- Keeps only key metrics required for chart rendering: time, temperature, dissolved oxygen, and green index.
- Feeds the BantAI model for trend-based forecasting.

### 4. PondAlert
Defined in `lib/models/pond_reading.dart`.

Responsibilities:
- Represents user-facing state changes or status notices in the alerts panel.
- Includes `title`, `detail`, `level`, and `time`.
- Can also reflect source-driven SMS alert events.

### 5. AlertLevel
Defined in `lib/models/pond_reading.dart`.

Values:
- `warning`
- `critical`
- `info`

### 6. Settings
Defined in the settings domain layer.

Responsibilities:
- Contains all app configuration and local state needed by the settings experience.
- Owns the raw JSON returned by the source API for diagnostics or rehydration.
- Exposes grouped settings in a tabbed navigation structure.
- Stores user display metadata for the app shell.

Key fields:
- `rawJson`: raw API payload captured from the sensor source
- `welcomeMessage`: user greeting displayed in the app
- `profileImageUrl`: user avatar or profile image path
- `tabs`: tab sections such as profile, device, alerts, and advanced settings
- `apiEndpoint`, `refreshInterval`, and other preferences if required by the devices page

Important rule:
The raw JSON payload is no longer treated as transient controller data only; it is stored within the `Settings` domain so it can be inspected, cached, and re-used from the settings screen.

### 7. UserProfile
Defined in the settings or app profile model.

Responsibilities:
- Represents the user identity displayed in the application shell.
- Includes the name or greeting used in the welcome message.
- Carries the profile image used in navigation and account surfaces.

Key fields:
- `displayName`
- `welcomeMessage`
- `profileImageUrl`

### 8. BantAIInsight
Defined in the BantAI prediction layer.

Responsibilities:
- Analyzes current pond conditions alongside historical readings.
- Compares temperature, dissolved oxygen, algae indicators, and trend behavior.
- Produces a forecast of likely pond health deterioration before a critical threshold is reached.

Key output fields:
- `riskLevel`: low, moderate, high, critical
- `summary`: plain-language explanation
- `predictedIssue`: likely problem such as oxygen crash, thermal stress, or algae bloom
- `confidence`: model confidence score or qualitative confidence
- `recommendedAction`: suggested operational response

## Relationships

- `DashboardController` owns the current `PondReading` and updates it after every sensor poll.
- `TemperatureApi` fetches `SensorSnapshot` data from the HTTP endpoint.
- `ReadingHistoryDatabase` persists recent readings into a local SQLite-like store.
- `Settings` owns raw source payloads and user display metadata.
- `DashboardView` reads the controller state and renders the dashboard widgets.
- `AlertsPage` renders operational notifications including `sms_alert` and `sms_timestamp` from the source API.
- `BantAI` consumes recent reading history plus the live sensor state to predict future health risks.

## Data flow
1. The app starts and initializes `DashboardController` and `Settings`.
2. The settings layer loads the stored profile metadata and raw JSON payload.
3. The controller fetches the last reading history from storage.
4. It triggers sensor polling at a defined interval.
5. `TemperatureApi.fetchSensors()` calls the ESP32 endpoint.
6. The returned JSON is validated and converted into `SensorSnapshot`.
7. The controller maps that snapshot into a `PondReading` update.
8. The UI re-renders with the latest readings and alerts.
9. The alerts pipeline checks for source-level `sms_alert` and `sms_timestamp` values and displays them in the alerts page.
10. `BantAI` reads current readings and recent history to estimate near-term health risk and propose a preventive action.

## Business rules
- A reading is considered unhealthy if dissolved oxygen is below 5.0 mg/L.
- A warning is raised when green index exceeds 0.40.
- Temperature warnings fire when the water is outside the configured operating range.
- Sensor history is trimmed to the last 24 hours.
- The settings screen is tab-based to group configuration, profile, device telemetry, and advanced parameters.
- A welcome message and profile image are displayed in the app using the values defined in the user profile settings.
- Alerts must include an SMS message and timestamp when sent via the source API: `sms_alert` and `sms_timestamp`.
- BantAI may raise a warning before a problem becomes critical if historical patterns suggest future deterioration.

## Settings architecture
The settings page should be organized as a tabbed experience rather than a long single list. Suggested sections:
- Profile: welcome message, display name, profile image
- Device: sensor endpoint, polling interval, relay settings, calibration values
- Alerts: notification preferences, SMS alert history, recent source messages
- Advanced: raw JSON inspection, diagnostics, stored configuration, debugging data

This keeps the UI easier to scan while preserving the full configuration context in one place.

## Quick guide questions
Use these questions during feature work or troubleshooting:
- What does this reading mean in physical terms, not just in code?
- Is this field a live API value, a derived metric, or a UI-only status?
- Which entity owns the source-of-truth state?
- Where should a new alert or threshold rule be added?
- Does this change belong in the API contract, the model, or the database shape?
- Do we need to persist this value for trend charts or only for display?
- Is this configuration part of the app profile, the device settings, or the raw API payload?
- Does the alert history need to display the original source SMS text and timestamp?
- Is BantAI evaluating current risk, historical trajectory, or both?

## Extension guidance
When adding a new sensor or pond metric:
1. Add the field to the domain model.
2. Ensure the API snapshot includes it.
3. Convert it into the dashboard model in the controller.
4. Decide whether it needs to be stored in history.
5. Show it in the appropriate widget or status card.
6. If it affects user configuration or alerting, also add it to the settings model and alerts flow.
7. If it informs long-range health prediction, include it in the BantAI feature inputs.

## Summary
The model is centered on `PondReading` as the current operational state, with `SensorSnapshot` as the external API contract, `ReadingHistoryPoint` as the historical trend representation, and `Settings` as the source of app configuration and raw sensor payload metadata. `Alerts` now also carry source-backed SMS evidence via `sms_alert` and `sms_timestamp`, and `BantAI` extends the system beyond monitoring into preventive pond-health prediction.
