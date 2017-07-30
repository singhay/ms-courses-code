#!/bin/sh
#
# usage: compile-it.sh  [no arguments] - compile homework.c, q1/2/3progs
#        compile-it.sh clean           - remove all output files
#        compile-it.sh compile prog.c  - compile prog.c into micro-program 'prog'
#

# Compiling the micro-programs is quite tricky. This set of commands
# will compile them into a single static executable with all the
# various sections (.text, .rodata, .data, .bss) mashed into a single
# 4K one.
#
# A single page is used for each micro-program, with the stack starting 
# at the top and the code starting at the bottom. The system call table
# in vector.s goes right above them in memory:
#
#   0x09002000 [vector.s]
#   0x09001000 [q3prog2 - has to live in memory with q3prog1]
#   0x09000000 [all other micro-programs]
#

CC_OPTS='-fno-builtin -fno-stack-protector -fno-zero-initialized-in-bss
             -mpreferred-stack-boundary=2 -march=i386 -g -Wa,--no-warn'

compile_uprog(){
    prog=$1; base=$2
    gcc  ${CC_OPTS} -c $prog.c -o $prog.o
    ld -static --entry=main --section-start .text=$base -o $prog $prog.o vector.o
    size=$(size $prog | cut -f4 | tail -1)
    if [ $size -gt 3000 ] ; then
    	echo "$prog too large: $size bytes, max 3000"
    	echo "   global variables too large?"
    fi
}

compile_vector(){
    as -o vector.o vector.s  # all relocation is in the assembler code
}

# compile the main program 
#
: ${hwfile:=homework}		# see "Parameter Expansion" in 'man sh'
compile_hw(){
    gcc -Wall -O0 -g -c $hwfile.c
    gcc -Wall -O0 -g -c misc.c
    gcc -g misc.o $hwfile.o -o homework
}

compile_all(){
    compile_hw
    compile_vector
    compile_uprog q1prog 0x09000000
    compile_uprog q2prog 0x09000000
    compile_uprog q3prog1 0x09000000
    compile_uprog q3prog2 0x09001000
}

do_clean(){
    rm -f *.o homework *.elf q1prog q2prog q3prog1 q3prog2
}

case x$1 in
    xclean)   do_clean;;
    xcompile) compile_uprog ${2%.c} 0x09000000;;
    *)	      compile_all;;
esac




