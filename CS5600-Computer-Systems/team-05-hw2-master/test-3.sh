#!/bin/bash

echo "Beginning tests for q3..."

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

# Path for holding temporary output
TMP_OUTPUT="/tmp/test3-output"

# Set up and mount the test image
./mktest /tmp/test3-image.img
MOUNT=/tmp/test3
mkdir -p $MOUNT
trap "sleep 1; fusermount -u $MOUNT; rm -rf $MOUNT; rm /tmp/test3-*" 0
./homework -image /tmp/test3-image.img $MOUNT

GRP=$(id -gn)

# Test 1
# ------------------
# getattr and readdir
test "$(ls $MOUNT/dir1)" = \
'file.0
file.2
file.270' || fail "Test 1 (readdir)"
test "$(ls $MOUNT)" = \
'dir1
file.7
file.A' || fail "Test 1 (readdir)"
test "$(ls -l $MOUNT/file.A)" = "-rwxrwxrwx 1 student student 1000 Jul 13  2012 ${MOUNT}/file.A" \
    || fail "Test 1 (getattr)"
test "$(ls $MOUNT/file.foo 2>&1)" = "ls: cannot access $MOUNT/file.foo: No such file or directory" \
    || fail "Test 1 (getattr)"
test "$(ls $MOUNT/file.A/ 2>&1)" = "ls: cannot access $MOUNT/file.A/: Not a directory" \
    || fail "Test 1 (getattr)"
test "$(ls $MOUNT/file.A/foo 2>&1)" = "ls: cannot access $MOUNT/file.A/foo: Not a directory" \
    || fail "Test 1 (getattr)"
test "$(ls $MOUNT/dirfoo/foo 2>&1)" = "ls: cannot access $MOUNT/dirfoo/foo: No such file or directory" \
    || fail "Test 1 (getattr)"

echo -e Test 1 "(getattr/readdir)": ${GREEN}PASSED${NC}

# Test 2
# ------------------
# mkdir, mknod
test "$(touch $MOUNT/dir1/blargus/foo 2>&1)" = "touch: cannot touch ‘$MOUNT/dir1/blargus/foo’: No such file or directory" \
    || fail "Test 2 (mkdir/mknod)"
test "$(touch $MOUNT/file.A/blargus 2>&1)" = "touch: cannot touch ‘$MOUNT/file.A/blargus’: Not a directory" \
    || fail "Test 2 (mkdir/mknod)"
test "$(mkdir $MOUNT/dir1/blargus/foo 2>&1)" = "mkdir: cannot create directory ‘$MOUNT/dir1/blargus/foo’: No such file or directory" \
    || fail "Test 2 (mkdir/mknod)"
test "$(mkdir $MOUNT/file.A/blargus 2>&1)" = "mkdir: cannot create directory ‘$MOUNT/file.A/blargus’: Not a directory" \
    || fail "Test 2 (mkdir/mknod)"
test "$(mkdir $MOUNT/file.A 2>&1)" = "mkdir: cannot create directory ‘$MOUNT/file.A’: File exists" \
    || fail "Test 2 (mkdir/mknod)"
test "$(mkdir $MOUNT/dir1 2>&1)" = "mkdir: cannot create directory ‘$MOUNT/dir1’: File exists" \
    || fail "Test 2 (mkdir/mknod)"
mkdir $MOUNT/newdir
touch $MOUNT/newfile
mkdir $MOUNT/filldir
for (( i = 0; i < 32; i++ )); do
    touch "$MOUNT/filldir/file${i}"
done

TIMESTAMP=$(date +'%Y-%m-%d %H:%M')
test "$(ls -ld --time-style=long-iso $MOUNT/newdir)" =\
     "drwxrwxr-x 1 $USER $GRP 0 $TIMESTAMP ${MOUNT}/newdir" \
    || fail "Test 2 (mkdir)"
TIMESTAMP=$(date +'%Y-%m-%d %H:%M')
test "$(ls -l --time-style=long-iso $MOUNT/newfile)" =\
     "-rw-rw-r-- 1 $USER $GRP 0 $TIMESTAMP ${MOUNT}/newfile" \
    || fail "Test 2 (mknod)"

touch $MOUNT/filldir/newf 2> $TMP_OUTPUT
test "$(cat $TMP_OUTPUT)" =\
     "touch: cannot touch ‘/tmp/test3/filldir/newf’: No space left on device" \
    || fail "Test 2 (mknod)"
mkdir $MOUNT/filldir/newdir 2> $TMP_OUTPUT
test "$(cat $TMP_OUTPUT)" =\
     "mkdir: cannot create directory ‘/tmp/test3/filldir/newdir’: No space left on device" \
    || fail "Test 2 (mkdir)"



echo -e Test 2 "(mknod/mkdir)": ${GREEN}PASSED${NC}

# Test 3
# -------------------
# Read/write

touch /tmp/test3-file0
yes '0 1 2 3 4 5 6 7' | fmt | head --bytes=5100 > /tmp/test3-file1
yes '0 1 2 3 4 5 6 7' | fmt | head --bytes=40000 > /tmp/test3-file2
yes '0 1 2 3 4 5 6 7' | fmt | head --bytes=270000 > /tmp/test3-file3

test3() {
BLOCK_SIZE=$1

dd if=/tmp/test3-file0 of=$MOUNT/f0 bs=$BLOCK_SIZE > /dev/null 2> /dev/null
dd if=/tmp/test3-file1 of=$MOUNT/f1 bs=$BLOCK_SIZE > /dev/null 2> /dev/null
dd if=/tmp/test3-file2 of=$MOUNT/f2 bs=$BLOCK_SIZE > /dev/null 2> /dev/null
dd if=/tmp/test3-file3 of=$MOUNT/f3 bs=$BLOCK_SIZE > /dev/null 2> /dev/null
dd if=$MOUNT/f0 of=/tmp/test3-file0x bs=$BLOCK_SIZE > /dev/null 2> /dev/null
dd if=$MOUNT/f1 of=/tmp/test3-file1x bs=$BLOCK_SIZE > /dev/null 2> /dev/null
dd if=$MOUNT/f2 of=/tmp/test3-file2x bs=$BLOCK_SIZE > /dev/null 2> /dev/null
dd if=$MOUNT/f3 of=/tmp/test3-file3x bs=$BLOCK_SIZE > /dev/null 2> /dev/null
rm $MOUNT/f0
rm $MOUNT/f1
rm $MOUNT/f2
rm $MOUNT/f3

cmp /tmp/test3-file0 /tmp/test3-file0x || fail "Test 3 (read/write, blksiz $BLOCK_SIZE)"
cmp /tmp/test3-file1 /tmp/test3-file1x || fail "Test 3 (read/write, blksiz $BLOCK_SIZE)"
cmp /tmp/test3-file2 /tmp/test3-file2x || fail "Test 3 (read/write, blksiz $BLOCK_SIZE)"
cmp /tmp/test3-file3 /tmp/test3-file3x || fail "Test 3 (read/write, blksiz $BLOCK_SIZE)"
}

test3 111
test3 1000
test3 1024
test3 1517
test3 2701

# Test filling up the disk. The file should still be readable
yes '0 1 2 3 4 5 6 7' | fmt | head --bytes=1000000 > /tmp/test3-file4
TIMESTAMP=$(date +'%Y-%m-%d %H:%M')
test "$(cp /tmp/test3-file4 $MOUNT/f4 2>&1)" = \
"cp: error writing ‘$MOUNT/f4’: No space left on device
cp: failed to extend ‘$MOUNT/f4’: No space left on device" || fail "Test 3 (write)"
test "$(ls -l --time-style=long-iso $MOUNT/f4)" =\
     "-rw-rw-r-- 1 $USER $GRP 742400 $TIMESTAMP ${MOUNT}/f4" \
    || fail "Test 3 (read/write)"
dd if=$MOUNT/f4 of=/tmp/test3-file4x bs=1000 > /dev/null 2> /dev/null
rm $MOUNT/f4

test $(wc -c < /tmp/test3-file4x) = 742400 || fail "Test 3 (write, run out of space)"
echo -e Test 3 "(read/write)": ${GREEN}PASSED${NC}

# Test 4
# -----------------
# Unlink
test "$(rm $MOUNT/dirfoo/foo 2>&1)" = "rm: cannot remove ‘$MOUNT/dirfoo/foo’: No such file or directory" \
    || fail "Test 4 (unlink)"
test "$(rm $MOUNT/file.A/foo 2>&1)" = "rm: cannot remove ‘$MOUNT/file.A/foo’: Not a directory" \
    || fail "Test 4 (unlink)"
test "$(rm $MOUNT/file.X 2>&1)" = "rm: cannot remove ‘$MOUNT/file.X’: No such file or directory" \
    || fail "Test 4 (unlink)"
test "$(rm $MOUNT/dir1 2>&1)" = "rm: cannot remove ‘$MOUNT/dir1’: Is a directory" \
    || fail "Test 4 (unlink)"

mkdir $MOUNT/rmfiles
cp /tmp/test3-file0 $MOUNT/rmfiles/f0
cp /tmp/test3-file1 $MOUNT/rmfiles/f1
cp /tmp/test3-file2 $MOUNT/rmfiles/f2
cp /tmp/test3-file3 $MOUNT/rmfiles/f3

test "$(ls $MOUNT/rmfiles)" = \
'f0
f1
f2
f3' || fail "Test 4 (unlink)"
rm $MOUNT/rmfiles/f0
rm $MOUNT/rmfiles/f1
rm $MOUNT/rmfiles/f2
rm $MOUNT/rmfiles/f3
test "$(ls -l $MOUNT/rmfiles)" = 'total 0' || fail "Test 4 (unlink)"

echo -e Test 4 "(unlink)": ${GREEN}PASSED${NC}

# Test 5
# -----------------
# truncate
test "$(truncate -s 0 $MOUNT/dirfoo/foo 2>&1)" = "truncate: cannot open ‘$MOUNT/dirfoo/foo’ for writing: No such file or directory" \
    || fail "Test 4 (unlink)"
test "$(truncate -s 0 $MOUNT/file.A/foo 2>&1)" = "truncate: cannot open ‘$MOUNT/file.A/foo’ for writing: Not a directory" \
    || fail "Test 4 (unlink)"

TIMESTAMP=$(date +'%Y-%m-%d %H:%M')

mkdir $MOUNT/trunk
cp /tmp/test3-file0 $MOUNT/trunk/f0
cp /tmp/test3-file1 $MOUNT/trunk/f1
cp /tmp/test3-file2 $MOUNT/trunk/f2
cp /tmp/test3-file3 $MOUNT/trunk/f3

TIMESTAMP=$(date +'%Y-%m-%d %H:%M')
test "$(ls -l --time-style=long-iso $MOUNT/trunk)" = \
"total 155
-rw-rw-r-- 1 $USER $GRP      0 $TIMESTAMP f0
-rw-rw-r-- 1 $USER $GRP   5100 $TIMESTAMP f1
-rw-rw-r-- 1 $USER $GRP  40000 $TIMESTAMP f2
-rw-rw-r-- 1 $USER $GRP 270000 $TIMESTAMP f3" || fail "Test 5 (truncate)"

test "$(truncate -s 10 $MOUNT/trunk/f0 2>&1)" = \
    "truncate: failed to truncate ‘$MOUNT/trunk/f0’ at 10 bytes: Invalid argument" \
    || fail "Test 5 (truncate)"
test "$(truncate -s 10 $MOUNT/trunk/f1 2>&1)" = \
    "truncate: failed to truncate ‘$MOUNT/trunk/f1’ at 10 bytes: Invalid argument" \
    || fail "Test 5 (truncate)"
test "$(truncate -s 10 $MOUNT/trunk/f2 2>&1)" = \
    "truncate: failed to truncate ‘$MOUNT/trunk/f2’ at 10 bytes: Invalid argument" \
    || fail "Test 5 (truncate)"
test "$(truncate -s 10 $MOUNT/trunk/f3 2>&1)" = \
    "truncate: failed to truncate ‘$MOUNT/trunk/f3’ at 10 bytes: Invalid argument" \
    || fail "Test 5 (truncate)"
test "$(ls -l --time-style=long-iso $MOUNT/trunk)" = \
"total 155
-rw-rw-r-- 1 $USER $GRP      0 $TIMESTAMP f0
-rw-rw-r-- 1 $USER $GRP   5100 $TIMESTAMP f1
-rw-rw-r-- 1 $USER $GRP  40000 $TIMESTAMP f2
-rw-rw-r-- 1 $USER $GRP 270000 $TIMESTAMP f3" || fail "Test 5 (truncate)"

truncate -s 0 $MOUNT/trunk/f0
truncate -s 0 $MOUNT/trunk/f1
truncate -s 0 $MOUNT/trunk/f2
truncate -s 0 $MOUNT/trunk/f3
test "$(ls -l --time-style=long-iso $MOUNT/trunk)" = \
"total 0
-rw-rw-r-- 1 $USER $GRP 0 $TIMESTAMP f0
-rw-rw-r-- 1 $USER $GRP 0 $TIMESTAMP f1
-rw-rw-r-- 1 $USER $GRP 0 $TIMESTAMP f2
-rw-rw-r-- 1 $USER $GRP 0 $TIMESTAMP f3" || fail "Test 5 (truncate)"

echo -e Test 5 "(truncate)": ${GREEN}PASSED${NC}

# Test 6
# ----------
# rmdir

# Actually removes
mkdir $MOUNT/test6-dir0
rmdir $MOUNT/test6-dir0
test "$(ls $MOUNT/test6-dir0 2>&1)" = \
     "ls: cannot access $MOUNT/test6-dir0: No such file or directory" \
     || fail "Test 6 (rmdir)"

# Trying to remove a file
touch $MOUNT/test6-file0
test "$(rmdir $MOUNT/test6-file0 2>&1)" = \
     "rmdir: failed to remove ‘$MOUNT/test6-file0’: Not a directory" \
     || fail "Test 6 (rmdir: Trying to remove a file)"

# Node in path is not a directory
test "$(rmdir $MOUNT/test6-file0/dir1 2>&1)" = \
     "rmdir: failed to remove ‘$MOUNT/test6-file0/dir1’: Not a directory" \
     || fail "Test 6 (rmdir: node in path is not a directory)"

# File does not exist
test "$(rmdir $MOUNT/dir1/test6-file0 2>&1)" = \
     "rmdir: failed to remove ‘$MOUNT/dir1/test6-file0’: No such file or directory" \
     || fail "Test 6 (rmdir: file does not exist)"

# Dir does not exist
test "$(rmdir $MOUNT/dir2/test6-file0 2>&1)" = \
     "rmdir: failed to remove ‘$MOUNT/dir2/test6-file0’: No such file or directory" \
     || fail "Test 6 (rmdir: directory does not exist)"

# Dir not empty
test "$(rmdir $MOUNT/dir1/ 2>&1)" = \
     "rmdir: failed to remove ‘$MOUNT/dir1/’: Directory not empty" \
     || fail "Test 6 (rmdir: directory not empty)"

echo -e Test 6 "(rmdir)": ${GREEN}PASSED${NC}


# Test 7
# ----------
# chmod

touch $MOUNT/test7-file0
chmod 666 $MOUNT/test7-file0
test "$(ls -l --time-style=long-iso $MOUNT/test7-file0 2>&1)" = \
     "-rw-rw-rw- 1 $USER $GRP 0 $TIMESTAMP $MOUNT/test7-file0" \
     || fail "Test 7 (chmod)"
mkdir $MOUNT/chdir
chmod 666 $MOUNT/chdir
test "$(ls -ld --time-style=long-iso $MOUNT/chdir 2>&1)" = \
     "drw-rw-rw- 1 $USER $GRP 0 $TIMESTAMP $MOUNT/chdir" \
     || fail "Test 7 (chmod)"
rmdir $MOUNT/chdir

echo -e Test 7 "(chmod)": ${GREEN}PASSED${NC}


# Test 8
# ----------
# rename

touch $MOUNT/test8-file0

# File doesn't exist
test "$(mv $MOUNT/blargusfasd $MOUNT/test8-file0-renamed 2>&1)" = \
     "mv: cannot stat ‘$MOUNT/blargusfasd’: No such file or directory" \
     || fail "Test 8 (rename: file does not exist)"

# middle part of path is a file
test "$(mv $MOUNT/file.A/foo $MOUNT/file.A/bar 2>&1)" = \
     "mv: failed to access ‘$MOUNT/file.A/bar’: Not a directory" \
     || fail "Test 8 (rename: middle part of path is a file)"

# File doesn't exist inside directory
test "$(mv $MOUNT/dir1/test8-file0 $MOUNT/test8-file0-renamed 2>&1)" = \
     "mv: cannot stat ‘$MOUNT/dir1/test8-file0’: No such file or directory" \
     || fail "Test 8 (rename: file does not exist inside directory)"

# Directory doesn't exist
test "$(mv $MOUNT/foodir/test8-file0 $MOUNT/foodir/test8-file0-renamed 2>&1)" = \
     "mv: cannot stat ‘$MOUNT/foodir/test8-file0’: No such file or directory" \
     || fail "Test 8 (rename: directory does not exist)"

# Destination is a file
touch $MOUNT/test8-file0-renamed
test "$(mv $MOUNT/test8-file0 $MOUNT/file.A 2>&1)" = \
     "mv: cannot move ‘$MOUNT/test8-file0’ to ‘$MOUNT/file.A’: File exists" \
     || fail "Test 8 (rename: destination exists, is a file)"
rm $MOUNT/test8-file0-renamed

# Destination exists and is a directory
# Note that fuse actually modifies the paths so that the dest path is $MOUNT/dir1/test8-file0
# because it recognizes dir1 is a directory
touch $MOUNT/test8-file0-renamed
test "$(mv $MOUNT/test8-file0 $MOUNT/dir1 2>&1)" = \
     "mv: cannot move ‘$MOUNT/test8-file0’ to a subdirectory of itself, ‘$MOUNT/dir1/test8-file0’" \
     || fail "Test 8 (rename: destination exists and is a directory)"

# No moving between directories
touch $MOUNT/dir1/test8-file0
mkdir $MOUNT/dir2
test "$(mv $MOUNT/dir1/test8-file0 $MOUNT/dir2/test8-file0-renamed 2>&1)" = \
     "mv: cannot move ‘$MOUNT/dir1/test8-file0’ to a subdirectory of itself, ‘$MOUNT/dir2/test8-file0-renamed’" \
     || fail "Test 8 (rename: no moving between directories)"

# Successful rename
mv $MOUNT/test8-file0 $MOUNT/renamed
test "$(ls -l --time-style=long-iso $MOUNT/renamed 2>&1)" = \
     "-rw-rw-r-- 1 $USER $GRP 0 $TIMESTAMP $MOUNT/renamed" \
     || fail "Test 8 (rename)"


echo -e Test 8 "(rename)": ${GREEN}PASSED${NC}


# Test 9
# ----------
# utime

touch -d 'Jan 01 2000' $MOUNT/test9-file0
test "$(ls -l $MOUNT/test9-file0 2>&1)" = \
     "-rw-rw-r-- 1 $USER $GRP 0 Jan  1  2000 $MOUNT/test9-file0" \
     || fail "Test 9 (utime)"

echo -e Test 9 "(utime)": ${GREEN}PASSED${NC}
