void POSTData()
{

    // Serialize JSON to string
    String jsonString;
    JsonObject readingObject = doc.createNestedObject("reading");

    for (int i = 0; i < entryCount; i++) {
      readingObject["Device " + readings[i].device] = readings[i].reading;
    }

    serializeJson(doc, jsonString);

    Serial.println(jsonString);

    // Send HTTP POST request to server
    HTTPClient http;
    http.begin(serverUrl);
    http.addHeader("Content-Type", "application/json");
    httpResponseCode = http.POST(jsonString);

    Serial.println("Posting...");

    if (httpResponseCode > 0) {
      Serial.print("HTTP response code: ");
      Serial.println(httpResponseCode);
      String response = http.getString();
      Serial.println(response);
    } else {
      Serial.print("HTTP POST request failed, error: ");
      Serial.println(httpResponseCode);
    }

    http.end();
  
}