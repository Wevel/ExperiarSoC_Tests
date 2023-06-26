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

char displayBuffer[MAP_SIZE];
char scoreTextBuffer[16];

static void clearDisplayBuffer ()
{
	for (int i = 0; i < MAP_SIZE; i++) displayBuffer[i] = ' ';
}

static inline void drawText (const char* text, int length, uint8_t x, uint8_t y)
{
	int baseIndex = (y * MAP_WIDTH) + x;
	for (int i = 0; i < length; i++) displayBuffer[baseIndex + i] = text[i];
}

static inline void drawTextCentred (const char* text, uint8_t y)
{
	int length = strlen (text);
	drawText (text, length, (MAP_WIDTH - length) / 2, y);
}

void DisplayInit ()
{
	clearDisplayBuffer ();
}

void DisplayClear ()
{
	clearDisplayBuffer ();
}

void DisplayDrawSprite (Vector2 position, uint8_t sprite)
{
	displayBuffer[(position.y * MAP_WIDTH) + position.x] = sprite;
}

void DrawGameWin (uint8_t score)
{
	drawTextCentred (gameWinText, MAP_HEIGHT / 2);
	snprintf (scoreTextBuffer, sizeof (scoreTextBuffer), scoreFormatText, score);
	drawTextCentred (scoreTextBuffer, (MAP_HEIGHT / 2) - 1);
}

void DrawGameLose (uint8_t score)
{
	drawTextCentred (gameOverText, MAP_HEIGHT / 2);
	snprintf (scoreTextBuffer, sizeof (scoreTextBuffer), scoreFormatText, score);
	drawTextCentred (scoreTextBuffer, (MAP_HEIGHT / 2) - 1);
}

void DisplayOutput ()
{
	for (int x = 0; x < MAP_WIDTH; x++)
	{
		for (int y = MAP_HEIGHT - 1; y >= 0; y--)
		{
			UARTWriteChar (UART1, displayBuffer[(y * MAP_WIDTH) + x]);
		}
	}
}

#else
#endif