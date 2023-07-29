#include "uart.h"
#include "time.h"

#include "mini-printf.h"

void UARTInit (volatile UARTDevice* device, uint32_t config)
{
	device->config = 0; // Ensure the device is disabled
	device->clear = 0xF; // Clear all buffers
	device->config = config; // Set the config
}

void UARTWrite (volatile UARTDevice* device, char* data)
{
	while (*data != '\0')
	{
		device->tx = *data;
		data++;
	}
}

void UARTWriteInt (volatile UARTDevice* device, int data)
{
	char buffer[12];
	int length = mini_snprintf (buffer, sizeof (buffer), "%d", data);
	UARTWrite (device, buffer);
}

int UARTReadWait (volatile UARTDevice* device, char* data, uint32_t timeout)
{
	uint32_t finalTime = GetMicros () + timeout;
	while (GetMicros () < finalTime)
	{
		if (UARTRead (device, data)) return TRUE;
	}

	return FALSE;
}