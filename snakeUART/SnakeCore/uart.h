#ifndef UART_H
#define UART_H

#include <stdint.h>

#include "../config.h"

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

typedef struct UARTDevice
{
	uint32_t config;
	uint32_t clear;
	uint32_t status;
	uint32_t rx;
	uint32_t tx;
} __attribute__ ((packed, aligned (4))) UARTDevice;

// Internal to caravel
#ifdef UART0_ENABLE
#define UART0_CYCLES_PER_BIT (((CPU_FREQUENCY + UART0_BAUD_RATE) / UART0_BAUD_RATE) - 1)
#define UART0_CONFIG_DISABLED ((0x1 << 16) | UART0_CYCLES_PER_BIT)
#define UART0_CONFIG_ENABLED ((0x3 << 16) | UART0_CYCLES_PER_BIT)

static volatile UARTDevice* const UART0 = (UARTDevice*)0x13001000;
#endif // UART0_ENABLE

// IO05: GPIO05 or UART1_RX
// IO06: GPIO06 or UART1_TX
#ifdef UART1_ENABLE
#define UART1_CYCLES_PER_BIT (((CPU_FREQUENCY + UART1_BAUD_RATE) / UART1_BAUD_RATE) - 1)
#define UART1_CONFIG_DISABLED ((0x1 << 16) | UART1_CYCLES_PER_BIT)
#define UART1_CONFIG_ENABLED ((0x3 << 16) | UART1_CYCLES_PER_BIT)

static volatile UARTDevice* const UART1 = (UARTDevice*)0x13002000;
#endif // UART1_ENABLE

// IO19: GPIO19 or UART2_RX
// IO20: GPIO20 or UART2_TX
#ifdef UART2_ENABLE
#define UART2_CYCLES_PER_BIT (((CPU_FREQUENCY + UART2_BAUD_RATE) / UART2_BAUD_RATE) - 1)
#define UART2_CONFIG_DISABLED ((0x1 << 16) | UART2_CYCLES_PER_BIT)
#define UART2_CONFIG_ENABLED ((0x3 << 16) | UART2_CYCLES_PER_BIT)

static volatile UARTDevice* const UART2 = (UARTDevice*)0x13003000;
#endif // UART2_ENABLE

// IO26: GPIO26 or UART3_RX
// IO27: GPIO27 or UART3_TX
#ifdef UART3_ENABLE
#define UART3_CYCLES_PER_BIT (((CPU_FREQUENCY + UART3_BAUD_RATE) / UART3_BAUD_RATE) - 1)
#define UART3_CONFIG_DISABLED ((0x1 << 16) | UART3_CYCLES_PER_BIT)
#define UART3_CONFIG_ENABLED ((0x3 << 16) | UART3_CYCLES_PER_BIT)

static volatile UARTDevice* const UART3 = (UARTDevice*)0x13004000;
#endif // UART3_ENABLE

inline void UARTWriteChar (volatile UARTDevice* device, char data)
{
	device->tx = data;
}

inline int UARTRead (volatile UARTDevice* device, char* data)
{
	uint32_t receiveValue = device->rx;
	*data = receiveValue;
	return receiveValue & 0x100;
}

void UARTInit (volatile UARTDevice* device, uint32_t config);
void UARTWrite (volatile UARTDevice* device, char* data);
void UARTWriteInt (volatile UARTDevice* device, int data);
int UARTReadWait (volatile UARTDevice* device, char* data, uint32_t timeout);

#endif // !UART_H
