#!/bin/bash

echo "Beginning tests for q1..."
echo

TEST_COUNT=2
success_count=0

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

test -f homework || { echo Could not find executable \"homework\". \
                           Are you sure that you compiled?; exit 0; }

# Test 1.1
echo Test 1.1
echo Program should produce the expected output, \"Hello world\"
echo ------------
./homework q1 > tmp.out
echo Hello world > ref.out
diff -u --label="q1 result" --label="reference" tmp.out ref.out \
    && { echo -e Result: ${GREEN}PASSED${NC}; let success_count=$success_count+1; } \
    || { echo -e Result: ${RED}FAILED${NC}; }
echo ------------
echo

# Test 1.2
echo Test 1.2
echo Valgrind should not identify any memory errors in the program
echo ------------
valgrind ./homework q1 >& tmp.out
error_summary=$(grep "ERROR SUMMARY" tmp.out)
echo $error_summary
if [[ $error_summary =~ "ERROR SUMMARY: 0" ]]; then
    echo -e Result: ${GREEN}PASSED${NC}
    let success_count=$success_count+1
else
    echo -e Result: ${RED}FAILED${NC}
fi
echo ------------

echo
echo Tests Complete: ${success_count}/${TEST_COUNT} Passed

# Clean up
rm *.out

# Exit code should only be success if all tests passed
if [[ $success_count == $TEST_COUNT ]]; then
    exit 0
else
    exit 1
fi
