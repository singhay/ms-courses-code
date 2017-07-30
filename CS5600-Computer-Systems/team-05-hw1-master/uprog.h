/*
 * file:        uprog.h
 * description: Declarations used by micro-programs.
 *
 * CS 5600, Computer Systems, Northeastern CCIS
 * Peter Desnoyers, Jan. 2011
 */

extern void  print(char *s);
extern void  readline(char *line, int len);
extern char *getarg(int i);
extern void  yield12(void);
extern void  yield21(void);
extern void  uexit(void);
