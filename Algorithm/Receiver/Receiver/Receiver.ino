// Author: Gustavo N. Santiago

//Libraries for LoRa
#include <SPI.h>
#include <LoRa.h>

// Libraries for microSD card
#include <SD.h>

//Libraries for OLED Display
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SSD1306.h>

//Libraries for WiFi and MongoDB
#include <ArduinoJson.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include "secrets.h"

//Define the pins used by the LoRa transceiver module
#define SCLK 5
#define MISO 19
#define MOSI 27
#define CS 18
#define RST 23
#define DIO0 26

// SD SPI pins
#define SD_CS 13
#define SD_SCK 14
#define SD_MOSI 15
#define SD_MISO 2

//OLED pins
#define OLED_SDA 21
#define OLED_SCL 22 
#define SCREEN_WIDTH 128 // OLED display width, in pixels
#define SCREEN_HEIGHT 64 // OLED display height, in pixels
Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RST);

// For SD card
File myFile;
SPIClass sd_spi(HSPI);

// Setting up a variable to store data from LoRa
String LoRaData;

// Monitore sending data to cloud
int httpResponseCode;

// Minimizing number of requests
#define MAX_ENTRIES 4 // Number of sensors
int entryCount = 0;
struct Reading {
  String device;
  String reading;
};
Reading readings[MAX_ENTRIES];
DynamicJsonDocument doc(1024);

void setup() { 

  // Initialize Serial Monitor
  Serial.begin(115200);

  // Initialize OLED
  Wire.begin(OLED_SDA, OLED_SCL);
  if(!display.begin(SSD1306_SWITCHCAPVCC, 0x3c, false, false)) { // Address 0x3C for 128x32
    Serial.println(F("SSD1306 allocation failed"));
    for(;;); // Don't proceed, loop forever
  }

  display.clearDisplay();
  display.setTextColor(WHITE);
  display.display();

  Serial.println("LoRa Receiver Test");
  
  //SPI LoRa pins
  SPI.begin(SCLK, MISO, MOSI, CS);
  LoRa.setPins(CS, RST, DIO0);

  //Initialize LoRa
  if (!LoRa.begin(915E6)) {
    Serial.println("Starting LoRa failed!");
    while (1);
  }

  //Set the specific communication between devices
  LoRa.setSyncWord(0xF3);

  Serial.println("LoRa Initializing OK!");
  display.setCursor(0,10);
  display.println("LoRa Initializing OK!");
  display.display();

  // Initialize microSD card
  sd_spi.begin(SD_SCK, SD_MISO, SD_MOSI, SD_CS);

  if (SD.begin(SD_CS, sd_spi)) {
    display.clearDisplay();
    display.setCursor(0,10);
    display.println("Card initialized.");
    display.display();
    Serial.println("Card initialized.");
  }
  else{
    display.clearDisplay();
    display.setCursor(0,10);
    display.println("Card failed, or not present");
    display.display();
    Serial.println("Card failed, or not present");
    while(1);
  }

  // Connecting to internet
  WiFi.begin(ssid, password);
  while(WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.println(".");
  }
  Serial.print("Connected to WiFi network with IP Address: ");
  Serial.println(WiFi.localIP());

}

void loop() {

  // Try to parse packet
  int packetSize = LoRa.parsePacket();

  String id;
  String device;
  String reading;
  String date;

  if (packetSize) {

    doc.clear();

    // Read packet
    while (LoRa.available()) {

      LoRaData = LoRa.readStringUntil(':');

      if(LoRaData.endsWith("ID"))
        id = LoRa.readStringUntil(',');
      if(LoRaData.endsWith("Device"))
        device = LoRa.readStringUntil(',');
      if(LoRaData.endsWith("Temperature"))
        reading = LoRa.readStringUntil(',');
      if(LoRaData.endsWith("DateTime"))
        date = LoRa.readStringUntil(',');

    }

    myFile = SD.open("/test.txt", FILE_APPEND);
    myFile.print(id);
    myFile.print(",");
    myFile.print(device);
    myFile.print(",");
    myFile.print(reading);
    myFile.print(",");
    myFile.print(date);
    myFile.println(",");
    myFile.close();

    Serial.println("Saved data to SD card.");

    // Print RSSI of packet
    int rssi = LoRa.packetRssi();

    //Parsing Data to JSON:
    doc["group"] = id;
    readings[entryCount].device = device;
    readings[entryCount].reading = reading;
    doc["dateTime"] = date;
    doc["LoRa RSSI"] = rssi;
    doc["Wifi RSSI"] = String(WiFi.RSSI());
    entryCount++;

    bool hasErrorReading = false;
    for (int i = 0; i < entryCount; i++) {
      if (readings[i].reading == "-127.00") {
        hasErrorReading = true;
        break; // Exit the loop early if an error reading is found
      }
    }

    if (entryCount == MAX_ENTRIES) {
      POSTData();
      entryCount = 0;
    }

    // Display information
    display.clearDisplay();
    display.setCursor(0,0);
    display.print("Received packet");

    display.setCursor(0,10);
    display.print("Group:");
    display.setCursor(40,10);
    display.print(id);

    display.setCursor(0,20);
    display.print("RSSI:");
    display.setCursor(50,20);
    display.print(rssi);

    display.setCursor(0,30);
    display.print("Response:");
    display.setCursor(60,30);
    if(httpResponseCode == 200){
      display.print("Sucess");
    }
    else{
      display.print("Error");
    }

    if(hasErrorReading == true){
      display.setCursor(0,40);
      display.print("Sensor reading error");
    }
    display.display();

  }

}
