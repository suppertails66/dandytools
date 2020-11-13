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
  if (argc < 2) {
    std::cout << "Remote Control Dandy script dumper" << std::endl;
    std::cout << "Usage: " << argv[0] << " [outprefix]" << std::endl;
    
    return 0;
  }
  
  std::string outprefix = std::string(argv[1]);
  
  try {
    
    DandyScriptScanner scanner;
    
    for (int i = 5; i <= 103; i++) {
//    for (int i = 5; i <= 7; i++) {
      std::string numstr = TStringConversion::intToString(i);
      std::string filename
        = std::string("files_unpacked/ADV/") + numstr + "/0.bin";
      TBufStream ifs;
      ifs.open(filename.c_str());
      while (numstr.size() < 3) numstr = "0" + numstr;
      scanner.scanScript(ifs, numstr);
    }
    
//    scanner.exportMasterFont("font.png");
    
//    TGraphic srcGrp;
//    TPngConversion::RGBAPngToGraphic("font.png", srcGrp);
    
    TThingyTable dandyTable;
    dandyTable.readSjis("table/dandy.tbl");
    
    std::ofstream ofs((outprefix + "script.txt").c_str(),
                      std::ios_base::binary);
//    TBufStream ofs;
    scanner.exportSimpleScript(ofs, dandyTable);
//    ofs.save((outprefix + "script.txt").c_str());
  }
  catch (TGenericException& e) {
    std::cerr << "Exception: " << e.problem() << std::endl;
    return 1;
  }
  
  
  
  return 0;
}
