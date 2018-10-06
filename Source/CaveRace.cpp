/***************************************************************************
 *                                                                         *
 *        Name : CaveRace.cpp                                              *
 *                                                                         *
 *     Version : 1.2 (01-05-98)                                            *
 *                                                                         *
 *     Made on : 17-03-97                                                  *
 *                                                                         *
 *     Made by : Clemens Schotte                                           *
 *               Harro Lock                                                *
 *               Paul Bosselaar                                            *
 *               Paul van Croonenburg                                      *
 *                                                                         *
 * Description : The Game CaveRace                                         *
 *                                                                         *
 ***************************************************************************/

#include "include\caverace.inc"

/***************************************************************************/

BYTE cheat_enabled=FALSE;          // Cheat functies beschikbaar ?
BYTE slow_enabled=FALSE;           // Voor slome PC's

/***************************************************************************/

void main(int argc,char *argv[])
{
  if(argc==2 && StringComp(argv[1],"-powerblast"))
  cheat_enabled=TRUE;              // Maak de cheat-functies beschikbaar

  if(argc==2 && StringComp(argv[1],"-slow"))
  slow_enabled=TRUE;               // Voor slome PC's

  FileCheck();                     // Controleer aanwezigheid van de bestanden
  AllocateVideoBuffers();          // Reserveer videogeheugen
  SetVideoMode(MCGA);              // Stel videomode in (grafisch 320*200*256)

  LoadPalette();                   // Stel palette in
  LoadFont();                      // Lees font in

  MouseInit();                     // Initialiseer de muis
  MainMenu();                      // Start het hoofdmenu

  SetVideoMode(TEXT);              // Stel videomode in (tekst-mode 80*25)
  FreeVideoBuffers();              // Videogeheugen vrijgeven

  printf("CaveRace (1.2) Copyright 1997-2018 NavaTron.\n\n");

  printf("Use: -powerblast for cheats, key F1 to F5.\n");
  printf("     -slow for slow PC's.\n\n");
  
  printf("www.caverace.com\n");
}

/**************************************************************************/