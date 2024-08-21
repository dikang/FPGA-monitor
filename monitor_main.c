#include <stdint.h>
#include <stdio.h>
#include "tasklet_config.h"
#include "monitor_utility.h"
#include "uart.h"
#include "syscalls.h"
#include "common.h"
// __attribute__((section(".rodata"))) char * tmps = "string";

#if 0
// the following code allocates and initializes the first a few bytes of configuration memory for monitors running on all Harts.
__attribute__((section(".config_mon0"))) tasklet_config mon0 = { 1, 1, 1, 0};
__attribute__((section(".config_mon1"))) tasklet_config mon1 = { 2, 2, 2, 0};
__attribute__((section(".config_mon2"))) tasklet_config mon2 = { 3, 3, 3, 0};
__attribute__((section(".data_master"))) tasklet_config mon3 = { PC_MASTER_ADDR, SP_MASTER_ADDR, TP_MASTER_ADDR, GP_MASTER_ADDR, \
                {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, \
                 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0}, \
                {0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, \
                 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0}, \
                 100, 0, 0 };
#endif

uint64_t process_int_cmd(int_cmd_queue * iq, tasklet_queue * tq) {
//   uint64_t addr = (uint64_t) iq;
   clear_soft_int();
   if (iq->front == iq->back) { // nothing to do
       return 0;
   }
   switch_cmd * cmd = & iq->cmds[iq->back];
   iq->back++;
   // if cp == 0, just switch to anything else
   if (cmd->cp != 0) { // target is specified
        // print cmd:
        tq->slots[cmd->slot].cp = cmd->cp;
//        tasklet_config * tcp = (tasklet_config *)(cmd->cp);
        
        // may optimize this with uint32_t save
        tq->slots[cmd->slot].active_save = cmd->active_save;
        if ((cmd->active_save & 0xF)) { // jump to that address
            // print switch:<cp>
            return cmd->cp;
        }
    }
    else { // cmd->cp == 0
        // pick next tasklet in the tasklet slots
        uint32_t i = (tq->curr_slot + 1) % NUM_TASKLET_SLOTS;
        while (i != tq->curr_slot) {
            if ((tq->slots[i].active_save & 0x0F) != 0) {
                return tq->slots[i].cp;
            }
            i = (i+1) % NUM_TASKLET_SLOTS;
        }
    }
    return 0;
}

void end_hart0() {
    int i, j;
    uint64_t sum = 0;
    for (i = 0; i < 1000000; i++)
        for (j = 0; j < 10; j++) sum++;
}

void test_hart0() {
    uint64_t i, j;
//    uint32_t * clint_addr = (uint32_t *)(CLINT_BASE);
    for (i = 0; i < 10000000; i++)  j++;
    trigger_int(0, (uint64_t) __config_mon0_start, 0, (1 | 0 << 16));
#if 0
    for (i = 0; i < 10000000; i++)  j++;
    trigger_int(2, CONFIG_TASKLET_ADDR(2), 0, (1 | 0 << 16));
    for (i = 0; i < 10000000; i++)  j++;
    trigger_int(1, CONFIG_TASKLET_ADDR(1), 1, (1 | 0 << 16));
    for (i = 0; i < 10000000; i++)  j++;
    trigger_int(2, CONFIG_TASKLET_ADDR(2), 1, (1 | 0 << 16));
#endif
}

static void tasklet_init_gp(tasklet_config * config, uint64_t tp, uint64_t sp) {
  register void* global_pointer asm("gp");
  printf("before: global_pointer = 0x%lx, tp_end = 0x%lx\n", (uint64_t) global_pointer, tp);
  uint64_t gp = tp + 0x100;
  if (gp & 0x7) gp = (gp & ~(0x7UL)) + 0x8;	// 64bit alignment
  uint64_t gdata_size = (uint64_t) &__sbss_end - (uint64_t) &__sdata_start;
  printf("before: __global_pointer = 0x%lx, gdata_size = 0x%lx, gp = 0x%lx\n", (uint64_t) &__global_pointer$, gdata_size, gp);
  printf("before: __sdata_start = 0x%lx, __sbss_end = 0x%lx\n", (uint64_t) (uint64_t)&__sdata_start, (uint64_t)&__sbss_end);
  memcpy((void*)gp, &__sdata_start, gdata_size);
  uint64_t diff = (uint64_t) &__global_pointer$ - (uint64_t) &__sdata_start;
  gp = gp + diff;
  global_pointer = (void*)gp;
  config->gp = gp;
  printf("after: global_pointer = 0x%lx\n", (uint64_t) gp);
}

static uint64_t tasklet_init_tls(tasklet_config * config, uint64_t sp)
{
  // setup tp
  register void* thread_pointer asm("tp");
//  void* thread_pointer;
  // TP = config + sizeof(tasklet_config) + 0x100 for buffering
  uint64_t tp = (uint64_t) config;
  tp = tp + sizeof(tasklet_config) + 0x100;
  if (tp & 0x7) tp = (tp & ~(0x7UL)) + 0x8;	// 64bit alignment
  thread_pointer = (void*) tp;
  extern char _tls_data;
  extern __thread char _tdata_begin, _tdata_end, _tbss_end;
  size_t tdata_size = &_tdata_end - &_tdata_begin;
  memcpy(thread_pointer, &_tls_data, tdata_size);
  size_t tbss_size = &_tbss_end - &_tdata_end;
  memset(thread_pointer + tdata_size, 0, tbss_size);
  printf("thread_pointer = 0x%lx\n", (uint64_t) thread_pointer);
  printf("config = 0x%lx, tp = 0x%lx, sp = 0x%lx, tdata_size(0x%lx), tbss_size(0x%lx)\n", (uint64_t)config, tp, sp, tdata_size, tbss_size);
  printf("__config_mon1_start = 0x%lx, __config_mon1_end = 0x%lx, __config_mon2_start = 0x%lx, __config_mon2_end = 0x%lx\n", (uint64_t) &__config_mon1_start, (uint64_t) &__config_mon2_start, (uint64_t) &__config_mon2_start, (uint64_t) &__config_mon3_start);
  printf("__intq0_start = 0x%lx, __intq0_start = 0x%lx, __intq2_start = 0x%lx, __intq_end = 0x%lx\n", (uint64_t)&__intq0_start, (uint64_t)&__intq1_start, (uint64_t)&__intq2_start, (uint64_t)&__intq_end);
  if ((tp + tdata_size + tbss_size) > sp) {
    print_uart("thread private is too big\n");
  }
  config->tp = (uint64_t)thread_pointer;
  return tp + tdata_size + tbss_size;
}

extern uint64_t monitor_main(tasklet_config * );
/* 
 *  monitor_init( address of configuration data, address of stack pointer)
 *      sets up pc, sp, tp and tp area for monitor tasklet
 *      this is called once at bootup time
 */
uint64_t monitor_init(tasklet_config * config, uint64_t sp, uint64_t gp) {
    print_uart("monitor_init: start\n");
    // setup pc
    config->pc = (uint64_t)(uintptr_t)monitor_main;
    // setup gp
    config->gp = gp;
    // setup sp
    config->sp = sp;
    // setup tp
    uint64_t tp_end = tasklet_init_tls(config, sp);
    tasklet_init_gp(config,tp_end,sp);
    printf("monitor_init: pc = 0x%lx, sp = 0x%lx, tp = 0x%lx\n", config->pc, config->sp, config->tp);
    tasklet_arg * arg = &(config->targ);
    asm volatile ("csrr %0, mhartid" : "=r" (arg->hartid));
    tasklet_queue * tq = (tasklet_queue *) &arg->tqueue;
    /* initialize intQ and slotQ */
    arg->entry = 0xbeef;
    switch(arg->hartid) {
	case 0: arg->intq = (int_cmd_queue *) __intq0_start; break;
	case 1: arg->intq = (int_cmd_queue *) __intq1_start; break;
	case 2: arg->intq = (int_cmd_queue *) __intq2_start; break;
	default: arg->intq = NULL; break;
    }
    arg->intq->front = arg->intq->back = 0;
    tq->low = tq->high = tq->curr_slot = tq->max_slots = tq->n_active = 0;
    return (uint64_t) arg;
}

#if 0
uint64_t monitor_main(tasklet_arg * arg) {
#else
uint64_t monitor_main(tasklet_config * config) {
#endif
//    int i;
    asm volatile ("csrr %0, mcycle" : "=r" (cycles2) : );
    asm volatile ("csrr %0, minstret" : "=r" (instructions2) : );
    printf("monitor_main: start arg(0x%lx)\n", (uint64_t)&config->targ);
    printf("monitor_main: cycles1(0x%lx), cycles2(0x%lx), instructions1(0x%lx), instructions2(0x%lx)\n",
	(uint64_t)&cycles1, (uint64_t)&cycles2, (uint64_t)&instructions1, (uint64_t)&instructions2);
    printf("monitor_main: cycles = %ld, instructions = %ld\n", cycles2-cycles1, instructions2-instructions1);
    return process_int_cmd(config->targ.intq, &config->targ.tqueue);
}
