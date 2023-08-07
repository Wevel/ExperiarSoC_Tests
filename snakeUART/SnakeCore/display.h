#ifndef DISPLAY_H
#define DISPLAY_H

#include <stdint.h>

#include "vector2.h"

void DisplayInit ();
void DisplayFinish ();
void DisplayClear ();
void DisplayDrawSprite (Vector2 position, uint8_t sprite);
void DrawGameWin (uint8_t score);
void DrawGameLose (uint8_t score);
void DisplayOutput ();

#endif // !DISPLAY_H
