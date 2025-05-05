import processing.serial.*;
import javax.sound.midi.*;

Serial myPort;  // Serial port object
MidiDevice device;  // MIDI device
Receiver receiver;  // MIDI receiver
Sequencer sequencer;  // MIDI sequencer

// Configuration
String loopMIDIPort = "MiDDi";  // Name of the loopMIDI port
String targetCOMPort = "COM3";  // Name of the COM port to connect to

// Status flags
boolean serialConnected = false;
boolean midiConnected = false;
boolean portFound = false;

// MIDI parameters
int currentCC = 1;  // Default CC number
int[] ccValues = new int[6];  // Array to store values for CC 1-5 (index 0 unused)
int currentValue = 0;  // Current MIDI value (0-127)

// Mouse control
boolean mousePressed = false;
int lastMouseY = 0;

// Add timing variables at the top with other variables
long lastTriggerTime = 0;
boolean isDelaying = false;

// Add animation variables
float sensor1Value = 0;
float sensor2Value = 0;
float targetSensor1Value = 0;
float targetSensor2Value = 0;
float animationSpeed = 0.1;

void setup() {
  size(400, 300);
  background(0);
  
  // Initialize MIDI
  try {
    MidiDevice.Info[] infos = MidiSystem.getMidiDeviceInfo();
    println("Available MIDI devices:");
    for (MidiDevice.Info info : infos) {
      println("Device: " + info.getName());
      if (info.getName().equals(loopMIDIPort)) {
        device = MidiSystem.getMidiDevice(info);
        device.open();
        receiver = device.getReceiver();
        midiConnected = true;
        println("Connected to MIDI device: " + info.getName());
        break;
      }
    }
  } catch (Exception e) {
    println("MIDI Error: " + e.getMessage());
    midiConnected = false;
  }
  
  // Initialize Serial
  try {
    String[] serialPorts = Serial.list();
    println("Available serial ports:");
    for (String port : serialPorts) {
      println("Port: " + port);
      if (port.equals(targetCOMPort)) {
        portFound = true;
        try {
          myPort = new Serial(this, port, 9600);
          myPort.bufferUntil('\n');
          serialConnected = true;
          println("Connected to serial port: " + port);
        } catch (Exception e) {
          println("Error connecting to serial port: " + e.getMessage());
          serialConnected = false;
        }
        break;
      }
    }
    
    if (!portFound) {
      println("Target COM port " + targetCOMPort + " not found");
    }
  } catch (Exception e) {
    println("Serial Error: " + e.getMessage());
    serialConnected = false;
  }
}

void draw() {
  background(0);
  
  // Smooth animation of sensor values
  sensor1Value = lerp(sensor1Value, targetSensor1Value, animationSpeed);
  sensor2Value = lerp(sensor2Value, targetSensor2Value, animationSpeed);
  
  // Draw HUD-style interface
  drawHUD();
  
  // Draw sensor visualization
  drawSensorVisualization();
  
  // Draw control area
  stroke(255);
  noFill();
  rect(50, 100, 300, 100);
  
  // Draw current value indicator
  if (mousePressed) {
    fill(255, 100);
    float y = constrain(mouseY, 100, 200);
    rect(50, y, 300, 1);
    currentValue = (int)map(y, 200, 100, 0, 127);
    ccValues[currentCC] = currentValue;  // Store the value
    sendMIDI(currentCC, currentValue);
  }
}

void drawHUD() {
  // Title
  fill(255);
  textAlign(CENTER);
  textSize(24);
  text("MIDI Controller", width/2, 40);
  
  // Connection status
  textSize(12);
  fill(serialConnected ? color(0, 255, 0) : color(255, 0, 0));
  text("Serial: " + getSerialStatus(), 60, 20);
  fill(midiConnected ? color(0, 255, 0) : color(255, 0, 0));
  text("MIDI: " + (midiConnected ? "Connected" : "Not Connected"), width-60, 20);
  
  // Draw CC value displays - all at same Y position
  float fixedY = 80;  // Fixed Y position for all displays
  for (int i = 1; i <= 5; i++) {
    drawCCDisplay(i, fixedY);
  }
  
  // Instructions
  fill(255, 150);
  textSize(12);
  text("Press '1-5' to select CC | Click and drag to control", width/2, height - 20);
}

void drawCCDisplay(int ccNum, float yPos) {
  float boxWidth = 50;  // Made slightly smaller to fit 5 boxes
  float boxHeight = 40;
  float spacing = 15;  // Slightly reduced spacing
  float totalWidth = (boxWidth * 5) + (spacing * 4);  // Total width for 5 boxes
  float startX = (width - totalWidth) / 2;  // Starting X position to center all boxes
  float xPos = startX + ((ccNum-1) * (boxWidth + spacing));
  
  // Draw box
  noFill();
  stroke(ccNum == currentCC ? color(0, 255, 0) : color(255));
  rect(xPos, yPos, boxWidth, boxHeight);
  
  // Draw value bar
  fill(50, 150, 255, 150);
  float valueHeight = map(ccValues[ccNum], 0, 127, 0, boxHeight);
  rect(xPos, yPos + boxHeight - valueHeight, boxWidth, valueHeight);
  
  // Draw text
  fill(255);
  textSize(12);
  textAlign(CENTER);
  text("CC" + ccNum, xPos + boxWidth/2, yPos - 5);
  text(ccValues[ccNum], xPos + boxWidth/2, yPos + boxHeight/2 + 5);
}

String getSerialStatus() {
  if (!portFound) return "Port not found";
  if (!serialConnected) return "Not Connected";
  return "Connected";
}

void mousePressed() {
  mousePressed = true;
  lastMouseY = mouseY;
}

void mouseReleased() {
  mousePressed = false;
}

void mouseDragged() {
  if (mousePressed) {
    float y = constrain(mouseY, 100, 200);
    currentValue = (int)map(y, 200, 100, 0, 127);
    ccValues[currentCC] = currentValue;  // Store the value
    sendMIDI(currentCC, currentValue);
  }
}

void keyPressed() {
  // Change CC number with keys 1-5
  if (key >= '1' && key <= '5') {
    currentCC = key - '0';
    println("Changed CC to: " + currentCC);
  }
}

void sendMIDI(int cc, int value) {
  if (midiConnected && receiver != null) {
    try {
      ShortMessage message = new ShortMessage();
      message.setMessage(ShortMessage.CONTROL_CHANGE, 0, cc, value);
      receiver.send(message, -1);
      ccValues[cc] = value;  // Store the value
      println("Sent MIDI CC" + cc + ": " + value);
    } catch (Exception e) {
      println("Error sending MIDI: " + e.getMessage());
    }
  } else {
    println("Warning: MIDI not connected");
  }
}

void drawSensorVisualization() {
  // Draw sensor 1 visualization (left side)
  float sensor1Height = map(sensor1Value, 0, 1023, 0, height - 100);
  fill(255, 0, 0, 150);
  noStroke();
  rect(50, height - sensor1Height - 50, 50, sensor1Height);
  
  // Draw sensor 2 visualization (right side)
  float sensor2Height = map(sensor2Value, 0, 1023, 0, height - 100);
  fill(0, 255, 0, 150);
  noStroke();
  rect(width - 100, height - sensor2Height - 50, 50, sensor2Height);
  
  // Draw threshold lines
  stroke(255, 100);
  // Sensor 1 threshold (90)
  float threshold1Y = height - map(90, 0, 1023, 0, height - 100) - 50;
  line(50, threshold1Y, 100, threshold1Y);
  // Sensor 2 threshold (50)
  float threshold2Y = height - map(50, 0, 1023, 0, height - 100) - 50;
  line(width - 100, threshold2Y, width - 50, threshold2Y);
  
  // Draw trigger indicators
  // Sensor 1 trigger (value > 90)
  if (sensor1Value > 90) {
    fill(255, 0, 0);
    noStroke();
    ellipse(75, 30, 20, 20);
    if (isDelaying) {
      // Draw pulsing effect during delay
      float pulseSize = 20 + sin(frameCount * 0.1) * 5;
      fill(255, 0, 0, 100);
      ellipse(75, 30, pulseSize, pulseSize);
    }
  }
  
  // Sensor 2 trigger (value > 50)
  if (sensor2Value > 50) {
    fill(0, 255, 0);
    noStroke();
    ellipse(width - 75, 30, 20, 20);
  } else if (sensor2Value <= 50 && isDelaying) {
    // Draw pulsing effect during delay
    fill(0, 255, 0);
    noStroke();
    ellipse(width - 75, 30, 20, 20);
    float pulseSize = 20 + sin(frameCount * 0.1) * 5;
    fill(0, 255, 0, 100);
    ellipse(width - 75, 30, pulseSize, pulseSize);
  }
  
  // Draw labels
  fill(255);
  textAlign(LEFT);
  text("Sensor 1: " + (int)sensor1Value, 50, height - 30);
  textAlign(RIGHT);
  text("Sensor 2: " + (int)sensor2Value, width - 50, height - 30);
  
  // Draw trigger status text only when max threshold is exceeded
  textAlign(CENTER);
  if (sensor1Value > 90) {
    fill(255, 0, 0);
    text("TRIGGERED", 75, 60);
  }
  if (sensor2Value > 50) {
    fill(0, 255, 0);
    text("TRIGGERED", width - 75, 60);
  }
}

void serialEvent(Serial p) {
  if (!serialConnected || !portFound) return;
  
  try {
    String inString = p.readStringUntil('\n');
    if (inString != null) {
      inString = trim(inString);
      
      // Split the string at the colon
      String[] values = split(inString, ':');
      if (values.length == 2) {
        try {
          int firstValue = Integer.parseInt(values[0]);
          int secondValue = Integer.parseInt(values[1]);
          
          // Update animation targets
          targetSensor1Value = firstValue;
          targetSensor2Value = secondValue;
          
          // If either sensor exceeds threshold, send random CC1 value and reset delay
          if (firstValue < 50 || secondValue > 1050) {
            int randomValue = (int)random(10, 128);  // random() is exclusive of max value
            sendMIDI(1, randomValue);
            isDelaying = true;  // Start new delay
            lastTriggerTime = millis();  // Reset the timer
          } 
          // Check if delay has elapsed
          else if (isDelaying && millis() - lastTriggerTime >= 2000) {
            sendMIDI(1, 0);
            isDelaying = false;
          }
          
        } catch (NumberFormatException e) {
          // Invalid number format
        }
      }
    }
  } catch (Exception e) {
    serialConnected = false;
  }
}

void dispose() {
  // Clean up MIDI resources
  if (device != null && device.isOpen()) {
    device.close();
  }
  if (receiver != null) {
    receiver.close();
  }
  // Clean up serial resources
  if (myPort != null) {
    myPort.stop();
  }
} 