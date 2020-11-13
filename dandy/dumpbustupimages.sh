
#set -o errexit

make blackt
make libpsx
make dandy_bustup_extr
make dandy_bustani_extr
make dandy_imgextr

mkdir -p img/bustup
mkdir -p img/bustani
mkdir -p img/bustani_img

for file in rsrc_raw/ADV.PAC_unpacked/1/decmp/*.bin; do
  name=$(basename $file .bin)
  
  echo $file
#  ./dandy_linkimgextr "$file" "img/SONIC.AOE/$name" -transparency
  ./dandy_bustup_extr "$file" "img/bustup/$name"
  
  # if bustup_extr failed, use bustani_extr
  if [ $? != 0 ]; then
    ./dandy_bustani_extr "$file" "img/bustani/$name"
    
    if [ $? == 0 ]; then
      # only the first file contains the palette.
      # force subsequent entries to use it.
      
      ./dandy_imgextr "img/bustani/$name-grp-0.bin" "img/bustani_img/$name-grp-0_forpal"
      
      for subfile in img/bustani/${name}*.bin; do
        subnameShort=$(basename $subfile .bin)
        ./dandy_imgextr "$subfile" "img/bustani_img/$subnameShort" -forcepalette "img/bustani_img/$name-grp-0_forpal-pal.bin"
      done;
      
      rm -f img/bustani_img/$name-grp-0_forpal*
    fi
  fi
done;

# mkdir -p img/ADV.PAC_2
# for file in rsrc_raw/ADV.PAC_unpacked/2/decmp/*.bin; do
#   name=$(basename $file .bin)
#   
#   ./dandy_imgextr "$file" "img/bg/$name"
# done;