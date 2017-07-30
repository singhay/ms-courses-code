#
# file:        Makefile - programming assignment 3
#

CFLAGS = -D_FILE_OFFSET_BITS=64 -g
ifdef COVERAGE
CFLAGS += -fprofile-arcs -ftest-coverage
LD_LIBS = --coverage
endif

FILE = homework
TOOLS = mktest read-img mkfs-x6

# note that implicit make rules work fine for compiling x.c -> x
# (e.g. for mktest). Also, the first target defined in the file gets
# compiled if you run without an argument.
#
all: homework $(TOOLS)

# '$^' expands to all the dependencies (i.e. misc.o homework.o image.o)
# and $@ expands to 'homework' (i.e. the target)
#
homework: misc.o $(FILE).o image.o
	gcc -g $^ -o $@ -lfuse $(LD_LIBS)

clean: 
	rm -f *.o homework $(TOOLS)
