import processing.serial.*;
import javax.sound.midi.*;

Serial myPort;  // Serial port object
MidiDevice device;  // MIDI device
Receiver receiver;  // MIDI receiver
Sequencer sequencer;  // MIDI sequencer

// Configuration
String loopMIDIPort = "MiDDi";  // Name of the loopMIDI port
String targetCOMPort = "COM6";  // Name of the COM port to connect to

// Status flags
boolean serialConnected = false;
boolean midiConnected = false;
boolean portFound = false;

// MIDI parameters
int currentCC = 1;  // Default CC number
int currentValue = 0;  // Current MIDI value (0-127)

// Mouse control
boolean mousePressed = false;
int lastMouseY = 0;

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
  fill(255);
  textAlign(CENTER);
  textSize(20);
  text("MIDI Controller", width/2, 40);
  
  // Display connection status
  textSize(14);
  text("Serial Status: " + getSerialStatus(), width/2, 80);
  text("MIDI Status: " + (midiConnected ? "Connected" : "Not Connected"), width/2, 100);
  text("MIDI CC: " + currentCC, width/2, 140);
  text("MIDI Value: " + currentValue, width/2, 160);
  text("Press '1-4' to change CC number", width/2, 200);
  text("Click and drag to send MIDI", width/2, 220);
  
  // Display port information
  textSize(12);
  text("Target COM Port: " + targetCOMPort, width/2, 240);
  if (!portFound) {
    text("Port not found!", width/2, 260);
  }
  
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
    sendMIDI(currentCC, currentValue);
  }
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
    sendMIDI(currentCC, currentValue);
  }
}

void keyPressed() {
  // Change CC number with keys 1-4
  if (key >= '1' && key <= '4') {
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
      // Map serial value to MIDI range (0-127)
      try {
        int value = Integer.parseInt(inString);
        currentValue = (int)map(value, 0, 1023, 0, 127);
        sendMIDI(currentCC, currentValue);
      } catch (NumberFormatException e) {
        println("Not a number: " + inString);
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