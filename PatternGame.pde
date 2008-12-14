/*
 * "Pattern Game"
 * 
 * You have to push the buttons in the sequence 1-2-3-4-4-3-2-1
 * repeatedly to avoid the output line getting turned on.
 */
 
int button1Pin = 2;
int button2Pin = 3;
int button3Pin = 4;
int button4Pin = 5;

int expectedPin[] = {2,3,4,5,5,4,3,2}; // buttons 1-2-3-4-4-3-2-1
int phase = 0;

long SECONDS = 1000000L;

long initialSamples = 5L;
long totalTime = initialSamples * SECONDS;

long averageTime = 1 * SECONDS; // 1 second, in microseconds

long numSamples = initialSamples;
long allowedTime;

long maxTime = 1500000L; // 1.5 seconds, in microseconds; cannot delay longer than this

long minMargin = 15;
long percentMargin = 20;
long maxMargin = 50;

int lightPin = 13;
int signalPin =11;
long time = 0;                    // variable for reading the pin status

int errorOn = 0;
int errorCount = 0;

void setup() {
  pinMode(signalPin, OUTPUT);      // declare LED as output 
  pinMode(lightPin, OUTPUT);      // declare LED as output
  digitalWrite(signalPin, LOW);
  digitalWrite(lightPin, LOW);  

  pinMode(button1Pin, INPUT);     // declare pushbutton as input  
  pinMode(button2Pin, INPUT);     // declare pushbutton as input  
  pinMode(button3Pin, INPUT);     // declare pushbutton as input  
  pinMode(button4Pin, INPUT);     // declare pushbutton as input
  
    Serial.begin(9600);           // Set up serial communication at 9600bps
    Serial.println("Ready");
    allowedTime = maxTime;

    int i = 0;
    for (i = 0; i < 4; i++) {
    // Signal readiness, then wait
      digitalWrite(lightPin, HIGH);  
      delay(250);      
      digitalWrite(lightPin, LOW);  
      delay(250);
    }
    // As soon as button 1 is pressed, the game begins
    pulseIn(expectedPin[phase], HIGH, 30000000L); // 30 seconds
    phase++;
}

void loop(){
  if (errorCount > 50) {
    digitalWrite(signalPin, LOW); // turn off
    digitalWrite(lightPin, LOW); // turn off
    errorOn = 0;
    return; // TODO return to the ready state
  }
  
  if (phase == 0 && percentMargin > minMargin) {
    percentMargin--;
    allowedTime = averageTime + ((percentMargin * averageTime) / 100); // you can slow as much as this (20%)...
  }
  if (allowedTime > maxTime) allowedTime = maxTime; // but no slower than the absolute limit
      
  Serial.print(allowedTime / 1000L);
  Serial.print("ms ");
  Serial.print(phase);
  Serial.print(": ");
  time = pulseIn(expectedPin[phase], HIGH, allowedTime);
  if (time == 0L) {            // did they click the expected switch?
      if (!errorOn) {
        analogWrite(signalPin, 128); // Play 1 490hz 50% square wave
        digitalWrite(lightPin, HIGH);
        phase = 0;
        Serial.println("BZZZT!");
        errorOn = 1;
      } 
      errorCount++;
      if (percentMargin < maxMargin) percentMargin++;
      allowedTime = allowedTime + (allowedTime / 4L);
      
   } else {
      digitalWrite(signalPin, LOW); // turn off
      digitalWrite(lightPin, LOW); // turn off
      errorOn = 0;
      phase = (phase + 1) % 8;
      Serial.print(time / 1000L);
      Serial.println("ms");
      
      if (time > 5000L) {
        totalTime += time;
        numSamples++;
        averageTime = totalTime / numSamples; 
//        allowedTime = averageTime;
      }
  }
}
