#include <Adafruit_NeoPixel.h>

#define centerLED 29

int array[5] =    {250,150,50,20,0};

int r = 0;
int g = 0;
int b = 0;
int wait = 12;
int test = 0;
int posB = 0;
int posR = 59;
int posG = 23;
boolean reverseB = false;
boolean reverseR = false;
boolean reverseG = true;
boolean connected  = false;
boolean booted = false;

Adafruit_NeoPixel pixels = Adafruit_NeoPixel(60,7,NEO_GRBW + NEO_KHZ800);

void setup ()
{  
   Serial.begin(4800);
   pixels.begin(); 
   int amount = pixels.numPixels()*2/3;
}
  
  void loop()
{
    if (booted == false){
     posR = BootStripes(1,posR,reverseR);
     posG = BootStripes(2,posG,reverseG);
     posB = BootStripes(3,posB,reverseB);
    }

    if (Serial.available() > 3){
      test = Serial.read();
      booted = true;
      if(test == 255)
        Visualizer();
      else if(test == 50)
        rainbowCycle();
      else if(test == 49)
        ClearStrand();
    }
     pixels.show();
  }
  
  
 void rainbowCycle() {
  uint16_t i, j;

  for(j=0; j<256*5; j++) { // 5 cycles of all colors on wheel
    for(i=0; i< pixels.numPixels(); i++) {
      pixels.setPixelColor(i, Wheel(((i * 256 / pixels.numPixels()) + j) & 255));
      if (Serial.available() > 3)
        return;
    }
    pixels.show();
    delay(wait);
  }
}

 void Visualizer(){

    r= Serial.read();
    g= Serial.read();
    b= Serial.read();
  
     for (int i = pixels.numPixels(); i > centerLED; i--){
      uint32_t color = pixels.getPixelColor(i-1);
      pixels.setPixelColor(i, color);
    }
     for (int i = 0; i < centerLED; i++){
      uint32_t color = pixels.getPixelColor(i+1);
      pixels.setPixelColor(i, color);
    }
    pixels.setPixelColor(centerLED, pixels.Color((int)r,(int)g,(int)b,0));
 }
 
  int BootStripes(int sel,int pos, boolean& reverse){
       for (int j = 0; j <5; j++){
          uint32_t color = pixels.Color(0,0,array[j],0);
          pixels.setPixelColor(pos+j, AddColor(pixels.getPixelColor(pos+j),array[j],sel));
          pixels.setPixelColor(pos-j, AddColor(pixels.getPixelColor(pos-j),array[j],sel));
       }
       delay(wait);
       if (pos <= 0)
         reverse = true;
       if (pos >= pixels.numPixels())
         reverse = false;
       if (reverse == false)
         pos--;
       else 
         pos++;
      return pos;
 }
 
 void ClearStrand(){
   for (int i = 0; i < pixels.numPixels(); i++)
     pixels.setPixelColor(i, pixels.Color(0,0,0,0));
 }
 
 uint8_t GetColor(uint32_t color, int sel){
     uint8_t result = 0;
     if (sel == 1)
       color = color<<8;
     if (sel == 2)
       color = color<<16;
     if (sel == 3)
       color = color<<24;
     result = color>>24;
     return result;
 }
uint32_t AddColor(uint32_t base, uint8_t add, int sel){ 
  return AddColor(base,add,sel,false);
}
 
uint32_t AddColor(uint32_t base, uint8_t add, int sel, boolean ammend){
    uint32_t correction = 255;
    uint32_t addbig = (uint32_t)add;
    int shift[4] = {24,16,8,0}; 
    if (ammend == false)
      base =(~(correction<<shift[sel]))&base;
    addbig = (uint32_t)add << shift[sel];
    uint32_t result = base | addbig;
    return result; 
}

uint32_t Wheel(byte WheelPos) {
  WheelPos = 255 - WheelPos;
  if(WheelPos < 85) {
    return pixels.Color(255 - WheelPos * 3, 0, WheelPos * 3);
  }
  if(WheelPos < 170) {
    WheelPos -= 85;
    return pixels.Color(0, WheelPos * 3, 255 - WheelPos * 3);
  }
  WheelPos -= 170;
  return pixels.Color(WheelPos * 3, 255 - WheelPos * 3, 0);
}
   
