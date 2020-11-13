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
#include "dandy/DandyLinkImg.h"
//#include "dandy/DandyImgExtr.h"
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

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Remote Control Dandy linked-list image extractor" << endl;
    cout << "Usage: " << argv[0] << " [infile] [outprefix]" << endl;
    cout << "Options: " << endl;
    cout << "  -grayscale         Force grayscale output even if a palette exists"
      << endl;
    cout << "  -transparency      Enable transparency (disabled by default)"
      << endl;
    cout << "  -semitransparency  Enable semitransparency (disabled by default)"
      << endl;
    
    return 0;
  }
  
  string infileName(argv[1]);
  string outPrefix(argv[2]);
  
  bool grayscale = TOpt::hasFlag(argc, argv, "-grayscale");
  bool transparency = TOpt::hasFlag(argc, argv, "-transparency");
  bool semiTransparency = TOpt::hasFlag(argc, argv, "-semitransparency");
  
  TBufStream ifs;
  ifs.open(infileName.c_str());
  
  int numLinks = ifs.readu32le();
  
  for (int i = 0; i < numLinks; i++) {
    int nextLinkAddr = ifs.readu32le();
    
    DandyLinkImg img;
    
    img.setGrayscale(grayscale);
    img.setTransparency(transparency);
    img.setSemiTransparency(semiTransparency);
    
    img.read(ifs);
    img.save(outPrefix + "-" + TStringConversion::intToString(i));
    
    if ((nextLinkAddr != 0) && (nextLinkAddr <= ifs.size()))
      ifs.seek(nextLinkAddr);
    
    if (nextLinkAddr > ifs.size()) {
      std::cerr << "error: not a valid linked-list image file" << std::endl;
      return 1;
    }
  }
  
  return 0;
}
