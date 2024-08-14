// Copyright (c) 2011-2024 Columbia University, System Level Design Group
// SPDX-License-Identifier: Apache-2.0

#include <stdio.h>
#include "uart.h"
#include "common.h"
#include "tasklet_config.h"

extern void set_int(uint32_t);
uint64_t cycles1, cycles2, instructions1, instructions2;
int main(int argc, char **argv)
{
	char buffer[128];
	int i;
        uint32_t hartid;
        asm volatile ("csrr %0, mhartid" : "=r" (hartid));
        uint64_t clint_addr = (CLINT_BASE + 4 * hartid);
        uint32_t * clint = (uint32_t*) (clint_addr);
	print_uart("Main\n");
	printf("Start: Hello from ISI !\n");
        asm volatile ("csrr %0, mcycle" : "=r" (cycles1) : );
        asm volatile ("csrr %0, minstret" : "=r" (instructions1) : );
        asm volatile ("csrr %0, mcycle" : "=r" (cycles2) : );
        asm volatile ("csrr %0, minstret" : "=r" (instructions2) : );
        sprintf(buffer,"Main: cycles = %ld, instructions = %ld\n", cycles2-cycles1, instructions2-instructions1);
        printstr(buffer);
        asm volatile ("csrr %0, mcycle" : "=r" (cycles1) : );
        asm volatile ("csrr %0, minstret" : "=r" (instructions1) : );
	set_soft_int(0);
//        * clint = 1;
	printf("After 1st triggering interrupt!\n");
        asm volatile ("csrr %0, mcycle" : "=r" (cycles1) : );
        asm volatile ("csrr %0, minstret" : "=r" (instructions1) : );
	set_soft_int(0);
//        * clint = 1;
	printf("After 2nd triggering interrupt!\n");
        asm volatile ("csrr %0, mcycle" : "=r" (cycles1) : );
        asm volatile ("csrr %0, minstret" : "=r" (instructions1) : );
	set_soft_int(0);
//        * clint = 1;
	printf("After 3rd triggering interrupt!\n");
	for (i = 0; i < 10; i++) {
            asm volatile ("csrr %0, mcycle" : "=r" (cycles1) : );
            asm volatile ("csrr %0, minstret" : "=r" (instructions1) : );
    	    set_soft_int(0);
    	    printf("After (%d)th triggering interrupt!\n", i+4);
	}
	while(1);
	return 0;
}
