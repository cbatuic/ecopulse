#include <Wire.h>
#include <Adafruit_TCS34725.h>

// ========================================
// TCS34725 COLOR SENSOR SETUP
// ========================================

// ESP32 I2C Pins
#define I2C_SDA 21
#define I2C_SCL 22

// Create TCS34725 sensor object
Adafruit_TCS34725 tcs =
  Adafruit_TCS34725(
    TCS34725_INTEGRATIONTIME_154MS,
    TCS34725_GAIN_4X
  );

// ========================================
// ALGAE / GREEN THRESHOLD
// ========================================

const float ALGAE_GREEN_THRESHOLD = 0.40;

// ========================================
// SETUP
// ========================================

void setup() {

  Serial.begin(115200);

  delay(1000);

  Serial.println();
  Serial.println(
    "========================================"
  );

  Serial.println(
    "     TCS34725 COLOR SENSOR TEST"
  );

  Serial.println(
    "========================================"
  );

  // Start I2C communication

  Wire.begin(
    I2C_SDA,
    I2C_SCL
  );

  // Initialize TCS34725

  if (
    tcs.begin()
  ) {

    // Keep the sensor active between measurements. On breakouts with a
    // controllable LED this also enables the onboard illumination.
    tcs.setInterrupt(false);

    Serial.println(
      "TCS34725 sensor detected!"
    );

  } else {

    Serial.println(
      "ERROR: TCS34725 not detected!"
    );

    Serial.println(
      "Check your wiring."
    );

    while (1);
  }

  Serial.println();

  Serial.println(
    "Reading color values..."
  );
}

// ========================================
// LOOP
// ========================================

void loop() {

  // Variables for sensor readings

  uint16_t red;
  uint16_t green;
  uint16_t blue;
  uint16_t clear;

  // Read color sensor

  tcs.getRawData(
    &red,
    &green,
    &blue,
    &clear
  );

  // Emit a compact machine-readable line for reliable serial monitoring.
  Serial.print("COLOR,");
  Serial.print(millis());
  Serial.print(",R=");
  Serial.print(red);
  Serial.print(",G=");
  Serial.print(green);
  Serial.print(",B=");
  Serial.print(blue);
  Serial.print(",C=");
  Serial.println(clear);

  if (clear == 0) {
    Serial.println("WARNING: Clear channel is zero; check sensor power, wiring, and illumination.");
  }

  // Calculate total RGB value

  unsigned long total =
    (unsigned long)red +
    (unsigned long)green +
    (unsigned long)blue;

  // Calculate Green Index

  float greenIndex = 0.0;

  if (
    total > 0
  ) {

    greenIndex =
      (float)green /
      (float)total;
  }

  // ========================================
  // DISPLAY RESULTS
  // ========================================

  Serial.println();

  Serial.println(
    "========================================"
  );

  Serial.println(
    "         COLOR SENSOR READINGS"
  );

  Serial.println(
    "========================================"
  );

  // Red

  Serial.print(
    "Red: "
  );

  Serial.println(
    red
  );

  // Green

  Serial.print(
    "Green: "
  );

  Serial.println(
    green
  );

  // Blue

  Serial.print(
    "Blue: "
  );

  Serial.println(
    blue
  );

  // Clear

  Serial.print(
    "Clear: "
  );

  Serial.println(
    clear
  );

  Serial.println();

  // Green Index

  Serial.print(
    "Green Index: "
  );

  Serial.println(
    greenIndex,
    3
  );

  // ========================================
  // WATER / ALGAE STATUS
  // ========================================

  Serial.print(
    "Water Status: "
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

  // Wait before next reading

  delay(2000);
}