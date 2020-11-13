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
#include "dandy/DandyPac.h"
#include "dandy/DandyCmp.h"
#include <algorithm>
#include <vector>
#include <string>
#include <iostream>
#include <iomanip>
#include <cmath>
#include <ctime>

using namespace std;
using namespace BlackT;
//using namespace Discaster;
using namespace Psx;

int main(int argc, char* argv[]) {
  if (argc < 4) {
    cout << "Remote Control Dandy sequential file compressor" << endl;
    cout << "Usage: " << argv[0] << " [inprefix] [outfile] [indexoutfile]"
      << endl;
    cout << "Options:" << endl;
    cout << "  --lazy   Don't use the compressor;" << endl
         << "           instead, just shove everything in the file as-is." << endl
         << "           Achieves massive speedup at the cost of..." << endl
         << "           well, having no compression." << endl
         << "           Since the compression algorithm is a bit slow," << endl
         << "           you might want to use this for anything that" << endl
         << "           doesn't actually need the full compression to function." << endl;
    
    return 0;
  }
  
  string inPrefix(argv[1]);
  string outName(argv[2]);
  string indexOutName(argv[3]);
  
  bool useLazyCompression = TOpt::hasFlag(argc, argv, "--lazy");
  
  int fileNum = 0;
  TBufStream ofs;
  TBufStream indexOfs;
  while (true) {
    std::string name = inPrefix + TStringConversion::intToString(fileNum)
      + ".bin";
    if (!TFileManip::fileExists(name)) break;
    
    ofs.alignToBoundary(4);
    
    indexOfs.writeu32le(ofs.tell());
    
    TBufStream ifs;
    ifs.open(name.c_str());
    
    std::cout << "Compressing: " << name << std::endl;
    
    int timer = clock();
    
  //  TOfstream ofs(outName.c_str(), ios_base::binary);
    TBufStream dataOfs;
    try {
      if (useLazyCompression) {
        DandyCmp::cmpLazy(ifs, dataOfs);
      }
      else {
        DandyCmp::cmp(ifs, dataOfs);
      }
    }
    catch (TGenericException& e) {
      std::cerr << "Exception: " << e.problem() << std::endl;
      std::cerr << "Saving partial output file" << std::endl;
      dataOfs.save(outName.c_str());
      return 1;
    }
  //  catch (...) {
  //    ofs.save(outName.c_str());
  //  }

    timer = clock() - timer;
    double timeAmt = (double)timer / (double)CLOCKS_PER_SEC;
    std::cout << "Compression time: " << timeAmt << " sec." << std::endl;
    
    ofs.write(dataOfs.data().data(), dataOfs.size());
    
    ++fileNum;
  }
  
  ofs.save(outName.c_str());
  indexOfs.save(indexOutName.c_str());

/*  TBufStream check;
  try {
    ofs.seek(0);
    DandyCmp::decmp(ofs, check);
    
    // DEBUG: verify that decompressing the compressed data yields the original
    // file
    
    if (check.size() != ifs.size()) {
      cerr << "error: output size mismatch" << endl;
      return 1;
    }
    
    ifs.seek(0);
    check.seek(0);
    for (int i = 0; i < check.size(); i++) {
      if (ifs.get() != check.get()) {
        cerr << "error: compression mismatch (at " << i - 1 << ")" << endl;
        return 1;
      }
    }
  }
  catch (...) {
    std::cerr << "???" << std::endl;
    std::cerr << std::hex << check.tell() << std::endl;
  } */
  
  return 0;
}
