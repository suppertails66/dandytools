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

const static int rowWidth = 640;
const static int rowHeight = 16;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Remote Control Dandy credits splitter" << endl;
    cout << "Usage: " << argv[0] << " [infile] [outprefix]" << endl;
    
    return 0;
  }
  
  string inFile(argv[1]);
  string outPrefix(argv[2]);
  
  TGraphic grp;
  TPngConversion::RGBAPngToGraphic(inFile, grp);
  
  int numRows = grp.h() / rowHeight;
  
  for (int i = 0; i < numRows; i++) {
    TGraphic rowGrp(rowWidth, rowHeight);
    rowGrp.copy(grp,
             TRect(0, 0, 0, 0),
             TRect(0, i * rowHeight, rowWidth, rowHeight));
    
    PsxBitmap img;
//    img.setFormat(PsxBitmap::format_8bit);
    img.setFormat(PsxBitmap::format_4bit);
    img.fromGrayscaleGraphic(rowGrp);
    
    TBufStream ofs;
    img.writePixelData(ofs);
    ofs.save(
      (outPrefix + TStringConversion::intToString(i) + ".bin").c_str());
  }
  
  return 0;
}
