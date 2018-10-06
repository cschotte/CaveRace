/***************************************************************************
 *                                                                         *
 *        Name : CaveRace.inc                                              *
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
 * Description : CaveRace functions                                        *
 *                                                                         *
 *        Note : Only for the game CaveRace                                *
 *                                                                         *
 ***************************************************************************/

#define _CAVERACE

/***************************************************************************/

#define XM 8                           // Marge in de x en y richting
#define YM 4                           // i.v.m. het kader

/***************************************************************************/

#ifndef _MAIN
#include "include\main.inc"
#endif

#ifndef _GRAPHICS
#include "include\graphics.inc"
#endif

#ifndef _MOUSE
#include "include\mouse.inc"
#endif

#ifndef _MEMORY
#include "include\memory.inc"
#endif

#ifndef _TIMER
#include "include\timer.inc"
#endif

#ifndef _MENU
#include "include\menu.inc"
#endif

#ifndef _KEYBOARD
#include "include\keyboard.inc"
#endif

#ifndef _STRING
#include "include\string.inc"
#endif

#ifndef _GAME
#include "include\game.inc"
#endif

#ifndef _FONT
#include "include\font.inc"
#endif

/***************************************************************************/

/*
  Doel      : Het kontroleren of er file(s) missen van CaveRace
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void FileCheck(void)
{
  FILE *pnf;
  BYTE fm=0;

  if((pnf=fopen("graphics\\bgs.bin","rb"))==NULL)
  { printf("File not found : graphics\\bgs.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\bom.bin","rb"))==NULL)
  { printf("File not found : graphics\\bom.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\car.bin","rb"))==NULL)
  { printf("File not found : graphics\\car.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\enm.bin","rb"))==NULL)
  { printf("File not found : graphics\\enm.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\sts.bin","rb"))==NULL)
  { printf("File not found : graphics\\sts.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\itm.bin","rb"))==NULL)
  { printf("File not found : graphics\\itm.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\man.bin","rb"))==NULL)
  { printf("File not found : graphics\\man.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\mn1.bin","rb"))==NULL)
  { printf("File not found : graphics\\mn1.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\mn2.bin","rb"))==NULL)
  { printf("File not found : graphics\\mn2.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\pal.bin","rb"))==NULL)
  { printf("File not found : graphics\\pal.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\trs.bin","rb"))==NULL)
  { printf("File not found : graphics\\trs.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\his.bin","rb"))==NULL)
  { printf("File not found : graphics\\his.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("graphics\\fnt.bin","rb"))==NULL)
  { printf("File not found : graphics\\fnt.bin\n"); fm++; } fclose(pnf);

  if((pnf=fopen("levels\\01.bin","rb"))==NULL)
  { printf("File not found : levels\\01.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("levels\\02.bin","rb"))==NULL)
  { printf("File not found : levels\\02.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("levels\\03.bin","rb"))==NULL)
  { printf("File not found : levels\\03.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("levels\\04.bin","rb"))==NULL)
  { printf("File not found : levels\\04.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("levels\\05.bin","rb"))==NULL)
  { printf("File not found : levels\\05.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("levels\\06.bin","rb"))==NULL)
  { printf("File not found : levels\\06.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("levels\\07.bin","rb"))==NULL)
  { printf("File not found : levels\\07.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("levels\\08.bin","rb"))==NULL)
  { printf("File not found : levels\\08.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("levels\\09.bin","rb"))==NULL)
  { printf("File not found : levels\\09.bin\n"); fm++; } fclose(pnf);
  if((pnf=fopen("levels\\10.bin","rb"))==NULL)
  { printf("File not found : levels\\10.bin\n"); fm++; } fclose(pnf);

  if(fm)
  { printf("\n%d file(s) missing, please re-install CaveRace.\n",fm); exit(1); }
}

/***************************************************************************/
