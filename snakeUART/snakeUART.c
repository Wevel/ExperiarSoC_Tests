#include "SnakeCore/snake.h"
#include "SnakeCore/uart.h"
#include "config.h"

void main ()
{
	UARTInit (UART1, UART1_CONFIG_ENABLED);
	UARTWriteChar (UART1, 'H');
	UARTWriteChar (UART1, 'e');
	UARTWriteChar (UART1, 'l');
	UARTWriteChar (UART1, 'l');
	UARTWriteChar (UART1, 'o');
	UARTWrite (UART1, "Hello World!\n");

	// Setup ();
	// while (Loop () == GAME_STATE_PLAYING) {}
	// Finish ();
}