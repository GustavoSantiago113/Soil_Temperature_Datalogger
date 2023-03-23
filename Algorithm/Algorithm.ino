// Author: Gustavo Nocera Santiago

// Including Libraries
#include <Wire.h>
#include <SD.h> // For SD Card
#include <SPI.h> // For SD Card
#include <RTClib.h> // For RTC Clock
#include <OneWire.h> // For Temperature Sensor
#include <DallasTemperature.h> // For Temperature Sensor

// Variables for SD Card (Card must be FAT16 or FAT32 formats)
File myFile;
String fileName = "Block1.txt";

// Variables for RTC
RTC_DS3231 rtc;

// Variables for Temp sensors
const int ONE_WIRE_BUS = 8;

// Setup a oneWire instance to communicate with any OneWire device
OneWire oneWire(ONE_WIRE_BUS);

// Pass oneWire reference to DallasTemperature library
DallasTemperature sensors(&oneWire);

// Number of temperature devices found
int numberOfDevices; 

// We'll use this variable to store a found device address
DeviceAddress tempDeviceAddress; 

void setup() {

  Serial.begin(9600);

  // LED blink
  pinMode(LED_BUILTIN, OUTPUT);

  // Sensors begin
  sensors.begin();
  
  // Grab a count of devices on the wire
  numberOfDevices = sensors.getDeviceCount();

  // Clock
  if (! rtc.begin())
  {
    Serial.println("Clock module not found!");
    while(1);
    
  }
  //rtc.adjust(DateTime(__DATE__, __TIME__)); //Upload code once with this line so the clock is adjusted, then coment this line and upload again

  if (!SD.begin(10)) {
    Serial.println("Card failed, or not present");
    digitalWrite(LED_BUILTIN, HIGH);
    return;
  }
  Serial.println("card initialized.");

  // locate devices on the bus
  Serial.print("Locating devices...");
  Serial.print("Found ");
  Serial.print(numberOfDevices, DEC);
  Serial.println(" devices.");
  
  // Loop through each device, print out address
  for(int i=0;i<numberOfDevices; i++) {
    // Search the wire for address
    if(sensors.getAddress(tempDeviceAddress, i)) {
      Serial.print("Found device ");
      Serial.print(i, DEC);
      Serial.print(" with address: ");
      printAddress(tempDeviceAddress);
      Serial.println();
    } else {
      Serial.print("Found ghost device at ");
      Serial.print(i, DEC);
      Serial.print(" but could not detect address. Check power and cabling");
    }
  }
  
}

void loop() {
  
  // Clock
  DateTime fecha = rtc.now();

  // Send the command to get temperatures
  sensors.requestTemperatures();

  // Saving everything on SD Card
  myFile = SD.open(fileName, FILE_WRITE);
  myFile.print(fecha.day());
  myFile.print("/");
  myFile.print(fecha.month());
  myFile.print("/");
  myFile.print(fecha.year());
  myFile.print(",");
  myFile.print(fecha.hour());
  myFile.print(":");
  myFile.print(fecha.minute());
  myFile.print(",");

  Serial.print(fecha.day());
  Serial.print("/");
  Serial.print(fecha.month());
  Serial.print("/");
  Serial.print(fecha.year());
  Serial.print(",");
  Serial.print(fecha.hour());
  Serial.print(":");
  Serial.print(fecha.minute());
  Serial.print(",");
  
  // Loop through each device, print out temperature data
  for(int i=0;i<numberOfDevices; i++) {
    // Search the wire for address
    if(sensors.getAddress(tempDeviceAddress, i)){
    
    // Output the device ID
    Serial.print("Temperature for device: ");
    Serial.print(i,DEC);
    Serial.print(" - ");
    
    // Print the data
    float tempC = sensors.getTempC(tempDeviceAddress);
    Serial.println(tempC);
    myFile.print(tempC);
    myFile.print(",");
    
    }
  }

  myFile.println("");
  myFile.close();
  
  delay(1800000);
  //delay(1000);

}

// function to print a device address
void printAddress(DeviceAddress deviceAddress) {
  for (uint8_t i = 0; i < 8; i++) {
    if (deviceAddress[i] < 16) Serial.print("0");
      Serial.print(deviceAddress[i], HEX);
  }
}
