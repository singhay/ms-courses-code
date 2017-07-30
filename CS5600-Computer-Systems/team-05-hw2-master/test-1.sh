#!/bin/bash

echo "Beginning tests for q1..."

RED="\033[0;31m"
GREEN="\033[0;32m"
NC="\033[0m"

# Failure function
fail() {
    echo -e ${RED}FAILED${NC}: $*
    exit 1
}

test -f homework || { echo Could not find executable \"homework\". \
                           Are you sure that you compiled?; exit 0; }

# Create test image
./mktest /tmp/test1-image.img

# Test 1
# ------------------
# fs_getattr tests
./homework -cmdline -image /tmp/test1-image.img <<EOF > /tmp/test1-output
ls-l fakedir/file.2
ls-l file.A/file.foo
ls-l foo
ls-l dir1/foo
ls-l file.A
ls-l dir1/file.0
quit
EOF

cmp /tmp/test1-output <<EOF || fail "Test 1 (fs_getattr)"
read/write block size: 1000
cmd> ls-l fakedir/file.2
error: No such file or directory
cmd> ls-l file.A/file.foo
error: Not a directory
cmd> ls-l foo
error: No such file or directory
cmd> ls-l dir1/foo
error: No such file or directory
cmd> ls-l file.A
/file.A -rwxrwxrwx 1000 1 Fri Jul 13 07:04:40 2012
cmd> ls-l dir1/file.0
/dir1/file.0 -rwxrwxrwx 0 0 Fri Jul 13 07:04:40 2012
cmd> quit
EOF
echo -e Test 1 "(fs_getattr)": ${GREEN}PASSED${NC}

# Test 2
# ------------------
# fs_readdir tests
./homework -cmdline -image /tmp/test1-image.img <<EOF > /tmp/test1-output2
ls
ls-l
ls file.A
ls dir1/file.0
ls dir1
ls foobar
ls dir1/foobar
quit
EOF

cmp /tmp/test1-output2 <<EOF || fail "Test 2 (fs_readdir)"
read/write block size: 1000
cmd> ls
dir1
file.7
file.A
cmd> ls-l
dir1 drwxr-xr-x 0 0 Fri Jul 13 07:08:00 2012
file.7 -rwxrwxrwx 6644 7 Fri Jul 13 07:06:20 2012
file.A -rwxrwxrwx 1000 1 Fri Jul 13 07:04:40 2012
cmd> ls file.A
error: Not a directory
cmd> ls dir1/file.0
error: Not a directory
cmd> ls dir1
file.0
file.2
file.270
cmd> ls foobar
error: No such file or directory
cmd> ls dir1/foobar
error: No such file or directory
cmd> quit
EOF
echo -e Test 2 "(fs_readdir)": ${GREEN}PASSED${NC}

# Test 3
# ------------------
# fs_read tests

# Path translation and "not a file" errors
./homework -cmdline -image /tmp/test1-image.img <<EOF > /tmp/test1-output3
show dir1/foobar
show dir1
quit
EOF

cmp /tmp/test1-output3 <<EOF || fail "Test 3 (fs_read)"
read/write block size: 1000
cmd> show dir1/foobar
error: No such file or directory
cmd> show dir1
error: Is a directory
cmd> quit
EOF

# Please note that the lack of indentation here is intentional for the
# EOF syntax to work
test3() {
BLOCK_SIZE=$1

./homework -cmdline -image /tmp/test1-image.img <<EOF > /dev/null
blksiz $BLOCK_SIZE
get file.A /tmp/test1-file.A
get file.7 /tmp/test1-file.7
get dir1/file.0 /tmp/test1-file.0
get dir1/file.2 /tmp/test1-file.2
get dir1/file.270 /tmp/test1-file.270
quit
EOF

# Test file sizes
test $(wc -c < /tmp/test1-file.0) = 0 \
    || fail "Test 3 (fs_read, blksize $BLOCK_SIZE); file.0 incorrect file size"
test $(wc -c < /tmp/test1-file.A) = 1000 \
    || fail "Test 3 (fs_read, blksize $BLOCK_SIZE); file.A incorrect file size"
test $(wc -c < /tmp/test1-file.2) = 2012 \
    || fail "Test 3 (fs_read, blksize $BLOCK_SIZE); file.2 incorrect file size"
test $(wc -c < /tmp/test1-file.7) = 6644 \
    || fail "Test 3 (fs_read, blksize $BLOCK_SIZE); file.7 incorrect file size"
test $(wc -c < /tmp/test1-file.270) = 276177 \
    || fail "Test 3 (fs_read, blksize $BLOCK_SIZE); file.270 incorrect file size"

# Test file contents
test "$(cat /tmp/test1-file.A | cksum)" = '3509208153 1000' \
    || fail "Test 3 (fs_read, blksize $BLOCK_SIZE); file.A incorrect checksum"
test "$(cat /tmp/test1-file.2 | cksum)" = '3106598394 2012' \
    || fail "Test 3 (fs_read, blksize $BLOCK_SIZE); file.2 incorrect checksum"
test "$(cat /tmp/test1-file.7 | cksum)" = '94780536 6644' \
    || fail "Test 3 (fs_read, blksize $BLOCK_SIZE); file.7 incorrect checksum"
test "$(cat /tmp/test1-file.270 | cksum)" = '1733278825 276177' \
    || fail "Test 3 (fs_read, blksize $BLOCK_SIZE); file.270 incorrect checksum"
}

# Test with various block sizes
test3 111
test3 1024
test3 1517
test3 2701

echo -e Test 3 "(fs_read)": ${GREEN}PASSED${NC}

# Valgrind Tests
# -----------------
# Test a bunch of interactions and make sure valgrind
# doesn't report any errors in the end
valgrind ./homework -cmdline -image /tmp/test2-image.img >& /tmp/test1-output <<EOF
ls
ls-l
ls-l file.A
ls file.A
ls dir1
ls-l dir1
ls dir1/file.270
show file.A
show foo
show dir1/file.270
blksiz 2700
show dir1/file.270
show dir1/file.0
EOF
error_summary=$(grep "ERROR SUMMARY" /tmp/test1-output)
echo $error_summary
if [[ $error_summary =~ "ERROR SUMMARY: 0" ]]; then
    echo -e Valgrind Test: ${GREEN}PASSED${NC}
else
    fail "Valgrind found errors"
fi


echo -e ${GREEN}All tests passed!${NC}
# Cleanup
rm -f /tmp/test1-*
