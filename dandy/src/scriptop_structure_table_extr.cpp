#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TFileManip.h"
#include "util/TSort.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include <algorithm>
#include <vector>
#include <string>
#include <map>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <cmath>

using namespace std;
using namespace BlackT;

typedef std::map<unsigned long int, int> AddrToOpMap;
AddrToOpMap textscrAddrToOpMap;

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

const int fileLoadAddress = 0x8000F800;
const int pointerTableBase = 0x80049848 - fileLoadAddress;
const int numOps = 0x150;

const char* argTypeNames[] = {
  // 00
  "type00_(unused)",
  // 01
  "scriptindex",
  // 02
  "type02",
  // 03
  "gametext",
  // 04
  "L1_type04?",
  // 05
  "L2_type05?",
  // 06
  "type06_(unused)",
  // 07
  "type07_(unused)",
  // 08
  "L1_type08?",
  // 09
  "L4",
  // 0A
  "string",
  // 0B
  "L1_type0B?",
  // 0C
  "L1_type0C?",
  // 0D
  "type0D",
  // 0E
  "type0E",
  // 0F
  "type0F",
  // 10
  "type10"
};

int main(int argc, char* argv[]) {
  if (argc < 1) {
    cout << "Dandy script op structure table reader" << endl;
    cout << "Usage: " << argv[0] << endl;
    
    return 0;
  }
  
  {
    TBufStream ifs;
    ifs.open("rsrc_raw/exe/SLPS_022.43");
    for (int i = 0; i < numOps; i++) {
      ifs.seek(pointerTableBase + (i * 4));
      
      unsigned int rawptr = ifs.readu32le();
      unsigned int offset = rawptr - fileLoadAddress;
//      cerr << hex << value << endl;

      ifs.seek(offset);
      cout << "op " << as3bHex(i + 1) << ": ";
      while (ifs.peek() != 0x00) {
//        cout << as2bHex(ifs.readu8()) << " ";
        cout << argTypeNames[ifs.readu8()] << " ";
      }
      cout << endl;
      
//      cout << TStringConversion::intToString(value, TStringConversion::baseHex)
//        << endl;
    }
  }
  
  return 0;
}
