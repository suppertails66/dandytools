
function unpackImgarcFile() {
  src=$1
  dst=$2
  
#  mkdir -p "$dst"
  
  echo "unpacking $src to $dst"
  ./dandy_unpac_imgarc "$src" "$dst"
}

function unpackChapterTitleImg() {
  missionNum=$1
  subfileNum=$2
  
  outBaseName=${missionNum}_${subfileNum}
  
  input=rsrc_raw/ADV.PAC_unpacked/$missionNum/$subfileNum.bin
  output=rsrc/chapter_title/raw/$outBaseName-
  
  unpackImgarcFile "$input" "$output"
  
  for subimgNum in `seq 0 2`; do
    inputGrp=rsrc/chapter_title/raw/$outBaseName-$subimgNum.bin
    outputGrp=rsrc/chapter_title/raw_grp/${outBaseName}-${subimgNum}
    echo $inputGrp $outputGrp
    # FIXME
    ./dandy_imgextr "$inputGrp" "$outputGrp" -transparency
  done;
  
  # copy letter image
  outPref=rsrc/chapter_title/raw_grp/${outBaseName}
  cp $outPref-0-img.png rsrc/chapter_title/orig/${outBaseName}-0.png
  # glue together two halves of overlay
  convert -page +0+0 $outPref-1-img.png -page +160+0 $outPref-2-img.png -background none -layers mosaic PNG32:rsrc/chapter_title/orig/${outBaseName}-1.png
}

function unpackChapterTitleImgSeq() {
  startMissionNum=$1
  endMissionNum=$2
  subfileNum=$3
  
  for i in `seq $startMissionNum $endMissionNum`; do
    unpackChapterTitleImg $i $subfileNum
  done;
}

set -o errexit



make

mkdir -p rsrc/chapter_title/raw
mkdir -p rsrc/chapter_title/raw_grp
mkdir -p rsrc/chapter_title/orig

unpackChapterTitleImg 6 3
#unpackChapterTitleImg 7 2
unpackChapterTitleImgSeq 7 64 2
unpackChapterTitleImgSeq 94 95 2

# 
# for i in {`seq 5 97`,`seq 102 103`}; do
# #   unpackSmallFile "files_unpacked/ADV/$i/1.bin" "portraits_unpacked/$i/1"
# #   for file in portraits_unpacked/$i/1_small/*.bin; do
# #     decmpFile $file
# #   done
#   
#   for file in portraits_unpacked/$i/1_small/decmp/*.bin; do
# #    echo portraits_unpacked/$i/1_small/decmp/$(basename $file .bin).grp
#     dst=portraits_unpacked/$i/1_small/decmp/$(basename $file .bin).png
#     echo $file
#     echo $dst
#     ./dandy_imgextr "$file" "$dst"
#   done
# done
# 
