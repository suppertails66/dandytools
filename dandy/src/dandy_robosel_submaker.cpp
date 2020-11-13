#include "util/TBufStream.h"
#include "util/TIfstream.h"
#include "util/TOfstream.h"
#include "util/TStringConversion.h"
#include "util/TFileManip.h"
#include "util/TSort.h"
#include "util/TGraphic.h"
#include "util/TPngConversion.h"
#include "util/TThingyTable.h"
#include "dandy/DandyScriptReader.h"
#include "exception/TException.h"
#include "exception/TGenericException.h"
#include "dandy/DandyPac.h"
#include <algorithm>
#include <vector>
#include <string>
#include <map>
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

typedef std::map<std::string, std::string> NameToContentMap;
NameToContentMap scriptStrings;

class RoboSelScript {
public:
  void addDelay(int amt) {
    data.writeu8(0x01);
    
    data.writeu16be(amt);
  }
  
  void addSendString(int dstLow, int dstHigh, std::string strName) {
    data.writeu8(0x02);
    
    data.writeu8(dstLow);
    data.writeu8(dstHigh);
//    data.writeString(str);
    data.writeString(scriptStrings.at(strName));
    // string terminator
    data.put(0x00);
  }
  
  void addShowSub(int src, int x, int y, int w, int h) {
    data.writeu8(0x03);
    
    data.writeu8(src);
    data.writeu8(x);
    data.writeu8(y);
    data.writeu8(w);
    data.writeu8(h);
  }
  
  void addHideSub() {
    data.writeu8(0x04);
  }
  
  void write(TStream& dst) {
    dst.write(data.data().data(), data.size());
    // terminator
    dst.put(0x00);
  }
  
  
  
  void addSingleStringAuto(std::string strName) {
    int dstLow = dstLowEvenParity;
    int dstHigh = dstHighEvenParity;
    if (parity) {
      dstLow = dstLowOddParity;
      dstHigh = dstHighOddParity;
    }
    
    addSendString(dstLow, dstHigh, strName);
    addShowSub(dstHigh,
               singleLineX, singleLineY,
               singleLineW, singleLineH);
    
    parity = !parity;
  }
  
  void addDoubleStringAuto(std::string strName1, std::string strName2) {
    int dstLow = dstLowEvenParity;
    int dstHigh = dstHighEvenParity;
    if (parity) {
      dstLow = dstLowOddParity;
      dstHigh = dstHighOddParity;
    }
    
    addSendString(dstLow, dstHigh, strName1);
    addSendString(dstLow, dstHigh, strName2);
    addShowSub(dstHigh,
               doubleLineX, doubleLineY,
               doubleLineW, doubleLineH);
    
    parity = !parity;
  }
  
  RoboSelScript()
    : parity(false) { }
  
protected:
  TBufStream data;
  
  bool parity;
  
  const static int dstLowEvenParity = 0x00;
  const static int dstLowOddParity = 0x00;
  const static int dstHighEvenParity = 0xA0;
  const static int dstHighOddParity = 0xC0;
  
  const static int singleLineX = 32;
  const static int singleLineY = 200;
  const static int singleLineW = 0;
//  const static int singleLineW = 192;
  const static int singleLineH = 16;
  
  const static int doubleLineX = 32;
  const static int doubleLineY = 192;
  const static int doubleLineW = 0;
//  const static int doubleLineW = 192;
  const static int doubleLineH = 32;
  
};

typedef std::map<int, RoboSelScript> IdToRoboSelScriptMap;
IdToRoboSelScriptMap roboSelScripts;

int main(int argc, char* argv[]) {
  if (argc < 2) {
    cout << "Remote Control Dandy robot select/deployment subtitle maker"
      << endl;
    cout << "Usage: " << argv[0] << " [outfile]" << endl;
    
    return 0;
  }
  
  std::string outfile(argv[1]);
  
  TThingyTable table;
  table.readSjis("table/dandy_en.tbl");
  
  {
    DandyScriptReader::FileToResultMap textScript;
    TBufStream src;
    src.open((std::string("out/script/common_wrapped.txt")).c_str());
    
    DandyScriptReader(src, textScript, table)();
    
    DandyScriptReader::ResultCollection results = textScript.at(0);
    for (DandyScriptReader::ResultCollection::iterator it = results.begin();
         it != results.end();
         ++it) {
      if (scriptStrings.find(it->name) != scriptStrings.end()) {
        std::cerr << "Error: multiply defined script string name: "
          << it->name << std::endl;
        return 1;
      }
      
//      scriptStrings[it->name] = *it;
      scriptStrings[it->name] = it->str;
    }
  }
  
  RoboSelScript vordanFull;
  RoboSelScript garethFull;
  RoboSelScript lionelFull;
  RoboSelScript percevalFull;
  RoboSelScript vordanShort;
  RoboSelScript garethShort;
  RoboSelScript lionelShort;
  RoboSelScript percevalShort;
  
  //===================
  // vordan full
  //===================
  
  {
    vordanFull.addSingleStringAuto("robosel_vordan_full_1-1");
    vordanFull.addDelay(22);
    vordanFull.addHideSub();
    
    vordanFull.addDelay(38);
    
    vordanFull.addSingleStringAuto("robosel_vordan_full_2-1");
    vordanFull.addDelay(32);
    vordanFull.addHideSub();
    
    vordanFull.addDelay(27);
    
    vordanFull.addSingleStringAuto("robosel_vordan_full_3-1");
    vordanFull.addDelay(35);
    vordanFull.addHideSub();
    
    vordanFull.addDelay(46);
    
    vordanFull.addSingleStringAuto("robosel_vordan_full_4-1");
    vordanFull.addDelay(34);
    vordanFull.addHideSub();
    
    vordanFull.addDelay(52);
    
    vordanFull.addSingleStringAuto("robosel_vordan_full_5-1");
    vordanFull.addDelay(41);
    vordanFull.addHideSub();
    
    vordanFull.addDelay(41);
    
    vordanFull.addSingleStringAuto("robosel_vordan_full_6-1");
    vordanFull.addDelay(51);
    vordanFull.addSingleStringAuto("robosel_vordan_full_7-1");
    vordanFull.addDelay(26);
    vordanFull.addSingleStringAuto("robosel_vordan_full_8-1");
    vordanFull.addDelay(23);
/*    vordanFull.addSingleStringAuto("robosel_vordan_full_9-1");
    vordanFull.addDelay(26);
    vordanFull.addSingleStringAuto("robosel_vordan_full_10-1");
    vordanFull.addDelay(26);
    vordanFull.addHideSub();
    
    vordanFull.addDelay(19);
    
    vordanFull.addSingleStringAuto("robosel_vordan_full_11-1");
    vordanFull.addDelay(40);
    vordanFull.addHideSub(); */
    
    vordanFull.addSendString(0, 0x90, "robosel_vordan_full_9-1");
    vordanFull.addDelay(1);
    vordanFull.addSendString(0, 0xB0, "robosel_vordan_full_10-1");
    vordanFull.addDelay(1);
    vordanFull.addSendString(0, 0xD0, "robosel_vordan_full_11-1");
    vordanFull.addDelay(1);
    
    vordanFull.addShowSub(0x90, 32, 200, 256, 16);
    vordanFull.addDelay(26);
    vordanFull.addShowSub(0xB0, 32, 200, 256, 16);
    vordanFull.addDelay(26);
    vordanFull.addHideSub();
    
    vordanFull.addDelay(20);
    
    vordanFull.addShowSub(0xD0, 32, 200, 256, 16);
    vordanFull.addDelay(29);
    vordanFull.addHideSub();
  }
  
  //===================
  // gareth full
  //===================
  
  {
    garethFull.addSingleStringAuto("robosel_gareth_full_1-1");
    garethFull.addDelay(22);
    garethFull.addHideSub();
    
    garethFull.addDelay(38);
    
    garethFull.addSingleStringAuto("robosel_gareth_full_2-1");
    garethFull.addDelay(41);
    garethFull.addHideSub();
    
    garethFull.addDelay(18);
    
    garethFull.addSingleStringAuto("robosel_gareth_full_3-1");
    garethFull.addDelay(35);
    garethFull.addHideSub();
    
    garethFull.addDelay(30);
    
    garethFull.addSingleStringAuto("robosel_gareth_full_4-1");
    garethFull.addDelay(55);
    garethFull.addHideSub();
    
    garethFull.addDelay(47);
    
    garethFull.addSingleStringAuto("robosel_gareth_full_5-1");
    garethFull.addDelay(43);
    garethFull.addHideSub();
    
    garethFull.addDelay(42);
    
    garethFull.addSingleStringAuto("robosel_gareth_full_6-1");
    garethFull.addDelay(45);
    garethFull.addSingleStringAuto("robosel_gareth_full_7-1");
    garethFull.addDelay(26);
    garethFull.addSingleStringAuto("robosel_gareth_full_8-1");
    garethFull.addDelay(19);
    
    garethFull.addSendString(0, 0x90, "robosel_gareth_full_9-1");
    garethFull.addDelay(1);
    garethFull.addSendString(0, 0xB0, "robosel_gareth_full_10-1");
    garethFull.addDelay(1);
    garethFull.addSendString(0, 0xD0, "robosel_gareth_full_11-1");
    garethFull.addDelay(1);
    
    garethFull.addShowSub(0x90, 32, 200, 256, 16);
    garethFull.addDelay(25);
    garethFull.addShowSub(0xB0, 32, 200, 256, 16);
    garethFull.addDelay(27);
    garethFull.addHideSub();
    
    garethFull.addDelay(27);
    
    garethFull.addShowSub(0xD0, 32, 200, 256, 16);
    garethFull.addDelay(29);
    garethFull.addHideSub();
  }
  
  //===================
  // lionel full
  //===================
  
  {
    lionelFull.addSingleStringAuto("robosel_lionel_full_1-1");
    lionelFull.addDelay(22);
    lionelFull.addHideSub();
    
    lionelFull.addDelay(38);
    
    lionelFull.addSingleStringAuto("robosel_lionel_full_2-1");
    lionelFull.addDelay(34);
    lionelFull.addHideSub();
    
    lionelFull.addDelay(22);
    
    lionelFull.addSingleStringAuto("robosel_lionel_full_3-1");
    lionelFull.addDelay(40);
    lionelFull.addHideSub();
    
    lionelFull.addDelay(42);
    
    lionelFull.addSingleStringAuto("robosel_lionel_full_4-1");
    lionelFull.addDelay(36);
    lionelFull.addHideSub();
    
    lionelFull.addDelay(51);
    
    lionelFull.addSingleStringAuto("robosel_lionel_full_5-1");
    lionelFull.addDelay(41);
    lionelFull.addHideSub();
    
    lionelFull.addDelay(42);
    
    lionelFull.addSingleStringAuto("robosel_lionel_full_6-1");
    lionelFull.addDelay(51);
    lionelFull.addSingleStringAuto("robosel_lionel_full_7-1");
    lionelFull.addDelay(26);
    lionelFull.addSingleStringAuto("robosel_lionel_full_8-1");
    lionelFull.addDelay(23);
    
    lionelFull.addSendString(0, 0x90, "robosel_lionel_full_9-1");
    lionelFull.addDelay(1);
    lionelFull.addSendString(0, 0xB0, "robosel_lionel_full_10-1");
    lionelFull.addDelay(1);
    lionelFull.addSendString(0, 0xD0, "robosel_lionel_full_11-1");
    lionelFull.addDelay(1);
    
    lionelFull.addShowSub(0x90, 32, 200, 256, 16);
    lionelFull.addDelay(25);
    lionelFull.addShowSub(0xB0, 32, 200, 256, 16);
    lionelFull.addDelay(27);
    lionelFull.addHideSub();
    
    lionelFull.addDelay(20);
    
    lionelFull.addShowSub(0xD0, 32, 200, 256, 16);
    lionelFull.addDelay(29);
    lionelFull.addHideSub();
  }
  
  //===================
  // perceval full
  //===================
  
  {
    percevalFull.addSingleStringAuto("robosel_perceval_full_1-1");
    percevalFull.addDelay(22);
    percevalFull.addHideSub();
    
    percevalFull.addDelay(36);
    
    percevalFull.addSingleStringAuto("robosel_perceval_full_2-1");
    percevalFull.addDelay(36);
    percevalFull.addHideSub();
    
    percevalFull.addDelay(32);
    
    percevalFull.addSingleStringAuto("robosel_perceval_full_3-1");
    percevalFull.addDelay(40);
    percevalFull.addHideSub();
    
    percevalFull.addDelay(33);
    
    percevalFull.addSingleStringAuto("robosel_perceval_full_4-1");
    percevalFull.addDelay(38);
    percevalFull.addHideSub();
    
    percevalFull.addDelay(49);
    
    percevalFull.addSingleStringAuto("robosel_perceval_full_5-1");
    percevalFull.addDelay(40);
    percevalFull.addHideSub();
    
    percevalFull.addDelay(49);
    
    percevalFull.addSingleStringAuto("robosel_perceval_full_6-1");
    percevalFull.addDelay(48);
    percevalFull.addSingleStringAuto("robosel_perceval_full_7-1");
    percevalFull.addDelay(25);
    percevalFull.addSingleStringAuto("robosel_perceval_full_8-1");
    percevalFull.addDelay(21);
    
    percevalFull.addSendString(0, 0x90, "robosel_perceval_full_9-1");
    lionelFull.addDelay(1);
    percevalFull.addSendString(0, 0xB0, "robosel_perceval_full_10-1");
    lionelFull.addDelay(1);
    percevalFull.addSendString(0, 0xD0, "robosel_perceval_full_11-1");
    lionelFull.addDelay(1);
    
    percevalFull.addShowSub(0x90, 32, 200, 256, 16);
    percevalFull.addDelay(25);
    percevalFull.addShowSub(0xB0, 32, 200, 256, 16);
    percevalFull.addDelay(26);
    percevalFull.addHideSub();
    
    percevalFull.addDelay(17);
    
    percevalFull.addShowSub(0xD0, 32, 200, 256, 16);
    percevalFull.addDelay(29);
    percevalFull.addHideSub();
  }
  
  //===================
  // vordan short
  //===================
  
  {
    vordanShort.addSingleStringAuto("robosel_vordan_short_1-1");
    vordanShort.addDelay(22);
    vordanShort.addHideSub();
    
    vordanShort.addDelay(38);
    
    vordanShort.addSingleStringAuto("robosel_vordan_short_2-1");
    vordanShort.addDelay(31);
    vordanShort.addHideSub();
    
    vordanShort.addDelay(27);
    
    vordanShort.addSingleStringAuto("robosel_vordan_short_3-1");
    vordanShort.addDelay(35);
    vordanShort.addHideSub();
    
    vordanShort.addDelay(12);
    
    vordanShort.addSingleStringAuto("robosel_vordan_short_4-1");
    vordanShort.addDelay(32);
    vordanShort.addHideSub();
    
    vordanShort.addDelay(23);
    
    vordanShort.addSingleStringAuto("robosel_vordan_short_5-1");
    vordanShort.addDelay(29);
    vordanShort.addHideSub();
  }
  
  //===================
  // gareth short
  //===================
  
  {
/*    garethShort.addSingleStringAuto("robosel_gareth_short_1-1");
    garethShort.addDelay(22);
    garethShort.addHideSub();
    
    garethShort.addDelay(38);
    
    garethShort.addSingleStringAuto("robosel_gareth_short_2-1");
    garethShort.addDelay(31);
    garethShort.addHideSub();
    
    garethShort.addDelay(27);
    
    garethShort.addSingleStringAuto("robosel_gareth_short_3-1");
    garethShort.addDelay(35);
    garethShort.addHideSub(); */
    
    garethShort.addSingleStringAuto("robosel_gareth_short_1-1");
    garethShort.addDelay(22);
    garethShort.addHideSub();
    
    garethShort.addDelay(32);
    
    garethShort.addSingleStringAuto("robosel_gareth_short_2-1");
    garethShort.addDelay(38);
    garethShort.addHideSub();
    
    garethShort.addDelay(26);
    
    garethShort.addSingleStringAuto("robosel_gareth_short_3-1");
    garethShort.addDelay(25);
    garethShort.addHideSub();
    
    garethShort.addDelay(10);
    
    garethShort.addSingleStringAuto("robosel_gareth_short_4-1");
    garethShort.addDelay(52);
    garethShort.addHideSub();
    
    garethShort.addDelay(23);
    
    garethShort.addSingleStringAuto("robosel_gareth_short_5-1");
    garethShort.addDelay(28);
    garethShort.addHideSub();
  }
  
  //===================
  // lionel short
  //===================
  
  {
    lionelShort.addSingleStringAuto("robosel_lionel_short_1-1");
    lionelShort.addDelay(22);
    lionelShort.addHideSub();
    
    lionelShort.addDelay(35);
    
    lionelShort.addSingleStringAuto("robosel_lionel_short_2-1");
    lionelShort.addDelay(31);
    lionelShort.addHideSub();
    
    lionelShort.addDelay(30);
    
    lionelShort.addSingleStringAuto("robosel_lionel_short_3-1");
    lionelShort.addDelay(35);
    lionelShort.addHideSub();
    
    lionelShort.addDelay(12);
    
    lionelShort.addSingleStringAuto("robosel_lionel_short_4-1");
    lionelShort.addDelay(32);
    lionelShort.addHideSub();
    
    lionelShort.addDelay(23);
    
    lionelShort.addSingleStringAuto("robosel_lionel_short_5-1");
    lionelShort.addDelay(29);
    lionelShort.addHideSub();
  }
  
  //===================
  // perceval short
  //===================
  
  {
    percevalShort.addSingleStringAuto("robosel_perceval_short_1-1");
    percevalShort.addDelay(22);
    percevalShort.addHideSub();
    
    percevalShort.addDelay(35);
    
    percevalShort.addSingleStringAuto("robosel_perceval_short_2-1");
    percevalShort.addDelay(38);
    percevalShort.addHideSub();
    
    percevalShort.addDelay(24);
    
    percevalShort.addSingleStringAuto("robosel_perceval_short_3-1");
    percevalShort.addDelay(35);
    percevalShort.addHideSub();
    
    percevalShort.addDelay(10);
    
    percevalShort.addSingleStringAuto("robosel_perceval_short_4-1");
    percevalShort.addDelay(36);
    percevalShort.addHideSub();
    
    percevalShort.addDelay(20);
    
    percevalShort.addSingleStringAuto("robosel_perceval_short_5-1");
    percevalShort.addDelay(29);
    percevalShort.addHideSub();
  }
  
  
  
  roboSelScripts[0] = vordanFull;
  roboSelScripts[1] = vordanShort;
  roboSelScripts[2] = garethFull;
  roboSelScripts[3] = garethShort;
  roboSelScripts[4] = lionelFull;
  roboSelScripts[5] = lionelShort;
  roboSelScripts[6] = percevalFull;
  roboSelScripts[7] = percevalShort;
  
  TBufStream ofs;
  int basePos = roboSelScripts.size() * 4;
  ofs.seek(basePos);
  
  for (IdToRoboSelScriptMap::iterator it = roboSelScripts.begin();
       it != roboSelScripts.end();
       ++it) {
    int indexNum = it->first;
    int indexAddr = (indexNum * 4);
    RoboSelScript& script = it->second;
//    int offset = ofs.tell() - indexAddr;
    int offset = ofs.tell();
    
//    cout << indexNum << " " << std::hex << offset << std::endl;
    
    ofs.seek(indexAddr);
    ofs.writeu32le(offset);
    ofs.seek(ofs.size());
    
    script.write(ofs);
  }
  
  ofs.save(outfile.c_str());
  
  return 0;
}
