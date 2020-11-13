#include "util/TBufStream.h"
#include "util/TStringConversion.h"
#include "util/TOpt.h"
#include <iostream>

using namespace std;
using namespace BlackT;

int main(int argc, char* argv[]) {
  if (argc < 7) {
    cout << "Binary file patcher" << endl;
    cout << "Usage: " << argv[0] << " <srcfile> <offset> <patchfile>"
      << " <patch_startoffset> <patch_size> <outfile>"
      << " [options]" << endl;
    cout << "Options: " << endl;
    cout << "  l   Sets maximum size of patch file; an error occurs if it"
         << endl
         << "      exceeds this size" << endl;
    
    return 0;
  }
  
  char* infile = argv[1];
  int offset = TStringConversion::stringToInt(string(argv[2]));
  char* patchfile = argv[3];
  int patchStart = TStringConversion::stringToInt(string(argv[4]));
  int patchSize = TStringConversion::stringToInt(string(argv[5]));
  char* outfile = argv[6];
  
  cout << "Patching " << infile << " at " << offset << " with "
    << patchfile << ", to " << outfile << endl;
  
  int maxPatchSize = -1;
  TOpt::readNumericOpt(argc, argv, "-l", &maxPatchSize);
  
  TBufStream file(1);
  file.open(infile);
  
  TBufStream patch(1);
  patch.open(patchfile);
  
  if ((maxPatchSize != -1)
      && (patch.size() > maxPatchSize)) {
    cerr << "Error: patch file is too large (max " << maxPatchSize
      << ", actual " << patch.size() << ")" << endl;
    return 1;
  }
  
  int endOffset = offset + patch.size();
  if (endOffset > file.capacity()) {
    file.setCapacity(endOffset);
  }
  
  file.seek(offset);
  file.write((char*)patch.data().data() + patchStart, patchSize);
  
  file.save(outfile);
  
  return 0;
}
