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

int main(int argc, char* argv[]) {
  if (argc < 5) {
    cout << "Remote Control Dandy partial bust-up animation inserter"
      << endl;
    cout << "Usage: " << argv[0] << " [srcfile] [inprefix] [numfiles] [outfile]"
      << endl;
    
    return 0;
  }
  
  string srcFile(argv[1]);
  string inPrefix(argv[2]);
  int numFiles = TStringConversion::stringToInt(std::string(argv[3]));
  string outName(argv[4]);
  
  TBufStream srcIfs;
  srcIfs.open(srcFile.c_str());
  
  TBufStream ofs;
  ofs.seek(0x10);
  
  // imgarc
  int imgArcOutPos = ofs.tell();
  {
    DandyImgArc::packDecompressed(
      ofs, numFiles, (inPrefix + "-grp-").c_str());
  }
  
  // stuff copied from original file
  
  srcIfs.seek(4);
  int chunk1Src = srcIfs.readu32le();
  int chunk2Src = srcIfs.readu32le();
  int chunk1Size = chunk2Src - chunk1Src;
  int chunk2Size = srcIfs.size() - chunk2Src;
  
  srcIfs.seek(chunk1Src);
  int chunk1OutPos = ofs.tell();
  ofs.writeFrom(srcIfs, chunk1Size);
  
  srcIfs.seek(chunk2Src);
  int chunk2OutPos = ofs.tell();
  ofs.writeFrom(srcIfs, chunk2Size);
  
  // finish index
  ofs.seek(0);
  ofs.writeu32le(imgArcOutPos);
  ofs.writeu32le(chunk1OutPos);
  ofs.writeu32le(chunk2OutPos);
  ofs.writeu32le(0);
  
  ofs.save(outName.c_str());
  
  return 0;
}
