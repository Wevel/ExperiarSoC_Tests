#ifndef VECTOR2_H
#define VECTOR2_H

typedef struct Vector2
{
	int x;
	int y;
} Vector2;

Vector2 Vector2Add (Vector2 v1, Vector2 v2);
Vector2 Vector2Subtract (Vector2 v1, Vector2 v2);

#endif // !VECTOR2_H
