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

int led1Pin = 6;
int led2Pin = 7;
int led3Pin = 8;
int led4Pin = 9;

int pattern[] = {1,2,3,4,4,3,2,1};
int buttonPins[] = {2,3,4,5};
int ledPins[]={6,7,8,9};

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

  int i;
  for (i = 0; i < 4; i++) {
    pinMode(buttonPins[i], INPUT);     // declare pushbutton as input
    pinMode(ledPins[i], OUTPUT);     // declare pushbutton as input  
  }
  
    Serial.begin(9600);           // Set up serial communication at 9600bps
    allowedTime = maxTime;
    
    // Attractor loop
    for (;;) {
      playSample(); 
      twinkleFirstLight(); // signal readiness
      // As soon as the first is pressed, the game begins
      time = pulseIn(buttonForPhase(0), HIGH, 15000000L); // 15 seconds
      if (time != 0) break;
    }
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
  time = pulseIn(buttonForPhase(phase), HIGH, allowedTime);
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

void playSample() {
    for (int phase = 0; phase <= 7; phase++) {
      int ledPin = ledForPhase(phase);
      digitalWrite(ledPin, HIGH);  
      delay(250);      
      digitalWrite(ledPin, LOW);  
      delay(250);
    }
}

void twinkleFirstLight() {
  int ledPin = ledForPhase(0);
  int count;
  for (count = 1; count <= 8; count++) {
    digitalWrite(ledPin, HIGH);
    delay(100);
    digitalWrite(ledPin, LOW);
    delay(100);
  } 
}


int ledForPhase(int phase) {
  int patternValue = pattern[phase];
  return ledPins[patternValue-1];
}

int buttonForPhase(int phase) {
    int patternValue = pattern[phase];
    return buttonPins[patternValue-1];
}
