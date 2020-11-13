
set -o errexit

make blackt
make libpsx
make dandy_imgextr

mkdir -p img/ADV.PAC_2
for file in rsrc_raw/ADV.PAC_unpacked/2/decmp/*.bin; do
  name=$(basename $file .bin)
  
  ./dandy_imgextr "$file" "img/bg/$name"
done;

# mkdir -p img/ADV.PAC_2
# for file in rsrc_raw/ADV.PAC_unpacked/2/decmp/*.bin; do
#   name=$(basename $file .bin)
#   
#   ./dandy_imgextr "$file" "img/bg/$name"
# done;