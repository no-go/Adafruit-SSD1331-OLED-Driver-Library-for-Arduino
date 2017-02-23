/**
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org>
 */

#define OLED_DC      5
#define OLED_CS     12
#define OLED_RESET   6
#define VBATPIN     A7  // A7 = D9 !!

byte hours   = 11;
byte minutes = 13;
byte seconds = 20;
byte tick    = 0;

struct Pix {
  byte x,y,lastX,lastY;
  void hopp() {
    lastX = x;
    lastY = y; 
  } 
};

Pix secPos;
Pix minPos;
Pix hourPos;

byte batLength = 60;

// Color definitions
#define BLACK           0x0000
#define GREYBLUE        0b0010000100010000
#define BLUE            0x001F
#define RED             0xF800
#define GREEN           0x07E0
#define CYAN            0x07FF
#define MAGENTA         0xF81F
#define YELLOW          0xFFE0  
#define WHITE           0xFFFF

#include <Adafruit_GFX.h>
#include <Adafruit_SSD1331.h>
#include <SPI.h>

Adafruit_SSD1331 oled = Adafruit_SSD1331(OLED_CS, OLED_DC, OLED_RESET);

byte powerTick(int mv) {
  float quot = (5100-2700)/(batLength-3); // scale: 5100 -> batLength, 2710 -> 0
  return (mv-2700)/quot;  
}

int readVcc() {
  float mv = analogRead(VBATPIN);
  mv *= 2;
  mv *= 3.3;
  return powerTick(mv);
}

void anaClock() {
  byte x = 43;
  byte y = 31;
  byte radius = 30;
  int hour = hours;
  if (hour>12) hour-=12;
  secPos.x = x + (radius-1)*cos(PI * ((float)seconds-15.0) / 30);
  secPos.y = y + (radius-1)*sin(PI * ((float)seconds-15.0) / 30);
  minPos.x = x + (radius-4)*cos(PI * ((float)minutes-15.0) / 30);
  minPos.y = y + (radius-4)*sin(PI * ((float)minutes-15.0) / 30);
  hourPos.x =x + (radius-12)*cos(PI * ((float)hour-3.0) / 6);
  hourPos.y =y + (radius-12)*sin(PI * ((float)hour-3.0) / 6);

  // remove old
  oled.drawLine(x, y, secPos.lastX, secPos.lastY, BLACK);
  oled.drawLine(x, y, minPos.lastX, minPos.lastY, BLACK);
  oled.drawLine(x, y, hourPos.lastX, hourPos.lastY, BLACK);

  // draw new ones
  oled.drawLine(x, y, secPos.x, secPos.y, YELLOW);
  oled.drawLine(x, y, minPos.x, minPos.y, GREEN);
  oled.drawLine(x, y, hourPos.x, hourPos.y, RED);
  secPos.hopp();
  minPos.hopp();
  hourPos.hopp();

  // dots
  for (byte i=0; i<12; ++i) {
    oled.drawPixel(x + (radius-3)*cos(PI * ((float)i) / 6), y + (radius-3)*sin(PI * ((float)i) / 6), WHITE);  
  }

  oled.setCursor(x-5,y-radius+4);
  oled.print(12);
  oled.setCursor(x-2,y+radius-11);
  oled.print(6);
  oled.setCursor(x+radius-9,y-3);
  oled.print(3);
  oled.setCursor(x-radius+6,y-3);
  oled.print(9);
}

void ticking() {
  tick++;
  if (tick > 9) {
    seconds += tick/10;
  } 
  if (tick > 9) {
    tick = tick % 10;
    if (seconds > 59) {
      minutes += seconds / 60;
      seconds  = seconds % 60;
    }
    if (minutes > 59) {
      hours  += minutes / 60;
      minutes = minutes % 60;
    }
    if (hours > 23) {
      hours = hours % 24;
    }
  }
}

void battery() {
  byte vccVal = readVcc();
  oled.fillRect(oled.width()-5, oled.height()  - batLength+2, 4, batLength-3, BLACK);
  oled.fillRect(oled.width()-5, oled.height()  - vccVal   -1, 4,      vccVal, GREEN); 
}

void setup() {
  oled.begin();
  oled.setTextColor(CYAN);
  oled.setTextSize(0);
  anaClock();
  oled.fillScreen(GREYBLUE);
  oled.fillCircle(43, 31, 30, BLACK);
  oled.drawCircle(43, 31, 30, WHITE);

  oled.drawPixel(oled.width()-4, oled.height() - batLength, WHITE);
  oled.drawPixel(oled.width()-3, oled.height() - batLength, WHITE);
  oled.drawRect(oled.width()-6, oled.height()  - batLength+1, 6, batLength-1, WHITE);  
  byte pos = oled.height() - powerTick(3000);
  oled.drawLine(oled.width()-9,  pos, oled.width()-6,  pos, WHITE);
  pos = oled.height() - powerTick(3500);
  oled.drawLine(oled.width()-7,  pos, oled.width()-6,  pos, WHITE);
  pos = oled.height() - powerTick(4000);
  oled.drawLine(oled.width()-9,  pos, oled.width()-6,  pos, WHITE);
  pos = oled.height() - powerTick(4500);
  oled.drawLine(oled.width()-7,  pos, oled.width()-6,  pos, WHITE);
}

void loop() {
  delay(100);
  anaClock();
  battery();
  ticking();
}

