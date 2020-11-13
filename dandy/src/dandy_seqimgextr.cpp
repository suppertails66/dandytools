#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TFileManip.h"
#include "util/TSort.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TOpt.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include "dandy/DandyImg.h"
#include "dandy/DandyImgExtr.h"
#include <algorithm>
#include <vector>
#include <string>
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

string as2bHexPrefix(int num) {
  return "$" + as2bHex(num) + "";
}

int fontCharW = 16;
int fontCharH = 16;
int bytesPerFontChar = (fontCharW * fontCharH) / 2;

int charactersPerRow = 16;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Remote Control Dandy sequential image extractor" << endl;
    cout << "Usage: " << argv[0] << " [image] [outprefix]" << endl;
    cout << "Options: " << endl;
    cout << "  -grayscale         Force grayscale output even if a palette exists"
      << endl;
    cout << "  -transparency      Enable transparency (disabled by default)"
      << endl;
    cout << "  -semitransparency  Enable semitransparency (disabled by default)"
      << endl;
    cout << "  -initialoffset [x] Skip X bytes at start of file"
      << endl;
    
    return 0;
  }
  
  string imageName(argv[1]);
  string outPrefix(argv[2]);
  
  bool grayscale = TOpt::hasFlag(argc, argv, "-grayscale");
  bool transparency = TOpt::hasFlag(argc, argv, "-transparency");
  bool semiTransparency = TOpt::hasFlag(argc, argv, "-semitransparency");
  int initialOffset = 0;
  TOpt::readNumericOpt(argc, argv, "-initialoffset", &initialOffset);
  
  TBufStream ifs;
  ifs.open(imageName.c_str());
  ifs.seekoff(initialOffset);
  
  int num = 0;
  while (!ifs.eof()) {
    DandyImg img;
    
    img.setGrayscale(grayscale);
    img.setTransparency(transparency);
    img.setSemiTransparency(semiTransparency);
    
    img.read(ifs);
    img.save((outPrefix + TStringConversion::intToString(num)).c_str());
    ++num;
  }
  
  return 0;
}
