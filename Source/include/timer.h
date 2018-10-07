/***************************************************************************
 *                                                                         *
 *        Name : Timer.h                                                   *
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
 * Description : Timer functions                                           *
 *                                                                         *
 ***************************************************************************/

#define _TIMER

#ifndef _MAIN
#include "include\main.h"
#endif

/***************************************************************************/

void msTimer(void);                     // Kloksnelheid aanpassen
void SetTimer(WORD);                    // Zet klok op aantal tikken
WORD GetTimer(void);                    // Leest klok uit
void Wait(WORD);                        // Wacht een aantal millisec.

/***************************************************************************/

/*
  Doel      : Millisecondentimer
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void msTimer(void)
{
  asm{
    mov ax,0x36;
    mov dx,0x43;
    cli;
    out dx,ax;
    mov al,es:[di];
    sti;
    mov ax,168.28;
    mov dx,0x40;
    cli;
    out dx,ax;
    mov al,es:[di];
    sti;
    mov ax,4;
    mov dx,0x40;
    cli;
    out dx,ax;
    mov al,es:[di];
    sti;
    mov ah,0x01;
    mov cx,0x00;
    mov dx,0x00;
    int 0x1a;
  }
}

/***************************************************************************/

/*
  Doel      : Zet de klok op een aantal tikken
  Invoer    : Aantal ms
  Uitvoer   : -
  Opmerking : -
*/
void SetTimer(WORD t)
{
  asm{
    mov ah,0x01;
    mov cx,0x00;
    mov dx,[t];
    int 0x1a;
  }
}

/***************************************************************************/

/*
  Doel      : Leest de klok uit
  Invoer    : -
  Uitvoer   : Aantal kloktikken
  Opmerking : -
*/
WORD GetTimer(void)
{
  WORD rv;
  asm{
    mov ah,0x00;
    int 0x1a;
    mov [rv],dx;
  }
  return(rv);
}

/***************************************************************************/

/*
  Doel      : Wacht een aantal milliseconden
  Invoer    : Aantal milliseconden
  Uitvoer   : -
  Opmerking : Tijdsduur afhankelijk van timersnelheid
*/
void Wait(WORD ticks)
{
  WORD i=GetTimer(),j=GetTimer();
  while(i<(j+ticks)) i=GetTimer();
}

/***************************************************************************/