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

int main(int argc, char* argv[]) {
  if (argc < 1) {
    cout << "Print list of Remote Control Dandy event unlocks" << endl;
    
    return 0;
  }
  
  TBufStream ifs;
  ifs.open("files_decmp/ADV.STM");
  
  for (int i = 0; i < 97; i++) {
    ifs.seek(0x2CBB8 + (i * 4));
    int bitfield = ifs.readu32le();
    
    std::cout << "Mission " << std::dec << i << ":" << std::endl;
    
    if (bitfield == 0) {
      std::cout << "  none" << std::endl;
      continue;
    }
    
    for (int i = 0; i < 32; i++) {
      int mask = 0x1 << i;
      if ((bitfield & mask) != 0) {
//        std::cout << "  " << std::hex << (i + 1) << std::endl;
        ifs.seek((0x8008D928 - 0x80060A60) + ((i + 1) * 4));
        int addr = ifs.readu32le();
        std::cout << "  " << std::hex << (i + 1)
          << " (" << addr << ")" << std::endl;
      }
    }
  }
  
  return 0;
}
