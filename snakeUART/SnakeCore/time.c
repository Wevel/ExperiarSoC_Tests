#include "time.h"
#include "../config.h"

static inline uint64_t readCycles ()
{
	// From the risc-v spec to make sure we safely read the full 64-bit register
	// again:
	// 	rdcycleh     x3
	// 	rdcycle      x2
	// 	rdcycleh     x4
	// 	bne          x3, x4, again

	uint32_t cycleLow;
	uint32_t cycleHigh;
	uint32_t cycleHigh2;

	do
	{
		__asm__ volatile ("csrr    %0, cycleh"
						  : "=r"(cycleHigh)
						  :
						  :);
		__asm__ volatile ("csrr    %0, cycle"
						  : "=r"(cycleLow)
						  :
						  :);
		__asm__ volatile ("csrr    %0, cycleh"
						  : "=r"(cycleHigh2)
						  :
						  :);
	} while (cycleHigh != cycleHigh2);

	return (uint64_t)cycleLow | ((uint64_t)cycleHigh << 32);
}

//__attribute__ ((section (".ramtext")))
uint32_t GetMicros ()
{
	uint64_t cycles = readCycles ();
	return (uint32_t)((cycles * CPU_CLOCK_PERIOD) / 1000);
}

uint32_t GetMillis ()
{
	return GetMicros () / 1000;
}