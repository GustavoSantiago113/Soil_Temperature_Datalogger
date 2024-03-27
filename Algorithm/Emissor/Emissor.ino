// Author: Gustavo Nocera Santiago

// Including Libraries
#include <Wire.h>
//#include <SD.h> // For SD Card
//#include <SPI.h> // For SD Card
#include <RTClib.h> // For RTC Clock
#include <OneWire.h> // For Temperature Sensor
#include <DallasTemperature.h> // For Temperature Sensor
#include <LowPower.h> // Put Arduino to sleep and save energy
#include <LoRa.h> // LoRa usage

// Lora pins
#define ss 10
#define rst 9
#define dio0 2

// Device ID
int ID = 1;

// Variables for RTC
RTC_DS3231 rtc;

// Variables for Temp sensors
const int ONE_WIRE_BUS = 4;

// Setup a oneWire instance to communicate with any OneWire device
OneWire oneWire(ONE_WIRE_BUS);

// Pass oneWire reference to DallasTemperature library
DallasTemperature sensors(&oneWire);

// Number of temperature devices you are using
int numberOfDevices; 

// Define the maximum number of sensors
#define MAX_SENSORS 4 

// We'll use this variable to store a found device address
DeviceAddress tempDeviceAddress[MAX_SENSORS];
int foundSensors = 0;

void setup() {

  Serial.begin(9600);

  // Clock
  if (! rtc.begin())
  {
    Serial.println("Clock module not found!");
    while(1);
    
  }
  //rtc.adjust(DateTime(F(__DATE__), F(__TIME__))); //Upload code once with this line uncommented so the clock is adjusted, then coment this line and upload again
  LoRa.setPins(ss, rst, dio0);

  // LoRa begin
  if (LoRa.begin(915E6)) {
    Serial.println("Starting LoRa success!");
    delay(500);
  }else{
    Serial.println("Starting LoRa Failed!");
  }
  LoRa.setSyncWord(0xF3);

  // Sensors begin
  sensors.begin();

  // locate devices on the bus
  Serial.print("Locating devices...");

  // Grab a count of devices on the wire
  numberOfDevices = sensors.getDeviceCount();
  Serial.print("Found ");
  Serial.print(numberOfDevices, DEC);
  Serial.println(" devices.");
  
  while (foundSensors < MAX_SENSORS) {
    sensors.begin();
    numberOfDevices = sensors.getDeviceCount();

    for (int i = 0; i < numberOfDevices && foundSensors < MAX_SENSORS; i++) {
      if (sensors.getAddress(tempDeviceAddress[foundSensors], i)) {
        Serial.print("Found device ");
        Serial.print(foundSensors, DEC);
        Serial.print(" with address: ");
        printAddress(tempDeviceAddress[foundSensors]);
        Serial.println();
        foundSensors++; // Increment the counter for found sensors
      } else {
        Serial.print("Found ghost device at ");
        Serial.print(i, DEC);
        Serial.println(", but could not detect address. Check power and cabling");
      }
      
    }
    // If not all sensors are found, delay and then retry
    if (foundSensors < MAX_SENSORS) {
      Serial.println("Not all sensors found. Retrying in 5 seconds...");
      delay(5000);
      foundSensors = 0;
    }
  }
  
}

void loop() {
  
  // Clock
  DateTime fecha = rtc.now();

  // Send the command to get temperatures
  sensors.requestTemperatures();

  Serial.print(fecha.day());
  Serial.print("/");
  Serial.print(fecha.month());
  Serial.print("/");
  Serial.print(fecha.year());
  Serial.print(", ");
  Serial.print(fecha.hour());
  Serial.print(":");
  Serial.println(fecha.minute());
  
  // Loop through each device, print out temperature data
  for(int i=0; i < numberOfDevices && i < MAX_SENSORS; i++) {
    float tempC = sensors.getTempC(tempDeviceAddress[i]);
    Serial.print("Temperature for device: ");
    Serial.print(i,DEC);
    Serial.print(" - "); 
    Serial.println(tempC);
    sendPacket(i, tempC, fecha);
    delay(250);
  }

  
  
  for(int i = 0; i<= 15; i++) //Here (i<=5400) you insert the number of seconds divided by two (i.e. you want 1 minute, so 60/2=30)
  {
     LowPower.powerDown(SLEEP_2S, ADC_OFF, BOD_OFF);
  }

}

// function to print a device address
void printAddress(DeviceAddress deviceAddress) {
  for (uint8_t i = 0; i < 8; i++) {
    if (deviceAddress[i] < 16) Serial.print("0");
      Serial.print(deviceAddress[i], HEX);
  }
}
