#include "common.h"

void monitor() {
  char buffer[128];
  asm volatile ("csrr %0, mcycle" : "=r" (cycles2) : );
  asm volatile ("csrr %0, minstret" : "=r" (instructions2) : );
  sprintf(buffer,"monitor: cycles = %ld, instructions = %ld\n", cycles2-cycles1, instructions2-instructions1);
  printstr(buffer);
  printstr("monitor returns\n");
}
