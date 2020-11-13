
echo "*******************************************************************************"
echo "Setting up environment..."
echo "*******************************************************************************"

set -o errexit

BASE_PWD=$PWD
PATH=".:$PATH"

DISCASTER="../discaster/discaster"
ARMIPS="./armips/build/armips"

mkdir -p out

function remapPalette() {
  oldFile=$1
  palFile=$2
  newFile=$3
  
  convert "$oldFile" -dither None -remap "$palFile" PNG32:$newFile
}

# function remapPaletteDithered() {
#   oldFile=$1
#   palFile=$2
#   newFile=$3
#   
#   convert "$oldFile" -dither Riemersma -remap "$palFile" PNG32:$newFile
# }

echo "*******************************************************************************"
echo "Copying game files..."
echo "*******************************************************************************"

#rm -r -f out/files
#if [ ! -e out/files ]; then
  mkdir -p out/files
  cp -r discfiles/* out/files
#fi

echo "*******************************************************************************"
echo "Building tools..."
echo "*******************************************************************************"

make

if [ ! -e $ARMIPS ]; then
  
  echo "********************************************************************************"
  echo "Building armips..."
  echo "********************************************************************************"
  
  cd armips
    mkdir build && cd build
    cmake -DCMAKE_BUILD_TYPE=Release ..
    make
  cd $BASE_PWD
  
fi

echo "*******************************************************************************"
echo "Refreshing archive directories..."
echo "*******************************************************************************"

cp -r rsrc_raw/SINKOU.PAC out

cp -r rsrc_raw/ADV.PAC out
cp -r rsrc_raw/ADV.PAC_unpacked out

cp -r rsrc_raw/SONIC.AOE_unpacked out/SONIC.AOE
cp -r rsrc_raw/SONIC.AOE_individual out

cp -r rsrc_raw/sinkoumodels out

echo "*******************************************************************************"
echo "Building font..."
echo "*******************************************************************************"

# number of actual characters in the font.
# anything at or past this index in the font file should be left blank,
# as it will be used for VWF composition.
# this must be kept at parity with numOldFontReservedChars in the ASM file!
# NOTE: actually, this needs to be numOldFontReservedChars - 0x10.
# the final row is reserved for the raw-format digits needed to generate
# valid number strings for menus.
# by leaving this at a lower value, it will be exempted from the format
# conversion done below with the flipend utility.
# NEW NOTE: never mind
numFontChars=0xB0



mkdir -p out/img

# copy the primary font table from the table folder to the font folder
# so the generic font class reader can be used
cp table/dandy_en.tbl rsrc/font/table.tbl

# HACK: create a copy of the font with a transparent background so the
# automatic character width analysis will work properly
cp rsrc/font/font-img.png rsrc/font/sheet.png
convert rsrc/font/sheet.png -transparent black rsrc/font/sheet.png

# generate character width table
fontbuild "rsrc/font/" $numFontChars "out/img/font_width.bin"

# convert to dandy-format image
dandy_imggen "rsrc/font/font" "out/img/font.bin"

# due to format shenanigans, we need to flip the endianness of all the
# words in the output data that comprise the font bitmap.
# this data begins at 0x40 in the output image file, and there are
# 0x40 bytes per character.
#flipend "out/img/font.bin" 0x40 0x1800 "out/img/font.bin"
flipend "out/img/font.bin" 0x40 $((numFontChars * 0x40)) "out/img/font.bin"

#folded into Makefile_script
# echo "*******************************************************************************"
# echo "Wrapping script..."
# echo "*******************************************************************************"
# 
# mkdir -p out/script
# 
# dandy_script_wrap "script/" "out/script/"

echo "*******************************************************************************"
echo "Building image packs with hardcoded positions for assembler use..."
echo "*******************************************************************************"

#=====================
# robot select
#=====================

mkdir -p out/grp
mkdir -p out/include

cp -r rsrc/roboselect out/grp

for file in out/grp/roboselect/*.png; do
  namePart=$(basename $file)
  remapPalette "$file" "out/grp/roboselect/orig/$namePart" "$file"
  
#  namePartNoExt=$(basename $file -img.png)
#  dandy_imggen "out/grp/roboselect/roboselect/$namePartNoExt" "out/robosel/${namePartNoExt}.bin"
done;

#dandy_seqimggen "out/grp/roboselect/roboselect/" 12 "out/grp/roboselect_overlaygrp.bin" "roboSelectOverlayGrpPack" "out/include/roboselect_overlaygrp.inc"
dandy_seqimggen "out/grp/roboselect/" 13 "out/grp/roboselect_overlaygrp.bin" "roboSelectOverlayGrpPack" "out/include/roboselect_overlaygrp.inc"
dandy_cmp "out/grp/roboselect_overlaygrp.bin" "out/ADV.PAC_unpacked/3/9.bin"

#=====================
# battle mode robot select labels
#=====================

#rm -f -r rsrc_raw/SINKOU.PAC_9
#rm -f -r rsrc_raw/SINKOU.PAC_9_img

cp -r rsrc_raw/SINKOU.PAC_9 out
cp -r rsrc_raw/SINKOU.PAC_9_img out

cp -r rsrc/robolabels out/grp
for file in out/grp/robolabels/*.png; do
  name=$(basename $file)
  
  remapPalette "$file" "out/grp/robolabels/orig/$name" "$file"
  cp "$file" "out/sinkoumodels"
  
  # figure out where to duplicate this file to for the robosel models
  
  primaryNumber=${name%%-*}
  subNumber=${name#${primaryNumber}-*}
  subNumber=${subNumber%%-*}
  
  dupeNum=$(($primaryNumber - 22))
  
  cp "$file" "out/SINKOU.PAC_9_img/$dupeNum-$subNumber-img.png"
#  echo $primaryNumber $subNumber
done;

for i in `seq 45 67`; do
  filename=$i.bin
  dandy_linkimggen "out/sinkoumodels/$i" -1 "out/SINKOU.PAC_decmp/$filename"
  dandy_cmp "out/SINKOU.PAC_decmp/$filename" "out/SINKOU.PAC/$filename"
  
  # in a baffling development, the game includes not one but _two_ copies of
  # the robot models/textures, which contain their nametags, in SINKOU.PAC.
  # (and a third copy, used in the game proper, elsewhere!)
  # they are stored inidividually within the pac as files 45-67,
  # but are also stored as an archive in file 9.
  # this archive consists of 46 sequential compressed files (no header),
  # each of which is a duplicate of one of the individual models.
  # these archived versions are the ones that are actually used to display the
  # nametags for the selection screen. who the hell knows what the others are for.
  
  dupeNum=$(($i - 22))
  dupeFilename=$dupeNum.bin
  
#  cp "out/SINKOU.PAC_decmp/$filename" "out/SINKOU.PAC_9/$dupeFilename"
  
#  cp "out/sinkoumodels/$i-img"
  dandy_linkimggen "out/SINKOU.PAC_9_img/$dupeNum" -1 "out/SINKOU.PAC_9/$dupeNum.bin"
done

# generate the nametag model archive and index
dandy_cmp_seq "out/SINKOU.PAC_9/" "out/SINKOU.PAC/9.bin" "out/include/sinkou9_index.bin"

#=====================
# credits
#=====================

mkdir -p out/credits/split

cp -r rsrc/credits/* out/credits

#cp rsrc/credits/credits.png out/credits/credits.png
#remapPalette rsrc/credits/credits.png rsrc/credits/orig/credits.png out/credits/credits.png
convert "out/credits/credits.png" -filter Point -resize 200%x100% PNG32:"out/credits/credits.png"

dandy_credits_split out/credits/credits.png out/credits/split/
dandy_cmp_seq "out/credits/split/" "out/credits/credits_raw.bin" "out/include/sinkou69_index.bin"
dandy_cmp "out/credits/credits_raw.bin" "out/SINKOU.PAC/69.bin"

# final copyright message
convert "out/credits/68-img.png"   -dither None -remap "out/credits/orig/68-img.png"   -filter Point -resize 200%x100% PNG32:"out/credits/68-img.png"
dandy_imggen "out/credits/68" "out/credits/68_raw.bin"
dandy_cmp "out/credits/68_raw.bin" "out/SINKOU.PAC/68.bin"

echo "*******************************************************************************"
echo "Building script..."
echo "*******************************************************************************"

make -f Makefile_script

#for folder in out/scriptfiles/*; do
#  fileNum=$(basename $folder)
#  cp "$folder/0.bin" "out/ADV.PAC_unpacked/$fileNum"
#done;

echo "*******************************************************************************"
echo "Building robot deployment subtitles..."
echo "*******************************************************************************"

mkdir -p out/robosel
dandy_robosel_submaker "out/robosel/subs.bin"

# new file
cp out/robosel/subs.bin out/ADV.PAC_unpacked/3/15.bin

#cp out/robosel/subs.bin out/robosel/12.bin
#dandy_seqfilegen "out/robosel/" 13 "out/grp/roboselect_overlaygrp.bin" "roboSelectOverlayGrpPack" "out/include/roboselect_overlaygrp.inc"
#dandy_cmp "out/grp/roboselect_overlaygrp.bin" "out/ADV.PAC_unpacked/3/9.bin"

echo "*******************************************************************************"
echo "Building ASM..."
echo "*******************************************************************************"

mkdir -p out/asm

# copy original executables
#cp rsrc_raw/exe/ADV.STM out/asm
#cp rsrc_raw/exe/GAME.XM out/asm
#cp rsrc_raw/exe/SINKOU.S3M out/asm
#cp rsrc_raw/exe/SLPS_022.43 out/asm
dandy_decmp out/files/ADV.STM out/asm/ADV.STM
dandy_decmp out/files/GAME.XM out/asm/GAME.XM
dandy_decmp out/files/SINKOU.S3M out/asm/SINKOU.S3M
cp out/files/SLPS_022.43 out/asm
cp rsrc_raw/SONIC.AOE_unpacked/4.bin out/asm/sonicaoe_4.bin

# build  
$ARMIPS asm/dandy.asm -temp out/asm/temp.txt -sym out/asm/symbols.sym -sym2 out/asm/symbols.sym2

# compress output files as needed
mkdir -p out/asm/compressed
dandy_cmp out/asm/ADV.STM out/asm/compressed/ADV.STM
dandy_cmp out/asm/GAME.XM out/asm/compressed/GAME.XM
dandy_cmp out/asm/SINKOU.S3M out/asm/compressed/SINKOU.S3M

# copy to output folder
cp out/asm/compressed/ADV.STM out/files
cp out/asm/compressed/GAME.XM out/files
cp out/asm/compressed/SINKOU.S3M out/files
cp out/asm/SLPS_022.43 out/files
cp out/asm/sonicaoe_4.bin out/SONIC.AOE/4.bin

echo "*******************************************************************************"
echo "Generating images..."
echo "*******************************************************************************"

mkdir -p out/grp

#=====================
# title frontend
#=====================

# function title_remapAndDecolorize() {
#   infile=$1
#   remapfile=$2
#   palette=$3
#   bpp=$4
#   decolorizedName=$5
#   
#   remapPalette out/grp/$infile out/grp/orig/$remapfile out/grp/$infile
#   psx_img_decolorize out/grp/$infile rsrc_raw/pal/$palette out/grp/$decolorizedName $bpp
# }

function title_remapPalette() {
  infile=$1
  
  remapPalette out/grp/$infile out/grp/orig/$infile out/grp/$infile
}

function title_decolorize() {
  infile=$1
  palette=$2
  bpp=$3
  
  if [ ! -e out/grp/${infile}_color.png ]; then
    echo "title_decolorize(): File not found: out/grp/${infile}_color.png"
  fi
  
  psx_img_decolorize out/grp/${infile}_color.png rsrc_raw/pal/$palette.bin out/grp/$infile.png $bpp
}

cp -r rsrc/grp/* out/grp

#title_remapAndDecolorize title_sub0_color.png title-logo-palette.png title-logo-palette.bin out/grp/title_sub0.png 8
#title_remapAndDecolorize title_sub1_color.png title-logo-palette.png title-logo-palette.bin out/grp/title_sub1.png 8
#title_remapAndDecolorize title_outline1_1_color.png title_outline1_1_color.png rsrc_raw/pal/title-outline1-palette.bin out/grp/title_outline1_1.png 4

remapPalette out/grp/title_sub0_color.png out/grp/orig/title-logo-palette.png out/grp/title_sub0_color.png
remapPalette out/grp/title_sub1_color.png out/grp/orig/title-logo-palette.png out/grp/title_sub1_color.png
remapPalette out/grp/title_shatter_color.png out/grp/orig/title-shatter-palette.png out/grp/title_shatter_color.png
#remapPalette out/grp/title_flash.png out/grp/orig/title_flash.png out/grp/title_flash.png
convert "out/grp/title_flash.png" -dither Riemersma -remap "out/grp/orig/title_flash.png" PNG32:out/grp/title_flash.png
# remapPalette out/grp/title_outline1_1_color.png out/grp/orig/title_outline1_1_color.png out/grp/title_outline1_1_color.png
# remapPalette out/grp/title_outline1_2_color.png out/grp/orig/title_outline1_2_color.png out/grp/title_outline1_2_color.png
# remapPalette out/grp/title_outline2_1_color.png out/grp/orig/title_outline2_1_color.png out/grp/title_outline2_1_color.png
# remapPalette out/grp/title_outline2_2_color.png out/grp/orig/title_outline2_2_color.png out/grp/title_outline2_2_color.png
# remapPalette out/grp/title_shadow_1_color.png out/grp/orig/title_shadow_1_color.png out/grp/title_shadow_1_color.png
# remapPalette out/grp/title_shadow_2_color.png out/grp/orig/title_shadow_2_color.png out/grp/title_shadow_2_color.png
# remapPalette out/grp/title_text_1_color.png out/grp/orig/title_text_1_color.png out/grp/title_text_1_color.png
title_remapPalette title_outline1_1_color.png
title_remapPalette title_outline1_2_color.png
title_remapPalette title_outline2_1_color.png
title_remapPalette title_outline2_2_color.png
title_remapPalette title_shadow_1_color.png
title_remapPalette title_shadow_2_color.png
title_remapPalette title_text_1_color.png
title_remapPalette title_text_2_color.png
title_remapPalette title_text_3_color.png
title_remapPalette title_text_4_color.png
title_remapPalette title_text_5_color.png
title_remapPalette title_text_6_color.png
title_remapPalette title_text_7_color.png
title_remapPalette title_options_1_color.png
title_remapPalette title_options_2_color.png
title_remapPalette title_options_3_color.png
title_remapPalette title_options_4_color.png
title_remapPalette title_options_5_color.png
title_remapPalette title_battle_1_color.png

# psx_img_decolorize out/grp/title_sub0_color.png rsrc_raw/pal/title-logo-palette.bin out/grp/title_sub0.png 8
# psx_img_decolorize out/grp/title_sub1_color.png rsrc_raw/pal/title-logo-palette.bin out/grp/title_sub1.png 8
# psx_img_decolorize out/grp/title_outline1_1_color.png rsrc_raw/pal/title-outline1-palette.bin out/grp/title_outline1_1.png 4
# psx_img_decolorize out/grp/title_outline1_2_color.png rsrc_raw/pal/title-outline1-palette.bin out/grp/title_outline1_2.png 4
# psx_img_decolorize out/grp/title_outline2_1_color.png rsrc_raw/pal/title-outline2-palette.bin out/grp/title_outline2_1.png 4
# psx_img_decolorize out/grp/title_outline2_2_color.png rsrc_raw/pal/title-outline2-palette.bin out/grp/title_outline2_2.png 4
# psx_img_decolorize out/grp/title_shadow_1_color.png rsrc_raw/pal/title-shadow-palette.bin out/grp/title_shadow_1.png 4
# psx_img_decolorize out/grp/title_shadow_2_color.png rsrc_raw/pal/title-shadow-palette.bin out/grp/title_shadow_2.png 4
title_decolorize title_sub0 title-logo-palette 8
title_decolorize title_sub1 title-logo-palette 8
title_decolorize title_shatter title-shatter-palette 8
title_decolorize title_outline1_1 title-outline1-palette 4
title_decolorize title_outline1_2 title-outline1-palette 4
title_decolorize title_outline2_1 title-outline2-palette 4
title_decolorize title_outline2_2 title-outline2-palette 4
title_decolorize title_shadow_1 title-shadow-palette 4
title_decolorize title_shadow_2 title-shadow-palette 4
title_decolorize title_text_1 title-text-palette 4
title_decolorize title_text_2 title-text-palette 4
title_decolorize title_text_3 title-text-palette 4
title_decolorize title_text_4 title-text-palette 4
title_decolorize title_text_5 title-text-palette 4
title_decolorize title_text_6 title-text-palette 4
title_decolorize title_text_7 title-text-palette 4
title_decolorize title_options_1 title-options-palette 4
title_decolorize title_options_2 title-options-palette 4
title_decolorize title_options_3 title-options-palette 4
title_decolorize title_options_4 title-options-palette 4
title_decolorize title_options_5 title-options-palette 4
title_decolorize title_battle_1 title-battle-palette 4

# handle 8-bit title frontend images, which have to be converted to 4-bit
# before being composited into the master image data
#psx_img_bitconv rsrc/grp/title_shatter.png out/grp/title_shatter.png 8 4
#psx_img_bitconv rsrc/grp/title_sub0.png out/grp/title_sub0.png 8 4
#psx_img_bitconv rsrc/grp/title_sub1.png out/grp/title_sub1.png 8 4
psx_img_bitconv out/grp/title_shatter.png out/grp/title_shatter_4bpp.png 8 4
psx_img_bitconv out/grp/title_sub0.png out/grp/title_sub0_4bpp.png 8 4
psx_img_bitconv out/grp/title_sub1.png out/grp/title_sub1_4bpp.png 8 4

# composite onto master image
#cp rsrc/grp/sinkou_0* out/grp
convert out/grp/sinkou_0-img.png\
  out/grp/title_shatter_4bpp.png -geometry +1024+0 -composite\
  out/grp/title_sub0_4bpp.png -geometry +0+360 -composite\
  out/grp/title_sub1_4bpp.png -geometry +256+300 -composite\
  out/grp/title_outline1_1.png -geometry +0+420 -composite\
  out/grp/title_outline1_2.png -geometry +656+256 -composite\
  out/grp/title_outline2_1.png -geometry +512+446 -composite\
  out/grp/title_outline2_2.png -geometry +512+327 -composite\
  out/grp/title_shadow_1.png -geometry +256+420 -composite\
  out/grp/title_shadow_2.png -geometry +656+316 -composite\
  out/grp/title_text_1.png -geometry +992+96 -composite\
  out/grp/title_text_2.png -geometry +1024+184 -composite\
  out/grp/title_text_3.png -geometry +1024+213 -composite\
  out/grp/title_text_4.png -geometry +1280+216 -composite\
  out/grp/title_text_5.png -geometry +1536+0 -composite\
  out/grp/title_text_6.png -geometry +1536+154 -composite\
  out/grp/title_text_7.png -geometry +1600+189 -composite\
  out/grp/title_options_1.png -geometry +960+0 -composite\
  out/grp/title_options_2.png -geometry +960+96 -composite\
  out/grp/title_options_3.png -geometry +0+480 -composite\
  out/grp/title_options_4.png -geometry +1536+173 -composite\
  out/grp/title_options_5.png -geometry +320+240 -composite\
  out/grp/title_battle_1.png -geometry +0+348 -composite\
  out/grp/title_flash.png -geometry +1724+0 -composite\
  PNG32:out/grp/sinkou_0-img.png

# second copy of interface graphics without the title screen data,
# used when reloading after entering into and backing out of a submenu
convert out/grp/sinkou_2-img.png\
  out/grp/title_text_1.png -geometry +992+96 -composite\
  out/grp/title_text_2.png -geometry +1024+184 -composite\
  out/grp/title_text_3.png -geometry +1024+213 -composite\
  out/grp/title_text_4.png -geometry +1280+216 -composite\
  out/grp/title_text_5.png -geometry +1536+0 -composite\
  out/grp/title_text_6.png -geometry +1536+154 -composite\
  out/grp/title_text_7.png -geometry +1600+189 -composite\
  out/grp/title_options_1.png -geometry +960+0 -composite\
  out/grp/title_options_2.png -geometry +960+96 -composite\
  out/grp/title_options_3.png -geometry +0+480 -composite\
  out/grp/title_options_4.png -geometry +1536+173 -composite\
  out/grp/title_options_5.png -geometry +320+240 -composite\
  out/grp/title_battle_1.png -geometry +0+348 -composite\
  PNG32:out/grp/sinkou_2-img.png
  
#convert out/grp/sinkou_0-img.png out/grp/title_sub0.png -geometry +0+360 -composite PNG32:out/grp/sinkou_0-img.png
#convert out/grp/sinkou_0-img.png out/grp/title_sub1.png -geometry +256+300 -composite PNG32:out/grp/sinkou_0-img.png

# convert to data
dandy_imggen out/grp/sinkou_0 out/grp/sinkou_0.bin
dandy_imggen out/grp/sinkou_2 out/grp/sinkou_2.bin
# compress
dandy_cmp out/grp/sinkou_0.bin out/grp/sinkou_0_cmp.bin
dandy_cmp out/grp/sinkou_2.bin out/grp/sinkou_2_cmp.bin
# include in output
cp out/grp/sinkou_0_cmp.bin out/SINKOU.PAC/0.bin
cp out/grp/sinkou_2_cmp.bin out/SINKOU.PAC/2.bin

#=====================
# chapter titles
#=====================

mkdir -p out/chapter_title

#rm -f -r out/chapter_title
cp -r rsrc/chapter_title/raw_grp out/chapter_title

function convertChapterTitle() {
  missionNum=$1
  subfileNum=$2
  
  baseName=${missionNum}_${subfileNum}
  outBaseName=out/chapter_title/raw_grp/${baseName}
  finalFileName=out/chapter_title/raw_grp/${baseName}.bin
  
  # background lettering
  cp rsrc/chapter_title/${baseName}-0.png $outBaseName-0-img.png
#  convert $outBaseName-0-img.png   -dither None -remap "rsrc/chapter_title/raw_grp/6_3-0-img.png"   PNG32:$outBaseName-0-img.png
  img_black_thresholder  $outBaseName-0-img.png $outBaseName-0-img.png
  convert $outBaseName-0-img.png   -dither None -remap "rsrc_raw/pal/chapter-title-back-pal-img.png"   PNG32:$outBaseName-0-img.png
  
  # crop two halves of front lettering graphic into separate images
#  convert rsrc/chapter_title/${baseName}-1.png -crop 160x240+0+0 +repage  -dither None -remap "rsrc/chapter_title/raw_grp/6_3-1-img.png"   PNG32:$outBaseName-1-img.png
#  convert rsrc/chapter_title/${baseName}-1.png -crop 160x240+160+0 +repage  -dither None -remap "rsrc/chapter_title/raw_grp/6_3-1-img.png" PNG32:$outBaseName-2-img.png
  convert rsrc/chapter_title/${baseName}-1.png -crop 160x240+0+0 +repage  -dither None -remap "rsrc_raw/pal/chapter-title-front-pal-img.png"   PNG32:$outBaseName-1-img.png
  convert rsrc/chapter_title/${baseName}-1.png -crop 160x240+160+0 +repage  -dither None -remap "rsrc_raw/pal/chapter-title-front-pal-img.png" PNG32:$outBaseName-2-img.png
  
  dandy_imggen $outBaseName-0 $outBaseName-0.bin
  dandy_imggen $outBaseName-1 $outBaseName-1.bin
  dandy_imggen $outBaseName-2 $outBaseName-2.bin
  
  echo $outBaseName $finalFileName
  dandy_pac_imgarc "$outBaseName-" 3 "$finalFileName"
  cp "$finalFileName" out/ADV.PAC_unpacked/${missionNum}/${subfileNum}.bin
}

function convertChapterTitleSeq() {
  startMissionNum=$1
  endMissionNum=$2
  subfileNum=$3
  
  for i in `seq $startMissionNum $endMissionNum`; do
    convertChapterTitle $i $subfileNum
  done
}

#convert rsrc/chapter_title/6_3-1.png -crop 160x240+0+0 +repage PNG32:test.png
convertChapterTitle 6 3
#convertChapterTitle 7 2
convertChapterTitleSeq 7 64 2
convertChapterTitleSeq 94 95 2

#=====================
# intro
#=====================

convert rsrc/grp/intro.png    -dither None -remap "rsrc/grp/orig/intro.png" PNG32:out/grp/intro.png
cp out/grp/intro.png out/SONIC.AOE_individual/147-11-img.png
cp out/grp/intro.png out/SONIC.AOE_individual/154-9-img.png

dandy_linkimggen "out/SONIC.AOE_individual/147" 12 "out/SONIC.AOE/147.bin"
dandy_linkimggen "out/SONIC.AOE_individual/154" 10 "out/SONIC.AOE/154.bin"

#=====================
# ADV.PAC misc
#=====================

cp -r rsrc/ADV.PAC out/grp
#cp -r rsrc_raw/ADV.PAC_2 out
cp -r rsrc_raw/ADV.PAC_2_raw out

#for file in out/grp/ADV.PAC_individual/*.png; do
for file in out/grp/ADV.PAC/*.png; do
  nameShort=$(basename $file)
  remapPalette "$file" "out/grp/ADV.PAC/orig/$nameShort" "$file"
  
  nameShort=$(basename $file -img.png)
  dandy_imggen "out/grp/ADV.PAC/$nameShort" "out/ADV.PAC_2_raw/$nameShort.bin"
  dandy_cmp  "out/ADV.PAC_2_raw/$nameShort.bin" "out/ADV.PAC_2_raw/$nameShort.bin"
done;

# mkdir -p out/ADV.PAC_2/build
# for file in out/ADV.PAC_2/*.png; do
#   nameShort=$(basename $file -img.png)
#   dandy_imggen "out/ADV.PAC_2/$nameShort" "out/ADV.PAC_2/build/$nameShort.bin"
#   dandy_cmp  "out/ADV.PAC_2/build/$nameShort.bin" "out/ADV.PAC_2/build/$nameShort.bin"
# done;

dandy_pac "out/ADV.PAC_2_raw/" 133 "out/ADV.PAC/2.bin"

#=====================
# ADV.PAC_0
#=====================

cp -r rsrc/ADV.PAC_0 out/grp
mkdir -p out/grp/ADV.PAC_0_img

for file in out/grp/ADV.PAC_0/*.png; do
  nameShort=$(basename $file)
  remapPalette "$file" "out/grp/ADV.PAC_0/orig/$nameShort" "$file"
  
  nameShort=$(basename $file -img.png)
  dandy_imggen "out/grp/ADV.PAC_0/$nameShort" "out/grp/ADV.PAC_0_img/$nameShort.bin"
done;

mkdir -p out/ADV.PAC_0
cp rsrc_raw/ADV.PAC_unpacked/0/*.bin "out/ADV.PAC_0"

dandy_pac_imgarc "out/grp/ADV.PAC_0_img/0-" 8 "out/ADV.PAC_0/0.bin"
dandy_pac_imgarc "out/grp/ADV.PAC_0_img/2-" 12 "out/ADV.PAC_0/2.bin"
dandy_pac_imgarc "out/grp/ADV.PAC_0_img/3-" 14 "out/ADV.PAC_0/3.bin"
dandy_pac_imgarc "out/grp/ADV.PAC_0_img/9-" 5 "out/ADV.PAC_0/9.bin"
dandy_pac_imgarc "out/grp/ADV.PAC_0_img/10-" 6 "out/ADV.PAC_0/10.bin"

#=====================
# ADV.PAC_1
#=====================

cp -r rsrc/ADV.PAC_1 out

#=========
# bustup
#=========

for file in out/ADV.PAC_1/bustup/*.png; do
  nameShort=$(basename $file)
  remapPalette "$file" "out/ADV.PAC_1/bustup/orig/$nameShort" "$file"
done;

mkdir -p out/ADV.PAC_1/bustup/build

dandy_bustup_insr "rsrc_raw/ADV.PAC_unpacked/1/decmp/260.bin" "out/ADV.PAC_1/bustup/260" "out/ADV.PAC_1/bustup/build/260.bin"
dandy_cmp "out/ADV.PAC_1/bustup/build/260.bin" "out/ADV.PAC_unpacked/1/260.bin"

#=========
# bustani
#=========

for file in out/ADV.PAC_1/bustani/*.png; do
  nameShort=$(basename $file)
  remapPalette "$file" "out/ADV.PAC_1/bustani/orig/$nameShort" "$file"
done;

mkdir -p out/ADV.PAC_1/bustani/build
mkdir -p out/ADV.PAC_1/bustani/packed

dandy_imggen out/ADV.PAC_1/bustani/256-grp-0 out/ADV.PAC_1/bustani/build/256-grp-0.bin
for i in `seq 1 9`; do
  dandy_imggen out/ADV.PAC_1/bustani/256-grp-$i out/ADV.PAC_1/bustani/build/256-grp-$i.bin -strippalette
done
dandy_bustani_insr rsrc_raw/ADV.PAC_unpacked/1/decmp/256.bin out/ADV.PAC_1/bustani/build/256 10 out/ADV.PAC_1/bustani/packed/256.bin
dandy_cmp out/ADV.PAC_1/bustani/packed/256.bin out/ADV.PAC_unpacked/1/256.bin

#=====================
# SONIC.AOE misc
#=====================

cp -r rsrc/SONIC.AOE out/grp

for file in out/grp/SONIC.AOE/*.png; do
  nameShort=$(basename $file)
  remapPalette "$file" "out/grp/SONIC.AOE/orig/$nameShort" "$file"
done;

cp out/grp/SONIC.AOE/logosmall.png out/SONIC.AOE_individual/0-0-img.png
cp out/grp/SONIC.AOE/*-img.png out/SONIC.AOE_individual

dandy_linkimggen "out/SONIC.AOE_individual/0" -1 "out/SONIC.AOE/0.bin"
dandy_linkimggen "out/SONIC.AOE_individual/5" -1 "out/SONIC.AOE/5.bin"
dandy_linkimggen "out/SONIC.AOE_individual/22" -1 "out/SONIC.AOE/22.bin"
dandy_linkimggen "out/SONIC.AOE_individual/23" -1 "out/SONIC.AOE/23.bin"

dandy_linkimggen "out/SONIC.AOE_individual/42" -1 "out/SONIC.AOE/42.bin"
dandy_linkimggen "out/SONIC.AOE_individual/49" -1 "out/SONIC.AOE/49.bin"
dandy_linkimggen "out/SONIC.AOE_individual/56" -1 "out/SONIC.AOE/56.bin"
dandy_linkimggen "out/SONIC.AOE_individual/63" -1 "out/SONIC.AOE/63.bin"
dandy_linkimggen "out/SONIC.AOE_individual/70" -1 "out/SONIC.AOE/70.bin"
dandy_linkimggen "out/SONIC.AOE_individual/77" -1 "out/SONIC.AOE/77.bin"
dandy_linkimggen "out/SONIC.AOE_individual/105" -1 "out/SONIC.AOE/105.bin"
dandy_linkimggen "out/SONIC.AOE_individual/196" -1 "out/SONIC.AOE/196.bin"
dandy_linkimggen "out/SONIC.AOE_individual/282" -1 "out/SONIC.AOE/282.bin"
dandy_linkimggen "out/SONIC.AOE_individual/306" -1 "out/SONIC.AOE/306.bin"
dandy_linkimggen "out/SONIC.AOE_individual/398" -1 "out/SONIC.AOE/398.bin"

#=====================
# SINKOU.PAC
#=====================

cp -r rsrc/SINKOU.PAC out/grp
mkdir -p out/grp/SINKOU.PAC_img

for file in out/grp/SINKOU.PAC/*.png; do
  nameShort=$(basename $file)
  remapPalette "$file" "out/grp/SINKOU.PAC/orig/$nameShort" "$file"
  
  nameShort=$(basename $file -img.png)
  dandy_imggen "out/grp/SINKOU.PAC/$nameShort" "out/grp/SINKOU.PAC_img/$nameShort.bin"
  dandy_cmp "out/grp/SINKOU.PAC_img/$nameShort.bin" "out/SINKOU.PAC/$nameShort.bin"
done;

echo "*******************************************************************************"
echo "Packing archives..."
echo "*******************************************************************************"

for folder in out/scriptfiles/*; do
  fileNum=$(basename $folder)
#  echo $fileNum
  cp "$folder/0.bin" "out/ADV.PAC_unpacked/$fileNum"
  dandy_pac "out/ADV.PAC_unpacked/$fileNum/" 6 "out/ADV.PAC/$fileNum.bin"
done;

#dandy_pac "out/ADV.PAC_unpacked/3/" 15 "out/ADV.PAC/3.bin"
dandy_pac "out/ADV.PAC_0/" 15 "out/ADV.PAC/0.bin"
dandy_pac "out/ADV.PAC_unpacked/1/" 289 "out/ADV.PAC/1.bin"
dandy_pac "out/ADV.PAC_unpacked/3/" 16 "out/ADV.PAC/3.bin"

dandy_pac "out/ADV.PAC/" 104 "out/files/ADV.PAC"
dandy_pac "out/SINKOU.PAC/" 181 "out/files/SINKOU.PAC"
dandy_pac "out/SONIC.AOE/" 503 "out/files/SONIC.AOE"

# echo "*******************************************************************************"
# echo "adv 6 test"
# echo "*******************************************************************************"
# 
# #mkdir -p out/ADV.PAC
# #cp files_unpacked/ADV/*.bin out/ADV.PAC
# 
# 
# dandy_script_asm scriptdism/orig/6/script.txt files_unpacked/ADV/6/0.bin 6 out/script/ out/img/font.bin scriptasm_test/test.bin
# cp scriptasm_test/test.bin out/ADV.PAC_unpacked/6/0.bin
# dandy_pac "out/ADV.PAC_unpacked/6/" 5 "out/ADV.PAC/6.bin"
# 
# dandy_script_asm scriptdism/orig/5/script.txt files_unpacked/ADV/5/0.bin 5 out/script/ out/img/font.bin scriptasm_test/test.bin
# cp scriptasm_test/test.bin out/ADV.PAC_unpacked/5/0.bin
# dandy_pac "out/ADV.PAC_unpacked/5/" 2 "out/ADV.PAC/5.bin"
# 
# dandy_pac "out/ADV.PAC/" 104 "out/files/ADV.PAC"
# 
# # mkdir -p rsrc_raw/SINKOU.PAC_decmp/pic
# # for file in rsrc_raw/SINKOU.PAC_decmp/*.bin; do
# #   echo $file
# #   dandy_imgextr "$file" "$(dirname $file)/pic/${file}.png"
# # done;
# # exit
# 
# #cp -r rsrc_raw/SINKOU.PAC_decmp out
# 
# #echo "EXIT"
# #exit

echo "*******************************************************************************"
echo "Building disc..."
echo "*******************************************************************************"

#$DISCASTER "base/dandy.dsc" -d
$DISCASTER "base/dandy.dsc"

echo "*******************************************************************************"
echo "Success!"
echo "*******************************************************************************"
