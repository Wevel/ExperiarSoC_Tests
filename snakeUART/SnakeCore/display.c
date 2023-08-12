// #include <stdio.h>
#include <string.h>

#include "../config.h"
#include "display.h"
#include "mini-printf.h"
#if USE_UART_OUTPUT

#include "uart.h"

static const char gameWinText[] = "You Win!";
static const char gameOverText[] = "Game Over!";
static const char scoreFormatText[] = "Score: %d";
static const char cursorPositionFormatText[] = "\x1b[%d;%dH";

char displayBuffer[MAP_SIZE];
char textBuffer[16];

static void clearDisplayBuffer ()
{
	for (int i = 0; i < MAP_SIZE; i++) displayBuffer[i] = MAP_SPRITE;
}

static inline void drawText (const char* text, int length, uint8_t x, uint8_t y)
{
	// Set cursor location
	mini_snprintf (textBuffer, sizeof (textBuffer), cursorPositionFormatText, y + 1, x + 1);
	UARTWrite (UART1, textBuffer);

	int baseIndex = (y * MAP_WIDTH) + x;
	for (int i = 0; i < length; i++)
	{
		displayBuffer[baseIndex + i] = text[i];
		UARTWriteChar (UART1, text[i]);
	}
}

static inline void drawTextCentred (const char* text, uint8_t y)
{
	int length = strlen (text);
	drawText (text, length, (MAP_WIDTH - length - 1) / 2, y);
}

void DisplayInit ()
{
	clearDisplayBuffer ();
}

void DisplayFinish ()
{
	UARTWrite (UART1, "\x1b[2J");
	UARTWrite (UART1, "\x1b[H");
}

void DisplayClear ()
{
	clearDisplayBuffer ();
}

void DisplayDrawSprite (Vector2 position, uint8_t sprite)
{
	displayBuffer[(position.y * MAP_WIDTH) + position.x] = sprite;

	mini_snprintf (textBuffer, sizeof (textBuffer), cursorPositionFormatText, position.y + 1, position.x + 1);
	UARTWrite (UART1, textBuffer);
	UARTWriteChar (UART1, sprite);
}

void DrawGameWin (uint8_t score)
{
	drawTextCentred (gameWinText, MAP_HEIGHT);
	mini_snprintf (textBuffer, sizeof (textBuffer), scoreFormatText, score);
	drawTextCentred (textBuffer, MAP_HEIGHT - 1);
}

void DrawGameLose (uint8_t score)
{
	drawTextCentred (gameOverText, MAP_HEIGHT);
	mini_snprintf (textBuffer, sizeof (textBuffer), scoreFormatText, score);
	drawTextCentred (textBuffer, MAP_HEIGHT - 1);
}

void DisplayOutput ()
{
	UARTWrite (UART1, "\x1b[2J");
	UARTWrite (UART1, "\x1b[H");

	// Draw map
	for (int y = MAP_HEIGHT - 1; y >= 0; y--)
	{
		for (int x = 0; x < MAP_WIDTH; x++)
		{
			UARTWriteChar (UART1, displayBuffer[(y * MAP_WIDTH) + x]);
		}
		UARTWriteChar (UART1, '\n');
	}
}

#else
#endif