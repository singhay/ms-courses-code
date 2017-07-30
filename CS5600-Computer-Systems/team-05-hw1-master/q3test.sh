#!/bin/bash

echo "Beginning tests for q3..."
echo

TEST_COUNT=2
success_count=0

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

test -f homework || { echo Could not find executable \"homework\". \
                           Are you sure that you compiled?; exit 0; }

# Test 3.1
echo Test 3.1
echo Program should execute properly
echo --------------
./homework q3 >& q3result.out \
    && { echo -e Result: ${GREEN}PASSED${NC}; let success_count=$success_count+1; } \
    || { echo -e Result: ${RED}FAILED${NC}; }
echo --------------
echo

# Test 3.2
echo Test 3.2
echo Program should produce the expected output
echo -e "program 1\nprogram 2\nprogram 1\nprogram 2\nprogram 1\nprogram 2\nprogram 1\nprogram 2" > q3expected.out
echo --------------
diff -u --label='your output' --label='expected output' q3result.out q3expected.out \
    && { echo -e Result: ${GREEN}PASSED${NC}; let success_count=$success_count+1; } \
    || { echo -e Result: ${RED}FAILED${NC}; }
echo --------------

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
