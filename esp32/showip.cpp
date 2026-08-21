#include <WiFi.h>
#include <BlynkSimpleEsp32.h>
#include <Wire.h>
#include <Adafruit_TCS34725.h>
#include <OneWire.h>
#include <DallasTemperature.h>

const char* ssid = "GFiber_05D31";
const char* password = "FFZwDKWF";

void setup() {
  Serial.begin(115200);
  delay(1000);

  Serial.println();
  Serial.println("========================================");
  Serial.println("          ECOPULSE ESP32 IP");
  Serial.println("========================================");
  Serial.print("Connecting to Wi-Fi: ");
  Serial.println(ssid);

  WiFi.mode(WIFI_STA);
  WiFi.begin(ssid, password);

  const unsigned long timeout = 20000;
  const unsigned long startedAt = millis();

  while (WiFi.status() != WL_CONNECTED && millis() - startedAt < timeout) {
    delay(500);
    Serial.print('.');
  }

  Serial.println();

  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("ERROR: Wi-Fi connection failed.");
    Serial.println("Check the SSID, password, and network availability.");
    return;
  }

  Serial.println("Wi-Fi connected.");
  Serial.print("ESP32 IP address: ");
  Serial.println(WiFi.localIP());
  Serial.print("Gateway: ");
  Serial.println(WiFi.gatewayIP());
  Serial.print("Signal strength: ");
  Serial.print(WiFi.RSSI());
  Serial.println(" dBm");
  Serial.println("Use this IP address for the EcoPulse API.");
  Serial.println("========================================");
}

void loop() {
  static unsigned long lastStatus = 0;

  if (millis() - lastStatus >= 10000) {
    lastStatus = millis();

    if (WiFi.status() == WL_CONNECTED) {
      Serial.print("IP: ");
      Serial.print(WiFi.localIP());
      Serial.print(" | RSSI: ");
      Serial.print(WiFi.RSSI());
      Serial.println(" dBm");
    } else {
      Serial.println("Wi-Fi disconnected.");
    }
  }
}
