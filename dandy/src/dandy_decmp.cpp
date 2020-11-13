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
    cout << "Remote Control Dandy file decompressor" << endl;
    cout << "Usage: " << argv[0] << " [infile] [outfile]" << endl;
    
    return 0;
  }
  
  string inName(argv[1]);
  string outName(argv[2]);
  
  TBufStream ifs;
  ifs.open(inName.c_str());
  TBufStream ofs;
  
  std::cout << "Decompressing: " << inName << std::endl;
  
//  TOfstream ofs(outName.c_str(), ios_base::binary);
//  try {
    DandyCmp::decmp(ifs, ofs);
//  }
//  catch (...) {
//    ofs.save(outName.c_str());
//  }
  
  ofs.save(outName.c_str());
  
  return 0;
}
