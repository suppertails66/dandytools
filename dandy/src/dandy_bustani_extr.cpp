#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TFileManip.h"
#include "util/TSort.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include "dandy/DandyPac.h"
#include "dandy/DandyCmp.h"
#include "dandy/DandyImg.h"
#include "dandy/DandyImgArc.h"
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
    cout << "Remote Control Dandy partial bust-up animation extractor"
      << endl;
    cout << "Usage: " << argv[0] << " [infile] [outprefix]" << endl;
    
    return 0;
  }
  
  string inName(argv[1]);
  string outPrefix(argv[2]);
  
  TBufStream ifs;
  ifs.open(inName.c_str());
  
  int firstOffset = ifs.readu32le();
  if (firstOffset != 0x10) {
    std::cerr << "Not a valid bustani file" << std::endl;
    return 1;
  }
  
//  int secondOffset = ifs.readu32le();
  
  ifs.seek(firstOffset);
  
  {
    DandyImgArc::unpackDecompressed(ifs, (outPrefix + "-grp-").c_str());
  }
  
  
  return 0;
}
