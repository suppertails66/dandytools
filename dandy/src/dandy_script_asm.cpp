#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TFileManip.h"
#include "util/TSort.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TThingyTable.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include "dandy/DandyPac.h"
#include "dandy/DandyCmp.h"
#include "dandy/DandyScriptAssembler.h"
#include "dandy/DandyScriptReader.h"
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
  if (argc < 7) {
    cout << "Remote Control Dandy script file assembler" << endl;
    cout << "Usage: " << argv[0] << " [asmfile] [basefile] [filenum]"
      << " [scriptprefix] [fontfile] [outfile]" << endl;
    
    return 0;
  }
  
  string asmfile(argv[1]);
  string basefile(argv[2]);
  int filenum = TStringConversion::stringToInt(std::string(argv[3]));
  string scriptprefix(argv[4]);
  string fontfile(argv[5]);
  string outfile(argv[6]);
  
  TBufStream baseifs;
  baseifs.open(basefile.c_str());
  
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
  
  DandyScriptAsmEnv env;
  
  int textGrpSize = baseifs.readu32le();
  int textGrpAddr = baseifs.tell();
  baseifs.seekoff(textGrpSize);
  
  int numScriptLabels = baseifs.readu32le();
  baseifs.seekoff(numScriptLabels * 0x14);
/*  for (int i = 0; i < numScriptLabels; i++) {
    char rawname[17];
    rawname[sizeof(rawname) - 1] = 0x00;
    ifs.read(rawname, 16);
    std::string name(rawname);
    
    int value = ifs.readu32le();
    
    DandyScriptLabel label;
    label.name = name;
    label.value = value;
    env.addLabel(label);
  } */
  
  int numBlock1And2EntriesAddr = baseifs.tell();
  int numBlock1And2Entries = baseifs.readu32le();
  
  int numBlock1Entries = baseifs.readu32le();
  int block1EntriesAddr = baseifs.tell();
  baseifs.seekoff(numBlock1Entries * 4);
  
  int numBlock2Entries = baseifs.readu32le();
  int block2EntriesAddr = baseifs.tell();
  baseifs.seekoff(numBlock2Entries * 4);
  
  cerr << "script data offset: " << hex << baseifs.tell() << endl;
//  env.basePos = baseifs.tell();
  
  TBufStream scriptIfs;
  scriptIfs.open(asmfile.c_str());
//  std::ifstream scriptIfs(asmfile.c_str());
  TBufStream scriptOfs;
  
  TThingyTable table;
  table.readSjis("table/dandy_en.tbl");
  
  // read size table
/*  DandyScriptReader::CharSizeTable sizeTable;
  {
    TBufStream ifs;
    ifs.open("out/img/font_width.bin");
    int pos = 0;
    while (!ifs.eof()) {
      sizeTable[pos++] = ifs.readu8();
    }
  } */
  
  {
    DandyScriptReader::FileToResultMap textScript;
    TBufStream src;
    src.open((scriptprefix + "script_wrapped.txt").c_str());
    
    DandyScriptReader(src, textScript, table)();
    
    DandyScriptReader::ResultCollection results = textScript.at(filenum);
    for (DandyScriptReader::ResultCollection::iterator it = results.begin();
         it != results.end();
         ++it) {
      env.strings[it->srcOffset] = *it;
    }
  }
  
  {
    DandyScriptReader::FileToResultMap textScript;
    TBufStream src;
    src.open((scriptprefix + "common_wrapped.txt").c_str());
    
    DandyScriptReader(src, textScript, table)();
    
    DandyScriptReader::ResultCollection results = textScript.at(0);
    for (DandyScriptReader::ResultCollection::iterator it = results.begin();
         it != results.end();
         ++it) {
      if (env.commonStrings.find(it->name) != env.commonStrings.end()) {
        std::cerr << "Error: multiply defined common string name: "
          << it->name << std::endl;
        return 1;
      }
      
      env.commonStrings[it->name] = *it;
    }
  }
  
//  try
  {
////    std::ofstream ofs((outprefix + "script.txt").c_str());
    DandyScriptAssembler(env, scriptIfs, scriptOfs)();
  }
//  catch (TException& e) {
//    std::cerr << e.what() << std::endl;
//    return 1;
//  }
  
  
  TBufStream ofs;
  
//  ofs.writeu32le(textGrpSize);
//  baseifs.seek(textGrpAddr);
//  ofs.writeFrom(baseifs, textGrpSize);
  {
    TBufStream ifs;
    ifs.open(fontfile.c_str());
    ofs.writeu32le(ifs.size());
    ofs.writeFrom(ifs, ifs.size());
  }
  
  env.writeLabelBlock(ofs);
  
  ofs.writeu32le(numBlock1And2Entries);
  
  ofs.writeu32le(numBlock1Entries);
  baseifs.seek(block1EntriesAddr);
  ofs.writeFrom(baseifs, numBlock1Entries * 4);
  
  ofs.writeu32le(numBlock2Entries);
  baseifs.seek(block2EntriesAddr);
  ofs.writeFrom(baseifs, numBlock2Entries * 4);
  
//  scriptOfs.save(outfile.c_str());

  scriptOfs.seek(0);
  ofs.writeFrom(scriptOfs, scriptOfs.size());
  
  ofs.save(outfile.c_str());
  
//  try {
//
//  }
//  catch (...) {
//    ofs.save(outName.c_str());
//  }
  
//  ofs.save(outName.c_str());
  
  return 0;
}
