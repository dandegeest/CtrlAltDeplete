#include <Adafruit_NeoPixel.h>
#ifdef __AVR__
#include <avr/power.h> // Required for 16 MHz Adafruit Trinket
#endif

#define LED_PIN    3
#define LED_PIN2   6
#define LED_COUNT 120
#define LED_COUNT2 250

Adafruit_NeoPixel strip(LED_COUNT, LED_PIN, NEO_RGB + NEO_KHZ800);
Adafruit_NeoPixel strip2(LED_COUNT2, LED_PIN2, NEO_RGBW + NEO_KHZ800);

// Timing variables
unsigned long previousMillis = 0;
unsigned long interval = 10;  // 10ms between updates

// Strip 1 variables
int currentPixel1 = 0;
uint32_t currentColor1 = 0;
bool isWiping1 = false;

// Strip 2 variables
int currentPixel2 = 0;
uint32_t currentColor2 = 0;
uint32_t nextColor2 = 0;  // Add variable for next color
bool isWiping2 = false;
bool isReversing2 = false;  // Add flag for reverse direction
int colorCount2 = 0;  // Track how many colors we've shown

void setup() {
#if defined(__AVR_ATtiny85__) && (F_CPU == 16000000)
  clock_prescale_set(clock_div_1);
#endif

  strip.begin();
  strip.show();
  strip.setBrightness(50);

  strip2.begin();
  strip2.show();
  strip2.setBrightness(50);

  Serial.begin(9600);
}

void loop() {
  unsigned long currentMillis = millis();
  
  // Read sensors every loop
  int sensor1 = analogRead(A0);
  int sensor2 = analogRead(A1);
  
  // Send sensor values
  Serial.print(sensor1);
  Serial.print(":");
  Serial.print(sensor2);
  Serial.println();

  // Handle LED effects based on sensor values
  if (sensor1 < 50 && !isWiping1) {
    startColorWipe(strip.Color(255, 0, 0));
  }
  
  if (sensor2 > 50 && !isWiping2) {
    startColorWipe2(strip2.Color(255, 0, 0));
  }

  // Update LED effects if active
  if (currentMillis - previousMillis >= interval) {
    previousMillis = currentMillis;
    
    if (isWiping1) {
      updateColorWipe();
    }
    
    if (isWiping2) {
      updateColorWipe2();
    }
  }
}

void startColorWipe(uint32_t color) {
  currentPixel1 = 0;
  currentColor1 = color;
  isWiping1 = true;
}

void updateColorWipe() {
  if (currentPixel1 < strip.numPixels()) {
    strip.setPixelColor(currentPixel1, currentColor1);
    strip.show();
    currentPixel1++;
  } else {
    isWiping1 = false;
    // Start next color in sequence
    if (currentColor1 == strip.Color(255, 0, 0)) {
      startColorWipe(strip.Color(255, 0, 255));
    } else if (currentColor1 == strip.Color(255, 0, 255)) {
      startColorWipe(strip.Color(65, 105, 235));
    } else if (currentColor1 == strip.Color(65, 105, 235)) {
      startColorWipe(strip.Color(0, 255, 255));
    } else if (currentColor1 == strip.Color(0, 255, 255)) {
      startColorWipe(strip.Color(139, 64, 18));
    } else if (currentColor1 == strip.Color(139, 64, 18)) {
      startColorWipe(strip.Color(0, 0, 0));
    }
  }
}

void startColorWipe2(uint32_t color) {
  currentPixel2 = 0;
  currentColor2 = color;
  isWiping2 = true;
  isReversing2 = false;
  if (color != strip2.Color(0, 0, 0)) {
    colorCount2++;
  }
}

void updateColorWipe2() {
  if (!isReversing2) {
    // Forward wipe
    if (currentPixel2 < strip2.numPixels()) {
      strip2.setPixelColor(currentPixel2, currentColor2);
      strip2.show();
      currentPixel2++;
    } else {
      isWiping2 = false;
      if (colorCount2 == 0) {
        // First activation - start with random color
        startColorWipe2(strip2.Color(random(255), random(255), random(255)));
      } else if (colorCount2 == 1) {
        // After first color - start second random color
        startColorWipe2(strip2.Color(random(255), random(255), random(255)));
      } else {
        // After second color - start reverse wipe to black
        isReversing2 = true;
        currentPixel2 = strip2.numPixels() - 1;
        isWiping2 = true;
        colorCount2 = 0;
      }
    }
  } else {
    // Reverse wipe to black
    if (currentPixel2 >= 0) {
      strip2.setPixelColor(currentPixel2, strip2.Color(0, 0, 0));
      strip2.show();
      currentPixel2--;
    } else {
      isWiping2 = false;
      isReversing2 = false;
    }
  }
}

void theaterChase(uint32_t color, int wait) {
  for (int a = 0; a < 10; a++) {
    for (int b = 0; b < 3; b++) {
      strip.clear();
      for (int c = b; c < strip.numPixels(); c += 3) {
        strip.setPixelColor(c, color);
      }
      strip.show();
      delay(wait);
    }
  }
}

void rainbow(int wait) {
  strip.show();
  delay(wait);
}

void theaterChaseRainbow(int wait) {
  int firstPixelHue = 0;
  for (int a = 0; a < 30; a++) {
    for (int b = 0; b < 3; b++) {
      strip.clear();
      for (int c = b; c < strip.numPixels(); c += 3) {
        int hue = firstPixelHue + c * 65536L / strip.numPixels();
        uint32_t color = strip.gamma32(strip.ColorHSV(hue));
        strip.setPixelColor(c, color);
      }
      strip.show();
      delay(wait);
      firstPixelHue += 65536 / 90;
    }
  }
}