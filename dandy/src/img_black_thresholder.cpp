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

// if all RGB components darker than this, increase to this level
const static int thresholdLevel = 0x41;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Tool to threshold black to dark gray in PNG images" << endl;
    cout << "Usage: " << argv[0] << " [infile] [outfile]" << endl;
    
    return 0;
  }
  
  string inFile(argv[1]);
  string outFile(argv[2]);

  TGraphic grp;
  TPngConversion::RGBAPngToGraphic(inFile, grp);
  
  for (int j = 0; j < grp.h(); j++) {
    for (int i = 0; i < grp.w(); i++) {
      TColor color = grp.getPixel(i, j);
      if ((color.a() == TColor::fullAlphaOpacity)
          && (color.r() < thresholdLevel)
          && (color.g() < thresholdLevel)
          && (color.b() < thresholdLevel)) {
        grp.setPixel(i, j,
          TColor(thresholdLevel, thresholdLevel, thresholdLevel));
      }
    }
  }

  TPngConversion::graphicToRGBAPng(outFile, grp);
  
  return 0;
}
