all: prom.exe systest.exe

CFLAGS=-Os -Wall -Werror -mcmodel=medany -mexplicit-relocs
CFLAGSCENV=-mcmodel=medany -static -std=gnu99 -O2 -ffast-math -fno-common -fno-builtin-printf -nostdlib -nostartfiles -lm -lgcc
INCLUDE=-Iinclude/bootrom -Iinclude/esp -Iinclude/env -Iinclude/common
INCLUDECENV=
LDFLAGS=-nostdlib -nodefaultlibs -nostartfiles
LDFLAGSTEST=-nostdlib -nostartfiles
LINKERSCRIPT=-T linker.lds
LINKERSCRIPTTEST=-T test.ld
TARGET_DIR=/home/espuser/esp/socs/xilinx-vc707-xc7vx485t_isi_prebuilt_demo/soft-build/ariane/

startup.o: startup.S
	riscv64-unknown-elf-gcc $(INCLUDE) $(CFLAGS) -c startup.S -o startup.o

uart.o: uart.c
	riscv64-unknown-elf-gcc $(INCLUDE) $(CFLAGS) -c uart.c

main.o: main.c
	riscv64-unknown-elf-gcc $(INCLUDE) $(CFLAGS) -c main.c

prom.exe: main.o uart.o startup.o
	riscv64-unknown-elf-gcc $(INCLUDE) $(CFLAGS) $(LDFLAGS) $(LINKERSCRIPT) -o prom.exe main.o uart.o startup.o
	riscv64-unknown-elf-objcopy -O srec prom.exe prom.srec

systest.exe: crt.S syscalls.c uart.o systest.c utility.c monitor.c common.h
	riscv64-unknown-elf-gcc $(INCLUDE) $(CFLAGSCENV) syscalls.c crt.S  $(LDFLAGSTEST) $(LINKERSCRIPTTEST) -o systest.exe uart.o systest.c utility.c monitor.c
	riscv64-unknown-elf-objcopy -O srec --gap-fill 0 systest.exe ram.srec
	riscv64-unknown-elf-objcopy -O binary prom.exe prom.bin
	riscv64-unknown-elf-objcopy -O binary systest.exe systest.bin
	riscv64-unknown-elf-objdump -D prom.exe > prom.dis
	riscv64-unknown-elf-objdump -D systest.exe > systest.dis
	cp *.bin *.srec *.exe $(TARGET_DIR)

clean:
	rm *.exe *.bin *.srec *.o
