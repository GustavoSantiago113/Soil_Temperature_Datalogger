void sendPacket(int i, float tempC, DateTime fecha)
{

  LoRa.beginPacket();
  LoRa.print("ID:");
  LoRa.print(ID);
  LoRa.print(", Device:");
  LoRa.print(i);
  LoRa.print(", Temperature:");
  LoRa.print(tempC);
  LoRa.print(", DateTime:");
  LoRa.print(fecha.day());
  LoRa.print("/");
  LoRa.print(fecha.month());
  LoRa.print("/");
  LoRa.print(fecha.year());
  LoRa.print(" ");
  LoRa.print(fecha.hour());
  LoRa.print("/");
  LoRa.print(fecha.minute());
  LoRa.print(",");
  LoRa.endPacket();

}