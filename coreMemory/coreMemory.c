#include <stdint.h>

// GPIO
#define GPIO0_OE_WRITE_ADDR ((uint32_t*)0x1031000)
#define GPIO0_OE_SET_ADDR ((uint32_t*)0x13031004)
#define GPIO0_OE_CLEAR_ADDR ((uint32_t*)0x13031008)
#define GPIO0_OE_TOGGLE_ADDR ((uint32_t*)0x1303100C)
#define GPIO0_OUTPUT_WRITE_ADDR ((uint32_t*)0x13031010)
#define GPIO0_OUTPUT_SET_ADDR ((uint32_t*)0x13031014)
#define GPIO0_OUTPUT_CLEAR_ADDR ((uint32_t*)0x13031018)
#define GPIO0_OUTPUT_TOGGLE_ADDR ((uint32_t*)0x1303101C)
#define GPIO0_INPUT_ADDR ((uint32_t*)0x13031020)
#define GPIO1_OE_WRITE_ADDR ((uint32_t*)0x13032000)
#define GPIO1_OE_SET_ADDR ((uint32_t*)0x13032004)
#define GPIO1_OE_CLEAR_ADDR ((uint32_t*)0x13032008)
#define GPIO1_OE_TOGGLE_ADDR ((uint32_t*)0x1303200C)
#define GPIO1_OUTPUT_WRITE_ADDR ((uint32_t*)0x13032010)
#define GPIO1_OUTPUT_SET_ADDR ((uint32_t*)0x13032014)
#define GPIO1_OUTPUT_CLEAR_ADDR ((uint32_t*)0x13032018)
#define GPIO1_OUTPUT_TOGGLE_ADDR ((uint32_t*)0x1303201C)
#define GPIO1_INPUT_ADDR ((uint32_t*)0x13032020)

// Reference data
#define UINT32_DATA_0 0x12345678
#define UINT32_DATA_1 0xDEADBEEF
#define UINT32_DATA_2 0xABCDEF01
#define UINT32_DATA_3 0x0F1E2D3C
#define UINT16_DATA_0 0x5678
#define UINT16_DATA_1 0x1234
#define UINT16_DATA_2 0xBEEF
#define UINT16_DATA_3 0xDEAD
#define INT16_DATA_0 0x00005678
#define INT16_DATA_1 0x00001234
#define INT16_DATA_2 0xFFFFBEEF
#define INT16_DATA_3 0xFFFFDEAD

#define UINT16_OFFSET_DATA_0 0x3456
#define UINT16_OFFSET_DATA_1 0xEF12
#define UINT16_OFFSET_DATA_2 0xADBE
#define UINT16_OFFSET_DATA_3 0x01DE

#define UINT32_DATA_COUNT 4
#define UINT16_DATA_COUNT 8
#define UINT8_DATA_COUNT 12

// Flash test data
const uint32_t flashData[4] = { UINT32_DATA_0, UINT32_DATA_1, UINT32_DATA_2, UINT32_DATA_3 };
const char flashString[] = "Hello world!";

// SRAM test data
volatile uint32_t sramData[4] = { UINT32_DATA_0, UINT32_DATA_1, UINT32_DATA_2, UINT32_DATA_3 };
volatile char sramString[] = "Hello world!";

void digitalWrite (uint32_t* location, uint32_t value)
{
	*((volatile uint32_t*)location) = value;
}

void setupTests ()
{
	digitalWrite (GPIO0_OUTPUT_WRITE_ADDR, 0x01000);
}

void testPass ()
{
	digitalWrite (GPIO0_OUTPUT_SET_ADDR, 0x03000);
	digitalWrite (GPIO0_OUTPUT_CLEAR_ADDR, 0x02000);
}

void testFail ()
{
	digitalWrite (GPIO0_OUTPUT_CLEAR_ADDR, 0x01000);
	digitalWrite (GPIO0_OUTPUT_SET_ADDR, 0x02000);

	while (1) {}
}

void assert (int condition)
{
	if (condition)
		testPass ();
	else
		testFail ();
}

void testInstructionsInFlash ()
{
	// Make local copies of the data
	volatile uint32_t flashDataCopy[UINT32_DATA_COUNT];
	volatile char flashStringCopy[UINT8_DATA_COUNT];

	for (int i = 0; i < UINT32_DATA_COUNT; i++)
		flashDataCopy[i] = flashData[i];

	for (int i = 0; i < UINT8_DATA_COUNT; i++)
		flashStringCopy[i] = flashString[i];

	// Check reading data from flash is correct
	volatile uint16_t* flashData16Copy = (uint16_t*)flashDataCopy;
	volatile int16_t* flashData16CopySigned = (int16_t*)flashDataCopy;
	volatile uint16_t* flashData16CopyOffset = (uint16_t*)((uint8_t*)flashDataCopy + 1);

	// UINT32
	assert (flashDataCopy[0] == UINT32_DATA_0);
	assert (flashDataCopy[1] == UINT32_DATA_1);
	assert (flashDataCopy[2] == UINT32_DATA_2);
	assert (flashDataCopy[3] == UINT32_DATA_3);

	// UINT16
	assert (flashData16Copy[0] == UINT16_DATA_0);
	assert (flashData16Copy[1] == UINT16_DATA_1);
	assert (flashData16Copy[2] == UINT16_DATA_2);
	assert (flashData16Copy[3] == UINT16_DATA_3);
	assert (flashData16CopySigned[0] == INT16_DATA_0);
	assert (flashData16CopySigned[1] == INT16_DATA_1);
	assert (flashData16CopySigned[2] == INT16_DATA_2);
	assert (flashData16CopySigned[3] == INT16_DATA_3);
	assert (flashData16CopyOffset[0] == UINT16_OFFSET_DATA_0);
	assert (flashData16CopyOffset[1] == UINT16_OFFSET_DATA_1);
	assert (flashData16CopyOffset[2] == UINT16_OFFSET_DATA_2);
	assert (flashData16CopyOffset[3] == UINT16_OFFSET_DATA_3);

	// UINT8
	assert (flashStringCopy[0] == 'H');
	assert (flashStringCopy[1] == 'e');
	assert (flashStringCopy[2] == 'l');
	assert (flashStringCopy[4] == 'o');
	assert (flashStringCopy[6] == 'w');
	assert (flashStringCopy[7] == 'o');
	assert (flashStringCopy[9] == 'l');
	assert (flashStringCopy[11] == '!');

	// Check reading data from sram is correct
	volatile uint16_t* sramData16 = (uint16_t*)sramData;
	volatile int16_t* sramData16Signed = (int16_t*)sramData;
	volatile uint16_t* sramData16Offset = (uint16_t*)((uint8_t*)sramData + 1);

	// UINT32
	assert (sramData[0] == UINT32_DATA_0);
	assert (sramData[1] == UINT32_DATA_1);
	assert (sramData[2] == UINT32_DATA_2);
	assert (sramData[3] == UINT32_DATA_3);

	// UINT16
	assert (sramData16[0] == UINT16_DATA_0);
	assert (sramData16[1] == UINT16_DATA_1);
	assert (sramData16[2] == UINT16_DATA_2);
	assert (sramData16[3] == UINT16_DATA_3);
	assert (sramData16Signed[0] == INT16_DATA_0);
	assert (sramData16Signed[1] == INT16_DATA_1);
	assert (sramData16Signed[2] == INT16_DATA_2);
	assert (sramData16Signed[3] == INT16_DATA_3);
	assert (sramData16Offset[0] == UINT16_OFFSET_DATA_0);
	assert (sramData16Offset[1] == UINT16_OFFSET_DATA_1);
	assert (sramData16Offset[2] == UINT16_OFFSET_DATA_2);
	assert (sramData16Offset[3] == UINT16_OFFSET_DATA_3);

	// UINT8
	assert (sramString[0] == 'H');
	assert (sramString[1] == 'e');
	assert (sramString[2] == 'l');
	assert (sramString[4] == 'o');
	assert (sramString[6] == 'w');
	assert (sramString[7] == 'o');
	assert (sramString[9] == 'l');
	assert (sramString[11] == '!');
}

__attribute__ ((section (".ramtext"))) void testInstructionsInSRAM ()
{
	// Make local copies of the flash data so it can't be optimised away
	volatile uint32_t flashDataCopy[UINT32_DATA_COUNT];
	volatile char flashStringCopy[UINT8_DATA_COUNT];

	for (int i = 0; i < UINT32_DATA_COUNT; i++)
		flashDataCopy[i] = flashData[i];

	for (int i = 0; i < UINT8_DATA_COUNT; i++)
		flashStringCopy[i] = flashString[i];

	// Check reading data from flash is correct
	volatile uint16_t* flashData16Copy = (uint16_t*)flashDataCopy;
	volatile int16_t* flashData16CopySigned = (int16_t*)flashDataCopy;
	volatile uint16_t* flashData16CopyOffset = (uint16_t*)((uint8_t*)flashDataCopy + 1);

	// UINT32
	assert (flashDataCopy[0] == UINT32_DATA_0);
	assert (flashDataCopy[1] == UINT32_DATA_1);
	assert (flashDataCopy[2] == UINT32_DATA_2);
	assert (flashDataCopy[3] == UINT32_DATA_3);

	// UINT16
	assert (flashData16Copy[0] == UINT16_DATA_0);
	assert (flashData16Copy[1] == UINT16_DATA_1);
	assert (flashData16Copy[2] == UINT16_DATA_2);
	assert (flashData16Copy[3] == UINT16_DATA_3);
	assert (flashData16CopySigned[0] == INT16_DATA_0);
	assert (flashData16CopySigned[1] == INT16_DATA_1);
	assert (flashData16CopySigned[2] == INT16_DATA_2);
	assert (flashData16CopySigned[3] == INT16_DATA_3);
	assert (flashData16CopyOffset[0] == UINT16_OFFSET_DATA_0);
	assert (flashData16CopyOffset[1] == UINT16_OFFSET_DATA_1);
	assert (flashData16CopyOffset[2] == UINT16_OFFSET_DATA_2);
	assert (flashData16CopyOffset[3] == UINT16_OFFSET_DATA_3);

	// UINT8
	assert (flashStringCopy[0] == 'H');
	assert (flashStringCopy[1] == 'e');
	assert (flashStringCopy[2] == 'l');
	assert (flashStringCopy[4] == 'o');
	assert (flashStringCopy[6] == 'w');
	assert (flashStringCopy[7] == 'o');
	assert (flashStringCopy[9] == 'l');
	assert (flashStringCopy[11] == '!');

	// Check reading data from sram is correct
	volatile uint16_t* sramData16 = (uint16_t*)sramData;
	volatile int16_t* sramData16Signed = (int16_t*)sramData;
	volatile uint16_t* sramData16Offset = (uint16_t*)((uint8_t*)sramData + 1);

	// UINT32
	assert (sramData[0] == UINT32_DATA_0);
	assert (sramData[1] == UINT32_DATA_1);
	assert (sramData[2] == UINT32_DATA_2);
	assert (sramData[3] == UINT32_DATA_3);

	// UINT16
	assert (sramData16[0] == UINT16_DATA_0);
	assert (sramData16[1] == UINT16_DATA_1);
	assert (sramData16[2] == UINT16_DATA_2);
	assert (sramData16[3] == UINT16_DATA_3);
	assert (sramData16Signed[0] == INT16_DATA_0);
	assert (sramData16Signed[1] == INT16_DATA_1);
	assert (sramData16Signed[2] == INT16_DATA_2);
	assert (sramData16Signed[3] == INT16_DATA_3);
	assert (sramData16Offset[0] == UINT16_OFFSET_DATA_0);
	assert (sramData16Offset[1] == UINT16_OFFSET_DATA_1);
	assert (sramData16Offset[2] == UINT16_OFFSET_DATA_2);
	assert (sramData16Offset[3] == UINT16_OFFSET_DATA_3);

	// UINT8
	assert (sramString[0] == 'H');
	assert (sramString[1] == 'e');
	assert (sramString[2] == 'l');
	assert (sramString[4] == 'o');
	assert (sramString[6] == 'w');
	assert (sramString[7] == 'o');
	assert (sramString[9] == 'l');
	assert (sramString[11] == '!');
}

void main ()
{
	setupTests ();
	testInstructionsInFlash ();
	testInstructionsInSRAM ();

	// Compare data in flash and sram
	// This is mostly to make sure the values don't get optimised away
	// UINT32
	for (int i = 0; i < UINT32_DATA_COUNT; i++)
		assert (flashData[i] == sramData[i]);

	// UINT16
	volatile uint16_t* flashData16 = (uint16_t*)flashData;
	volatile uint16_t* sramData16 = (uint16_t*)sramData;
	for (int i = 0; i < UINT16_DATA_COUNT; i++)
		assert (flashData16[i] == sramData16[i]);

	// UINT8
	for (int i = 0; i < UINT8_DATA_COUNT; i++)
		assert (flashString[i] == sramString[i]);
}