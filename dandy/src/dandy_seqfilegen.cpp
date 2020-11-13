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
  if (argc < 6) {
    cout << "Remote Control Dandy sequential file packer" << endl;
    cout << "Usage: " << argv[0] << " [inprefix] [numfiles] [outfile]"
      << " [asmlabelprefix] [outasmindex]" << endl;
    
    return 0;
  }
  
  string inPrefix(argv[1]);
  int numFiles = TStringConversion::stringToInt(std::string(argv[2]));
  string outFile(argv[3]);
  string asmLabelPrefix(argv[4]);
  string outAsmIndex(argv[5]);
  
//  bool grayscale = TOpt::hasFlag(argc, argv, "-grayscale");
//  bool transparency = TOpt::hasFlag(argc, argv, "-transparency");
//  bool semiTransparency = TOpt::hasFlag(argc, argv, "-semitransparency");
//  int initialOffset = 0;
//  TOpt::readNumericOpt(argc, argv, "-initialoffset", &initialOffset);

  TBufStream ofs;
  
  std::ofstream asmOfs(outAsmIndex.c_str());

  for (int i = 0; i < numFiles; i++) {
    std::string namePrefix = inPrefix + TStringConversion::intToString(i)
      + ".bin";
    TBufStream ifs;
    ifs.open(namePrefix.c_str());
    
    int startPos = ofs.tell();
//    img.write(ofs);
    ofs.write(ifs.data().data(), ifs.size());
//    int endPos = ofs.tell();
    
    asmOfs << asmLabelPrefix << "_file" << std::dec << i
      << " equ " << TStringConversion
      ::intToString(startPos, TStringConversion::baseHex)
      << std::endl;
  }
  
  ofs.save(outFile.c_str());
  
  return 0;
}
