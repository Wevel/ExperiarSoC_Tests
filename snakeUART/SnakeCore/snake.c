#include <stdint.h>

#include "snake.h"

Game game;

void Setup ()
{
	DisplayInit ();
	DisplayOutput ();

	GameInit (&game);
}

int Loop ()
{
	char input;
	int gameState = GameUpdate (&game, GetInput (MOVE_TIMEOUT, &input), input);

	if (gameState == GAME_STATE_WON)
		DrawGameWin (game.score);
	else if (gameState == GAME_STATE_LOST)
		DrawGameLose (game.score);

	return gameState;
}

void Finish ()
{
	GameFinish (&game);
	DisplayFinish ();
}