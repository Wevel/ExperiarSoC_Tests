#include <stdint.h>

#include "snake.h"

Game game;

void Setup ()
{
	GameInit (&game);
}

int Loop ()
{
	int gameState = GameUpdate (&game, GetInput (MOVE_TIMEOUT));
	// DrawGame (&game);

	if (gameState == GAME_STATE_WON)
		DrawGameWin (game.score);
	else if (gameState == GAME_STATE_LOST)
		DrawGameLose (game.score);

	return gameState;
}

void Finish ()
{
	GameFinish (&game);
}