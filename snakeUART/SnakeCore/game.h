#ifndef GAME_H
#define GAME_H

#include <stdint.h>

#include "../config.h"
#include "vector2.h"

#define GAME_STATE_PLAYING 0
#define GAME_STATE_WON 1
#define GAME_STATE_LOST 2

typedef struct Game
{
	Vector2 food;
	uint8_t score;
	uint8_t tailLength;
	uint8_t headIndex;
	Vector2 tailPositions[MAX_TAIL_LENGTH];
	Vector2 direction;
} Game;

void GameInit (Game* game);
int GameUpdate (Game* game, Vector2 input, char inputChar);
void GameFinish (Game* game);

#endif // !GAME_H
