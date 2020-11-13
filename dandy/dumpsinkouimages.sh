
#set -o errexit

make blackt
make libpsx
make dandy_imgextr
make dandy_linkimgextr
make dandy_unpac_imgarc
make dandy_unpac_imgarc_raw
make dandy_decmp_seq
make dandy_credits_unpack

mkdir -p img/SINKOU.PAC

function quickImgarcConvRaw() {
  infile=$1
  outprefix=$2

  ./dandy_unpac_imgarc_raw "$infile" "$outprefix-"

  for file in $outprefix-*.bin; do
    ./dandy_imgextr "$file" "$(dirname $file)/$(basename $file .bin)"
  done;

}

# mkdir -p img/SINKOU.PAC/cmppack/69
# mkdir -p img/SINKOU.PAC/cmppack/69_img
# ./dandy_decmp_seq img/sinkoutemp/cmppack/69.bin img/SINKOU.PAC/cmppack/69/
# for file in img/SINKOU.PAC/cmppack/69/*.bin; do
#   name=$(basename $file .bin)
#   
# #  ./psx_rawimg_extr
# done;



mkdir -p img/SINKOU.PAC/9_sub
#for file in rsrc_raw/SINKOU.PAC_decmp/*.bin; do
for i in `seq 23 45`; do
  echo $i
  ./dandy_linkimgextr "rsrc_raw/SINKOU.PAC_decmp/9_sub/$i.bin" "img/SINKOU.PAC/9_sub/$i"
done;



mkdir -p img/SINKOU.PAC/credits
./dandy_credits_unpack img/sinkoutemp/cmppack/69.bin img/SINKOU.PAC/credits/credits.png

#exit 0



# mkdir -p img/SINKOU.PAC/imgarc
# for file in img/sinkoutemp/imgarc/*.bin; do
#   name=$(basename $file .bin)
#   
#   echo $file
# #  ./dandy_unpac_imgarc "$file" "img/SINKOU.PAC/imgarc/$name"
# #  ./quick_imgarc_conv.sh "$file" "img/SINKOU.PAC/imgarc/${name}"
#   quickImgarcConvRaw "$file" "img/SINKOU.PAC/imgarc/${name}"
# done;



mkdir -p img/SINKOU.PAC/linkimg
for file in img/sinkoutemp/linkimg/*.bin; do
  name=$(basename $file .bin)
  
  echo $file
  ./dandy_linkimgextr "$file" "img/SINKOU.PAC/linkimg/$name"
done;



mkdir -p img/SINKOU.PAC/img
#for file in rsrc_raw/SINKOU.PAC_decmp/*.bin; do
for file in img/sinkoutemp/img/*.bin; do
  name=$(basename $file .bin)
  
  echo $file
  ./dandy_imgextr "$file" "img/SINKOU.PAC/img/$name"
done;
