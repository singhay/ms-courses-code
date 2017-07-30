#!/bin/bash

echo "Beginning tests for q2..."
echo

TEST_COUNT=9
success_count=0

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

test -f homework || { echo Could not find executable \"homework\". \
                           Are you sure that you compiled?; exit 0; }

# Test 2.1
echo Test 2.1
echo It should run the q2prog command
echo ----------------
echo 2.1.a unsuccessful pattern matching
./homework q2 > tmp.out <<EOF
q2prog pattern
line of input
more lines of input, then a blank
line signalling end of input before quit

quit
EOF

has_output=$(test -s homework.c)
if [[ $(cat tmp.out) != "> > " ]]; then
    echo -e Result A: ${RED}FAILED${NC}
else
    echo -e Result A: ${GREEN}PASSED${NC}
    let success_count=$success_count+1
fi
test -s tmp.out || { echo TEST q2.1 failed; exit; }

echo 2.1.b successful pattern matching
./homework q2 > tmp.out <<EOF
q2prog pattern
this line doesn't match
this line has the pattern!

quit
EOF

if grep --quiet "\-\- this line has the pattern!" tmp.out ; then
    echo -e Result B: ${GREEN}PASSED${NC}
    let success_count=$success_count+1
else
    echo -e Result B: ${RED}FAILED${NC}
fi
echo ----------------
echo


# Test 2.2
echo Test 2.2
echo It should be able to handle blank lines
echo ----------------
echo 2.2.a Blank lines alone
./homework q2 > tmp.out <<EOF



quit
EOF

if [[ $(cat tmp.out) != "> > > > " ]]; then
    echo -e Result A: ${RED}FAILED${NC}
else
    echo -e Result A: ${GREEN}PASSED${NC}
    let success_count=$success_count+1
fi
test -s tmp.out || { echo TEST q2.2 failed; exit; }

echo 2.2.b Blank lines mixed with commands
./homework q2 > tmp.out <<EOF

q2prog pattern
this line doesn't match
this line has the pattern!

quit
EOF

if grep --quiet "\-\- this line has the pattern!" tmp.out ; then
    echo -e Result B: ${GREEN}PASSED${NC}
    let success_count=$success_count+1
else
    echo -e Result B: ${RED}FAILED${NC}
fi

echo ----------------
echo


# Test 2.3
echo Test 2.3
echo It should be able to run arbitrary commands
cp q1prog q1prog_cpy
cp q2prog q2prog_cpy
echo ---------------
echo 2.3.a Copy of q1prog
./homework q2 > tmp.out <<EOF
q1prog_cpy
quit
EOF
echo -en "> Hello world\n> " > tmp0.out

if [[ $(cat tmp.out) != $(cat tmp0.out) ]]; then
    echo -e Result A: ${RED}FAILED${NC}
else
    echo -e Result A: ${GREEN}PASSED${NC}
    let success_count=$success_count+1
fi
test -s tmp.out || { echo TEST q2.3 failed; exit; }

echo 2.3.b Copy of q2prog
./homework q2 > tmp.out <<EOF
q2prog_cpy pattern
this line doesn't match
this line has the pattern!

quit
EOF

if grep --quiet "\-\- this line has the pattern!" tmp.out ; then
    echo -e Result B: ${GREEN}PASSED${NC}
    let success_count=$success_count+1
else
    echo -e Result B: ${RED}FAILED${NC}
fi

echo ---------------
echo


# Test 2.4
echo Test 2.4
echo It should handle bad command names gracefully
echo ----------------
./homework q2 > tmp.out <<EOF
grep
quit
EOF
echo -en "> Unable to find command: grep\n> " > bd_cmnd_grcfl.out
if [[ $(cat tmp.out) != $(cat bd_cmnd_grcfl.out) ]]; then
    echo -e Result: ${RED}FAILED${NC}
else
    echo -e Result: ${GREEN}PASSED${NC}
    let success_count=$success_count+1
fi
test -s tmp.out || { echo TEST q2.4 failed; exit; }
echo ----------------
echo


# Test 2.5
echo Test 2.5
echo It should be able to run multiple programs in one session
echo ----------------
./homework q2 > tmp.out <<EOF
q1prog
q2prog test
this line doesn't have test
this line has test

quit
EOF

echo -en "> Hello world\n> -- this line doesn't have test\n-- this line has test\n> " > multpl_prgrm.out

if [[ $(cat tmp.out) != $(cat multpl_prgrm.out) ]]; then
    echo -e Result: ${RED}FAILED${NC}
else
    echo -e Result: ${GREEN}PASSED${NC}
    let success_count=$success_count+1
fi
test -s tmp.out || { echo TEST q2.5 failed; exit; }
echo ----------------
echo


# Test 2.6
echo Test 2.6
echo Valgrind should not identify any memory errors in the program
echo ----------------
valgrind ./homework q2 >& tmp.out <<EOF
q2prog pattern
line without pat...tern
line with pattern

quit
EOF
error_summary=$(grep "ERROR SUMMARY" tmp.out)
echo $error_summary
if [[ $error_summary =~ "ERROR SUMMARY: 0" ]]; then
    echo -e Result: ${GREEN}PASSED${NC}
    let success_count=$success_count+1
else
    echo -e Result: ${RED}FAILED${NC}
fi
echo ----------------
echo

echo
echo Tests Complete: ${success_count}/${TEST_COUNT} Passed

# Clean up
rm *.out
rm q1prog_cpy
rm q2prog_cpy

# Exit code should only be success if all tests passed
if [[ $success_count == $TEST_COUNT ]]; then
    exit 0
else
    exit 1
fi
