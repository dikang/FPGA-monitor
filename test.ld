/*======================================================================*/
/* Proxy kernel linker script                                           */
/*======================================================================*/
/* This is the linker script used when building the proxy kernel. */

/*----------------------------------------------------------------------*/
/* Setup                                                                */
/*----------------------------------------------------------------------*/

/* The OUTPUT_ARCH command specifies the machine architecture where the
   argument is one of the names used in the BFD library. More
   specifically one of the entires in bfd/cpu-mips.c */
#include "tasklet_basic.h"

OUTPUT_ARCH( "riscv" )
ENTRY(_start)

/*----------------------------------------------------------------------*/
/* Sections                                                             */
/*----------------------------------------------------------------------*/

SECTIONS
{

  /* text: test code section */
  . = RAM_START;
  .text.init : { *(.text.init) }

  /* DK: Configuration Data for Monitors 
   *     256K total                       */

  . = CONFIG_MONITOR0;
  .config_mon0 : {
    __config_mon0_start = .;
    *(.config_mon0)
  }
  . = CONFIG_MONITOR1;
  .config_mon1 : {
    __config_mon1_start = .;
    *(.config_mon1)
  }
  . = CONFIG_MONITOR2;
  .config_mon2 : {
    __config_mon2_start = .;
    *(.config_mon2)
  }
  . = CONFIG_MONITOR3;
    __config_mon3_start = .;

  /* DK: interrupt request Queue */
  .intq (NOLOAD) : {
    __intq0_start = .;   /* Mark the start of the intq section */
    . += INTQ_SIZE;                   /* Allocate 16KB for the intq section */
    __intq1_start = .;   /* Mark the start of the intq section */
    . += INTQ_SIZE;                   /* Allocate 16KB for the intq section */
    __intq2_start = .;   /* Mark the start of the intq section */
    . += INTQ_SIZE;                   /* Allocate 16KB for the intq section */
    __intq_end = .;     /* Mark the end of the intq section */
  } 

  . = ALIGN(0x1000);
  .tohost : { *(.tohost) }

  .text : { *(.text) }

  /* data segment */
  .data : { *(.data) }

  .sdata : {
    __sdata_start = .;
    __global_pointer$ = . + 0x800;
    *(.srodata.cst16) *(.srodata.cst8) *(.srodata.cst4) *(.srodata.cst2) *(.srodata*)
    *(.sdata .sdata.* .gnu.linkonce.s.*)
  }

  /* bss segment */
  .sbss : {
    *(.sbss .sbss.* .gnu.linkonce.sb.*)
    *(.scommon)
    __sbss_end = .;
  }

  .bss : { *(.bss) }

  /* thread-local data segment */
  .tdata :
  {
    _tls_data = .;
    *(.tdata.begin)
    *(.tdata)
    *(.tdata.end)
  }
  .tbss :
  {
    *(.tbss)
    *(.tbss.end)
  }

  /* End of uninitalized data segement */
  _end = .;
}

