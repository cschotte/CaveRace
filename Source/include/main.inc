/***************************************************************************
 *                                                                         *
 *        Name : Main.inc                                                  *
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
 * Description : Algemene headerfile voor veelgebruikte defines/includes   *
 *                                                                         *
 ***************************************************************************/

#define _MAIN

#ifndef __STDIO_H
#include <stdio.h>   // fopen(),fread(),fwrite(),fclose(),printf()
#endif

#ifndef __DOS_H
#include <dos.h>
#endif

#ifndef __CONIO_H
#include <conio.h>   // getch(),kbhit()
#endif

#ifndef __PROCESS_H
#include <process.h> // exit()
#endif

#ifndef __ALLOC_H    // malloc(),free()
#include <alloc.h>
#endif

#ifndef __MATH_H
#include <math.h>    // abs()
#endif

#ifndef __SRDLIB.H
#include <stdlib.h>  // randomize(),rand()
#endif

#ifndef __TIME.H
#include <time.h>   // randomize(),rand()
#endif

/***************************************************************************/

#define TRUE  1    // Waar of niet waar
#define FALSE 0

/***************************************************************************/

// Extra variable type.
typedef unsigned char  BYTE;  //  8-Bit
typedef unsigned short WORD;  // 16-Bit
typedef unsigned long  LONG;  // 32-Bit

/***************************************************************************/

#define sgn(x) ((x<0)?-1:((x>0)?1:0))

/***************************************************************************/

void error(void)
{
  asm{ mov ax,0x03; int(0x10); }
  printf("Unexpected error, programm terminated.\n");
  exit(1);
}

/***************************************************************************/