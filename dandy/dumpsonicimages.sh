
#set -o errexit

make blackt
make libpsx
make dandy_linkimgextr

mkdir -p img/SONIC.AOE

for file in rsrc_raw/SONIC.AOE_unpacked/*.bin; do
  name=$(basename $file .bin)
  
  echo $file
  ./dandy_linkimgextr "$file" "img/SONIC.AOE/$name" -transparency
done;

# mkdir -p img/ADV.PAC_2
# for file in rsrc_raw/ADV.PAC_unpacked/2/decmp/*.bin; do
#   name=$(basename $file .bin)
#   
#   ./dandy_imgextr "$file" "img/bg/$name"
# done;