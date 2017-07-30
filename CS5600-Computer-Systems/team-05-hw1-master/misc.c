/*
 * file:        misc.c
 * description: Support functions for homework 1
 *
 * CS 3600, Systems & Networks, Northeastern CCIS
 * Peter Desnoyers, Sept. 2010
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <sys/select.h>

void *vector;

/*
 * do_switch - save stack pointer to *location_for_old_sp, set
 *             stack pointer to 'new_value', and return.
 *             Note that the return takes place on the new stack.
 *
 * For more details, see:
 *  http://pdos.csail.mit.edu/6.828/2004/lec/l2.html - GCC calling conventions
 *  http://www.ibiblio.org/gferg/ldp/GCC-Inline-Assembly-HOWTO.html
*/
void do_switch(void **location_for_old_sp, void *new_value)
{
    /* C calling conventions require that we preserve %ebp, %ebx,
     * %esi, and %edi. GCC saves %ebp already, so save the remaining
     * 3 registers on the stack.
     */
    asm("push %%ebx;" 
	"push %%esi;"
	"push %%edi" : :);

    if (location_for_old_sp != NULL)
	asm("mov %%esp,%0" : : "m"(*location_for_old_sp));
    
    asm("mov %0,%%esp" : "=m"(new_value) :); /* switch! */

    asm("pop %%edi;"		/* Restore "callee-save" registers */
	"pop %%esi;"		
	"pop %%ebx" : :);
}


/*
 * setup_stack(stack, function) - sets up a stack so that switching to
 * it from 'do_switch' will call 'function'. Returns the resulting
 * stack pointer.
 */
void *setup_stack(void *_stack, void *func)
{
    int old_bp = (int)_stack;	/* top frame - SP = BP */
    int *stack = _stack;
    
    *(--stack) = (int)func;	/* return address */
    *(--stack) = old_bp;	/* %ebp */
    *(--stack) = 0;		/* %ebx */
    *(--stack) = 0;		/* %esi */
    *(--stack) = 0;		/* %edi */

    return stack;
}


/*
 * init_memory - initialize the following variables:
 *   proc1, proc1_stack - bottom and top of process 1 address space
 *   proc2, proc2_stack - ditto for process 2
 *   vector - OS interface vector
 */
void init_memory(void)
{
    vector = mmap((void*)0x09002000, 4096, PROT_READ | PROT_WRITE |
		     PROT_EXEC, MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);

    if (vector == MAP_FAILED) {
	fprintf(stderr, "Error mapping memory: %s\n", strerror(errno));
	exit(1);
    }
}
    
/*
 * init_terms() - initialize simulated terminals. Creates two TCP
 * sockets which may be connected to via 'telnet' to similate
 * terminals. 
 */
static int tfd[2];
void init_terms(void)
{
    struct sockaddr_in addr;
    size_t addr_len = sizeof(addr);
    int i, sock = socket(PF_INET, SOCK_STREAM, 0);
    listen(sock, 1);
    if (getsockname(sock, (struct sockaddr*)&addr, &addr_len) < 0)
	perror("getsockname");
    printf("To connect to terminals 0 and 1, type:\n"
	   "  telnet localhost %d\n"
	   "in two separate windows\n", ntohs(addr.sin_port));

    for (i = 0; i < 2; i++) {
	tfd[i] = accept(sock, NULL, NULL);
	int flags = fcntl(tfd[i], F_GETFL, 0);
	fcntl(tfd[i], F_SETFL, flags | O_NONBLOCK);
	printf(" ...connection %d OK\n", i);
    }
}

/*
 * connection_num = get_net_input(buf, len) - waits until input is
 * available on either connection 0 or 1.
 *
 * Return value is the connection (0 or 1) on which input was
 * received. Null-terminated input string (including terminating
 * newline) is stored in 'buf'.
 *
 * NOTE - ONLY FOR QUESTION 4
 * for questions 1, 2, and 3 your readline function should read from
 * standard input, not from the network.
 */
int get_net_input(char *buf, int len)
{
    fd_set fds;
    int i;
    
    FD_ZERO(&fds);
    FD_SET(tfd[0], &fds);
    FD_SET(tfd[1], &fds);

    select(tfd[1] > tfd[0] ? tfd[1]+1 : tfd[0]+1, &fds, NULL, NULL, NULL);

    for (i = 0; i < 2; i++) {
	if (FD_ISSET(tfd[i], &fds)) {
	    int l2 = read(tfd[i], buf, len-1);
	    buf[l2] = 0;
	    return i;
	}
    }
    return -1;
}

/*
 * put_net_output(i, buf, len) - output 'len' bytes to connection 'i'
 */
void put_net_output(int i, char *buf, int len)
{
    write(tfd[i], buf, len);
}

extern void q1(void);
extern void q2(void);
extern void q3(void);

void usage(char *prog)
{
    printf("usage:\t%s q1\n"
           "or:   \t%s q2, or q3\n", prog, prog);
    exit(1);
}

int main(int argc, char **argv)
{
    int tmp1 = 0x12345678, tmp2 = 0xa5b4c3d2;
    
    init_memory();

    if (argc != 2) 
        usage(argv[0]);
    
    if (!strcmp(argv[1], "q1"))
        q1();
    else if (!strcmp(argv[1], "q2"))
        q2();
    else if (!strcmp(argv[1], "q3"))
        q3();
    else
        usage(argv[0]);

    if (tmp1 != 0x12345678 || tmp2 != 0xa5b4c3d2)
        printf("*** ERROR: stack corruption (0x%x, 0x%x)\n", tmp1, tmp2);

    return 0;
}

