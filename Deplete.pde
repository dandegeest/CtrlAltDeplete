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
        
        // Initialize all CC values to 64
        for (int i = 1; i <= 5; i++) {
          ccValues[i] = 64;
          sendMIDI(i, 64);
        }
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
  
  // Draw HUD-style interface
  drawHUD();
  
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

void serialEvent(Serial p) {
  if (!serialConnected || !portFound) return;
  
  try {
    String inString = p.readStringUntil('\n');
    if (inString != null) {
      inString = trim(inString);
      println("Received: " + inString);
      
      // Split the string at the colon
      String[] values = split(inString, ':');
      if (values.length == 2) {
        try {
          int firstValue = Integer.parseInt(values[0]);
          int secondValue = Integer.parseInt(values[1]);
          
          // If first value > 90, start delay timer
          if (firstValue > 90 && !isDelaying) {
            isDelaying = true;
            lastTriggerTime = millis();
            println("Starting 2-second delay");
          }
          
          // Check if delay has elapsed
          if (isDelaying && millis() - lastTriggerTime >= 2000) {
            sendMIDI(1, 0);
            isDelaying = false;
            println("Delay complete, sent CC1 0");
          }
          
          // If value is 90 or less, send random value
          if (firstValue <= 90) {
            int randomValue = (int)random(10, 128);
            sendMIDI(1, randomValue);
          }
        } catch (NumberFormatException e) {
          println("Invalid number format: " + inString);
        }
      } else {
        println("Invalid format: " + inString);
      }
    }
  } catch (Exception e) {
    println("Error reading serial: " + e.getMessage());
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