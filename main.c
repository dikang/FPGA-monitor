#include "uart.h"

int main()
{
	__asm__ volatile(
		"csrr a0, mhartid;"
		"bne a0, x0, 1f");

	init_uart();

	print_uart("Init routine\n");

	// jump to the address
	__asm__ volatile(
		"1:"
		"li s0, 0x80000000;"
		"la a1, _dtb;"
		"jr s0");

	/* DK: never reaches this point, because previous call is not a function call: no return */
	while (1)
	{
		// do nothing
	}
}

/* DK: this handle_trap is NOT registered as a trap handler */
void handle_trap(void)
{
	print_uart("trap occured\n");
}
