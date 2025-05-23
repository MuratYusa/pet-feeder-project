#include <Servo.h>
#include <SoftwareSerial.h>

Servo myServo;
SoftwareSerial bluetooth(3, 2); // RX, TX

unsigned long previousMillis = 0;
const long interval = 10000; // 10 saniye = 10000 ms

void setup() {
  myServo.attach(9); // Servo motor pin
  bluetooth.begin(9600); // HC-05 için baud rate
  myServo.write(90); // Başlangıç konumu
}

void loop() {
  unsigned long currentMillis = millis();

  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;

    // Mama verme işlemi
    myServo.write(170);
    delay(5000); // 5 saniye bekle
    myServo.write(90);

    // Flutter'a bildirim gönder
    bluetooth.println("MAMA:VERILDI");
  }
}
