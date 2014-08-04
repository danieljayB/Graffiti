/*


  ____              _      _       _               ____            _                     ____   ___  _ _____ 
 |  _ \  __ _ _ __ (_) ___| |     | | __ _ _   _  | __ )  ___ _ __| |_ _ __   ___ _ __  |___ \ / _ \/ |___ / 
 | | | |/ _` | '_ \| |/ _ \ |  _  | |/ _` | | | | |  _ \ / _ \ '__| __| '_ \ / _ \ '__|   __) | | | | | |_ \ 
 | |_| | (_| | | | | |  __/ | | |_| | (_| | |_| | | |_) |  __/ |  | |_| | | |  __/ |     / __/| |_| | |___) |
 |____/ \__,_|_| |_|_|\___|_|  \___/ \__,_|\__, | |____/ \___|_|   \__|_| |_|\___|_|    |_____|\___/|_|____/ 
                                           |___/                                                             
Realtime grafitti spray can interfacing with Arduino, Processing, and TUIO client sending OSC messages. 
For a demonstration, refer here: https://vimeo.com/76232143


*/


import TUIO.*;
TuioProcessing tuioClient;

import java.util.*;
import processing.serial.*;
import cc.arduino.*;

Arduino arduino;


ColorDrop[] drops, delDrops;

color pencil; // color of the spray painter
int dropAlpha = 255;
int randomDrop = 2; // percentaged possibility to generate a color drop

float oldX, oldY;


float cursor_size = 15;
float object_size = 60;
float table_size = 760;
float scale_factor = 10;
PFont font;


final static int DELAY = 1000;

int nextTimer, counter;


int ledRed = 9;
int ledGreen = 10;
int ledBlue = 11;
int button = 2;
int IRLED = 13;


int pot1 = 0;
int pot2 = 1;
int pot3 = 2;

// --- setup procedure ---
void setup() {
  size(1024, 768);
  frameRate(60);
  
    println(Arduino.list());

    arduino = new Arduino(this, Arduino.list()[14], 57600);
    arduino.pinMode(ledRed, Arduino.OUTPUT);
     arduino.pinMode(ledGreen, Arduino.OUTPUT);

 arduino.pinMode(ledBlue, Arduino.OUTPUT);


 arduino.pinMode(IRLED, Arduino.OUTPUT);

 arduino.pinMode(button, Arduino.INPUT);



  font = createFont("Arial", 18);
  scale_factor = height/table_size;
  
  // we create an instance of the TuioProcessing client
  // since we add "this" class as an argument the TuioProcessing class expects
  // an implementation of the TUIO callback methods (see below)
  tuioClient  = new TuioProcessing(this);
  
  //fullscreenGraffiti = new FullScreen(this);
  //fullscreenGraffiti.enter();

  drops = new ColorDrop[0];
  delDrops = new ColorDrop[0];

  stroke(pencil, dropAlpha);
  strokeWeight(20);
  background(0);
  smooth();
}

// --- draw procedure ---
void draw() {
  
  
  
  
  int buttonState = arduino.digitalRead(button);
  
 float pot1Val = arduino.analogRead(pot1);
   float pot2Val = arduino.analogRead(pot2);

  float pot3Val = arduino.analogRead(pot3);
  
  float redKnob = map(pot1Val, 0, 1023, 0, 255);
float GreenKnob = map(pot2Val, 0, 1023, 0, 255);

float BlueKnob = map(pot3Val, 0, 1023, 0, 255);
pencil = color(redKnob, GreenKnob, BlueKnob);


arduino.analogWrite(ledRed, int(redKnob));
arduino.analogWrite(ledGreen, int(GreenKnob));

arduino.analogWrite(ledBlue, int(BlueKnob));


if(buttonState==1){
  
  arduino.digitalWrite(IRLED,Arduino.HIGH);
  
}
else{
  
  
  arduino.digitalWrite(IRLED,Arduino.LOW);
  
}
  
  
  
  for (int i = 0; i < drops.length; i++) {
    if (drops[i].moveDrop())
      drops[i].drawDrop();
  }

  stroke(100);
  strokeWeight(1);
  noFill();
  rect(0, 0, width-1, height-1);


textFont(font,18*scale_factor);
  float obj_size = object_size*scale_factor; 
  float cur_size = cursor_size*scale_factor; 
   
  Vector tuioObjectList = tuioClient.getTuioObjects();
  for (int i=0;i<tuioObjectList.size();i++) {
     TuioObject tobj = (TuioObject)tuioObjectList.elementAt(i);
     stroke(0);
     fill(0);
     pushMatrix();
     translate(tobj.getScreenX(width),tobj.getScreenY(height));
     rotate(tobj.getAngle());
     rect(-obj_size/2,-obj_size/2,obj_size,obj_size);
     popMatrix();
     fill(255);
     text(""+tobj.getSymbolID(), tobj.getScreenX(width), tobj.getScreenY(height));
   }
   
   Vector tuioCursorList = tuioClient.getTuioCursors();
   for (int i=0;i<tuioCursorList.size();i++) {
      TuioCursor tcur = (TuioCursor)tuioCursorList.elementAt(i);
      Vector pointList = tcur.getPath();
      
      if (pointList.size()>0) {
        stroke(0,0,255);
        TuioPoint start_point = (TuioPoint)pointList.firstElement();;
        for (int j=0;j<pointList.size();j++) {
           TuioPoint end_point = (TuioPoint)pointList.elementAt(j);
           start_point = end_point;
           
           
    // normal spray drawing foo
    stroke(pencil, dropAlpha);
    strokeWeight(20);
           line(oldX, oldY,oldX, oldY);

    // drop generating
    int randomValueForDrop = floor(random(0, 5000));
    if (randomValueForDrop < randomDrop) {
      ColorDrop setDrop = new ColorDrop(start_point.getScreenX(width),end_point.getScreenY(height), pencil);
      drops = (ColorDrop[]) append(drops, setDrop);
    
    
  }
  oldX = start_point.getScreenX(width);
  oldY = start_point.getScreenY(height);
  
if(start_point.getScreenX(width) ==RIGHT){
    drops = delDrops;
    background(0);
  //counter=0;
        }
        
  
  
        }
        
       // stroke(192,192,192);
       // fill(192,192,192);
       // ellipse( tcur.getScreenX(width), tcur.getScreenY(height),cur_size,cur_size);
        //fill(0);
       // text(""+ tcur.getCursorID(),  tcur.getScreenX(width)-5,  tcur.getScreenY(height)+5);
      }
   }

}


// called when an object is added to the scene
void addTuioObject(TuioObject tobj) {
  println("add object "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle());
}

// called when an object is removed from the scene
void removeTuioObject(TuioObject tobj) {
  println("remove object "+tobj.getSymbolID()+" ("+tobj.getSessionID()+")");
}

// called when an object is moved
void updateTuioObject (TuioObject tobj) {
  println("update object "+tobj.getSymbolID()+" ("+tobj.getSessionID()+") "+tobj.getX()+" "+tobj.getY()+" "+tobj.getAngle()
          +" "+tobj.getMotionSpeed()+" "+tobj.getRotationSpeed()+" "+tobj.getMotionAccel()+" "+tobj.getRotationAccel());
}

// called when a cursor is added to the scene
void addTuioCursor(TuioCursor tcur) {
  println("add cursor "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY());
}

// called when a cursor is moved
void updateTuioCursor (TuioCursor tcur) {
  println("update cursor "+tcur.getCursorID()+" ("+tcur.getSessionID()+ ") " +tcur.getX()+" "+tcur.getY()
          +" "+tcur.getMotionSpeed()+" "+tcur.getMotionAccel());
}

// called when a cursor is removed from the scene
void removeTuioCursor(TuioCursor tcur) {
  println("remove cursor "+tcur.getCursorID()+" ("+tcur.getSessionID()+")");
}

// called after each message bundle
// representing the end of an image frame
void refresh(TuioTime bundleTime) { 
  redraw();
}

