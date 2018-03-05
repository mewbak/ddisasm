# ./reassemble_and_test.sh project_directory binary_path [compiler_flags]
# Take a project directory where the main makefile is located
# and the relative path of the main executable within the directory and:
# -Rebuild the project
# -Disassemble the binary
# -Reassemble the binary (substituting the old one)
# -Run the makefile's tests

# The reassembly uses the 'compiler_flags' arguments

# Example:
# ./CBC_reassemble_and_test.sh /code/cgc-cbs/cqe-challenges/CROMU_00001 -lm
#
. /code/cgc-cbs/sourceme.sh

red=`tput setaf 1`
green=`tput setaf 2`
normal=`tput sgr0`

if [[ $# -eq 0 || $1 == "-h" || $1 == "--help" ]]; then
    printf "USAGE: ./CBC_reassemble_and_test.sh cbc_challenge_dir  [compiler_flags]
 Take a directory of a cbc challenge:
 -build the binary with the compiler flags
 -Disassemble the binary
 -Reassemble the binary with the suffix _2
 -Run the tests on the initial binary
 -Run the tests on the new binary

 The reassembly uses the 'compiler_flags' arguments

 Example:
 ./CBC_reassemble_and_test.sh /code/cgc-cbs/cqe-challenges/CROMU_00001 -O2
"   
    exit
fi

dir=$1
tests=/poller/for-release/
#tests=/poller/for-testing/
shift
exe=$(basename "$dir")
suffix="_2"
new_exe=$exe$suffix
#compiler="gcc"
compiler="clang"
compiler_reassembly="gcc"

main_dir=$(pwd)
cd $dir
build.sh $exe $compiler $@
cd $main_dir

printf "\n\n Disasembling $dir/$exe into $dir/$exe.s"
if !(time(./disasm "$dir/$exe" -asm > "$dir/$exe.s")); then
    printf "\n Disassembly failed\n"
    exit 1
fi
printf "OK\n"
printf "\n Reassembling  $dir/$exe.s into $dir/$new_exe \n"
if !($compiler_reassembly "$dir/$exe.s" -lm -o  "$dir/$new_exe"); then
    echo "Reassembly failed"
    exit 1
fi

printf "\n Testing of the original file\n"
cb-test --directory $dir --cb $exe --xml_dir $dir$tests  >/tmp/original.out

cat /tmp/original.out  | grep   -e "^\# total" -e "^\# polls" >/tmp/original_summary.out
cat /tmp/original_summary.out

printf "\n Testing the new binary $new_exe \n"
cb-test --directory $dir --cb "$new_exe" --xml_dir $dir$tests  >/tmp/new.out
cat /tmp/new.out | grep   -e "^\# total" -e "^\# polls" > /tmp/new_summary.out
cat /tmp/new_summary.out

diff=$(diff /tmp/original_summary.out  /tmp/new_summary.out)
if [[ -z  $diff ]] ; then
    echo "$green TEST OK $normal";
else
    echo "$red TEST FAILED $normal"
    echo "$diff"
    exit 1
fi


