#include <stdio.h>
#include <stdint.h>
#include "encoding.h"
#include "tasklet_config.h"

void clear_soft_int() {
    uint32_t hartid;
    asm volatile ("csrr %0, mhartid" : "=r" (hartid));
    uint64_t clint_addr = (CLINT_BASE + 4 * hartid);
    uint32_t * clint = (uint32_t*) (clint_addr);
    * clint = 0;
}

void set_soft_int(uint32_t hartid) {
    /* trigger interrupt */
    uint64_t clint_addr = (CLINT_BASE + 4 * hartid);
    uint32_t * clint = (uint32_t*) (clint_addr);
    * clint = 1;
}

void trigger_int(uint32_t hartid, uint64_t cp, uint32_t slot, uint32_t active_save) {
    // disable_interrupt();
    // lock();
    /* write the cmd to int_cmd_queue */
    int_cmd_queue *iq;
    switch(hartid) {
        case 0: iq = (int_cmd_queue *)__intq0_start; break;
        case 1: iq = (int_cmd_queue *)__intq1_start; break;
        case 2: iq = (int_cmd_queue *)__intq2_start; break;
        default: iq = (int_cmd_queue *)NULL;
    }
    if (((iq->front + 1) % NUM_INTQ_SLOTS) == iq->back) { // full
       // unlock();
       // enable_interrupt();
        return; 
    }
    switch_cmd * cmd = &iq->cmds[iq->front];
    cmd->cp = cp;
    cmd->slot = slot;
    cmd->active_save = active_save;
    iq->front++;

    // unlock();
    // enable_interrupt();
}
