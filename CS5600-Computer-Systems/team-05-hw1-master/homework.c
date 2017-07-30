/*
 * file:        homework.c
 * description: Skeleton for homework 1
 *
 * CS 5600, Computer Systems, Northeastern CCIS
 * Peter Desnoyers, Jan. 2012
 * $Id: homework.c 500 2012-01-15 16:15:23Z pjd $
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>

#include "elf32.h"
#include "uprog.h"

/***********************************/
/* Declarations for code in misc.c */
/***********************************/

extern void init_memory(void);
extern void do_switch(void **location_for_old_sp, void *new_value);
extern void *setup_stack(void *stack, void *func);
extern int get_term_input(char *buf, size_t len);
extern void init_terms(void);

extern void  **vector;          /* system call vector */


/***********************************************/
/********* Your code starts here ***************/
/***********************************************/

/*
 * Loads the given ELF file into memory.
 *
 * Inputs:
 * - filename: name of the file to load
 * Outputs:
 * - alloc_addr: address allocated with mmap
 * - entry_addr: the entry point address specified in the ELF header
 * Returns:
 * 0 for success, 1 for failure (e.g. file not found)
 */
int load_elf_file(char *filename, void **alloc_addr, void **entry_addr)
{
    // Read the ELF header
    struct elf32_ehdr hdr;
    int fd = open(filename, O_RDONLY);
    read(fd, &hdr, sizeof(hdr));

    *entry_addr = hdr.e_entry;

    int numHeaders = hdr.e_phnum;
    struct elf32_phdr phdrs[numHeaders];
    lseek(fd, hdr.e_phoff, SEEK_SET);
    read(fd, &phdrs, sizeof(phdrs));

    // Search for the program header that should be loaded into memory
    int i;
    for(i = 0; i < numHeaders; i++) {
        if(phdrs[i].p_type == PT_LOAD) {
            *alloc_addr = phdrs[i].p_vaddr;
            void *buf = mmap(*alloc_addr, 4096, PROT_READ | PROT_WRITE |
                PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS | MAP_FIXED, -1, 0);
            if(buf == MAP_FAILED) {
                perror("mmap failed in loading ELF PT_LOAD header");
                close(fd);
                return 1;
            }
            lseek(fd, phdrs[i].p_offset, SEEK_SET);
            read(fd, buf, phdrs[i].p_filesz);
            close(fd);

            return 0;
        }
    }

    perror("No PT_LOAD header found");
    return 1;
}

/**
 * Attempts to load an ELF file into memory and run it.
 *
 * Inputs:
 * - filename, the name of the file to load
 *
 * Returns:
 * 1 if the file could not be loaded, else 0.
 */
int load_and_run_elf_file(char *filename)
{
    // Attempt to to load the command into memory
    void *alloc_addr = NULL;
    void *entry_addr = NULL;
    int load_success;
    load_success = load_elf_file(filename, &alloc_addr, &entry_addr);

    // File failed to load, return error
    if(load_success == 1) {
        return 1;
    }

    // Run the program
    void (*f)() = NULL;
    f = entry_addr;
    f();

    return 0;
}

/*
 * Question 1.
 *
 * The micro-program q1prog.c has already been written, and uses the
 * 'print' micro-system-call (index 0 in the vector table) to print
 * out "Hello world".
 *
 * You'll need to write the (very simple) print() function below, and
 * then put a pointer to it in vector[0].
 *
 * Then you read the micro-program 'q1prog' into 4KB of memory starting
 * at the address indicated in the program header, then execute it,
 * printing "Hello world".
 */

/**
 * Prints a string to stdout
 *
 * Inputs:
 * - *line, the string to print
 */
void print(char *line)
{
    printf("%s", line);
}

void q1(void)
{
    // Initialize the vector table
    vector[0] = &print;

    load_and_run_elf_file("q1prog");
}


/*
 * Question 2.
 *
 * Add two more functions to the vector table:
 *   void readline(char *buf, int len) - read a line of input into 'buf'
 *   char *getarg(int i) - gets the i'th argument (see below)

 * Write a simple command line which prints a prompt and reads command
 * lines of the form 'cmd arg1 arg2 ...'. For each command line:
 *   - save arg1, arg2, ... in a location where they can be retrieved
 *     by 'getarg'
 *   - load and run the micro-program named by 'cmd'
 *   - if the command is "quit", then exit rather than running anything
 *
 * Note that this should be a general command line, allowing you to
 * execute arbitrary commands that you may not have written yet. You
 * are provided with a command that will work with this - 'q2prog',
 * which is a simple version of the 'grep' command.
 *
 * NOTE - your vector assignments have to mirror the ones in vector.s:
 *   0 = print
 *   1 = readline
 *   2 = getarg
 */

#define MAX_LINE_LENGTH 120
#define MAX_ARGS 10
#define MAX_ARG_LENGTH 20
#define DELIMITER " \t\n"

/**
 * Reads a line of input into the given buffer until return is pressed
 * or the specified length is reached. The read input is terminated with a
 * NULL character.
 *
 * Inputs:
 * - buf, the string to fill with the user's input
 * - len, the maximum number of bytes to read
 */
void readline(char *buf, int len) /* vector index = 1 */
{
    fgets(buf, len, stdin);
}

// Buffer stores the command in index 0, plus up to 10 args
// (hence MAX_ARGS + 1 size)
char arg_buffer[MAX_ARGS + 1][MAX_ARG_LENGTH];
int highest_arg_ix;

/**
 * Gets the command from the most recent input (i.e. the first
 * word).
 *
 * Returns:
 * The string which is the first word of the last entry. It will
 * return the empty string if the user provided an empty line.
 */
char *getcommand()
{
    return arg_buffer[0];
}

/**
 * Gets the argument at the indicated index.
 *
 * Inputs:
 * - i, the 0-based index of the argument.
 *
 * Returns:
 * The ith argument passed to the command as a string, or
 * NULL if invalid.
 */
char *getarg(int i)		/* vector index = 2 */
{
    i++; // Account for offset from command
    if(i > MAX_ARGS || i > highest_arg_ix) {
        return NULL;
    }
    return arg_buffer[i];
}

/**
 * Gets the next word from string s, delimited by the characters in
 * the string "delim".
 *
 * Inputs:
 * - *s, the string to extract the word from
 * - *buf, the char array to store words in
 * - len, the number of bytes to store into the buffer
 * - *delim, string containing the delimiter characters
 *
 * Returns:
 * A pointer to the location in *s immediately after the word,
 * or NULL if the end of the string was reached.
 */
char *strwrd(char *s, char *buf, size_t len, char *delim)
{
    s += strspn(s, delim);
    // Count the span of bytes (characters) in the complement of *delim
    int n = strcspn(s, delim);
    if(len - 1 < n) {
        n = len - 1;
    }
    memcpy(buf, s, n);
    buf[n] = 0;
    s += n;
    return (*s == 0) ? NULL : s;
}

/*
 * Note - see c-programming.pdf for sample code to split a line into
 * separate tokens.
 */
void q2(void)
{
    // Initialize vector table
    vector[0] = &print;
    vector[1] = &readline;
    vector[2] = &getarg;

    while (1) {
        printf("> ");

        // Read the line and store all words in the arg buffer
        char line[MAX_LINE_LENGTH];
        char *line_ptr = line;
        readline(line, MAX_LINE_LENGTH);

        int arg_ix;
        for(arg_ix = 0; arg_ix <= MAX_ARGS; arg_ix++) {
            line_ptr = strwrd(line_ptr, arg_buffer[arg_ix], MAX_ARG_LENGTH, DELIMITER);
            if(line_ptr == NULL) {
                break;
            }
        }
        // Minus one to account for the first word being the command
        highest_arg_ix = arg_ix - 1;

        char *command = getcommand();
        if(strcmp(command, "") == 0) {
            continue;
        }
        else if(strcmp(command, "quit") == 0) {
            break;
        }

        // Attempt to run the program
        int load_success;
        load_success = load_and_run_elf_file(command);

        // Report an error if the command could not be loaded
        // (i.e. file not found)
        if(load_success == 1) {
            printf("Unable to find command: %s\n", command);
        }
    }
}

/*
 * Question 3.
 *
 * Create two processes which switch back and forth.
 *
 * You will need to add another 3 functions to the table:
 *   void yield12(void) - save process 1, switch to process 2
 *   void yield21(void) - save process 2, switch to process 1
 *   void uexit(void)   - return to original homework.c stack
 *
 * The code for this question will load 2 micro-programs, q3prog1 and
 * q3prog2, which are provided and merely consists of interleaved
 * calls to yield12() or yield21() and print(), finishing with uexit().
 *
 * Hints:
 * - Use setup_stack() to set up the stack for each process. It returns
 *   a stack pointer value which you can switch to.
 * - you need a global variable for each process to store its context
 *   (i.e. stack pointer)
 * - To start you use do_switch() to switch to the stack pointer for
 *   process 1
 */

#define PAGE_SIZE 4096

// Global variable for each process to store its context
void *p1_sp = NULL;
void *p2_sp = NULL;
void *q3_sp = NULL;

/**
 * Stores the current stack pointer for process 1 and switches to process 2
 */
void yield12(void)      /* vector index = 3 */
{
    do_switch(&p1_sp, p2_sp);
}

/**
 * Stores the current stack pointer for process 2 and switches to process 1
 */
void yield21(void)      /* vector index = 4 */
{
    do_switch(&p2_sp, p1_sp);
}

/**
 * Switch to the saved parent stack
 */
void uexit(void)        /* vector index = 5 */
{
    // exit to main stack pointer
    do_switch(NULL, q3_sp);
}

/**
 * Calculates the initial stack pointer based on the given
 * pointer to where the memory was allocated and the page size.
 *
 * Inputs:
 * - *alloc_addr, A pointer to the memory that was allocated for
 * a program.
 * Returns:
 * A pointer to the initial stack pointer of the program
 */
void *calculate_stack_pointer(void *alloc_addr)
{
    return alloc_addr + PAGE_SIZE;
}

/**
 * Loads an ELF file, initializes the stack for the program, and
 * stores a pointer to the SP.
 *
 * Inputs:
 * - filename, the name of the file to load
 * - **location_for_sp, location to save the stack pointer to
 * Outputs:
 * - The stack pointer for the program is stored in (*location_for_sp)
 */
void load_program_and_setup_stack(char *filename, void **location_for_sp)
{
    void *alloc_addr = NULL;
    void *entry_addr = NULL;
    void (*f)() = NULL;

    load_elf_file(filename, &alloc_addr, &entry_addr);
    f = entry_addr;
    *location_for_sp = setup_stack(calculate_stack_pointer(alloc_addr), f);
}

void q3(void)
{
    // Initialize the vector table
    vector[0] = &print;
    vector[1] = &readline;
    vector[2] = &getarg;
    vector[3] = &yield12;
    vector[4] = &yield21;
    vector[5] = &uexit;

    // Load programs and set up their stacks
    load_program_and_setup_stack("q3prog1", &p1_sp);
    load_program_and_setup_stack("q3prog2", &p2_sp);

    // Switch to process 1
    do_switch(&q3_sp, p1_sp);
}

/***********************************************/
/*********** Your code ends here ***************/
/***********************************************/
