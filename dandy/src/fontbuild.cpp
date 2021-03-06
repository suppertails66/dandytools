#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TIniFile.h"
#include "util/TBufStream.h"
#include "util/TOfstream.h"
#include "util/TIfstream.h"
#include "util/TStringConversion.h"
#include "util/TBitmapFont.h"
#include <iostream>
#include <vector>

using namespace std;
using namespace BlackT;

const static int charW = 12;
const static int charH = 12;

void charToData(const TGraphic& src,
                int xOffset, int yOffset,
                TStream& ofs) {
  for (int j = 0; j < charH; j++) {
    int output = 0;
    
    int mask = 0x8000;
    for (int i = 0; i < charW; i++) {
      int x = xOffset + i;
      int y = yOffset + j;
      TColor color = src.getPixel(x, y);
      
      if ((color.a() == TColor::fullAlphaTransparency)
          || (color.r() < 0x80)) {
        
      }
      else {
        output |= mask;
      }
      
      mask >>= 1;
    }
    
    ofs.writeu16be(output);
  }
}

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Remote Control Dandy font builder" << endl;
    cout << "Usage: " << argv[0] << " <font> <maxchars> <outwidthfile>"
      << endl;
    
    return 0;
  }
  
  string fontName(argv[1]);
//  string outFontFileName(argv[2]);
  int maxChars = TStringConversion::stringToInt(string(argv[2]));
  string outWidthFileName(argv[3]);
  
  TBitmapFont font;
  font.load(fontName);
  
//  TBufStream fontofs;
  TBufStream widthofs;
  
//  if (font.numFontChars() < maxChars) maxChars = font.numFontChars();
  
//  for (int i = 0; i < maxChars; i++) {
  for (int i = 0; i < font.numFontChars(); i++) {
    const TBitmapFontChar& fontChar = font.fontChar(i);
    int width = fontChar.advanceWidth;
    
//    charToData(fontChar.grp, 0, 0, fontofs);
    widthofs.writeu8(width);
  }
  
  int extraSlots = maxChars - font.numFontChars();
  for (int i = 0; i < extraSlots; i++) {
    widthofs.writeu8(0);
  }
  
//  fontofs.save(outFontFileName.c_str());
  widthofs.save(outWidthFileName.c_str());
  
  return 0;
}
