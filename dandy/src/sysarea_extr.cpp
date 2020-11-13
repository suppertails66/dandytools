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

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "PSX disc system area extractor" << endl;
    cout << "Usage: " << argv[0] << " [infile] [outfile]" << endl;
    
    return 0;
  }
  
  string infile(argv[1]);
  string outfile(argv[2]);
  
//  TBufStream ifs;
//  ifs.open(infile.c_str());
  TIfstream ifs(infile.c_str(), ios_base::binary);
  TBufStream ofs;
  
  for (int i = 0; i < 16; i++) {
//  for (int i = 16; i < 32; i++) {
    ifs.seek((i * 0x930) + 0x18);
    ofs.writeFrom(ifs, 0x800);
  }
  
  ofs.save(outfile.c_str());
  
  return 0;
}
