const int dirpin = 2;
const int steppin = 4;

const int ms1 = 21;
const int ms2 = 22;
const int ms3 = 23;

const int steprev = 1600;

void setup() {
  // put your setup code here, to run once:
  pinMode(dirpin, OUTPUT);
  pinMode(steppin, OUTPUT);
  
  pinMode(ms1, OUTPUT);
  pinMode(ms2, OUTPUT);
  pinMode(ms3, OUTPUT);
  digitalWrite(ms1, HIGH);
  digitalWrite(ms2, HIGH);
  digitalWrite(ms3, LOW);

   Serial.begin(9600);

}

void stepMotor(int steps, bool direction) {
    digitalWrite(dirpin, direction);
    for (int i = 0; i < steps; i++) {
        digitalWrite(steppin, HIGH);
        delayMicroseconds(4500);
        digitalWrite(steppin, LOW);
        delayMicroseconds(4500);
    }
}

void stepMotorback(int steps, bool direction) {
    digitalWrite(dirpin, direction);
    for (int i = 0; i < steps; i++) {
        digitalWrite(steppin, HIGH);
        delayMicroseconds(1000);
        digitalWrite(steppin, LOW);
        delayMicroseconds(1000);
    }
}

void loop() {

  if (Serial.available() > 0) { // Si MATLAB envía un comando
       char comando = Serial.read();
        if (comando == 'S') {  // Si el comando es 'S', inicia el movimiento
            Serial.println("Iniciando movimiento...");
            stepMotor(steprev, HIGH);  // Avanza 360°
            delay(5000);
            stepMotorback(steprev, LOW);   // Regresa a 0°
        }
  }
}


