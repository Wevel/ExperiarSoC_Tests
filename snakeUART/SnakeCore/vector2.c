#include "vector2.h"

Vector2 Vector2Add (Vector2 v1, Vector2 v2)
{
	Vector2 result = { v1.x + v2.x, v1.y + v2.y };
	return result;
}

Vector2 Vector2Subtract (Vector2 v1, Vector2 v2)
{
	Vector2 result = { v1.x - v2.x, v1.y - v2.y };
	return result;
}