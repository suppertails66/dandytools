
set -o errexit

make blackt
make libpsx
make dandy_script_dism

mkdir -p scriptdism

#for i in {`seq 5 97`,`seq 102 103`}; do
for i in `seq 5 103`; do
  infile="files_unpacked/ADV/${i}/0.bin"
  outfile="scriptdism/orig/${i}"
  echo $infile
  
  mkdir -p "scriptdism/orig/${i}"
  
  ./dandy_script_dism "$infile" "${outfile}/"
done

