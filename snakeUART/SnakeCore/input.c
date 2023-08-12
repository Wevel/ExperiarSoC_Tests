#include "input.h"
#include "../config.h"
#include "uart.h"

#if USE_UART_INPUT

Vector2 GetInput (uint32_t timeout, char* input)
{
	*input = '-';
	if (UARTReadWait (UART1, input, timeout))
	{
		switch (*input)
		{
			case 'w':
				return (Vector2){ 0, -1 };
			case 'a':
				return (Vector2){ -1, 0 };
			case 's':
				return (Vector2){ 0, 1 };
			case 'd':
				return (Vector2){ 1, 0 };
			default:
				return (Vector2){ 0, 0 };
		}
	}

	return (Vector2){ 0, 0 };
}

#else
#endif