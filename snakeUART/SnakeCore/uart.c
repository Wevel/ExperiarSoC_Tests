#include "uart.h"
#include "time.h"

void UARTInit (volatile UARTDevice* device, uint32_t config)
{
	device->config = 0; // Ensure the device is disabled
	device->clear = 0xF; // Clear all buffers
	device->config = config; // Set the config
}

void UARTWrite (volatile UARTDevice* device, char data)
{
	device->tx = data;
}

int UARTRead (volatile UARTDevice* device, char* data)
{
	uint32_t receiveValue = device->rx;
	*data = receiveValue;
	return receiveValue & 0x100;
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