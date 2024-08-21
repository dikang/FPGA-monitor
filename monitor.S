# See LICENSE for license details.

#include "encoding.h"

#define MTIMECMP_OFFSET 0x4000
#define MTIMECMP_OFFSET_HART 0x1000

#if __riscv_xlen == 64
# define LREG ld
# define SREG sd
# define REGBYTES 8
#else
# define LREG lw
# define SREG sw
# define REGBYTES 4
#endif

#include "tasklet_basic.h"

  .section ".text.init"
  .globl _start
_start:
  li  x1, 0
  li  x2, 0
  li  x3, 0
  li  x4, 0
  li  x5, 0
  li  x6, 0
  li  x7, 0
  li  x8, 0
  li  x9, 0
  li  x10,0
  li  x11,0
  li  x12,0
  li  x13,0
  li  x14,0
  li  x15,0
  li  x16,0
  li  x17,0
  li  x18,0
  li  x19,0
  li  x20,0
  li  x21,0
  li  x22,0
  li  x23,0
  li  x24,0
  li  x25,0
  li  x26,0
  li  x27,0
  li  x28,0
  li  x29,0
  li  x30,0
  li  x31,0

  # enable FPU and accelerator if present
  li t0, MSTATUS_FS | MSTATUS_XS
  csrs mstatus, t0

  # make sure XLEN agrees with compilation choice
  li t0, 1
  slli t0, t0, 31
#if __riscv_xlen == 64
  bgez t0, 1f
#else
  bltz t0, 1f
#endif
2:
  li a0, 1
  sw a0, tohost, t0
  j 2b
1:

#ifdef __riscv_flen
  # initialize FPU if we have one
  la t0, 1f
  csrw mtvec, t0

  fssr    x0
  fmv.s.x f0, x0
  fmv.s.x f1, x0
  fmv.s.x f2, x0
  fmv.s.x f3, x0
  fmv.s.x f4, x0
  fmv.s.x f5, x0
  fmv.s.x f6, x0
  fmv.s.x f7, x0
  fmv.s.x f8, x0
  fmv.s.x f9, x0
  fmv.s.x f10,x0
  fmv.s.x f11,x0
  fmv.s.x f12,x0
  fmv.s.x f13,x0
  fmv.s.x f14,x0
  fmv.s.x f15,x0
  fmv.s.x f16,x0
  fmv.s.x f17,x0
  fmv.s.x f18,x0
  fmv.s.x f19,x0
  fmv.s.x f20,x0
  fmv.s.x f21,x0
  fmv.s.x f22,x0
  fmv.s.x f23,x0
  fmv.s.x f24,x0
  fmv.s.x f25,x0
  fmv.s.x f26,x0
  fmv.s.x f27,x0
  fmv.s.x f28,x0
  fmv.s.x f29,x0
  fmv.s.x f30,x0
  fmv.s.x f31,x0
1:
#endif

  # initialize trap vector
  la t0, trap_entry
  csrw mtvec, t0

  # initialize global pointer
.option push
.option norelax
  la gp, __global_pointer$
.option pop

  la  tp, _end + 63
  and tp, tp, -64

  # get core id
  csrr a0, mhartid

.if 0	# original code
  # for now, assume only 1 core
  # DK: Hart[1..N] will loop infinitely here --> FIXIT
  li a1, 1
1:bgeu a0, a1, 1b

  # give each core 128KB of stack + TLS
#define STKSHIFT 17
  sll a2, a0, STKSHIFT
  add tp, tp, a2
  add sp, a0, 1
  sll sp, sp, STKSHIFT
  add sp, sp, tp

  j _init	# DK: this calls main()
.else
  # get pointer to configuration data (a1)
  # get SP
  # get TP
  bne a0, x0, m1
  la a1, __config_mon0_start
  la sp, __config_mon1_start
  j mend
m1: 
  li a3, 1
  bne a0, a3, m2
  la a1, __config_mon1_start
  la sp, __config_mon2_start
  j mend
m2: 
  li a3, 2
  bne a0, a3, mend
  la a1, __config_mon2_start
  la sp, __config_mon3_start
mend:

  # FIXIT: set up argument (to be done once tasklet CP data structure is fixed)
  mv s1, a1	# config data start address
  mv a0, a1
  mv a1, sp	# SP
  mv a2, gp	# GP
  # call monitor_init, 
  #   which initializes config data and TP, GP area.
  #   return value is pointer to arg of monitor_main
  jal monitor_init


  # DK
enable_int:
.if 0
    # Clear Timer Interrupt (To kill timer interrupt. Is it needed?)
    csrr a0, mhartid	# Hart ID
    li a1, CLINT_BASE   # Load base address of CLINT
    li a2, MTIMECMP_OFFSET # Offset for mtimecmp register
    add a1, a1, a2      # Calculate address of mtimecmp register

    li a3, MTIMECMP_OFFSET_HART # Offset per Hart (e.g., 4 KB)
    mul a4, a0, a3 # a4 = Hart ID * Offset per Hart
    add a1, a1, a4 # a1 = Base MTIMECMP Address + (Hart ID * Offset per Hart)

    li a2, -1           # Load the maximum value to clear the timer interrupt
    sd a2, 0(a1)        # Store value in mtimecmp to disable timer interrupt
.endif

    # Enable global interrupts (MIE)
    csrsi mstatus, 0x8

    # Enable software interrupts (MSIE)
    li a1, 0x8
    csrs mie, a1
  # end of DK

  csrr a0, mhartid	# Hart ID
  beq a0, x0, run_app

init_loop:	# non-zero Hart
  j init_loop
.endif

run_app:	# only Hart0 runs this
  # a0 keep the same : config data start address
  # setup sp, tp, gp
  # s1 has config data start address
  ld sp, 8(s1)	# tasklet_config->sp
  ld tp, 16(s1) # tasklet_config->tp
  ld gp, 24(s1) # tasklet_config->gp
  mv a0, x0
  mv a1, x0
  jal main	# Master Controller of the Application
  
  .align 2
trap_entry:
  addi sp, sp, -272

  SREG x1, 1*REGBYTES(sp)
  SREG x2, 2*REGBYTES(sp)
  SREG x3, 3*REGBYTES(sp)
  SREG x4, 4*REGBYTES(sp)
  SREG x5, 5*REGBYTES(sp)
  SREG x6, 6*REGBYTES(sp)
  SREG x7, 7*REGBYTES(sp)
  SREG x8, 8*REGBYTES(sp)
  SREG x9, 9*REGBYTES(sp)
  SREG x10, 10*REGBYTES(sp)
  SREG x11, 11*REGBYTES(sp)
  SREG x12, 12*REGBYTES(sp)
  SREG x13, 13*REGBYTES(sp)
  SREG x14, 14*REGBYTES(sp)
  SREG x15, 15*REGBYTES(sp)
  SREG x16, 16*REGBYTES(sp)
  SREG x17, 17*REGBYTES(sp)
  SREG x18, 18*REGBYTES(sp)
  SREG x19, 19*REGBYTES(sp)
  SREG x20, 20*REGBYTES(sp)
  SREG x21, 21*REGBYTES(sp)
  SREG x22, 22*REGBYTES(sp)
  SREG x23, 23*REGBYTES(sp)
  SREG x24, 24*REGBYTES(sp)
  SREG x25, 25*REGBYTES(sp)
  SREG x26, 26*REGBYTES(sp)
  SREG x27, 27*REGBYTES(sp)
  SREG x28, 28*REGBYTES(sp)
  SREG x29, 29*REGBYTES(sp)
  SREG x30, 30*REGBYTES(sp)
  SREG x31, 31*REGBYTES(sp)

.if 0
  csrr a0, mcause
  csrr a1, mepc
  mv a2, sp
  jal handle_trap
.else
#  csrr a0, mcause
#  jal debug_trap
  csrr a1, mhartid
  la a0, __config_mon0_start
  beq a1, x0, monitor0
  li a2, CONFIG_MONITOR_SIZE
  mul a1, a1, a2
  add a0, a0, a1 
monitor0:
  ld tp, TPOFFSET(a0)
/*  ld gp, GPOFFSET(a0) */	
  jal monitor_main
.endif

.if 0 # original code DK thinks this is bug
  csrw mepc, a0
.endif

  beq a0, x0, ret_isr
  csrw mepc, a0

ret_isr:

  # Remain in M-mode after eret
  li t0, MSTATUS_MPP
  csrs mstatus, t0

  LREG x1, 1*REGBYTES(sp)
  LREG x2, 2*REGBYTES(sp)
  LREG x3, 3*REGBYTES(sp)
  LREG x4, 4*REGBYTES(sp)
  LREG x5, 5*REGBYTES(sp)
  LREG x6, 6*REGBYTES(sp)
  LREG x7, 7*REGBYTES(sp)
  LREG x8, 8*REGBYTES(sp)
  LREG x9, 9*REGBYTES(sp)
  LREG x10, 10*REGBYTES(sp)
  LREG x11, 11*REGBYTES(sp)
  LREG x12, 12*REGBYTES(sp)
  LREG x13, 13*REGBYTES(sp)
  LREG x14, 14*REGBYTES(sp)
  LREG x15, 15*REGBYTES(sp)
  LREG x16, 16*REGBYTES(sp)
  LREG x17, 17*REGBYTES(sp)
  LREG x18, 18*REGBYTES(sp)
  LREG x19, 19*REGBYTES(sp)
  LREG x20, 20*REGBYTES(sp)
  LREG x21, 21*REGBYTES(sp)
  LREG x22, 22*REGBYTES(sp)
  LREG x23, 23*REGBYTES(sp)
  LREG x24, 24*REGBYTES(sp)
  LREG x25, 25*REGBYTES(sp)
  LREG x26, 26*REGBYTES(sp)
  LREG x27, 27*REGBYTES(sp)
  LREG x28, 28*REGBYTES(sp)
  LREG x29, 29*REGBYTES(sp)
  LREG x30, 30*REGBYTES(sp)
  LREG x31, 31*REGBYTES(sp)

  addi sp, sp, 272
  mret

.section ".tdata.begin"
.globl _tdata_begin
_tdata_begin:

.section ".tdata.end"
.globl _tdata_end
_tdata_end:

.section ".tbss.end"
.globl _tbss_end
_tbss_end:

.section ".tohost","aw",@progbits
.align 6
.globl tohost
tohost: .dword 0
.align 6
.globl fromhost
fromhost: .dword 0

