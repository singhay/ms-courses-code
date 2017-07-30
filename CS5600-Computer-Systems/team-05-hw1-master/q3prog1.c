/*
 * Homework 1 micro-programs - CS 7600, Spring 2010
 *
 * q3prog1.c - process 1 task switch program. No need to modify.
 */

#include "uprog.h"

int main(void)
{
    print("program 1\n");
    yield12();

    print("program 1\n");
    yield12();

    print("program 1\n");
    yield12();

    print("program 1\n");
    yield12();

    uexit();

    return 0;
}
