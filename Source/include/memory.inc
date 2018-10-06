/***************************************************************************
 *                                                                         *
 *        Name : Memory.inc                                                *
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
 * Description : Functions for fast 32Bit memory access                    *
 *                                                                         *
 *        Note : This program will only work on 386+ PC systems            *
 *                                                                         *
 ***************************************************************************/

#define _MEMORY

#ifndef _MAIN
#include "include\main.inc"
#endif

/***************************************************************************/

void MemCopy(BYTE *,BYTE *,WORD);           // Blok data kopieeren
void MemFill(BYTE *,WORD,BYTE);             // Blok geheugen vullen

/***************************************************************************/

/*
  Doel      : Datablok kopieren (werkt met array's, strings, pointers,...)
  Invoer    : Bron, doel, grootte
  Uitvoer   : -
  Opmerking : Maakt gebruik van 32-bits instructies (386+)
*/
void MemCopy(BYTE *source,BYTE *dest,WORD size)
{
  asm{
    les  di,[dest];                      // bestemming
    lds  si,[source];                    // bron
    mov  cx,[size];                      // grootte
    mov  bx,cx;
    shr  cx,2;
    db   0x66;
    rep  movsw;
    and  bx,3;
    mov  cx,bx;
    rep  movsb;
  }
}

/***************************************************************************/

/*
  Doel      : Vult een geheugenblok met een bepaalde waarde
  Invoer    : Adres, aantal, waarde
  Uitvoer   : -
  Opmerking : Maakt gebruik van 32-bits instructies (386+)
*/
void MemFill(BYTE *addr,WORD count,BYTE value)
{
  asm{
    les di,[addr];
    mov cx,[count];
    mov al,value;
    mov ah,al;
    mov bx,ax;
    db 0x66;
    shl ax,16;
    shr ax,16;
    mov ax,bx;
    mov bx,cx;
    shr cx,2;
    db 0x66;
    rep stosw;
    and bx,3;
    mov cx,bx;
    rep stosb;
  }
}

/***************************************************************************/