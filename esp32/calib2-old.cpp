#include <WiFi.h>
#include <WebServer.h>
#include <time.h>

#include <Wire.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Adafruit_TCS34725.h>

// ============================================================================
// CALIBRATION AND CONFIGURATION
// Change values in this section only when wiring, calibrating, or tuning the
// pond monitoring behavior. Keep the numbered order during calibration.
// ============================================================================

// 01. Wi-Fi connection
const char* WIFI_SSID = "GFiber_05D31";
const char* WIFI_PASSWORD = "FFZwDKWF";

// 02. SIM800A wiring and SMS recipient
const int SIM800A_RX = 16;
const int SIM800A_TX = 17;
const char* PHONE_NUMBER = "+639569563247";

// 03. Sensor and actuator pins
const int ONE_WIRE_BUS = 4;  // DS18B20 data pin
const int DO_PIN = 34;       // Gravity analog DO sensor
const int RELAY_PIN = 26;    // Aerator relay
const int I2C_SDA = 21;      // TCS34725 SDA
const int I2C_SCL = 22;      // TCS34725 SCL

// 04. TCS34725 color sensor calibration
const uint8_t COLOR_INTEGRATION_TIME = TCS34725_INTEGRATIONTIME_154MS;
const uint8_t COLOR_GAIN = TCS34725_GAIN_4X;

// 05. Dissolved oxygen calibration
// DO (mg/L) = (measured voltage * DO_SLOPE) + DO_OFFSET
float DO_SLOPE = 3.30;
float DO_OFFSET = 0.00;
const float ADC_REFERENCE = 3.30;
const float ADC_MAX_VALUE = 4095.0;

// 06. Green-index / algae threshold
const float ALGAE_GREEN_THRESHOLD = 0.35;

// 07. Automatic aeration thresholds
const float DO_AERATOR_ON = 1.00;
const float DO_AERATOR_OFF = 2.00;
const bool RELAY_ACTIVE_LOW = true;

// 08. Temperature alert and reset thresholds (degrees Celsius)
const float TEMP_HIGH_ALERT = 32.0;
const float TEMP_LOW_ALERT = 20.0;
const float TEMP_HIGH_RESET = 31.0;
const float TEMP_LOW_RESET = 21.0;

// 09. Timing calibration (milliseconds)
const unsigned long SMS_COOLDOWN = 60000UL;
const unsigned long SENSOR_INTERVAL = 2000UL;
const char* NTP_SERVER = "pool.ntp.org";
const long UTC_OFFSET_SECONDS = 0;
const int DAYLIGHT_OFFSET_SECONDS = 0;

// ============================================================================
// HARDWARE AND SERVER OBJECTS
// ============================================================================

HardwareSerial sim800a(2);
OneWire oneWire(ONE_WIRE_BUS);
DallasTemperature waterTemp(&oneWire);
Adafruit_TCS34725 tcs =
  Adafruit_TCS34725(
    TCS34725_INTEGRATIONTIME_154MS,
    TCS34725_GAIN_4X
  );
WebServer server(80);

// ========================================
// SENSOR VARIABLES
// ========================================

// Temperature
float temperatureC = 0.0;

// Dissolved Oxygen
float dissolvedOxygen = 0.0;
float doVoltage = 0.0;
int doRawValue = 0;

// RGB Color
uint16_t redValue = 0;
uint16_t greenValue = 0;
uint16_t blueValue = 0;
uint16_t clearValue = 0;

bool colorSensorAvailable = false;

// Aerator
bool aeratorOn = false;

// Temperature alert state
bool highTemperatureAlert = false;
bool lowTemperatureAlert = false;

// Green Index
float greenIndex = 0.0;

// ========================================
// SMS ALERT STATES
// ========================================

bool lowDOAlert = false;
bool highAlgaeAlert = false;
String lastSMSAlert = "";
String lastSMSTimestamp = "";

bool highTempSMSAlert = false;
bool lowTempSMSAlert = false;

// Runtime state: prevent SMS flooding
unsigned long lastSMSSent = 0;

unsigned long lastSensorRead = 0;

String getCurrentTimestamp() {

  struct tm timeInfo;

  if (getLocalTime(&timeInfo, 1000)) {

    char timestamp[25];
    strftime(timestamp, sizeof(timestamp), "%Y-%m-%dT%H:%M:%SZ", &timeInfo);
    return String(timestamp);
  }

  return String("uptime_ms:") + String(millis());
}

String escapeJson(const String& value) {

  String escaped = value;
  escaped.replace("\\", "\\\\");
  escaped.replace("\"", "\\\"");
  escaped.replace("\n", "\\n");
  escaped.replace("\r", "\\r");
  return escaped;
}

// ========================================
// CORS HEADERS
// ========================================

void addCorsHeaders() {

  server.sendHeader(
    "Access-Control-Allow-Origin",
    "*"
  );

  server.sendHeader(
    "Access-Control-Allow-Methods",
    "GET, OPTIONS"
  );

  server.sendHeader(
    "Access-Control-Allow-Headers",
    "Content-Type"
  );
}

// ========================================
// HANDLE CORS OPTIONS
// ========================================

void handleOptions() {

  addCorsHeaders();

  server.send(
    204,
    "text/plain",
    ""
  );
}

// ========================================
// SIM800A BASIC COMMAND
// ========================================

void sendSIM800Command(
  const char* command,
  unsigned long waitTime
) {

  sim800a.println(command);

  delay(waitTime);

  while (sim800a.available()) {

    Serial.write(
      sim800a.read()
    );
  }
}

// ========================================
// CHECK SIM800A
// ========================================

void checkSIM800A() {

  Serial.println();
  Serial.println("Checking SIM800A...");

  sim800a.println("AT");

  delay(1000);

  while (sim800a.available()) {

    Serial.write(
      sim800a.read()
    );
  }

  Serial.println();
}

// ========================================
// SEND SMS
// ========================================

bool sendSMS(String message) {

  unsigned long currentMillis = millis();

  // SMS cooldown
  if (
    lastSMSSent != 0 &&
    currentMillis - lastSMSSent < SMS_COOLDOWN
  ) {

    Serial.println(
      "SMS cooldown active."
    );

    return false;
  }

  Serial.println();
  Serial.println("==============================");
  Serial.println("SENDING SMS");
  Serial.println("==============================");

  Serial.print("Message: ");
  Serial.println(message);

  // Check modem
  sim800a.println("AT");

  delay(500);

  // Text mode
  sim800a.println("AT+CMGF=1");

  delay(500);

  // Set recipient
  sim800a.print("AT+CMGS=\"");
  sim800a.print(PHONE_NUMBER);
  sim800a.println("\"");

  delay(1500);

  // Send message
  sim800a.print(message);

  delay(500);

  // CTRL+Z
  sim800a.write(26);

  delay(5000);

  Serial.println("SMS command completed.");

  lastSMSSent = millis();
  lastSMSAlert = message;
  lastSMSTimestamp = getCurrentTimestamp();

  Serial.println("==============================");

  return true;
}

// ========================================
// POND SMS ALERTS
// ========================================

void checkPondSMSAlerts() {

  bool lowDO =
    dissolvedOxygen < DO_AERATOR_ON;

  bool highAlgae =
    greenIndex >= ALGAE_GREEN_THRESHOLD;

  // ======================================
  // BOTH LOW DO + HIGH ALGAE
  // ======================================

  if (
    lowDO &&
    highAlgae &&
    (!lowDOAlert || !highAlgaeAlert)
  ) {

    String message =
      "FISH POND CRITICAL ALERT! "
      "LOW OXYGEN: " +
      String(dissolvedOxygen, 2) +
      " mg/L. "
      "HIGH ALGAE: " +
      String(greenIndex, 3) +
      ". Aerator ON.";

    if (sendSMS(message)) {

      lowDOAlert = true;
      highAlgaeAlert = true;
    }

    return;
  }

  // ======================================
  // LOW DISSOLVED OXYGEN
  // ======================================

  if (lowDO) {

    if (!lowDOAlert) {

      String message =
        "FISH POND ALERT: "
        "DISSOLVED OXYGEN LOW. "
        "DO = " +
        String(dissolvedOxygen, 2) +
        " mg/L. "
        "Aerator activated.";

      if (sendSMS(message)) {

        lowDOAlert = true;
      }
    }

  } else {

    // Reset after DO reaches OFF threshold
    if (
      dissolvedOxygen >= DO_AERATOR_OFF
    ) {

      if (lowDOAlert) {

        String message =
          "FISH POND RECOVERY: "
          "Dissolved oxygen is now "
          + String(dissolvedOxygen, 2)
          + " mg/L.";

        if (sendSMS(message)) {

          lowDOAlert = false;
        }

      } else {

        lowDOAlert = false;
      }
    }
  }

  // ======================================
  // HIGH ALGAE
  // ======================================

  if (highAlgae) {

    if (!highAlgaeAlert) {

      String message =
        "FISH POND ALERT: "
        "ALGAE LEVEL HIGH. "
        "Green Index = " +
        String(greenIndex, 3) +
        ". Aerator activated.";

      if (sendSMS(message)) {

        highAlgaeAlert = true;
      }
    }

  } else {

    if (highAlgaeAlert) {

      String message =
        "FISH POND RECOVERY: "
        "Algae/green level returned "
        "to normal. Green Index = " +
        String(greenIndex, 3) +
        ".";

      if (sendSMS(message)) {

        highAlgaeAlert = false;
      }

    } else {

      highAlgaeAlert = false;
    }
  }
}

// ========================================
// TEMPERATURE SMS ALERTS
// ========================================

void checkTemperatureSMSAlerts() {

  if (temperatureC == -999.0) {
    return;
  }

  // ======================================
  // HIGH TEMPERATURE
  // ======================================

  if (temperatureC >= TEMP_HIGH_ALERT) {

    if (!highTempSMSAlert) {

      String message =
        "FISH POND ALERT: "
        "HIGH WATER TEMPERATURE. "
        "Temperature = " +
        String(temperatureC, 2) +
        " C.";

      if (sendSMS(message)) {

        highTempSMSAlert = true;
      }
    }

  } else if (
    temperatureC < TEMP_HIGH_RESET
  ) {

    highTempSMSAlert = false;
  }

  // ======================================
  // LOW TEMPERATURE
  // ======================================

  if (temperatureC <= TEMP_LOW_ALERT) {

    if (!lowTempSMSAlert) {

      String message =
        "FISH POND ALERT: "
        "LOW WATER TEMPERATURE. "
        "Temperature = " +
        String(temperatureC, 2) +
        " C.";

      if (sendSMS(message)) {

        lowTempSMSAlert = true;
      }
    }

  } else if (
    temperatureC > TEMP_LOW_RESET
  ) {

    lowTempSMSAlert = false;
  }
}

// ========================================
// RELAY / AERATOR CONTROL
// ========================================

void setAerator(bool state) {

  aeratorOn = state;

  const int relayLevel =
    RELAY_ACTIVE_LOW
      ? (state ? LOW : HIGH)
      : (state ? HIGH : LOW);

  digitalWrite(
    RELAY_PIN,
    relayLevel
  );

  Serial.print("AERATOR: ");

  Serial.println(
    state ? "ON" : "OFF"
  );
}

// ========================================
// AUTOMATIC AERATION
// ========================================

void automaticAeration() {

  const bool lowDO =
    dissolvedOxygen < DO_AERATOR_ON;

  const bool highGreen =
    greenIndex >= ALGAE_GREEN_THRESHOLD;

  // Turn ON
  if (
    lowDO ||
    highGreen
  ) {

    if (!aeratorOn) {

      setAerator(true);

      Serial.println(
        "Aerator activated automatically."
      );
    }

    return;
  }

  // Turn OFF
  if (
    aeratorOn &&
    dissolvedOxygen >= DO_AERATOR_OFF &&
    greenIndex < ALGAE_GREEN_THRESHOLD
  ) {

    setAerator(false);

    Serial.println(
      "Aerator turned OFF automatically."
    );
  }
}

// ========================================
// TEMPERATURE ALERTS
// ========================================

void temperatureAlerts() {

  if (temperatureC == -999.0) {
    return;
  }

  // High temperature
  if (
    temperatureC >= TEMP_HIGH_ALERT &&
    !highTemperatureAlert
  ) {

    Serial.print(
      "TEMPERATURE ALERT: HIGH = "
    );

    Serial.print(
      temperatureC,
      2
    );

    Serial.println(" C");

    highTemperatureAlert = true;

  } else if (
    temperatureC < TEMP_HIGH_RESET
  ) {

    highTemperatureAlert = false;
  }

  // Low temperature
  if (
    temperatureC <= TEMP_LOW_ALERT &&
    !lowTemperatureAlert
  ) {

    Serial.print(
      "TEMPERATURE ALERT: LOW = "
    );

    Serial.print(
      temperatureC,
      2
    );

    Serial.println(" C");

    lowTemperatureAlert = true;

  } else if (
    temperatureC > TEMP_LOW_RESET
  ) {

    lowTemperatureAlert = false;
  }
}

// ========================================
// READ TEMPERATURE
// ========================================

void readTemperature() {

  waterTemp.requestTemperatures();

  float temp =
    waterTemp.getTempCByIndex(0);

  if (
    temp != DEVICE_DISCONNECTED_C
  ) {

    temperatureC = temp;

  } else {

    temperatureC = -999.0;

    Serial.println(
      "ERROR: DS18B20 disconnected!"
    );
  }
}

// ========================================
// READ DISSOLVED OXYGEN
// ========================================

void readDissolvedOxygen() {

  doRawValue =
    analogRead(DO_PIN);

  doVoltage =
    (doRawValue / ADC_MAX_VALUE) *
    ADC_REFERENCE;

  // Estimated DO calculation
  // Calibration required for accurate reading

  dissolvedOxygen =
    (doVoltage * DO_SLOPE) +
    DO_OFFSET;

  if (
    dissolvedOxygen < 0
  ) {

    dissolvedOxygen = 0;
  }
}

// ========================================
// READ TCS34725 COLOR SENSOR
// ========================================

void readColorSensor() {

  if (!colorSensorAvailable) {
    return;
  }

  uint16_t r;
  uint16_t g;
  uint16_t b;
  uint16_t c;

  tcs.getRawData(
    &r,
    &g,
    &b,
    &c
  );

  redValue = r;
  greenValue = g;
  blueValue = b;
  clearValue = c;

  // Calculate Green Index

  unsigned long total =
    (unsigned long)redValue +
    (unsigned long)greenValue +
    (unsigned long)blueValue;

  if (
    total > 0
  ) {

    greenIndex =
      (float)greenValue /
      (float)total;

  } else {

    greenIndex = 0.0;
  }
}

// ========================================
// PRINT SENSOR VALUES
// ========================================

void printSensorValues() {

  Serial.println();

  Serial.println(
    "========================================"
  );

  Serial.println(
    "       ESP32 FISH POND SENSOR DATA"
  );

  Serial.print("IP Address: ");
  Serial.println(WiFi.localIP());

  Serial.println(
    "========================================"
  );

  // AERATOR

  Serial.print("Aerator: ");

  Serial.println(
    aeratorOn ? "ON" : "OFF"
  );

  // TEMPERATURE

  Serial.print(
    "Temperature: "
  );

  if (
    temperatureC == -999.0
  ) {

    Serial.println(
      "Sensor Disconnected"
    );

  } else {

    Serial.print(
      temperatureC,
      2
    );

    Serial.println(" C");
  }

  Serial.println();

  // DISSOLVED OXYGEN

  Serial.print(
    "Dissolved Oxygen: "
  );

  Serial.print(
    dissolvedOxygen,
    2
  );

  Serial.println(
    " mg/L"
  );

  Serial.print(
    "Oxygen Raw Value: "
  );

  Serial.println(
    doRawValue
  );

  Serial.print(
    "Oxygen Voltage: "
  );

  Serial.print(
    doVoltage,
    3
  );

  Serial.println(
    " V"
  );

  Serial.println();

  // COLOR SENSOR

  Serial.println(
    "--- TCS34725 COLOR SENSOR ---"
  );

  Serial.print("Red: ");
  Serial.println(redValue);

  Serial.print("Green: ");
  Serial.println(greenValue);

  Serial.print("Blue: ");
  Serial.println(blueValue);

  Serial.print("Clear: ");
  Serial.println(clearValue);

  Serial.println();

  // GREEN INDEX

  Serial.print(
    "Green Index: "
  );

  Serial.println(
    greenIndex,
    3
  );

  // ALGAE STATUS

  Serial.print(
    "Water/Algae Status: "
  );

  if (
    greenIndex >=
    ALGAE_GREEN_THRESHOLD
  ) {

    Serial.println(
      "HIGH GREEN DETECTED"
    );

  } else {

    Serial.println(
      "NORMAL"
    );
  }

  // SMS STATES

  Serial.print(
    "Low DO SMS Alert: "
  );

  Serial.println(
    lowDOAlert ? "SENT/ACTIVE" : "NORMAL"
  );

  Serial.print(
    "High Algae SMS Alert: "
  );

  Serial.println(
    highAlgaeAlert ? "SENT/ACTIVE" : "NORMAL"
  );

  Serial.println(
    "========================================"
  );
}

// ========================================
// READ ALL SENSORS
// ========================================

void readAllSensors() {

  readTemperature();

  readDissolvedOxygen();

  readColorSensor();

  // Automatic aeration
  automaticAeration();

  // Local temperature alerts
  temperatureAlerts();

  // SMS alerts
  checkPondSMSAlerts();

  checkTemperatureSMSAlerts();

  // Serial output
  printSensorValues();
}

// ========================================
// API: ALL SENSORS
// ========================================

void handleSensors() {

  addCorsHeaders();

  String json = "{";

  // Temperature

  json += "\"temperature\":";
  json += String(
    temperatureC,
    2
  );

  json += ",";

  json +=
    "\"temperature_unit\":\"C\",";

  // Dissolved Oxygen

  json +=
    "\"dissolved_oxygen\":";

  json += String(
    dissolvedOxygen,
    2
  );

  json += ",";

  json +=
    "\"oxygen_unit\":\"mg/L\",";

  json += "\"oxygen_raw\":";

  json += String(
    doRawValue
  );

  json += ",";

  json +=
    "\"oxygen_voltage\":";

  json += String(
    doVoltage,
    3
  );

  json += ",";

  // Color

  json += "\"red\":";
  json += String(redValue);
  json += ",";

  json += "\"green\":";
  json += String(greenValue);
  json += ",";

  json += "\"blue\":";
  json += String(blueValue);
  json += ",";

  json += "\"clear\":";
  json += String(clearValue);
  json += ",";

  // Green Index

  json += "\"green_index\":";

  json += String(
    greenIndex,
    3
  );

  json += ",";

  // Algae Status

  json += "\"algae_status\":\"";

  if (
    greenIndex >=
    ALGAE_GREEN_THRESHOLD
  ) {

    json +=
      "HIGH GREEN DETECTED";

  } else {

    json +=
      "NORMAL";
  }

  json += "\"";

  // Aerator

  json += ",\"aerator_on\":";

  json +=
    aeratorOn
      ? "true"
      : "false";

  // Temperature alerts

  json +=
    ",\"temperature_high_alert\":";

  json +=
    highTemperatureAlert
      ? "true"
      : "false";

  json +=
    ",\"temperature_low_alert\":";

  json +=
    lowTemperatureAlert
      ? "true"
      : "false";

  // SMS status

  json +=
    ",\"low_do_sms_alert\":";

  json +=
    lowDOAlert
      ? "true"
      : "false";

  json +=
    ",\"high_algae_sms_alert\":";

  json +=
    highAlgaeAlert
      ? "true"
      : "false";

  // Latest SMS payload

  json += ",\"sms_alert\":\"";
  json += escapeJson(lastSMSAlert);
  json += "\"";

  json += ",\"sms_timestamp\":\"";
  json += lastSMSTimestamp;
  json += "\"";

  json += "}";

  server.send(
    200,
    "application/json",
    json
  );
}

// ========================================
// API: TEMPERATURE ONLY
// ========================================

void handleTemperature() {

  addCorsHeaders();

  String json = "{";

  json += "\"temperature\":";

  json += String(
    temperatureC,
    2
  );

  json += ",";

  json +=
    "\"unit\":\"C\"";

  json += "}";

  server.send(
    200,
    "application/json",
    json
  );
}

// ========================================
// API: OXYGEN ONLY
// ========================================

void handleOxygen() {

  addCorsHeaders();

  String json = "{";

  json +=
    "\"dissolved_oxygen\":";

  json += String(
    dissolvedOxygen,
    2
  );

  json += ",";

  json +=
    "\"unit\":\"mg/L\",";

  json += "\"raw\":";

  json += String(
    doRawValue
  );

  json += ",";

  json +=
    "\"voltage\":";

  json += String(
    doVoltage,
    3
  );

  json += "}";

  server.send(
    200,
    "application/json",
    json
  );
}

// ========================================
// API: COLOR SENSOR ONLY
// ========================================

void handleColor() {

  addCorsHeaders();

  String json = "{";

  json += "\"red\":";
  json += String(redValue);
  json += ",";

  json += "\"green\":";
  json += String(greenValue);
  json += ",";

  json += "\"blue\":";
  json += String(blueValue);
  json += ",";

  json += "\"clear\":";
  json += String(clearValue);
  json += ",";

  json += "\"green_index\":";

  json += String(
    greenIndex,
    3
  );

  json += ",";

  json +=
    "\"algae_threshold\":";

  json += String(
    ALGAE_GREEN_THRESHOLD,
    2
  );

  json += ",";

  json +=
    "\"algae_status\":\"";

  if (
    greenIndex >=
    ALGAE_GREEN_THRESHOLD
  ) {

    json +=
      "HIGH GREEN DETECTED";

  } else {

    json +=
      "NORMAL";
  }

  json += "\"";

  json += "}";

  server.send(
    200,
    "application/json",
    json
  );
}

// ========================================
// HOME PAGE
// ========================================

void handleRoot() {

  addCorsHeaders();

  String message =
    "ESP32 Fish Pond Sensor API\n\n";

  message +=
    "GET /sensors\n";

  message +=
    "GET /temperature\n";

  message +=
    "GET /oxygen\n";

  message +=
    "GET /color\n";

  server.send(
    200,
    "text/plain",
    message
  );
}

// ========================================
// SETUP
// ========================================

void setup() {

  Serial.begin(115200);

  delay(1000);

  Serial.println();

  Serial.println(
    "Starting ESP32 Fish Pond Monitoring..."
  );

  // ----------------------------------------
  // SIM800A
  // ----------------------------------------

  sim800a.begin(
    9600,
    SERIAL_8N1,
    SIM800A_RX,
    SIM800A_TX
  );

  delay(2000);

  Serial.println(
    "Initializing SIM800A..."
  );

  sim800a.println("AT");

  delay(1000);

  while (sim800a.available()) {

    Serial.write(
      sim800a.read()
    );
  }

  sim800a.println("ATE0");

  delay(500);

  sim800a.println("AT+CMGF=1");

  delay(500);

  Serial.println(
    "SIM800A initialized."
  );

  // ----------------------------------------
  // RELAY
  // ----------------------------------------

  pinMode(
    RELAY_PIN,
    OUTPUT
  );

  // Make sure aerator starts OFF

  setAerator(false);

  // ----------------------------------------
  // I2C FOR TCS34725
  // ----------------------------------------

  Wire.begin(
    I2C_SDA,
    I2C_SCL
  );

  // ----------------------------------------
  // DS18B20
  // ----------------------------------------

  waterTemp.begin();

  Serial.println(
    "DS18B20 Temperature Sensor Initialized"
  );

  // ----------------------------------------
  // GRAVITY DO SENSOR
  // ----------------------------------------

  analogReadResolution(12);

  analogSetPinAttenuation(
    DO_PIN,
    ADC_11db
  );

  Serial.println(
    "Gravity Dissolved Oxygen Sensor Initialized"
  );

  // ----------------------------------------
  // TCS34725 COLOR SENSOR
  // ----------------------------------------

  colorSensorAvailable =
    tcs.begin();

  if (
    colorSensorAvailable
  ) {

    Serial.println(
      "TCS34725 Color Sensor Initialized"
    );

  } else {

    Serial.println(
      "ERROR: TCS34725 not detected!"
    );
  }

  // ----------------------------------------
  // WIFI
  // ----------------------------------------

  Serial.println();

  Serial.println(
    "Connecting to WiFi..."
  );

  WiFi.begin(
    WIFI_SSID,
    WIFI_PASSWORD
  );

  while (
    WiFi.status() !=
    WL_CONNECTED
  ) {

    delay(500);

    Serial.print(".");
  }

  Serial.println();

  Serial.println(
    "WiFi Connected!"
  );

  configTime(
    UTC_OFFSET_SECONDS,
    DAYLIGHT_OFFSET_SECONDS,
    NTP_SERVER
  );

  Serial.print(
    "ESP32 IP Address: "
  );

  Serial.println(
    WiFi.localIP()
  );

  // ----------------------------------------
  // API ROUTES
  // ----------------------------------------

  server.on(
    "/",
    HTTP_GET,
    handleRoot
  );

  server.on(
    "/sensors",
    HTTP_GET,
    handleSensors
  );

  server.on(
    "/temperature",
    HTTP_GET,
    handleTemperature
  );

  server.on(
    "/oxygen",
    HTTP_GET,
    handleOxygen
  );

  server.on(
    "/color",
    HTTP_GET,
    handleColor
  );

  // ----------------------------------------
  // CORS OPTIONS
  // ----------------------------------------

  server.on(
    "/sensors",
    HTTP_OPTIONS,
    handleOptions
  );

  server.on(
    "/temperature",
    HTTP_OPTIONS,
    handleOptions
  );

  server.on(
    "/oxygen",
    HTTP_OPTIONS,
    handleOptions
  );

  server.on(
    "/color",
    HTTP_OPTIONS,
    handleOptions
  );

  // ----------------------------------------
  // START WEB SERVER
  // ----------------------------------------

  server.begin();

  Serial.println(
    "Web Server Started!"
  );

  Serial.println(
    "Reading sensors every 2 seconds..."
  );
}

// ========================================
// MAIN LOOP
// ========================================

void loop() {

  // Handle API requests

  server.handleClient();

  // Read sensors every 2 seconds

  unsigned long currentMillis =
    millis();

  if (
    currentMillis -
    lastSensorRead >=
    SENSOR_INTERVAL
  ) {

    lastSensorRead =
      currentMillis;

    readAllSensors();
  }
}
