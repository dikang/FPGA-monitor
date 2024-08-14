-- Copyright (c) 2011-2024 Columbia University, System Level Design Group
-- SPDX-License-Identifier: Apache-2.0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package esp_global is

  ------ Emulation parameters for ASIC designs
  constant ESP_EMU : integer := 0;
  constant ESP_EMU_FREQ : integer := 0;

  ------ Global architecture parameters
  ------ General
  constant ARCH_BITS : integer := 64;
  constant COH_NOC_WIDTH : integer := 64;
  constant DMA_NOC_WIDTH : integer := 64;
  constant MAX_NOC_WIDTH : integer := 64;
  constant MULTICAST_NOC_EN : integer := 0;
  constant MAX_MCAST_DESTS : integer := 2;
  constant GLOB_WORD_OFFSET_BITS : integer := 1;
  constant GLOB_DMA_WORD_OFFSET_BITS : integer := 2;
  constant GLOB_BYTE_OFFSET_BITS : integer := 3;
  constant GLOB_OFFSET_BITS : integer := GLOB_WORD_OFFSET_BITS + GLOB_BYTE_OFFSET_BITS;
  constant GLOB_ADDR_INCR : integer := 8;
  constant GLOB_PHYS_ADDR_BITS : integer := 32;
  constant GLOB_MAXIOSLV : integer := 128;

  ------ CPU
  type cpu_arch_type is (leon3, ariane, ibex);
  constant GLOB_CPU_ARCH : cpu_arch_type := ariane;
  constant CPU_STR : string := "ariane";
  constant GLOB_CPU_AXI : integer range 0 to 1 := 1;
  constant GLOB_CPU_RISCV : integer range 0 to 1 := 1;
  constant GLOB_CPU_LLSC : integer range 0 to 1 := 1;

  ------ Shared local memory (SLM)
  constant CFG_SLM_KBYTES : integer := 256;
  constant CFG_SLMDDR_KBYTES : integer := 524288;

  ------ DMA memory allocation (contiguous buffer or scatter/gather)
  constant CFG_SCATTER_GATHER : integer range 0 to 1 := 1;

  ------ Cache hierarchy
  constant CFG_CACHE_RTL   : integer := 1;
  constant USE_SPANDEX     : integer := 0;
  constant CFG_L2_ENABLE   : integer := 0;
  constant CFG_L2_DISABLE  : integer := 1;
  constant CFG_LLC_ENABLE  : integer := 0;
  constant CFG_CACHE_LINE_SIZE  : integer := 128;
  constant CFG_L2_SETS          : integer := 512;
  constant CFG_L2_WAYS          : integer := 4;
  constant CFG_LLC_SETS         : integer := 1024;
  constant CFG_LLC_WAYS         : integer := 16;
  constant CFG_ACC_L2_SETS      : integer := 512;
  constant CFG_ACC_L2_WAYS      : integer := 4;

  ------ Caches interrupt line
  constant CFG_SLD_LLC_CACHE_IRQ : integer := 4;
  constant CFG_SLD_L2_CACHE_IRQ : integer := 3;

  ------ UART
  constant CFG_UART1_ENABLE : integer := 1;
  constant CFG_UART1_FIFO : integer := 32;
  constant CFG_UART1_IRQ : integer := (2);

  ------ JTAG based DSU interface (DO NOT ENABLE, NOT SUPPORTED)
  constant CFG_AHB_JTAG : integer := 0;

  ------ JTAG based test interface
  constant CFG_JTAG_EN : integer := 0;

  ------ Ethernet
  constant CFG_ETH_EN : integer := 1;

  ------ Gaisler Ethernet core
  constant CFG_GRETH : integer := 1;
  constant CFG_GRETH1G : integer := 0;
  constant CFG_ETH_FIFO : integer := 8;
  constant CFG_GRETH_FT : integer := 0;
  constant CFG_GRETH_EDCLFT : integer := 0;

  ------ Custom IO Link
  constant CFG_IOLINK_EN : integer := 0;
  constant CFG_IOLINK_BITS : integer := 16;

  ------ Custom Memory Link to FPGA for DDR access
  constant CFG_MEM_LINK_BITS : integer := 64;

  ------ SVGA
  constant CFG_SVGA_ENABLE : integer := 0;
  constant CFG_SVGA_MEMORY_HADDR : integer := 16#B01#;

  ------ Ethernet DSU
  constant CFG_DSU_ETH : integer := 1 + 0 + 0;
  constant CFG_ETH_BUF : integer := 16;
  constant CFG_ETH_IPM : integer := 16#C0A8#;
  constant CFG_ETH_IPL : integer := 16#0104#;
  constant CFG_ETH_ENM : integer := 16#535522#;
  constant CFG_ETH_ENL : integer := 16#F00707#;

  ------ Clock Strategy
  constant CFG_CLK_STR : integer := 0;
  constant CFG_SYNC_EN : integer := 1;

  ------ NoC
  constant CFG_XLEN : integer := 2;
  constant CFG_YLEN : integer := 2;
  constant CFG_TILES_NUM : integer := CFG_XLEN * CFG_YLEN;

  ------ Monitors (requires proFPGA MMI64)
  constant CFG_MON_DDR_EN : integer := 0;
  constant CFG_MON_MEM_EN : integer := 0;
  constant CFG_MON_NOC_INJECT_EN : integer := 0;
  constant CFG_MON_NOC_QUEUES_EN : integer := 0;
  constant CFG_MON_ACC_EN : integer := 0;
  constant CFG_MON_L2_EN : integer := 0;
  constant CFG_MON_LLC_EN : integer := 0;
  constant CFG_MON_DVFS_EN : integer := 0;

  ------ Number of components
  constant CFG_NCPU_TILE : integer := 1;
  constant CFG_NMEM_TILE : integer := 1;
  constant CFG_NSLM_TILE : integer := 0;
  constant CFG_NSLMDDR_TILE : integer := 0;
  constant CFG_NL2 : integer := 0;
  constant CFG_NLLC : integer := 0;
  constant CFG_NLLC_COHERENT : integer := 0;

  ------ AMBA settings
  constant CFG_DEFMST : integer := (0);
  constant CFG_RROBIN : integer := 1;
  constant CFG_SPLIT : integer := 0;
  constant CFG_FPNPEN : integer := 1;
  constant CFG_AHBIO : integer := 16#FFF#;
  constant CFG_AHB_MON : integer := 0;
  constant CFG_AHB_MONERR : integer := 0;
  constant CFG_AHB_MONWAR : integer := 0;
  constant CFG_AHB_DTRACE : integer := 0;

  ------ Local-port synchronizers (always present)
  constant CFG_HAS_SYNC : integer := 1;

  ------ Domain voltage-frequency scaling (DVFS)
  constant CFG_HAS_DVFS : integer := 0;

  ------ Synthesis options
  constant CFG_SCAN : integer := 0;

  ------ GRLIB debugging
  constant CFG_DUART : integer := 1;

end esp_global;
