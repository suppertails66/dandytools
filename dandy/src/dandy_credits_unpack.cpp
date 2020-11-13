#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TFileManip.h"
#include "util/TSort.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "dandy/DandyCmp.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include "psx/PsxBitmap.h"
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

PsxBitmap::Format getFormatOfNumber(int num) {
  switch (num) {
  case 16:
    return PsxBitmap::format_rgb;
    break;
  case 2:
    return PsxBitmap::format_2bit;
    break;
  case 4:
    return PsxBitmap::format_4bit;
    break;
  case 8:
    return PsxBitmap::format_8bit;
    break;
  default:
    throw TGenericException(T_SRCANDLINE,
                            "getFormatOfNumber()",
                            std::string("Unknown format code: ")
                            + TStringConversion::intToString(num));
    break;
  }
}

const static int rowWidth = 320;
const static int rowHeight = 16;

int main(int argc, char* argv[]) {
  if (argc < 2) {
    cout << "Remote Control Dandy credits extractor" << endl;
    cout << "Usage: " << argv[0] << " [infile] [outfile]" << endl;
    
    return 0;
  }
  
  string inFile(argv[1]);
  string outFile(argv[2]);
  
  TBufStream ifs;
  ifs.open(inFile.c_str());
  
  std::vector<PsxBitmap> rows;
  
  while (!ifs.eof()) {
    TBufStream ofs;
    DandyCmp::decmp(ifs, ofs);
    
    ofs.seek(0);
    
    PsxBitmap img;
    img.readPixelData(ofs, PsxBitmap::format_8bit, rowWidth, rowHeight);
    rows.push_back(img);
    
    ifs.alignToBoundary(4);
  }
  
  TGraphic grp(rowWidth, rowHeight * rows.size());
  for (unsigned int i = 0; i < rows.size(); i++) {
    PsxBitmap& img = rows[i];
    TGraphic subGrp;
    img.toGrayscaleGraphic(subGrp);
    
    grp.copy(subGrp, TRect(0, i * rowHeight, 0, 0));
  }
  
  TPngConversion::graphicToRGBAPng(outFile, grp);
  
  return 0;
}
