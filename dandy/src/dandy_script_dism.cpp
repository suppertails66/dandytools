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
#include "dandy/DandyScriptDisassembler.h"
#include <algorithm>
#include <vector>
#include <string>
#include <iostream>
#include <fstream>
#include <iomanip>
#include <cmath>

using namespace std;
using namespace BlackT;
//using namespace Discaster;
using namespace Psx;

int main(int argc, char* argv[]) {
  if (argc < 3) {
    cout << "Remote Control Dandy script file disassembler" << endl;
    cout << "Usage: " << argv[0] << " [infile] [outprefix]" << endl;
    
    return 0;
  }
  
  string infile(argv[1]);
  string outprefix(argv[2]);
  
  TBufStream ifs;
  ifs.open(infile.c_str());
  
/*SCENE DATA
  see ADV.PAC files 5-103, subfile 0
  - 4b size of font graphic
  - font graphic (see GRAPHICS for format)
  - 4b number of script labels
  - script label array, 0x14 bytes per entry
    - 0x10-byte name (padded with null)
    - 4b offset from script block start?
  - 4b ? number(?) of ???
       seems to be sum of the number of entries in the two unknown
       blocks that follow.
       game skips over this...
  - 4b number of ?
       count of words that follow (can be zero)
  - words...
  - 4b number of ?
       count of words that follow (can be zero)
  - words...
  - script block */
  
  // TODO
  
  DandyScriptEnv env;
  
  int textGrpSize = ifs.readu32le();
  ifs.seekoff(textGrpSize);
  
  int numScriptLabels = ifs.readu32le();
//  ifs.seekoff(numScriptLabels * 0x14);
  for (int i = 0; i < numScriptLabels; i++) {
    char rawname[17];
    rawname[sizeof(rawname) - 1] = 0x00;
    ifs.read(rawname, 16);
    std::string name(rawname);
    
    int value = ifs.readu32le();
    
    DandyScriptLabel label;
    label.name = name;
    label.value = value;
    env.addLabel(label);
  }
  
  int numBlock1And2Entries = ifs.readu32le();
  
  int numBlock1Entries = ifs.readu32le();
  ifs.seekoff(numBlock1Entries * 4);
  
  int numBlock2Entries = ifs.readu32le();
  ifs.seekoff(numBlock2Entries * 4);
  
  cerr << "script data offset: " << hex << ifs.tell() << endl;
  env.basePos = ifs.tell();
  
  // copy script data
  TBufStream scriptIfs;
  scriptIfs.writeFrom(ifs, ifs.remaining());
  
  {
    scriptIfs.save((outprefix + "script_raw.bin").c_str());
    
    scriptIfs.seek(0);
    std::ofstream ofs((outprefix + "script.txt").c_str());
    DandyScriptDisassembler(env, scriptIfs, ofs)();
  }
  
  
//  try {
//
//  }
//  catch (...) {
//    ofs.save(outName.c_str());
//  }
  
//  ofs.save(outName.c_str());
  
  return 0;
}
