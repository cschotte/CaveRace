/***************************************************************************
 *                                                                         *
 *        Name : KeyBoard.h                                                *
 *                                                                         *
 *     Version : 1.0 (13-06-97)                                            *
 *                                                                         *
 *     Made on : 17-03-97                                                  *
 *                                                                         *
 *     Made by : Clemens Schotte                                           *
 *               Harro Lock                                                *
 *               Paul Bosselaar                                            *
 *               Paul van Croonenburg                                      *
 *                                                                         *
 * Description : Keyboard functions                                        *
 *                                                                         *
 ***************************************************************************/

#define _KEYBOARD

#ifndef _MAIN
#include "include\main.h"
#endif

/***************************************************************************/

#define ESC   1                         // Veelgebruikte toetsen
#define ENTER 28
#define SPACE 57
#define UP    72
#define DOWN  80
#define LEFT  75
#define RIGHT 77

/***************************************************************************/

WORD GetKey();                    // Leest een toets uit
void SetTypematicRate(BYTE,BYTE); // Zet de snelheid van het toetsenbord
void ClearKbBuffer(void);         // Maak het toetsenbord buffer leeg

BYTE keydown[128];

/***************************************************************************/

/*
  Doel      : Leest een key uit het toesenbordbuffer
  Invoer    : -
  Uitvoer   : Key + Scan code
  Opmerking : -
*/
WORD GetKey(void)
{
  WORD k;
  asm{
    mov ah,0x00;
    int 0x16;
    mov k,ax;
  }
  return(k);
}

/***************************************************************************/

/*
  Doel      : Het leeg maken van het toetsenbordbuffer
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void ClearKbBuffer(void)
{
  *(int far *) MK_FP(0x40,0x1a) = *(int far *) MK_FP(0x40,0x1C);
}

/***************************************************************************/

/*
  Doel      : Het instellen van de snelheid dat toesen worden ingelezen
  Invoer    : De vertraging en de snelheid
  Uitvoer   : -
  Opmerking : -
*/
void SetTypematicRate(BYTE delay,BYTE rate)
{
  asm{
    mov ah,3;
    mov al,5;
    mov bh,rate;
    mov bl,delay;
    int 0x16;
  }
}

/***************************************************************************/