#include <WiFi.h>
#include <WebServer.h>

#include <Wire.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <Adafruit_TCS34725.h>

// ========================================
// WIFI CONFIGURATION
// ========================================

const char* ssid = "GFiber_05D31";
const char* password = "FFZwDKWF";

// ========================================
// PIN CONFIGURATION
// ========================================

// DS18B20 Temperature Sensor
#define ONE_WIRE_BUS 4

// Gravity Analog Dissolved Oxygen Sensor
#define DO_PIN 34

// 5V relay controlling the 12V aerator
#define RELAY_PIN 26

// TCS34725 I2C
#define I2C_SDA 21
#define I2C_SCL 22

// ========================================
// DS18B20 SETUP
// ========================================

OneWire oneWire(ONE_WIRE_BUS);

DallasTemperature waterTemp(&oneWire);

// ========================================
// TCS34725 COLOR SENSOR
// ========================================

Adafruit_TCS34725 tcs =
  Adafruit_TCS34725(
    TCS34725_INTEGRATIONTIME_154MS,
    TCS34725_GAIN_4X
  );

// ========================================
// WEB SERVER
// ========================================

WebServer server(80);

// ========================================
// DISSOLVED OXYGEN CALIBRATION
// ========================================

/*
  IMPORTANT:

  These are placeholder values.

  You need to calibrate the DO sensor
  for an accurate mg/L reading.
*/

float DO_SLOPE = 3.30;
float DO_OFFSET = 0.00;

const float ADC_REFERENCE = 3.3;

// ========================================
// ALGAE / GREEN THRESHOLD
// ========================================

const float ALGAE_GREEN_THRESHOLD = 0.40;

// Automatic aeration hysteresis
const float DO_AERATOR_ON = 5.0;
const float DO_AERATOR_OFF = 5.5;
const bool RELAY_ACTIVE_LOW = true;

// Temperature alert thresholds
const float TEMP_HIGH_ALERT = 32.0;
const float TEMP_LOW_ALERT = 20.0;
const float TEMP_HIGH_RESET = 31.0;
const float TEMP_LOW_RESET = 21.0;

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

// Aerator and alert state
bool aeratorOn = false;
bool highTemperatureAlert = false;
bool lowTemperatureAlert = false;

// Green Index
float greenIndex = 0.0;

// ========================================
// SENSOR INTERVAL
// ========================================

unsigned long lastSensorRead = 0;

const unsigned long SENSOR_INTERVAL = 2000;

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
// RELAY / AERATOR CONTROL
// ========================================

void setAerator(bool state) {

  aeratorOn = state;

  const int relayLevel = RELAY_ACTIVE_LOW
    ? (state ? LOW : HIGH)
    : (state ? HIGH : LOW);

  digitalWrite(RELAY_PIN, relayLevel);

  Serial.print("AERATOR: ");
  Serial.println(state ? "ON" : "OFF");
}

void automaticAeration() {

  const bool lowDO = dissolvedOxygen < DO_AERATOR_ON;
  const bool highGreen = greenIndex >= ALGAE_GREEN_THRESHOLD;

  if (lowDO || highGreen) {
    if (!aeratorOn) {
      setAerator(true);
    }
    return;
  }

  if (aeratorOn &&
      dissolvedOxygen >= DO_AERATOR_OFF &&
      greenIndex < ALGAE_GREEN_THRESHOLD) {
    setAerator(false);
  }
}

void temperatureAlerts() {

  if (temperatureC == -999.0) {
    return;
  }

  if (temperatureC >= TEMP_HIGH_ALERT && !highTemperatureAlert) {
    Serial.print("TEMPERATURE ALERT: HIGH = ");
    Serial.print(temperatureC, 2);
    Serial.println(" C");
    highTemperatureAlert = true;
  } else if (temperatureC < TEMP_HIGH_RESET) {
    highTemperatureAlert = false;
  }

  if (temperatureC <= TEMP_LOW_ALERT && !lowTemperatureAlert) {
    Serial.print("TEMPERATURE ALERT: LOW = ");
    Serial.print(temperatureC, 2);
    Serial.println(" C");
    lowTemperatureAlert = true;
  } else if (temperatureC > TEMP_LOW_RESET) {
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
    (doRawValue / 4095.0) *
    ADC_REFERENCE;

  /*
    Estimated DO calculation.

    Calibration is required for
    an accurate mg/L value.
  */

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

  Serial.println(
    "========================================"
  );

  Serial.print("Aerator: ");
  Serial.println(aeratorOn ? "ON" : "OFF");

  // TEMPERATURE

  Serial.print("Temperature: ");

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

  automaticAeration();
  temperatureAlerts();

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
  json += String(temperatureC, 2);
  json += ",";

  json += "\"temperature_unit\":\"C\",";
  
  // Dissolved Oxygen

  json += "\"dissolved_oxygen\":";
  json += String(dissolvedOxygen, 2);
  json += ",";

  json += "\"oxygen_unit\":\"mg/L\",";
  
  json += "\"oxygen_raw\":";
  json += String(doRawValue);
  json += ",";

  json += "\"oxygen_voltage\":";
  json += String(doVoltage, 3);
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
  json += String(greenIndex, 3);
  json += ",";

  // Algae Status

  json += "\"algae_status\":\"";

  if (
    greenIndex >=
    ALGAE_GREEN_THRESHOLD
  ) {

    json += "HIGH GREEN DETECTED";

  } else {

    json += "NORMAL";
  }

  json += "\"";

  json += ",\"aerator_on\":";
  json += aeratorOn ? "true" : "false";

  json += ",\"temperature_high_alert\":";
  json += highTemperatureAlert ? "true" : "false";

  json += ",\"temperature_low_alert\":";
  json += lowTemperatureAlert ? "true" : "false";

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
  json += String(temperatureC, 2);
  json += ",";

  json += "\"unit\":\"C\"";

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

  json += "\"dissolved_oxygen\":";
  json += String(dissolvedOxygen, 2);
  json += ",";

  json += "\"unit\":\"mg/L\",";
  
  json += "\"raw\":";
  json += String(doRawValue);
  json += ",";

  json += "\"voltage\":";
  json += String(doVoltage, 3);

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
  json += String(greenIndex, 3);
  json += ",";

  json += "\"algae_threshold\":";
  json += String(
    ALGAE_GREEN_THRESHOLD,
    2
  );
  json += ",";

  json += "\"algae_status\":\"";

  if (
    greenIndex >=
    ALGAE_GREEN_THRESHOLD
  ) {

    json += "HIGH GREEN DETECTED";

  } else {

    json += "NORMAL";
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

  message += "GET /sensors\n";
  message += "GET /temperature\n";
  message += "GET /oxygen\n";
  message += "GET /color\n";

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

  pinMode(RELAY_PIN, OUTPUT);
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

  colorSensorAvailable = tcs.begin();

  if (colorSensorAvailable) {

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
    ssid,
    password
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