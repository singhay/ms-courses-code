#!/bin/bash

echo "Beginning tests for q2..."

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

# Test 1
# ------------------
# fs_mkdir tests
./mktest /tmp/test2-image.img
./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
mkdir dir1/dir2/dir3
mkdir dir1/file.0/dir3
mkdir dir1/file.270
mkdir dir1
mkdir dir1/dir2
mkdir dir1/dir3/
ls dir1
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 1 (fs_mkdir)"
read/write block size: 1000
cmd> mkdir dir1/dir2/dir3
error: No such file or directory
cmd> mkdir dir1/file.0/dir3
error: Not a directory
cmd> mkdir dir1/file.270
error: File exists
cmd> mkdir dir1
error: File exists
cmd> mkdir dir1/dir2
cmd> mkdir dir1/dir3/
cmd> ls dir1
dir2
dir3
file.0
file.2
file.270
cmd> quit
EOF

# Stuff the directory until its full
for (( i = 1; i <= 31; i++ )); do
./homework -cmdline -image /tmp/test2-image.img <<EOF > /dev/null
mkdir dir1/dirtest_${i}
quit
EOF
done

# Test for -ENOSPC
./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
mkdir dir1/foo
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 1 (fs_mkdir, part 2)"
read/write block size: 1000
cmd> mkdir dir1/foo
error: No space left on device
cmd> quit
EOF

echo -e Test 1 "(fs_mkdir)": ${GREEN}PASSED${NC}
rm /tmp/test2-image.img


# Test 2
# ------------------
# fs_mknod tests
./mktest /tmp/test2-image.img
touch /tmp/test2-foo
./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
put /tmp/test2-foo dir1/dir2/foo
put /tmp/test2-foo dir1/file.0/foo
put /tmp/test2-foo dir1/file.270
put /tmp/test2-foo dir1
put /tmp/test2-foo dir1/foo
ls dir1
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 2 (fs_mknod)"
read/write block size: 1000
cmd> put /tmp/test2-foo dir1/dir2/foo
error: No such file or directory
cmd> put /tmp/test2-foo dir1/file.0/foo
error: Not a directory
cmd> put /tmp/test2-foo dir1/file.270
error: File exists
cmd> put /tmp/test2-foo dir1
error: File exists
cmd> put /tmp/test2-foo dir1/foo
cmd> ls dir1
file.0
file.2
file.270
foo
cmd> quit
EOF

# Stuff the directory until its full
for (( i = 1; i <= 31; i++ )); do
./homework -cmdline -image /tmp/test2-image.img <<EOF > /dev/null
mkdir dir1/dirtest_${i}
quit
EOF
done

# Test for -ENOSPC
./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
put /tmp/test2-foo dir1/foobar
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 2 (fs_mknod, part 2)"
read/write block size: 1000
cmd> put /tmp/test2-foo dir1/foobar
error: No space left on device
cmd> quit
EOF

echo -e Test 2 "(fs_mknod)": ${GREEN}PASSED${NC}
rm /tmp/test2-image.img


# Test 3
# ------------------
# fs_unlink tests
./mktest /tmp/test2-image.img
./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
rm dir1/dir2/foo
rm dir1/file.0/foo
rm dir1/foobar
rm dir1
rm file.A
rm file.7
rm dir1/file.0
rm dir1/file.270
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 3 (fs_unlink)"
read/write block size: 1000
cmd> rm dir1/dir2/foo
error: No such file or directory
cmd> rm dir1/file.0/foo
error: Not a directory
cmd> rm dir1/foobar
error: No such file or directory
cmd> rm dir1
error: Is a directory
cmd> rm file.A
cmd> rm file.7
cmd> rm dir1/file.0
cmd> rm dir1/file.270
cmd> quit
EOF

# Check that there were no lost blocks
test "$(./read-img /tmp/test2-image.img | tail -2 | wc --words)" = 4 || fail "Test 3 (fs_unlink)"

echo -e Test 3 "(fs_unlink)": ${GREEN}PASSED${NC}

# Test 4
# ------------------
# fs_truncate tests
# Note that we can only test trucating to zero length with the command-line
./mktest /tmp/test2-image.img
./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
truncate dir1/dir2/foo
truncate dir1/file.0/foo
truncate dir1/foobar
truncate dir1
truncate file.A
truncate file.7
truncate dir1/file.0
truncate dir1/file.270
get file.A /tmp/test2-file.A
get file.7 /tmp/test2-file.7
get dir1/file.0 /tmp/test2-file.0
get dir1/file.270 /tmp/test2-file.270
show file.A
show file.7
show dir1/file.0
show dir1/file.270
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 4 (fs_truncate)"
read/write block size: 1000
cmd> truncate dir1/dir2/foo
error: No such file or directory
cmd> truncate dir1/file.0/foo
error: Not a directory
cmd> truncate dir1/foobar
error: No such file or directory
cmd> truncate dir1
error: Is a directory
cmd> truncate file.A
cmd> truncate file.7
cmd> truncate dir1/file.0
cmd> truncate dir1/file.270
cmd> get file.A /tmp/test2-file.A
cmd> get file.7 /tmp/test2-file.7
cmd> get dir1/file.0 /tmp/test2-file.0
cmd> get dir1/file.270 /tmp/test2-file.270
cmd> show file.A
cmd> show file.7
cmd> show dir1/file.0
cmd> show dir1/file.270
cmd> quit
EOF

test $(wc -c < /tmp/test2-file.0) = 0 \
    || fail "Test 4 (fs_truncate); file should be zero length"
test $(wc -c < /tmp/test2-file.A) = 0 \
    || fail "Test 4 (fs_truncate); file should be zero length"
test $(wc -c < /tmp/test2-file.7) = 0 \
    || fail "Test 4 (fs_truncate); file should be zero length"
test $(wc -c < /tmp/test2-file.270) = 0 \
    || fail "Test 4 (fs_truncate); file should be zero length"

# Check that there were no lost blocks
test "$(./read-img /tmp/test2-image.img | tail -2 | wc --words)" = 4 || fail "Test 4 (fs_unlink)"

echo -e Test 4 "(fs_truncate)": ${GREEN}PASSED${NC}


# Test 5
# ------------------
# fs_rmdir tests
./mktest /tmp/test2-image.img
./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
rmdir dir1/dir2/dir3
rmdir dir1/file.0/dir3
rmdir dir1/dir2
rmdir dir1/file.270
rmdir dir1
mkdir foo
ls
rmdir foo
ls
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 5 (fs_mkdir)"
read/write block size: 1000
cmd> rmdir dir1/dir2/dir3
error: No such file or directory
cmd> rmdir dir1/file.0/dir3
error: Not a directory
cmd> rmdir dir1/dir2
error: No such file or directory
cmd> rmdir dir1/file.270
error: Not a directory
cmd> rmdir dir1
error: Directory not empty
cmd> mkdir foo
cmd> ls
dir1
file.7
file.A
foo
cmd> rmdir foo
cmd> ls
dir1
file.7
file.A
cmd> quit
EOF

echo -e Test 5 "(fs_rmdir)": ${GREEN}PASSED${NC}
rm /tmp/test2-image.img


# Test 6
# ------------------
# fs_write tests
test6() {
./mktest /tmp/test2-image.img
BLOCK_SIZE=$1

touch /tmp/test2-file0
yes '0 1 2 3 4 5 6 7' | fmt | head --bytes=5100 > /tmp/test2-file1
yes '0 1 2 3 4 5 6 7' | fmt | head --bytes=40000 > /tmp/test2-file2
yes '0 1 2 3 4 5 6 7' | fmt | head --bytes=270000 > /tmp/test2-file3

./homework -cmdline -image /tmp/test2-image.img <<EOF > /dev/null
blksiz $BLOCK_SIZE
put /tmp/test2-file0 f1
put /tmp/test2-file1 f2
put /tmp/test2-file2 f3
put /tmp/test2-file3 f4
get f1 /tmp/test2-file0x
get f2 /tmp/test2-file1x
get f3 /tmp/test2-file2x
get f4 /tmp/test2-file3x
EOF

cmp /tmp/test2-file0 /tmp/test2-file0x || fail "Test 6 (fs_write, blksiz $BLOCK_SIZE)"
cmp /tmp/test2-file1 /tmp/test2-file1x || fail "Test 6 (fs_write, blksiz $BLOCK_SIZE)"
cmp /tmp/test2-file2 /tmp/test2-file2x || fail "Test 6 (fs_write, blksiz $BLOCK_SIZE)"
cmp /tmp/test2-file3 /tmp/test2-file3x || fail "Test 6 (fs_write, blksiz $BLOCK_SIZE)"
}

test6 111
test6 1000
test6 1024
test6 1517
test6 2701

# Test running out of space on the disk
# The disk should still be readable
./mktest /tmp/test2-image.img
yes '0 1 2 3 4 5 6 7' | fmt | head --bytes=1000000 > /tmp/test2-file4
./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
put /tmp/test2-file4 file
get file /tmp/test2-file4
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 6 (fs_write)"
read/write block size: 1000
cmd> put /tmp/test2-file4 file
error: No space left on device
cmd> get file /tmp/test2-file4
cmd> quit
EOF

test $(wc -c < /tmp/test2-file4) = 744448 || fail "Test 6 (fs_write)"

echo -e Test 6 "(fs_write)": ${GREEN}PASSED${NC}
rm /tmp/test2-image.img


# Test 7
# ------------------
# fs_chmod tests
./mktest /tmp/test2-image.img

./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
chmod 777 dir1/dir2/foo
chmod 777 dir1/file.2/foo
chmod 777 foobar
chmod 555 file.A
ls-l file.A
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 7 (fs_chmod)"
read/write block size: 1000
cmd> chmod 777 dir1/dir2/foo
error: No such file or directory
cmd> chmod 777 dir1/file.2/foo
error: Not a directory
cmd> chmod 777 foobar
error: No such file or directory
cmd> chmod 555 file.A
cmd> ls-l file.A
/file.A -r-xr-xr-x 1000 1 Fri Jul 13 07:04:40 2012
cmd> quit
EOF

echo -e Test 7 "(fs_chmod)": ${GREEN}PASSED${NC}


# Test 8
# ------------------
# fs_utime tests
./mktest /tmp/test2-image.img

./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
utime dir1/dir2/foo
utime dir1/file.2/foo
utime foobar
utime file.A
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 8 (fs_utime)"
read/write block size: 1000
cmd> utime dir1/dir2/foo
error: No such file or directory
cmd> utime dir1/file.2/foo
error: Not a directory
cmd> utime foobar
error: No such file or directory
cmd> utime file.A
cmd> quit
EOF

echo -e Test 8 "(fs_utime)": ${GREEN}PASSED${NC}

# Test 9
# ------------------
# fs_rename tests
./mktest /tmp/test2-image.img

./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
rename foo bar
rename file.A/foo file.A/bar
rename file.A file.7
rename file.A dir1
rename file.A dir1/bar
rename dir1/file.0 foo
rename file.A file.B
ls
rename dir1/file.0 dir1/file.empty
ls dir1
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 9 (fs_rename)"
read/write block size: 1000
cmd> rename foo bar
error: No such file or directory
cmd> rename file.A/foo file.A/bar
error: Not a directory
cmd> rename file.A file.7
error: File exists
cmd> rename file.A dir1
error: File exists
cmd> rename file.A dir1/bar
error: Invalid argument
cmd> rename dir1/file.0 foo
error: Invalid argument
cmd> rename file.A file.B
cmd> ls
dir1
file.7
file.B
cmd> rename dir1/file.0 dir1/file.empty
cmd> ls dir1
file.2
file.270
file.empty
cmd> quit
EOF

echo -e Test 9 "(fs_rename)": ${GREEN}PASSED${NC}

# Test 10
# ------------------
# fs_statfs tests
./homework -cmdline -image /tmp/test2-image.img <<EOF > /tmp/test2-output
statfs
quit
EOF

cmp /tmp/test2-output <<EOF || fail "Test 10 (fs_statfs)"
read/write block size: 1000
cmd> statfs
max name length: 27
block size: 1024
cmd> quit
EOF

echo -e Test 10 "(fs_statfs)": ${GREEN}PASSED${NC}

# Valgrind Tests
# -----------------
# Test a bunch of interactions and make sure valgrind
# doesn't report any errors in the end
./mktest /tmp/test2-image.img

valgrind ./homework -cmdline -image /tmp/test2-image.img >& /tmp/test2-output <<EOF
ls-l
ls dir1
ls file.A
ls-l file.A
show file.A
show file.7
mkdir file.A
mkdir dir1
mkdir dir2
put dir1/homework.c
rm dir1/homework.c
rm dir1
rmdir dir1
rmdir dir2
truncate dir1
truncate file.A
chmod 555 file.7
utime file.7
rename dir1 dir2
quit
EOF
error_summary=$(grep "ERROR SUMMARY" /tmp/test2-output)
echo $error_summary
if [[ $error_summary =~ "ERROR SUMMARY: 0" ]]; then
    echo -e Valgrind Test: ${GREEN}PASSED${NC}
else
    fail "Valgrind found errors"
fi

echo -e ${GREEN}All tests passed!${NC}
# Cleanup
rm -f /tmp/test2-*
