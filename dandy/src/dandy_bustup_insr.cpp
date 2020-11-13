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
    cout << "Remote Control Dandy partial bust-up portrait extractor" << endl;
    cout << "Usage: " << argv[0] << " [srcfile] [inprefix] [outfile]" << endl;
    
    return 0;
  }
  
  string srcFile(argv[1]);
  string inPrefix(argv[2]);
  string outFile(argv[3]);
  
  TBufStream srcIfs;
  srcIfs.open(srcFile.c_str());
  
  TBufStream ofs;
  ofs.seek(0x20);
  
  int mainOutPos = ofs.tell();
  {
    DandyImg img;
    img.load((inPrefix + "-main").c_str());
    img.write(ofs);
  }
  
  int subOutPos = ofs.tell();
  {
    DandyImg img;
    img.load((inPrefix + "-sub").c_str());
    img.write(ofs);
  }
  
  // other...
  for (int i = 0; i < 3; i++) {
    srcIfs.seek(8 + (i * 4));
    int nextChunkPos = srcIfs.readu32le();
    int nextNextChunkPos = srcIfs.readu32le();
    if (i == 2) nextNextChunkPos = srcIfs.size();
    
    int nextChunkSize = nextNextChunkPos - nextChunkPos;
    
    srcIfs.seek(nextChunkPos);
    int outChunkPos = ofs.tell();
    ofs.writeFrom(srcIfs, nextChunkSize);
    ofs.seek(8 + (i * 4));
    ofs.writeu32le(outChunkPos);
    ofs.seek(ofs.size());
  }
  
  ofs.seek(0);
  ofs.writeu32le(mainOutPos);
  ofs.writeu32le(subOutPos);
  
  ofs.seek(0x14);
  for (int i = 0; i < 3; i++) ofs.writeu32le(0);
  
  ofs.save(outFile.c_str());
  
  return 0;
}
