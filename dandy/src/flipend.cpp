#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TFileManip.h"
#include "util/TSort.h"
#include "util/TGraphic.h"
#include "util/TColor.h"
#include "util/TPngConversion.h"
#include "util/TBitmapFont.h"
#include "util/TThingyTable.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include "dandy/DandyPac.h"
#include "dandy/DandyScriptScanner.h"
#include <algorithm>
#include <vector>
#include <string>
#include <map>
#include <iostream>
#include <iomanip>
#include <cmath>

using namespace std;
using namespace BlackT;

int main(int argc, char* argv[]) {
  if (argc < 5) {
    cout << "Endianness flipper" << endl;
    cout << "Usage: " << argv[0] << " [infile] [start] [length] [outfile]"
      << endl;
    return 0;
  }
  
  std::string infile(argv[1]);
  int start = TStringConversion::stringToInt(string(argv[2]));
  int length = TStringConversion::stringToInt(string(argv[3]));
  std::string outfile(argv[4]);
  
  int end = start + length;
  
  TBufStream ifs;
  ifs.open(infile.c_str());
  
  ifs.seek(start);
  for (int i = start; i < end; i += 2) {
    // original data is formatted as 16-bit little endian halfwords
    // with reversed halfnybble order (compared to a straightforward
    // left-to-right representation).
    // we want to output it as a series of little-endian 32-bit words.
  
    int value = ifs.readu16le();
    
    // flip halfnybble order
    int output = 0;
    for (int i = 0; i < 8; i++) {
      int inshift = i * 2;
      int inmask = 0x3 << inshift;
      int hn = (value & inmask) >> inshift;
      
      int outshift = (8 - i - 1) * 2;
      output |= (hn << outshift);
    }
    
    ifs.seekoff(-2);
    ifs.writeu16be(output);
  }
  
  ifs.seek(start);
  for (int i = start; i < end; i += 4) {
    int value = ifs.readu32le();
    ifs.seekoff(-4);
    ifs.writeu32be(value);
  }
  
  ifs.save(outfile.c_str());
  
  return 0;
}
