/*
 * Homework 1 micro-programs - CS 5600, Fall 2011
 *
 * ugrep - simple ("micro" - i.e. 'u') grep command.
 */

#include "uprog.h"

/* prototype for functions at bottom. (note that 'main' has to be at
 * the top of the file for our simple loader to work)
 */
int string_contains(char *s1, char *s2);

int main(void)			/* GCC doesn't like void main() */
{
    char buf[128];
    char *pattern = getarg(0);

    if (pattern == 0 || getarg(1) != 0) {
        print("usage: q2prog <pattern>\n");
        return 0;
    }
    
    for (;;) {
        readline(buf, sizeof(buf));
        if (buf[0] == '\n' || buf[0] == 0)
            break;
        if (string_contains(pattern, buf)) {
            print("-- ");
            print(buf);
        }
    }
    return 0;
}

/*
 * Crude string functions.
 */
int strings_equal(char *s1, char *s2)
{
    while (*s1 != 0)
        if (*s1 != *s2)
            return 0;
        else
            s1++, s2++;
    return 1;
}

int string_contains(char *pattern, char *str)
{
    while (*str != 0) {
        if (strings_equal(pattern, str))
            return 1;
        str++;
    }
    return 0;
}
