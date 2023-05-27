#include "SnakeCore/snake.h"
#include "SnakeCore/uart.h"
#include "config.h"

void main ()
{
	UARTInit (UART0, UART0_CONFIG_ENABLED);

	Setup ();
	while (Loop () == GAME_STATE_PLAYING) {}
	Finish ();
}