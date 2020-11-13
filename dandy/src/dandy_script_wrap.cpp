#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TThingyTable.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include "dandy/DandyLineWrapper.h"
#include <iostream>

using namespace std;
using namespace BlackT;
//using namespace Discaster;
using namespace Psx;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Remote Control Dandy string file wrapper" << endl;
    cout << "Usage: " << argv[0] << " [inprefix] [outprefix]" << endl;
    
    return 0;
  }
  
  string inPrefix(argv[1]);
  string outPrefix(argv[2]);
  
  TThingyTable table;
  table.readSjis("table/dandy_en.tbl");
  
  // wrap script
  {
    // read size table
    DandyLineWrapper::CharSizeTable sizeTable;
    {
      TBufStream ifs;
      ifs.open("out/img/font_width.bin");
      int pos = 0;
      while (!ifs.eof()) {
        sizeTable[pos++] = ifs.readu8();
      }
    }
    
    {
      TBufStream ifs;
      ifs.open((inPrefix + "script.txt").c_str());
      
      TLineWrapper::ResultCollection results;
      DandyLineWrapper(ifs, results, table, sizeTable)();
      
      if (results.size() > 0) {
        TOfstream ofs((outPrefix + "script_wrapped.txt").c_str());
        for (int i = 0; i < results.size(); i++) {
          ofs.write(results[i].str.c_str(), results[i].str.size());
        }
      }
    }
    
    {
      TBufStream ifs;
      ifs.open((inPrefix + "common.txt").c_str());
      
      TLineWrapper::ResultCollection results;
      DandyLineWrapper(ifs, results, table, sizeTable)();
      
      if (results.size() > 0) {
        TOfstream ofs((outPrefix + "common_wrapped.txt").c_str());
        for (int i = 0; i < results.size(); i++) {
          ofs.write(results[i].str.c_str(), results[i].str.size());
        }
      }
    }
    
/*    {
      TBufStream ifs;
      ifs.open((inPrefix + "new.txt").c_str());
      
      TLineWrapper::ResultCollection results;
      DandyLineWrapper(ifs, results, table, sizeTable)();
      
      if (results.size() > 0) {
        TOfstream ofs((outPrefix + "new_wrapped.txt").c_str());
        ofs.write(results[0].str.c_str(), results[0].str.size());
      }
    } */
  }
  
  return 0;
}
