
function unpackFile() {
  src=$1
  dst=$2
  
  mkdir -p "$dst"
  
  echo "unpacking $src to $dst"
  ./dandy_unpac "$src" "$dst/"
}

function unpackSmallFile() {
  src=$1
  dst=$2_small
  
  mkdir -p "$dst"
  
  echo "unpacking $src to $dst"
  ./dandy_unpac_small "$src" "$dst/"
}

function decmpFile() {
  src=$1
#  dst=$2
  
  fileName=$(basename $src)
  folderPath=$(dirname $src)/decmp
  
  mkdir -p "$folderPath"
  
  dst=$folderPath/$fileName
  
  echo "decompressing $src to $dst"
  ./dandy_decmp "$src" "$folderPath/$fileName"
}

decmpFolder() {
  src=$1
  
  echo "decompressing folder $src"
  for file in $src/*; do
    if [ -f $file ]; then
      echo $file
      decmpFile $file
    fi
  done;
}

set -o errexit



make

mkdir -p files_unpacked

# # unpackFile files/ADV.PAC files_unpacked/ADV
# #   for i in `seq 0 103`; do
# #     unpackFile files_unpacked/ADV/$i.bin files_unpacked/ADV/$i
# #   done
# # #   unpackFile files_unpacked/ADV/0.bin files_unpacked/ADV/0
# # #   unpackFile files_unpacked/ADV/1.bin files_unpacked/ADV/1
# # #   unpackFile files_unpacked/ADV/2.bin files_unpacked/ADV/2
# # #   unpackFile files_unpacked/ADV/3.bin files_unpacked/ADV/3
# # #   unpackFile files_unpacked/ADV/4.bin files_unpacked/ADV/4
# #   unpackSmallFile "files_unpacked/ADV/5/1.bin" files_unpacked/ADV/5/1
#   unpackSmallFile "files_unpacked/ADV/6/1.bin" files_unpacked/ADV/6/1
# 
# # for i in `seq 0 10`; do
# #   decmpFile files_unpacked/ADV/0/$i.bin
# # done
# # decmpFolder files_unpacked/ADV/1
# # decmpFolder files_unpacked/ADV/2
# # for i in {`seq 0 0`,`seq 2 6`,`seq 9 11`,`seq 13 14`}; do
# #   decmpFile files_unpacked/ADV/3/$i.bin
# # done
# # decmpFolder files_unpacked/ADV/4
# # decmpFolder files_unpacked/ADV/5/1_small
# decmpFolder files_unpacked/ADV/6/1_small
# decmpFile files_unpacked/ADV/6/3.bin
# 
# 
# 
# 
# 
# 
# 
# #   for i in {`seq 0 10`,`seq 14 14`}; do
# #     decmpFile files_unpacked/ADV/0/$i.bin
# #   done
# 

for i in {`seq 5 97`,`seq 102 103`}; do
#   unpackSmallFile "files_unpacked/ADV/$i/1.bin" "portraits_unpacked/$i/1"
#   for file in portraits_unpacked/$i/1_small/*.bin; do
#     decmpFile $file
#   done
  
  for file in portraits_unpacked/$i/1_small/decmp/*.bin; do
#    echo portraits_unpacked/$i/1_small/decmp/$(basename $file .bin).grp
    dst=portraits_unpacked/$i/1_small/decmp/$(basename $file .bin).png
    echo $file
    echo $dst
    ./dandy_imgextr "$file" "$dst"
  done
done

