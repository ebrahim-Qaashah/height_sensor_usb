/*
 * Height Sensor USB Firmware
 * 
 * ESP32-C3 firmware for VL53L0X height sensor with USB CDC support
 * 
 * Features:
 * - USB CDC communication
 * - JSON protocol
 * - Continuous measurements
 * - Command interface (INFO, READ, RESET)
 * 
 * Hardware Connections:
 * VL53L0X -> ESP32-C3
 * VCC     -> 3.3V
 * GND     -> GND
 * SDA     -> GPIO 2
 * SCL     -> GPIO 3
 * 
 * Required build flags:
 * -DARDUINO_USB_MODE=1
 * -DARDUINO_USB_CDC_ON_BOOT=1
 */

#include <Arduino.h>
#include <Wire.h>
#include <VL53L0X.h>

#define SDA_PIN 2
#define SCL_PIN 3
#define DEVICE_NAME "Smat Minds Height Meter"
#define VERSION "1.0"
#define SENSOR_TYPE "VL53L0X"
#define MEASUREMENT_INTERVAL_MS 100

VL53L0X sensor;
unsigned long lastMeasurement = 0;
bool continuousMode = true;
int measurementInterval = MEASUREMENT_INTERVAL_MS;

void setup() {
  // Initialize USB CDC
  Serial.begin(115200);
  delay(1000);
  
  // Initialize I2C
  Wire.begin(SDA_PIN, SCL_PIN);
  
  // Initialize sensor
  sensor.setTimeout(500);
  if (!sensor.init()) {
    Serial.println("{\"error\":\"sensor_init_failed\"}");
    while(1) delay(1000);
  }
  
  // Configure sensor for high accuracy
  sensor.setMeasurementTimingBudget(200000);
  
  // Send ready status
  Serial.printf("{\"status\":\"ready\",\"device\":\"%s\",\"version\":\"%s\",\"sensor\":\"%s\"}\n", 
                DEVICE_NAME, VERSION, SENSOR_TYPE);
}

void loop() {
  handleSerialCommands();
  
  // Continuous measurements
  if (continuousMode && (millis() - lastMeasurement > measurementInterval)) {
    sendMeasurement();
    lastMeasurement = millis();
  }
}

void handleSerialCommands() {
  static String command = "";
  
  while (Serial.available()) {
    char c = Serial.read();
    if (c == '\n' || c == '\r') {
      if (command.length() > 0) {
        processCommand(command);
        command = "";
      }
    } else {
      command += c;
    }
  }
}

void processCommand(String cmd) {
  cmd.trim();
  
  if (cmd == "INFO") {
    Serial.printf("{\"info\":{\"name\":\"%s\",\"version\":\"%s\",\"sensor\":\"%s\"}}\n", 
                  DEVICE_NAME, VERSION, SENSOR_TYPE);
  }
  else if (cmd == "READ") {
    sendMeasurement();
  }
  else if (cmd == "RESET") {
    Serial.println("{\"status\":\"resetting\"}");
    delay(100);
    ESP.restart();
  }
  else if (cmd == "START") {
    continuousMode = true;
    Serial.println("{\"status\":\"continuous_started\"}");
  }
  else if (cmd == "STOP") {
    continuousMode = false;
    Serial.println("{\"status\":\"continuous_stopped\"}");
  }
  else if (cmd.startsWith("INTERVAL")) {
    // Parse interval: INTERVAL 200
    int spaceIndex = cmd.indexOf(' ');
    if (spaceIndex > 0) {
      String intervalStr = cmd.substring(spaceIndex + 1);
      int newInterval = intervalStr.toInt();
      if (newInterval >= 10 && newInterval <= 5000) {
        measurementInterval = newInterval;
        Serial.printf("{\"status\":\"interval_set\",\"interval_ms\":%d}\n", measurementInterval);
      } else {
        Serial.println("{\"error\":\"invalid_interval\"}");
      }
    } else {
      Serial.println("{\"error\":\"missing_interval_value\"}");
    }
  }
  else if (cmd == "STATUS") {
    Serial.printf("{\"status\":{\"continuous_mode\":%s,\"interval_ms\":%d}}\n", 
                  continuousMode ? "true" : "false", measurementInterval);
  }
  else {
    Serial.printf("{\"error\":\"unknown_command\",\"command\":\"%s\"}\n", cmd);
  }
}

void sendMeasurement() {
  uint16_t distance = sensor.readRangeSingleMillimeters();
  
  if (!sensor.timeoutOccurred()) {
    Serial.printf("{\"measurement\":{\"distance_cm\":%.2f,\"distance_mm\":%d,\"timestamp\":%lu,\"is_valid\":true}}\n", 
                  distance/10.0, distance, millis());
  } else {
    Serial.println("{\"measurement\":{\"distance_cm\":0.0,\"distance_mm\":0,\"timestamp\":0,\"is_valid\":false,\"error\":\"timeout\"}}");
  }
}
