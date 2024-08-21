#ifndef __TASKLET_CONFIG_H__
#define __TASKLET_CONFIG_H__
#include <stdint.h>
#include "tasklet_basic.h"

/* ---------------------------------------------------------------------

			       Interrupt
 
 * --------------------------------------------------------------------- */

/* Memory layout of interrupt exchange 
 * NxN table of entries of two 32 bit words (CMD, subCMD)
 */
typedef struct {
            uint16_t  active;	// enable, disable
            uint16_t  context_save;	// context_save or not
} tasklet_fields;

typedef struct {
     uint64_t cp;	// cp value of the tasklet
     uint32_t slot;	// slot number ??
     union {
        uint32_t active_save;
        tasklet_fields fields;
     };
} switch_cmd ;

typedef struct {
     uint64_t cp;
     union {
        uint32_t active_save;
        tasklet_fields fields;
     };
} tasklet_slot;

typedef struct {
     uint32_t front;
     uint32_t back;
     switch_cmd cmds[NUM_INTQ_SLOTS];
} int_cmd_queue;	// cyclic queue

typedef struct {
     uint32_t low;	
     uint32_t high;	
     uint32_t max_slots;
     uint32_t curr_slot;
     uint32_t n_active;	// number of active slots
     tasklet_slot slots[NUM_TASKLET_SLOTS];
} tasklet_queue;	// cyclic queue

typedef struct {
    uint32_t tasklet_id;// the start address of the arg. of tasklet function
    uint32_t entry;	// 0: new, any nonzero number: reetrant
    uint32_t hartid;	// core ID
    int_cmd_queue * intq;	// interrupt queue
    tasklet_queue tqueue;	// tasklet queue
} tasklet_arg;

typedef struct {
    uint64_t pc;	/* PC */
    uint64_t sp;
    uint64_t tp;
    uint64_t gp;
    uint64_t int_reg[32];	/* space to save int registers */
    float    float_reg[32];	/* space to save float registers */
    tasklet_arg targ;	/* tasklet argument */
} tasklet_config;

#define TASKLET_ARG_OFFSET	(36* sizeof(uint64_t) + 32*sizeof(float))
#define TASKLET_ENTRY_OFFSET	(TASKLET_ARG_OFFSET + sizeof(uint32_t))
#define TASKLET_HARTID_OFFSET	(TASKLET_ENTRY_OFFSET + sizeof(uint32_t))

#if 0
/* Memory layout of interrupt messages */
#define BASE_ADDR_INT_MSGQ   0x803F0000UL
#define INT_MSGQ_SIZE   (sizeof(int_cmd_queue)) 
#define INT_MSGQ_ADDR(n) (BASE_ADDR_INT_MSGQ + INT_MSGQ_SIZE * n)
#define TASKLETQ_SIZE  (sizeof(tasklet_queue))
#else
extern void *__config_mon0_start;
extern void *__config_mon1_start;
extern void *__config_mon2_start;
extern void *__config_mon3_start;
extern void *__gp_end;
extern void *__global_pointer$;
extern void *__sdata_start;
extern void *__sbss_end;
/* extern void *__config_mon0_end;
extern void *__config_mon1_end;
extern void *__config_mon2_end; */
extern void *__intq0_start;
extern void *__intq1_start;
extern void *__intq2_start;
extern void *__intq_end;

#endif

/* How to trigger switching
 *
 *    disable_interrupt()	- to avoid being kicked out after locking
 *    lock(target_hart_mutex)
 *    add switch command
 *    unlock(target_hart_mutex)
 *    enable_interrupt()
 *
 */
#endif
