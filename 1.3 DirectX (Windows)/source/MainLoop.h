#ifndef __MainLoop_h__
#define __MainLoop_h__

/************************************************************************/

// Old DOS code
#include <time.h>
#include <stdio.h>
#include <stdlib.h>
// End old DOS code

#include "WinMain.h"

/************************************************************************/

#define GAME_MENU	0
#define	GAME_SCORE	1
#define GAME_EXIT	2
#define	GAME_START	3

#define BOMBTIME	12
#define HITPOINTS	2

#define	MAP_WIDTH	19
#define MAP_HIGHT	11

#define MAX_ENEMY	16
#define MAX_BOMB	4
#define MAX_LEVEL	9

#define OFFSET_X	16
#define OFFSET_Y	8

/************************************************************************/

void	MainLoop(void);
bool	InitBuffers(void);
void	ReleaseBuffers(void);

/************************************************************************/

void	DrawMouse(void);

void	ShowMenu(void);
void	RemoveMenu(BYTE);
void	DrawMenu(BYTE);

void	ShowScore(void);

void	ShowGame(void);
void	DrawMap(void);

// Old code
void	LoadMap(char *filename);
void	GetSpritesXY(void);
void	GetEnemyMove(void);
int		random(int max);
void	GetPlayerMove(void);
void	MoveSprites(void);
BYTE	CheckEnemyHit(void);
void	CheckBombs(void);
void	CheckLevelComplete(void);
BYTE	CheckBombHit(void);
BYTE	in(WORD x,WORD y,WORD x1,WORD y1,WORD x2,WORD y2);

/************************************************************************/

#endif