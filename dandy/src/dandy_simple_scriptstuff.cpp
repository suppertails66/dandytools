#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TFileManip.h"
#include "util/TSort.h"
#include "util/TGraphic.h"
#include "util/TColor.h"
#include "util/TPngConversion.h"
#include "util/TBitmapFont.h"
#include "util/TThingyTable.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include "dandy/DandyPac.h"
#include "dandy/DandyScriptScanner.h"
#include <algorithm>
#include <vector>
#include <string>
#include <map>
#include <iostream>
#include <iomanip>
#include <cmath>

using namespace std;
using namespace BlackT;
//using namespace Discaster;
using namespace Psx;

string as3bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 3) str = string("0") + str;
  
//  return "<$" + str + ">";
  return str;
}

string as2bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 2) str = string("0") + str;
  
//  return "<$" + str + ">";
  return str;
}

string as1bHex(int num) {
  string str = TStringConversion::intToString(num,
                  TStringConversion::baseHex).substr(2, string::npos);
  while (str.size() < 1) str = string("0") + str;
  
//  return "<$" + str + ">";
  return str;
}

string as2bHexPrefix(int num) {
  return "$" + as2bHex(num) + "";
}

int fontCharW = 16;
int fontCharH = 16;
int bytesPerFontChar = (fontCharW * fontCharH) / 2;

int charactersPerRow = 16;

std::map<int, TColor> colorTable;

int main(int argc, char* argv[]) {
/*  TBufStream ifs;
  ifs.open(argv[1]);
  
  ifs.seek(0x14);
  double colorScale = (double)255 / (double)31;
  for (int i = 0; i < 0x100; i++) {
    int rawColor = ifs.readu16le();
    
    int r = ((rawColor & (0x1F << 0)) >> 0) * colorScale;
    int g = ((rawColor & (0x1F << 5)) >> 5) * colorScale;
    int b = ((rawColor & (0x1F << 10)) >> 10) * colorScale;
    
    TColor color(r, g, b);
    colorTable[i] = color;
  }
  
  ifs.seekoff(1);
  int w = ifs.readu16le();
  w = 320;
  ifs.seek(0x21E);
  int h = ifs.readu16le();
  
  TGraphic grp(w, h);
  grp.clearTransparent();
  
  for (int j = 0; j < h; j++) {
    for (int i = 0; i < w; i++) {
      grp.setPixel(i, j, colorTable[ifs.readu8()]);
    }
  }
  
  TPngConversion::graphicToRGBAPng(argv[2], grp); */
  
  try {
    TBufStream ifs;
    
    DandyScriptScanner scanner;
    
    for (int i = 5; i <= 103; i++) {
      std::string numstr = TStringConversion::intToString(i);
      std::string filename
        = std::string("files_unpacked/ADV/") + numstr + "/0.bin";
      ifs.open(filename.c_str());
      while (numstr.size() < 3) numstr = "0" + numstr;
      scanner.scanScript(ifs, numstr);
    }
    
    scanner.exportMasterFont("font.png");
    
    TGraphic srcGrp;
    TPngConversion::RGBAPngToGraphic("font.png", srcGrp);
    
    // black out known chars
    TThingyTable dandyTable;
    dandyTable.readSjis("table/dandy.tbl");
//    int unknownCharCount = 0;
    for (unsigned int j = 0; j < scanner.masterFont.fontChars.size(); j++) {
      if (!dandyTable.hasEntry(j)) continue;
      
      srcGrp.fillRect((j % 16) * 16, (j / 16) * 16,
                      16, 16,
                      TColor(0, 0, 0));
//      ++unknownCharCount;
    }
//    std::cerr << unknownCharCount << std::endl;
    
    TBitmapFont font;
    font.load("font/12px/");
    
    TThingyTable table;
    table.readSjis("font/12px/table.tbl");
//    table.readSjis("table/ascii.tbl");
    
    TGraphic grp(srcGrp.w() + 16, srcGrp.h() + 16);
    grp.clear(TColor(0, 0, 0));
    grp.copy(srcGrp,
             TRect(16, 16, 0, 0), TGraphic::transUpdate);
    int numRows = srcGrp.h() / 16;
    for (int j = 0; j < numRows; j++) {
      TGraphic label;
      
      TBufStream ifs;
      ifs.writeString(as2bHex(j));
      ifs.seek(0);
      
      font.render(label, ifs, table);
      label.regenerateTransparencyModel();
      
      int y = (j * 16) + 16 + (8 - (label.h() / 2));
      grp.blit(label,
               TRect((8 - (label.w() / 2)) - 2, y, 0, 0),
               TRect(0, 0, 0, 0), TGraphic::transUpdate);
    }
    
    for (int i = 0; i < 16; i++) {
      TGraphic label;
      
      TBufStream ifs;
      ifs.writeString(as1bHex(i));
      ifs.seek(0);
      
      font.render(label, ifs, table);
      label.regenerateTransparencyModel();
      
      int x = (i * 16) + 16 + (8 - (label.w() / 2));
      grp.blit(label,
               TRect(x, (8 - (label.h() / 2)) - 1, 0, 0),
               TRect(0, 0, 0, 0), TGraphic::transUpdate);
    }
    
    grp.drawLine(13, 13,
                 grp.w(), 13,
                 TColor(255, 255, 255),
                 1);
    grp.drawLine(13, 13,
                 13, grp.h(),
                 TColor(255, 255, 255),
                 1);
    
    TPngConversion::graphicToRGBAPng("font.png", grp);
    
    TBufStream scriptOfs;
    scanner.saveScript(scriptOfs);
    scriptOfs.save("script_raw.bin");
  }
  catch (TGenericException& e) {
    std::cerr << "Exception: " << e.problem() << std::endl;
    return 1;
  }
  
  
  
  return 0;
}
