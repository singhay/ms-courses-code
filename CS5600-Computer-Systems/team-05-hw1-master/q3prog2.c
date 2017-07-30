/*
 * Homework 1 micro-programs - CS 7600, Spring 2010
 *
 * q3prog2.c - process 2 task switch program. No need to modify.
 */

#include "uprog.h"

int main(void)
{
    print("program 2\n");
    yield21();

    print("program 2\n");
    yield21();

    print("program 2\n");
    yield21();

    print("program 2\n");
    yield21();

    uexit();

    return 0;
}
