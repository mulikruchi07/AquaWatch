#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <ArduinoJson.h>
#include <EEPROM.h>

#define EEPROM_SIZE 16
#define ESP_ID_ADDR 0

#define TDS_PIN 34    
#define TRIG_PIN 25
#define ECHO_PIN 27
#define RELAY_PIN 23    

const char* SUPABASE_URL = "https://SUPABASE_URL/rest/v1/esp_data";
const char* SUPABASE_API_KEY = "SUPABASE_API_KEY";  

#define SERVICE_UUID        "12345678-1234-5678-1234-56789abcdef0"
#define CHARACTERISTIC_UUID "abcdefab-cdef-1234-5678-1234567890ab"

BLECharacteristic* wifiCharacteristic;
bool newCredentialsReceived = false;
String receivedData = "";
String espId = "";

String generateLocalEspId() {
  uint64_t chipid = ESP.getEfuseMac(); 
  uint32_t shortId = (uint32_t)(chipid & 0xFFFFFF); 
  uint16_t idNum = shortId % 1000; 
  char formattedId[4];
  snprintf(formattedId, sizeof(formattedId), "%03d", idNum);
  return String(formattedId);
}


class WifiCredentialsCallback : public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic* pCharacteristic) override {
    receivedData = pCharacteristic->getValue().c_str();
    receivedData.trim();
    Serial.println("📩 Received over BLE: " + receivedData);
    newCredentialsReceived = true;
  }
};

void setupBLE() {
  BLEDevice::init("ESP32-Provisioning");
  BLEServer* server = BLEDevice::createServer();
  BLEService* wifiService = server->createService(SERVICE_UUID);

  wifiCharacteristic = wifiService->createCharacteristic(
    CHARACTERISTIC_UUID,
    BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_NOTIFY
  );

  wifiCharacteristic->setCallbacks(new WifiCredentialsCallback());
  wifiCharacteristic->addDescriptor(new BLE2902());
  wifiService->start();

  BLEAdvertising* advertising = BLEDevice::getAdvertising();
  advertising->addServiceUUID(SERVICE_UUID);
  advertising->start();
  Serial.println("📶 BLE Wi-Fi Provisioning Service Started...");
}

void connectToWiFi(const String& creds) {
  int separator = creds.indexOf('|');
  if (separator == -1) {
    Serial.println("❌ Invalid format. Use: SSID|PASSWORD");
    wifiCharacteristic->setValue("WIFI_FAIL");
    wifiCharacteristic->notify();
    return;
  }

  String ssid = creds.substring(0, separator);
  String password = creds.substring(separator + 1);

  Serial.println("🔗 Connecting to Wi-Fi...");
  WiFi.begin(ssid.c_str(), password.c_str());

  int attempts = 0;
  while (WiFi.status() != WL_CONNECTED && attempts < 20) {
    delay(500);
    Serial.print(".");
    attempts++;
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println("\n✅ Wi-Fi Connected!");
    Serial.println("📡 IP: " + WiFi.localIP().toString());
    wifiCharacteristic->setValue("WIFI_OK");
    wifiCharacteristic->notify();
    BLEDevice::deinit(true);

    WiFiClientSecure client;
    client.setInsecure();
    HTTPClient http;

    String url = "https://SUPABASE_URL/rest/v1/user_devices";
    http.begin(client, url);
    http.addHeader("Content-Type", "application/json");
    http.addHeader("apikey", SUPABASE_API_KEY);
    http.addHeader("Authorization", "Bearer " + String(SUPABASE_API_KEY));
    http.addHeader("Prefer", "return=minimal");

    StaticJsonDocument<100> doc;
    doc["esp_id"] = espId;

    String payload;
    serializeJson(doc, payload);
    Serial.println("📤 Posting esp_id to Supabase: " + payload);

    int code = http.POST(payload);
    if (code == 201 || code == 200 || code == 204) {
      Serial.println("✅ esp_id saved to user_devices");
    } else {
      Serial.println("❌ Failed to save esp_id to user_devices. HTTP Code: " + String(code));
    }
    http.end();
  } else {
    Serial.println("\n❌ Failed to connect to Wi-Fi.");
    wifiCharacteristic->setValue("WIFI_FAIL");
    wifiCharacteristic->notify();
  }
}

float readUltrasonicCM() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  long duration = pulseIn(ECHO_PIN, HIGH, 30000);
  if (duration == 0) return -1;
  return duration * 0.034 / 2.0;
}

float readTDS() {
  int analogValue = analogRead(TDS_PIN);
  float voltage = analogValue * (3.3 / 4095.0);
  float tdsValue = (133.42 * voltage * voltage * voltage
                  - 255.86 * voltage * voltage
                  + 857.39 * voltage) * 0.5;
  return tdsValue;
}

void controlRelay(float distance) {
  if (distance > 90) {  
    digitalWrite(RELAY_PIN, LOW);
    Serial.println("✅ Tank Low → Relay ON");
  } 
  else if (distance < 10 && distance > 0) {  
    digitalWrite(RELAY_PIN, HIGH);
    Serial.println("🚫 Tank Full → Relay OFF");
  }
}

void sendDataToSupabase(float distance, float tdsValue, float waterLevel) {
  if (WiFi.status() != WL_CONNECTED) return;

  int32_t rssi = WiFi.RSSI();

  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient http;

  http.begin(client, SUPABASE_URL);
  http.addHeader("Content-Type", "application/json");
  http.addHeader("apikey", SUPABASE_API_KEY);
  http.addHeader("Authorization", "Bearer " + String(SUPABASE_API_KEY));
  http.addHeader("Prefer", "return=minimal");

  StaticJsonDocument<200> doc;
  doc["esp_id"] = espId;
  doc["tds_value"] = tdsValue;
  doc["water_level"] = waterLevel;
  doc["device_status"] = String(rssi) + " dBm";

  String jsonPayload;
  serializeJson(doc, jsonPayload);
  Serial.println("📤 Sending Data: " + jsonPayload);

  int httpCode = http.POST(jsonPayload);
  if (httpCode > 0) {
    Serial.println("✅ Data sent! HTTP Code: " + String(httpCode));
  } else {
    Serial.println("❌ Failed to send data. Code: " + String(httpCode));
  }

  http.end();
}

void setup() {
  Serial.begin(115200);
  randomSeed(analogRead(0));
  EEPROM.begin(EEPROM_SIZE);

  pinMode(TRIG_PIN, OUTPUT);
  pinMode(ECHO_PIN, INPUT);
  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, HIGH);

  char storedId[8] = {0};
  for (int i = 0; i < 7; ++i) {
    storedId[i] = EEPROM.read(ESP_ID_ADDR + i);
  }

  String loadedId = String(storedId);
  loadedId.trim();

  if (loadedId.length() == 3 && loadedId.toInt() > 0) {
    espId = loadedId;
    Serial.println("🔁 Loaded ESP ID from EEPROM: " + espId);
  } else {
    espId = generateLocalEspId();
    Serial.println("🆕 Generated ESP ID: " + espId);
    for (int i = 0; i < espId.length(); ++i)
      EEPROM.write(ESP_ID_ADDR + i, espId[i]);
    EEPROM.write(ESP_ID_ADDR + espId.length(), '\0');
    EEPROM.commit();
    Serial.println("💾 ESP ID saved to EEPROM.");
  }

  setupBLE();
}

void loop() {
  if (newCredentialsReceived) {
    connectToWiFi(receivedData);
    newCredentialsReceived = false;
  }

  if (WiFi.status() == WL_CONNECTED) {
    float tdsValue = readTDS();
    float distance = readUltrasonicCM();
    float tankHeight = 100.0;  
    float waterLevel = 1.0 - (distance / tankHeight);
    waterLevel = constrain(waterLevel, 0.0, 1.0);

    controlRelay(distance);

    sendDataToSupabase(distance, tdsValue, waterLevel);

    delay(10000);  
  }

  delay(100);
}
