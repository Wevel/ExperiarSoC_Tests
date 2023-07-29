#include "game.h"
#include "time.h"

#include "display.h"

static uint32_t randomSeed = 123456789;

static inline uint32_t random (uint32_t min, uint32_t max)
{
	randomSeed ^= randomSeed << 13;
	randomSeed ^= randomSeed >> 17;
	randomSeed ^= randomSeed << 5;
	return randomSeed % (max - min) + min;
}

static void spawnFood (Game* game)
{
	uint32_t index = random (0, MAP_SIZE - game->tailLength);

	uint8_t x = 0;
	uint8_t y = 0;

	for (uint32_t i = 0; i < index; i++)
	{
		// Check if food spawns on the snake
		for (uint8_t j = 0; j < game->tailLength; j++)
		{
			if (x == game->tailPositions[j].x && y == game->tailPositions[j].y)
			{
				// If it does move to the next position, but undo the increment
				i--;
				break;
			}
		}

		// Move to the next position
		x++;
		if (x == MAP_WIDTH)
		{
			x = 0;
			y++;
		}
	}

	game->food = (Vector2){ .x = x, .y = y };
}

void GameInit (Game* game)
{
	randomSeed = random (0, -1);
	//+GetMicros ();

	game->score = 0;
	game->tailLength = 1;
	game->headIndex = 0;
	game->tailPositions[0] = (Vector2){ .x = MAP_WIDTH / 2, .y = MAP_HEIGHT / 2 };

	DisplayDrawSprite (game->tailPositions[0], SNAKE_SPRITE);

	spawnFood (game);
	DisplayDrawSprite (game->food, FOOD_SPRITE);
}

int GameUpdate (Game* game, Vector2 input)
{
	// Get new head position
	Vector2 newLocation = Vector2Add (game->tailPositions[game->headIndex], input);
	newLocation.x = (newLocation.x + MAP_WIDTH) % MAP_WIDTH;
	newLocation.y = (newLocation.y + MAP_HEIGHT) % MAP_HEIGHT;

	// Check if snake eats itself
	// If it does, then the player lost the game
	for (uint8_t i = 0; i < game->tailLength; i++)
	{
		if (newLocation.x == game->tailPositions[i].x && newLocation.y == game->tailPositions[i].y)
		{
			return GAME_STATE_LOST;
		}
	}

	// Check if snake eats food
	if (newLocation.x == game->food.x && newLocation.y == game->food.y)
	{
		// Increase score
		game->score++;

		// Check if tail is too long
		// If it is, then the player won the game
		if (game->tailLength >= MAX_TAIL_LENGTH) return GAME_STATE_WON;

		// Increase tail length
		game->tailLength++;

		// Spawn new food
		spawnFood (game);
		DisplayDrawSprite (game->food, FOOD_SPRITE);
	}

	// Move tail
	game->headIndex = (game->headIndex + 1) % 64;
	game->tailPositions[game->headIndex] = newLocation;
	DisplayDrawSprite (newLocation, SNAKE_SPRITE);

	// Return that the game is still running
	return GAME_STATE_PLAYING;
}

void GameFinish (Game* game)
{
	// ¯\_(ツ)_/¯
}