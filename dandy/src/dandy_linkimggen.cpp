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
#include "dandy/DandyLinkImg.h"
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
    cout << "Remote Control Dandy linked-list image generator" << endl;
    cout << "Usage: " << argv[0] << " [inprefix] [numfiles] [outfile]" << endl;
    
    return 0;
  }
  
  string inPrefix(argv[1]);
  int numInputFiles = TStringConversion::stringToInt(std::string(argv[2]));
  string outfileName(argv[3]);
  
  // this allows us to be lazy if we don't know the exact number of files
  bool autoSize = false;
  if (numInputFiles == -1) {
    autoSize = true;
    numInputFiles = 999999;
  }
  
  TBufStream ofs;
//  ofs.writeu32le(numInputFiles);
  // placeholder for input file count
  ofs.writeu32le(0);
  
  int trueNumInputFiles = 0;
  for (int i = 0; i < numInputFiles; i++) {
    // placeholder for link to next image
    int lastLinkPos = ofs.tell();
    ofs.writeu32le(0);
  
    std::string infilePrefix = inPrefix + "-"
      + TStringConversion::intToString(i);
    
    if (autoSize && !TFileManip::fileExists(infilePrefix + "-img.png")) break;
    
    ++trueNumInputFiles;
    
    DandyLinkImg img;
    img.load(infilePrefix);
    
    img.write(ofs);
    
    // write link to next image
    int pos = ofs.tell();
    ofs.seek(lastLinkPos);
    ofs.writeu32le(pos);
    ofs.seek(pos);
  }
  
  // write image file count
  ofs.seek(0);
  ofs.writeu32le(trueNumInputFiles);
  
  ofs.save(outfileName.c_str());
  
  return 0;
}
