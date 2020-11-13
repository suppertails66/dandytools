
infile=$1
outprefix=$2

make libpsx
make dandy_unpac_imgarc
make dandy_imgextr

./dandy_unpac_imgarc "$infile" "$outprefix-"

for file in $outprefix-*.bin; do
  ./dandy_imgextr "$file" "$(dirname $file)/$(basename $file .bin)" -transparency
  rm "$file"
done;

