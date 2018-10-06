/***************************************************************************
 *                                                                         *
 *        Name : Menu.inc                                                  *
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
 * Description : Menu functions voor CaveRace                              *
 *                                                                         *
 *        Note : Only for the game CaveRace                                *
 *                                                                         *
 ***************************************************************************/

#define _MENU

#ifndef _GAME
#include "include\game.inc"
#endif

#ifndef _STRING
#include "include\string.inc"
#endif

/***************************************************************************/

void MainMenu(void);                     // Hoofd menu functie
void SubMenu(void);                      // Sub Menu functie
void RemoveMenu(BYTE,BYTE);              // Haalt menu selectie weg
void DrawMenu(BYTE);                     // Toont menu slectie
void LoadMenuPics(void);                 // Leest menu plaatjes in

void HighScores(void);                   // Toont highscore menu
void LoadHighScores(void);               // Load highscores
void SaveHighScores(void);               // Save highscores

/***************************************************************************/

struct
{
  BYTE name[21];
  WORD points;
} highscores[8]={
{"CLEMENS SCHOTTE",10000},
{"HARRO LOCK",9000},
{"PAUL VAN CROONENBURG",8000},
{"PAUL BOSSELAAR",7000},
{"CLEMENS SCHOTTE",6000},
{"HARRO LOCK",5000},
{"PAUL VAN CROONENBURG",4000},
{"PAUL BOSSELAAR",3000},
};

/***************************************************************************/

void MainMenu(void)
{
  BYTE key=0;
  BYTE stop=FALSE;
  BYTE menu=1;

  SetPalette(PaletteMem+768);               // Maak alle kleuren zwart
  LoadMenuPics();                           // Lees menuplaatjes in
  HideCursor();                             // Verberg muiscursor
  MemCopy(VideoMem[1],VideoMem[0],64000);   // Toon scherm
  Rectangle(60,110,260,130,1);
  StdCursor();                              // Laadt standaard cursor
  FadeIn(PaletteMem);                       // Infaden

  while(!stop)
  {
    if(kbhit())                             // Toets-afhandeling
    {
      key=(GetKey()>>8);
      if(key==ESC)             { stop=TRUE; FadeOut(PaletteMem); }
      if(key==UP && menu!=1)   { RemoveMenu(menu,1); menu--; DrawMenu(menu); }
      if(key==DOWN && menu!=3) { RemoveMenu(menu,1); menu++; DrawMenu(menu); }
      if(key==ENTER)
      {
        FadeOut(PaletteMem);
        if(menu==1) SubMenu();
        if(menu==2) HighScores();
        if(menu==3) stop=TRUE;
      }
    }

    if(m.k)                                 // Muis-afhandeling
    {
      if(MouseIn(60,110,260,130))
      {
        if(menu!=1) { RemoveMenu(menu,1); menu=1; DrawMenu(menu); }
        FadeOut(PaletteMem);
        SubMenu();
      }
      else if(MouseIn(60,132,260,152))
      {
        if(menu!=2) { RemoveMenu(menu,1); menu=2; DrawMenu(menu); }
        FadeOut(PaletteMem);
        HighScores();
      }
      else if(MouseIn(60,154,260,174))
      {
        if(menu!=3) { RemoveMenu(menu,1); menu=3; DrawMenu(menu); }
        FadeOut(PaletteMem);
        stop=TRUE;
      }
    }
    GetMouse();
  }
}

/***************************************************************************/

void SubMenu(void)
{
  BYTE key=0;
  BYTE stop=FALSE;
  BYTE menu=1;

  HideCursor();
  MemCopy(VideoMem[2],VideoMem[0],64000);
  Rectangle(60,110,260,130,1);
  StdCursor();
  FadeIn(PaletteMem);

  while(!stop)
  {
    if(kbhit())
    {
      key=(GetKey()>>8);
      if(key==ESC)             { stop=TRUE; FadeOut(PaletteMem); }
      if(key==UP && menu!=1)   { RemoveMenu(menu,2); menu--; DrawMenu(menu); }
      if(key==DOWN && menu!=3) { RemoveMenu(menu,2); menu++; DrawMenu(menu); }
      if(key==ENTER)
      {
	FadeOut(PaletteMem);
	if(menu==1)
	{
	  StartGame();
	  LoadMenuPics();
	  HighScores();
	}
	if(menu==2) FadeIn(PaletteMem); //IPXGame();
	if(menu==3) stop=TRUE;
      }
    }
    if(m.k)
    {
      if(MouseIn(60,110,260,130))
      {
	if(menu!=1) { RemoveMenu(menu,2); menu=1; DrawMenu(menu); }
	FadeOut(PaletteMem);
	StartGame();
	LoadMenuPics();
	HighScores();
      }
      else if(MouseIn(60,132,260,152))
      {
	if(menu!=2) { RemoveMenu(menu,2); menu=2; DrawMenu(menu); }
	/*
	FadeOut(PaletteMem);
	IPXGame()
	*/
      }
      else if(MouseIn(60,154,260,174))
      {
	if(menu!=3) { RemoveMenu(menu,2); menu=3; DrawMenu(menu); }
	FadeOut(PaletteMem);
	stop=TRUE;
      }
    }
    GetMouse();
  }
  HideCursor();
  MemCopy(VideoMem[1],VideoMem[0],64000);
  Rectangle(60,110,260,130,1);
  StdCursor();
  FadeIn(PaletteMem);
}

/***************************************************************************/

/*
  Doel      : Haalt een kader om een item uit het menu weg
  Invoer    : Welk item uit het menu en welk scherm hoort er bij
  Uitvoer   : -
  Opmerking : -
*/
void RemoveMenu(BYTE menu,BYTE screen)
{
  BYTE color;

  for(color=1;color<12;color++)
  {
    WaitScreenRefresh();
    HideCursor();
    Rectangle(60,(menu*22)+88,260,(menu*22)+108,color);
    StdCursor();
  }
  HideCursor();
  MemCopy(VideoMem[screen],VideoMem[0],64000);
  StdCursor();
}

/***************************************************************************/

/*
  Doel      : Tekent een kader om een item uit het menu.
  Invoer    : Welk item uit het menu en welk scherm hoort er bij
  Uitvoer   : -
  Opmerking : -
*/
void DrawMenu(BYTE menu)
{
  BYTE color;

  for(color=11;color>0;color--)
  {
    WaitScreenRefresh();
    HideCursor();
    Rectangle(60,(menu*22)+88,260,(menu*22)+108,color);
    StdCursor();
  }
}

/***************************************************************************/

/*
  Doel      : Laat de twee menu plaatjes in de verschilende video buffers
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void LoadMenuPics(void)
{
  FILE *pnf;

  if((pnf=fopen("graphics\\mn1.bin","rb"))==NULL) error();
  fread(VideoMem[1],64000,1,pnf);
  fclose(pnf);

  if((pnf=fopen("graphics\\mn2.bin","rb"))==NULL) error();
  fread(VideoMem[2],64000,1,pnf);
  fclose(pnf);
}

/***************************************************************************/

void HighScores(void)
{
  FILE *pnf;
  BYTE string[21],i=0;
  WORD temp;

  HideCursor();

  if((pnf=fopen("graphics\\his.bin","rb"))==NULL) error();
  fread(VideoMem[0],32000,2,pnf);
  fclose(pnf);

  font.fgColor=255;
  PutString(0,101,66,"NAME");
  PutString(0,201,66,"SCORE");

  font.fgColor=1;
  PutString(0,100,65,"NAME");
  PutString(0,200,65,"SCORE");

  LoadHighScores();

  for(i=0;i<8;i++)
  {
    PutString(0,100,80+(i<<3),highscores[i].name);
    Word2Str(highscores[i].points,string);
    PutString(0,200,80+(i<<3),string);
  }

  FadeIn(PaletteMem);

  if(player.points>highscores[7].points)
  {
    font.fgColor=11;
    font.bgColor=16;

    Rectangle(98,148,220,156,2);

    Word2Str(player.points,string);
    PutString(0,200,150,string);

    ReadString(100,150,highscores[7].name,20);
    highscores[7].points=player.points;

    FillRectangle(98,75,220,160,16);

    /* Sorteer highscore-lijst */
    for(i=0;i<7;i++)
    if(highscores[7-i].points>highscores[6-i].points)
    {
      StringSwap(highscores[6-i].name,highscores[7-i].name);

      temp=highscores[6-i].points;
      highscores[6-i].points=highscores[7-i].points;
      highscores[7-i].points=temp;
    }
    font.fgColor=1;
  }

  for(i=0;i<8;i++)
  {
    PutString(0,100,80+(i<<3),highscores[i].name);
    Word2Str(highscores[i].points,string);
    PutString(0,200,80+(i<<3),string);
  }

  GetKey();
  FadeOut(PaletteMem);

  SaveHighScores();

  if(player.points==0)
  {
    MemCopy(VideoMem[1],VideoMem[0],64000);
    Rectangle(60,132,260,152,1);
    StdCursor();
    FadeIn(PaletteMem);
  }
  else
  {
    MemCopy(VideoMem[2],VideoMem[0],64000);
    Rectangle(60,110,260,130,1);
    StdCursor();
    FadeIn(PaletteMem);
    player.points=0;
  }
}

/***************************************************************************/

void LoadHighScores(void)
{
  FILE *pnf;
  if((pnf=fopen("caverace.his","rb"))!=NULL)
  {
    fread(&highscores,sizeof(highscores),1,pnf);
    fclose(pnf);
  }
}

/***************************************************************************/

void SaveHighScores(void)
{
  FILE *pnf;
  if((pnf=fopen("caverace.his","wb"))==NULL) error();
  fwrite(&highscores,sizeof(highscores),1,pnf);
  fclose(pnf);
}

/***************************************************************************/
