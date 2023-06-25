#include "SnakeCore/snake.h"
#include "SnakeCore/uart.h"
#include "config.h"

void main ()
{
	UARTInit (UART1, UART1_CONFIG_ENABLED);
	UARTWrite (UART1, 'H');
	UARTWrite (UART1, 'e');
	UARTWrite (UART1, 'l');
	UARTWrite (UART1, 'l');
	UARTWrite (UART1, 'o');

	Setup ();
	while (Loop () == GAME_STATE_PLAYING) {}
	Finish ();
}