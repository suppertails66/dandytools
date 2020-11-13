
set -o errexit

make blackt
make libpsx
make dandy_script_dism

mkdir -p script_dism_test

#for i in {`seq 5 97`,`seq 102 103`}; do
for i in `seq 5 97`; do
  file="files_unpacked/ADV/${i}/0.bin"
  echo $file
  ./dandy_script_dism "$file" "script_dism_test/"
done

