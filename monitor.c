#include <stdio.h>
#include "common.h"

void monitor() {
  char buffer[128];
  asm volatile ("csrr %0, mcycle" : "=r" (cycles2) : );
  asm volatile ("csrr %0, minstret" : "=r" (instructions2) : );
  printf("monitor: cycles = %ld, instructions = %ld\n", cycles2-cycles1, instructions2-instructions1);
  printf("monitor returns\n");
}
