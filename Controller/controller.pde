/**
Some comment
*/

import processing.serial.*;

import javax.swing.*;
import ddf.minim.analysis.*;
import ddf.minim.*;

Serial port;
Minim minim;
AudioInput in;
FFT fft;

// Visualizer efaults
float valScale = 20.0;
float maxVisible = 10.0;
float beatThreshold = 0.25;
float brightness = 250;
float colorOffset = -20;
float autoColorOffset = 0.0;

// Show text if recently adjusted
boolean showscale = true;
boolean showBeatThreshold = false;
boolean showHelp = false;
boolean showBrightness = false;
boolean isExit = false;

float beatH = 0;
float beatS = 0;
float beatB = 0;
float arduinoBeatB = 0;

float[] lastY;
float[] lastVal;

int buffer_size = 1024;  // also sets FFT size (frequency resolution)
float sample_rate = 44100;


boolean fullscreen = false;
int lastWidth = 0;
int lastHeight = 0;



void setup() {

  size(500, 300);
  frame.setResizable(true);
  
  background(0);
  
  minim = new Minim(this);
  in = minim.getLineIn(Minim.MONO,buffer_size,sample_rate);
  
  fft = new FFT(in.bufferSize(), in.sampleRate());
  fft.logAverages(16, 2);
  fft.window(FFT.HAMMING);
  
  lastY = new float[fft.avgSize()];
  lastVal = new float[fft.avgSize()];
  initLasts();
  port = new Serial(this, Serial.list()[1],4800); 
  textSize(10);
  printArray(Serial.list());
  frame.setAlwaysOnTop(true);

}

int leftBorder()   { return int(.05 * width); }
int rightBorder()  { return int(.05 * width); }
int bottomBorder() { return int(.05 * width); }
int topBorder()    { return int(.05 * width); }


void initLasts()
{
  println(fft.avgSize());
  for(int i = 0; i < fft.avgSize(); i++) {
    
    lastY[i] = height - bottomBorder();
    lastVal[i] = 0;
  }
  
}

void draw() {
   
    colorMode(RGB);
    //this.frame.setVisible(false);
    // Detect resizes
    if(width != lastWidth || height != lastHeight)
    {
      lastWidth = width;
      lastHeight = height;
      background(0);
      initLasts();
      println("resized");
    }
  
    // Slowly erase the screen
    fill(0,20 * 100/frameRate); // Based on 60fps
    rect(0,0,width,height - 0.8*bottomBorder());
  
    colorMode(HSB, 100);
  
    fft.forward(in.mix);
    smooth();
    noStroke();
    
    
    int iCount = fft.avgSize();
    float barHeight =  0.03*(height-topBorder()-bottomBorder());
    float barWidth = (width-leftBorder()-rightBorder())/iCount;
    
    float biggestValChange = 0;
    float noiseVal = 0;
    float biggestVal = 0;

    float volume = in.left.level()*10000;
    for(int i = 0; i < iCount; i++) {
      
      float iPercent = 1.0*i/iCount;
      
      float highFreqscale = 1.0 + pow(iPercent, 4) * 2.0;
      
      float val = sqrt(fft.getAvg(i)) * valScale * highFreqscale / maxVisible;

      
      float y = height - bottomBorder() - val * (height - bottomBorder() - topBorder());
      float x = leftBorder() + iPercent * (width - leftBorder() - rightBorder()) ;
      
      float h = 100 - (100.0 * iPercent*(iCount/11.1) + colorOffset) % 100;
      float s = 70 - pow(val, 3) * 70;
      float b = 100;
      fill(h, s, b);
      textAlign(CENTER, BOTTOM);
      text(nf(int(100*val),2), x+barWidth/2, y);
           
      rectMode(CORNERS);
      rect(x, y+barHeight/2, x+barWidth, lastY[i]+barHeight/2);
      
  
      float valDiff = val-lastVal[i];
      noiseVal = valDiff;
      if(valDiff > beatThreshold && valDiff > biggestValChange && volume > 1)
      {
        biggestValChange = valDiff;
        beatH = h;
        beatS = s;
        beatB = b;
        biggestVal = val;
      }
      
      lastY[i] = y;
      lastVal[i] = val;

    }
    //println(noiseVal);
    if (biggestVal > 0.9 || (biggestVal < 0.6 && biggestVal >0))
        valScale = valScale * (0.70/biggestVal);
    // If we've hit a beat, bring the brightness of the bar up to full
    if(biggestValChange > beatThreshold)
    {
      arduinoBeatB = 90;
    }  
    
    // calculate the arduino beat color
    color c_hsb = color(beatH, 100, constrain(arduinoBeatB, 0, 100));
    
    int r = int(red(c_hsb) / 100 * brightness);
    int g = int(green(c_hsb) / 100 * brightness);
    int b = int(blue(c_hsb) / 100 * brightness);
   
     //send to serial
      port.write(255); //write marker (0xff) for synchronization
      port.write((byte)r);
      port.write((byte)g);
      port.write((byte)b);
      //0port.write((byte)0);
    //println(r + ", "+g + ", "+b + ", ");
    // clear out the message area
    fill(0);
    rect(0, height - 0.8*bottomBorder(), width, height);
    
    // draw the beat bar
    colorMode(RGB, 255);
    fill(r, g, b);
    rect(leftBorder(), height - 0.8*bottomBorder(), width-rightBorder(), height - .5*bottomBorder());


    // Decay the arduino beat brightness (based on 60 fps)
    arduinoBeatB *= 1.0   - 0.02 * 60/frameRate;
    
    // Automatically advance the color
    colorOffset += autoColorOffset;
    colorOffset %= 100;
    
    //delay(20);
    
    // Show the scale if it was adjusted recently
    if(showscale)
    {
      fill(255,255,255);
      textAlign(RIGHT, TOP);
      text("scale:"+nf(valScale,1,1), width-rightBorder(), topBorder()+10);
      //showscale=false;
    }
    
    // Show the beat threshold if it was adjusted recently
    if(showBeatThreshold)
    {
      fill(255,255,255);
      textAlign(RIGHT, TOP);
      text("beat threshold:"+nf(beatThreshold,1,2), width-rightBorder(), topBorder());
      showBeatThreshold=false;
    }
    if(showBrightness)
    {
      fill(255,255,255);
      textAlign(RIGHT, TOP);
      text("brightness:"+nf(brightness,1,0), width-rightBorder(), topBorder());
      showBrightness=false;
    }
     
    // Show the help
    if(showHelp)
    {
      fill(255,255,255);
      textAlign(RIGHT, TOP);
      text("Help:\nUP/DOWN arrows = Scale Visualizer\n" + 
           "LEFT/RIGHT arrows = Temporarily shift colors\n" + 
           "+/- = Beat Detection Sensitivity\n" + 
           "TAB = Use Next Arduino Port\n" + 
           "SPACE = Toggle full-screen\n" + 
           "Anything Else = Show this help", width-rightBorder(), topBorder());
      showHelp=false;
    }
     
    // Display the frame rate
    fill(16, 16, 16);
    textAlign(RIGHT, BOTTOM);
    text(nf(frameRate,2,1) + " fps", width - rightBorder(), topBorder());
    if(!fullscreen)
    {
    surface.setTitle("Music Visualizer ("+nf(frameRate,2,1)+" fps)");
    }
    if(isExit)
     port.stop();
}

void keyReleased()
{
  if (key == CODED)
  {
   if (keyCode == UP)
   {
     if (brightness < 250)
       brightness += 10;
     showBrightness=true;
   }
   else if (keyCode == DOWN)
   {
     if (brightness > 0)
       brightness -= 10;
     showBrightness = true;
   }
   else if (keyCode == RIGHT)
   {
     colorOffset -= 5;
   }
   else if (keyCode == LEFT)
   {
     colorOffset += 5;
   }
  }
  else
  {
    if (key == '+')
    {
      beatThreshold += 0.05;
      showBeatThreshold=true;
    }
    else if (key == '-')
    {
      beatThreshold -= 0.05;
      showBeatThreshold=true;
    }
    else
    {
      showHelp = true;
    }
  } 
}




void exit()
{
  isExit = true;
  port.write(50);
  port.write(50);
  port.write(50);
  port.write(50);  
  // always close Minim audio classes when you finish with them
  in.close();
  minim.stop();
  super.exit();
  
}