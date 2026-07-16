/***************************************************************************
 *                                                                         *
 *        Name : Game.h                                                    *
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
 * Description : Game functions for the game CaveRace                      *
 *                                                                         *
 *        Note : Only for the singleplayer-game                            *
 *                                                                         *
 ***************************************************************************/

#define _GAME

#ifndef _KEYBOARD
#include "include\keyboard.h"
#endif

#ifndef _FONT
#include "include\font.h"
#endif

#ifndef _STRING
#include "include\string.h"
#endif

#define BOMBTIME 12                 // tijd van de bommen
#define MAXLEVEL  9                 // Max. levelnr
#define HITPOINTS 2                 //

/***************************************************************************/

extern BYTE cheat_enabled;                    // Cheat functies beschikbaar ?
extern BYTE slow_enabled;                     // Voor slome PC's

struct
{
  BYTE background[50][16][16];                // achtergrond plaatje(s)
  BYTE item[13][16][16];                      // voorwerpen    ""
  BYTE bomb[17][16][16];                      // bommen        ""
  BYTE enemy[15][16][16];                     // vijanden      ""
  BYTE player[17][16][16];                    // speler        ""
  BYTE status[4][16][16];                     // status        ""
  BYTE treasure[7][16][16];                   //               ""
} sprite={0};

struct
{
  BYTE background[19][11];
  BYTE item[19][11];
  BYTE treasure[19][11];
  BYTE enemy[19][11];
  BYTE player[19][11];
  BYTE bomb[19][11];
} map={0};

struct
{
  BYTE lives;                                 // aantal levens
  BYTE energy;                                // gezondheid
  BYTE bombs;                                 // max. aantal bommen
  BYTE power;                                 // kracht van de bommen
  WORD x,y;                                   // positie speler
  char xmov,ymov;                             // move-variabelen
  WORD points;
} player={0};

struct
{
  BYTE number;                                // nummer
  WORD x,y;                                   // positie
  char xmov,ymov;                             // move-variabelen
} enemy[16]={0};

struct
{
  BYTE time;                                  // resterende tijd
  BYTE power;                                 // kracht van de bom
  WORD x,y;                                   // positie van de bom
} bomb[4]={0};

/* namen van de levels */
BYTE *levels[]={
"levels\\01.bin","levels\\02.bin",
"levels\\03.bin","levels\\04.bin",
"levels\\05.bin","levels\\06.bin",
"levels\\07.bin","levels\\08.bin",
"levels\\09.bin","levels\\10.bin"
};

BYTE levelnr=0;                               // level nummer

/***************************************************************************/

void LoadPalette(void);             // Leest palette in
void LoadMap(BYTE *);               // Leest map data in
void LoadSprites(WORD);             // Leest alle sprite data in
void GetSpritesXY(void);            // Leest de posities uit map

void MakeBackGround(void);          // Maakt achtergrond plaatje
void MoveSprites(BYTE);             // Beweegt de sprites

void GetPlayerMove(BYTE);           // Bepaalt de move-variabelen speler
void GetEnemyMove(void);            // Bepaalt de move-variabelen vijanden

BYTE CheckEnemyHit(void);           // Controleert of speler vijand raakt
BYTE CheckBombHit(void);            // Controleert of iets door bom kapot moet
void CheckBombs(void);              // Telt de tijd van de bomen af
void CheckLevelComplete(void);      // Controleert of level afgelopen is
void Cheat(BYTE);                   // Voer cheat functies uit

void StartGame(void);               // Begint het spel

/* Bepaalt of een punt in een bepaalt gebied valt */
BYTE in(WORD,WORD,WORD,WORD,WORD,WORD);

/***************************************************************************/

/*
  Doel      : Leest palette in
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void LoadPalette(void)
{
  FILE *pnf;

  if((pnf=fopen("graphics\\pal.bin","rb"))==NULL) error();
  fread(PaletteMem,768,1,pnf);
  fclose(pnf);
}

/***************************************************************************/

/*
  Doel      : Leest de map (level) in
  Invoer    : filename van een level
  Uitvoer   : -
  Opmerking : -
*/
void LoadMap(BYTE *filename)
{
  FILE *pnf;

  if((pnf=fopen(filename,"rb"))==NULL) error();
  fread(&map,1045,1,pnf);
  fclose(pnf);
}

/***************************************************************************/

/*
  Doel      : Leest alle sprite data in de buffers
  Invoer    : Welk thema sprites
  Uitvoer   : -
  Opmerking : -
*/
void LoadSprites(WORD theme)
{
  FILE *pnf;

  if((pnf=fopen("graphics\\bgs.bin","rb"))==NULL) error();
  fseek(pnf,theme*12800,1);
  fread(sprite.background,sizeof(sprite.background),1,pnf);
  fclose(pnf);

  if((pnf=fopen("graphics\\trs.bin","rb"))==NULL) error();
  fread(sprite.treasure,sizeof(sprite.treasure),1,pnf);
  fclose(pnf);

  if((pnf=fopen("graphics\\itm.bin","rb"))==NULL) error();
  fread(sprite.item,sizeof(sprite.item),1,pnf);
  fclose(pnf);

  if((pnf=fopen("graphics\\sts.bin","rb"))==NULL) error();
  fread(sprite.status,sizeof(sprite.status),1,pnf);
  fclose(pnf);

  if((pnf=fopen("graphics\\bom.bin","rb"))==NULL) error();
  fread(sprite.bomb,sizeof(sprite.bomb),1,pnf);
  fclose(pnf);

  if((pnf=fopen("graphics\\enm.bin","rb"))==NULL) error();
  fread(sprite.enemy,sizeof(sprite.enemy),1,pnf);
  fclose(pnf);

  if((pnf=fopen("graphics\\man.bin","rb"))==NULL) error();
  fread(sprite.player,sizeof(sprite.player),1,pnf);
  fclose(pnf);
}

/***************************************************************************/

/*
  Doel      : Maakt in VideoBuffer 2 de achtergrond van het spel
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void MakeBackGround(void)
{
  FILE *pnf;
  WORD x,y,px,py,j;

  if((pnf=fopen("graphics\\car.bin","rb"))==NULL) error();
  fread(VideoMem[2],64000,1,pnf);
  fclose(pnf);

  for(py=0;py<11;py++)
  for(px=0;px<19;px++)
  {
    PutSprite(2,(XM+(px<<4)),(YM+(py<<4)),(sprite.background[(map.background[px][py])]));
    if(map.item[px][py])     PutSprite(2,(XM+(px<<4)),(YM+(py<<4)),(sprite.item[(map.item[px][py])]));
    if(map.treasure[px][py]) PutSprite(2,(XM+(px<<4)),(YM+(py<<4)),(sprite.treasure[(map.treasure[px][py])]));
    if(map.enemy[px][py])    PutSprite(1,(XM+(px<<4)),(YM+(py<<4)),(sprite.enemy[(map.enemy[px][py])]));
    if(map.player[px][py])   PutSprite(1,(XM+(px<<4)),(YM+(py<<4)),(sprite.player[(map.player[px][py])]));
  }

  for(j=0;j<player.lives;j++) PutSprite(2,8+(j<<3)+(j<<1),182,sprite.status[0]);

  MemCopy(VideoMem[2],VideoMem[1],64000);
  MemCopy(VideoMem[1],VideoMem[0],64000);
}

/***************************************************************************/

/*
  Doel      : Bepaalt waar alle bewegende sprites moeten beginen
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void GetSpritesXY(void)
{
  BYTE j=0,px,py;

  for(py=0;py<11;py++)
  for(px=0;px<19;px++)
  if(map.player[px][py]==1)
  {
    player.x=(px<<4)+XM;
    player.y=(py<<4)+YM;
  }

  for(py=0;py<11;py++)
  for(px=0;px<19;px++)
  if(j<16)
  {
    enemy[j].number=map.enemy[px][py];
    enemy[j].x=(px<<4)+XM;
    enemy[j].y=(py<<4)+YM;
    if(map.enemy[px][py]) j++;
  }
}

/***************************************************************************/

/*
  Doel      : Bepaalt de move-variabelen speler
  Invoer    : De richting of aktie
  Uitvoer   : -
  Opmerking : -
*/
void GetPlayerMove(BYTE dir)
{
  BYTE i;
  /* move-variabelen van speler instellen  */
  if(dir==SPACE)                         // een bom leggen
  {
    if(player.bombs&&!map.bomb[(player.x-XM)>>4][(player.y-YM)>>4])
    {
      for(i=0;i<4;i++)
      if(!bomb[i].time)                  // bom beschikbaar ?
      {
	 PutSprite(2,player.x,player.y,sprite.bomb[1]);
	 map.bomb[(player.x-XM)>>4][(player.y-YM)>>4]=1;
	 bomb[i].time=BOMBTIME;
	 bomb[i].x=player.x;
	 bomb[i].y=player.y;
	 bomb[i].power=player.power;
	 player.bombs--;
	 if(player.points>4) player.points-=5;
	 break;                         // bom gelegd -> stoppen
      }
    }
    player.xmov=0; player.ymov=0;
  }
  else
  if(dir==DOWN)                          // beweeg omlaag
  {
    if(((player.y-YM)>>4<10)&&(map.background[((player.x-XM)>>4)][((player.y-YM)>>4)+1]<25)&&(map.item[((player.x-XM)>>4)][((player.y-YM)>>4)+1]<=4)&&(!map.bomb[((player.x-XM)>>4)][((player.y-YM)>>4)+1]))
    { player.xmov=0; player.ymov=1; }
    else { player.xmov=0; player.ymov=0; }
  }
  else
  if(dir==UP)                            // beweeg omhoog
  {
    if(((player.y-YM)>>4>0)&&(map.background[((player.x-XM)>>4)][((player.y-YM)>>4)-1]<25)&&(map.item[((player.x-XM)>>4)][((player.y-YM)>>4)-1]<=4)&&(!map.bomb[((player.x-XM)>>4)][((player.y-YM)>>4)-1]))
    { player.xmov=0; player.ymov=-1; }
    else { player.xmov=0; player.ymov=0; }
  }
  else
  if(dir==RIGHT)                         // beweeg rechts
  {
    if(((player.x-XM)>>4<18)&&(map.background[((player.x-XM)>>4)+1][((player.y-YM)>>4)]<25)&&(map.item[((player.x-XM)>>4)+1][((player.y-YM)>>4)]<=4)&&(!map.bomb[((player.x-XM)>>4)+1][((player.y-YM)>>4)]))
    { player.xmov=1; player.ymov=0; }
    else { player.xmov=0; player.ymov=0; }
  }
  else
  if(dir==LEFT)                          // beweeg links
  {
    if(((player.x-XM)>>4>0)&&(map.background[((player.x-XM)>>4)-1][((player.y-YM)>>4)]<25)&&(map.item[((player.x-XM)>>4)-1][((player.y-YM)>>4)]<=4)&&(!map.bomb[((player.x-XM)>>4)-1][((player.y-YM)>>4)]))
    { player.xmov=-1; player.ymov=0; }
    else { player.xmov=0; player.ymov=0; }
  }
  else { player.xmov=0; player.ymov=0; } // blijf staan
}

/***************************************************************************/

/*
  Doel      : Bepaalt de move-variabelen enemys
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void GetEnemyMove(void)
{
  BYTE d,i;
  /* move-variabelen van alle vijanden instellen  */

  for(i=0;i<16;i++) if(enemy[i].number)
  {
    d=random(4);

    if(d==0)
    {
      if(((enemy[i].y-YM)>>4<10)&&(map.background[((enemy[i].x-XM)>>4)][((enemy[i].y-YM)>>4)+1]<25)&&(map.item[((enemy[i].x-XM)>>4)][((enemy[i].y-YM)>>4)+1]<=4)&&(!map.bomb[((enemy[i].x-XM)>>4)][((enemy[i].y-YM)>>4)+1]))
      { enemy[i].xmov=0;  enemy[i].ymov=1; } // omlaag
      else { enemy[i].xmov=0;  enemy[i].ymov=0; }
    }
    else
    if(d==1)
    {
      if(((enemy[i].y-YM)>>4>0)&&(map.background[((enemy[i].x-XM)>>4)][((enemy[i].y-YM)>>4)-1]<25)&&(map.item[((enemy[i].x-XM)>>4)][((enemy[i].y-YM)>>4)-1]<=4)&&(!map.bomb[((enemy[i].x-XM)>>4)][((enemy[i].y-YM)>>4)-1]))
      { enemy[i].xmov=0;  enemy[i].ymov=-1; } // omhoog
      else { enemy[i].xmov=0; enemy[i].ymov=0; }
    }
    else
    if(d==2)
    {
      if(((enemy[i].x-XM)>>4<18)&&(map.background[((enemy[i].x-XM)>>4)+1][((enemy[i].y-YM)>>4)]<25)&&(map.item[((enemy[i].x-XM)>>4)+1][((enemy[i].y-YM)>>4)]<=4)&&(!map.bomb[((enemy[i].x-XM)>>4)+1][((enemy[i].y-YM)>>4)]))
      { enemy[i].xmov=1; enemy[i].ymov=0;  } // rechts
      else { enemy[i].xmov=0;  enemy[i].ymov=0; }
    }
    else
    if(d==3)
    {
      if(((enemy[i].x-XM)>>4>0)&&(map.background[((enemy[i].x-XM)>>4)-1][((enemy[i].y-YM)>>4)]<25)&&(map.item[((enemy[i].x-XM)>>4)-1][((enemy[i].y-YM)>>4)]<=4)&&(!map.bomb[((enemy[i].x-XM)>>4)-1][((enemy[i].y-YM)>>4)]))
      { enemy[i].xmov=-1; enemy[i].ymov=0;  } // links
      else { enemy[i].xmov=0; enemy[i].ymov=0; }
    }
    else
    { enemy[i].xmov=0; enemy[i].ymov=0;  }  // blijf staan
  }
}

/***************************************************************************/

/*
  Doel      : Beweeg alle sprites. 16 stappen
  Invoer    : Richting van de player
  Uitvoer   : -
  Opmerking : -
*/
void MoveSprites(BYTE dir)
{
  BYTE power,i,j,k;
  BYTE enemyhit=FALSE,bombhit=FALSE;
  BYTE score[5];

  /* beweeg alle vijanden + speler in 16 stappen */
  for(i=0;i<16;i++)
  {
    /* scherm opbouwen */
    if(!slow_enabled) WaitScreenRefresh();

    MemCopy(VideoMem[1],VideoMem[0],64000);
    MemCopy(VideoMem[2],VideoMem[1],64000);

    /* speler kan 1 keer per beweging worden geraakt */
    if(!enemyhit) enemyhit=CheckEnemyHit();
    if(!bombhit) bombhit=CheckBombHit();

    /* Teken status */
    for(j=0;j<player.energy;j++) PutSprite(1,53+(j<<2)+j,178,sprite.status[1]);
    for(j=0;j<player.bombs;j++) PutSprite(1,98+(j<<2)+(j<<1),178,sprite.status[3]);
    for(j=0;j<player.power;j++) PutSprite(1,127+(j<<3),178,sprite.status[2]);

    /* Druk score af */
    font.bgColor=0;
    Word2Str(player.points,score);
    PutString(1,202,188,score);

    /* Beweeg mannetje */
    player.x+=player.xmov;
    player.y+=player.ymov;

    /* Teken mannetje */
    if(dir==UP)    {PutSprite(1,player.x,player.y,sprite.player[(i>>1)%4+5]); }
    else if(dir==DOWN)  {PutSprite(1,player.x,player.y,sprite.player[(i>>1)%4+1]); }
    else if(dir==LEFT)  {PutSprite(1,player.x,player.y,sprite.player[(i>>2)%4+9]); }
    else if(dir==RIGHT) {PutSprite(1,player.x,player.y,sprite.player[(i>>2)%4+13]);}
    else PutSprite(1,player.x,player.y,sprite.player[2]);

    /* Beweeg vijanden */
    for(j=0;j<16;j++) if(enemy[j].number)
    {
      enemy[j].x+=enemy[j].xmov;
      enemy[j].y+=enemy[j].ymov;
      PutSprite(1,enemy[j].x,enemy[j].y,sprite.enemy[enemy[j].number]);
    }

    /* Teken Bom explosie */
    for(k=0;k<4;k++)
    if(bomb[k].time==1)
    {
      for(power=1;power<=bomb[k].power;power++)
      {
  if(i<3)                                               // frame 1
	{
	  PutSprite(1,bomb[k].x,bomb[k].y,sprite.bomb[2]);
	  if(bomb[k].y<180-(power<<4)) PutSprite(1,bomb[k].x,bomb[k].y+(power<<4),sprite.bomb[3]);
	  if(bomb[k].x>(power<<4)) PutSprite(1,bomb[k].x-(power<<4),bomb[k].y,sprite.bomb[4]);
	  if(bomb[k].y>(power<<4)) PutSprite(1,bomb[k].x,bomb[k].y-(power<<4),sprite.bomb[5]);
	  if(bomb[k].x<312-(power<<4)) PutSprite(1,bomb[k].x+(power<<4),bomb[k].y,sprite.bomb[6]);
	}
	else
	if(i<6)                                               // frame 2
	{
	  PutSprite(1,bomb[k].x,bomb[k].y,sprite.bomb[7]);
	  if(bomb[k].y<180-(power<<4)) PutSprite(1,bomb[k].x,bomb[k].y+(power<<4),sprite.bomb[8]);
	  if(bomb[k].x>(power<<4)) PutSprite(1,bomb[k].x-(power<<4),bomb[k].y,sprite.bomb[9]);
	  if(bomb[k].y>(power<<4)) PutSprite(1,bomb[k].x,bomb[k].y-(power<<4),sprite.bomb[10]);
	  if(bomb[k].x<312-(power<<4)) PutSprite(1,bomb[k].x+(power<<4),bomb[k].y,sprite.bomb[11]);
	}
	else
	if(i<10)                                              // frame 3
	{
	  PutSprite(1,bomb[k].x,bomb[k].y,sprite.bomb[12]);
	  if(bomb[k].y<180-(power<<4)) PutSprite(1,bomb[k].x,bomb[k].y+(power<<4),sprite.bomb[13]);
	  if(bomb[k].x>(power<<4)) PutSprite(1,bomb[k].x-(power<<4),bomb[k].y,sprite.bomb[14]);
	  if(bomb[k].y>(power<<4)) PutSprite(1,bomb[k].x,bomb[k].y-(power<<4),sprite.bomb[15]);
	  if(bomb[k].x<312-(power<<4)) PutSprite(1,bomb[k].x+(power<<4),bomb[k].y,sprite.bomb[16]);
	}
	else
	if(i<13)                                              // frame 2
	{
	  PutSprite(1,bomb[k].x,bomb[k].y,sprite.bomb[7]);
	  if(bomb[k].y<180-(power<<4)) PutSprite(1,bomb[k].x,bomb[k].y+(power<<4),sprite.bomb[8]);
	  if(bomb[k].x>(power<<4)) PutSprite(1,bomb[k].x-(power<<4),bomb[k].y,sprite.bomb[9]);
	  if(bomb[k].y>(power<<4)) PutSprite(1,bomb[k].x,bomb[k].y-(power<<4),sprite.bomb[10]);
	  if(bomb[k].x<312-(power<<4)) PutSprite(1,bomb[k].x+(power<<4),bomb[k].y,sprite.bomb[11]);
	}
	else                                                  // frame 1
	{
	  PutSprite(1,bomb[k].x,bomb[k].y,sprite.bomb[2]);
	  if(bomb[k].y<180-(power<<4)) PutSprite(1,bomb[k].x,bomb[k].y+(power<<4),sprite.bomb[3]);
	  if(bomb[k].x>(power<<4)) PutSprite(1,bomb[k].x-(power<<4),bomb[k].y,sprite.bomb[4]);
	  if(bomb[k].y>(power<<4)) PutSprite(1,bomb[k].x,bomb[k].y-(power<<4),sprite.bomb[5]);
	  if(bomb[k].x<312-(power<<4)) PutSprite(1,bomb[k].x+(power<<4),bomb[k].y,sprite.bomb[6]);
	}
      }
    }
  }
}

/***************************************************************************/

/*
  Doel      : Controleert of player geraakt wordt door enemy
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
BYTE CheckEnemyHit(void)
{
  BYTE i;
  for(i=0;i<16;i++)
  if(enemy[i].number&&player.x==enemy[i].x&&player.y==enemy[i].y)
  {
    if(player.energy>HITPOINTS)
    {
      player.energy-=HITPOINTS;
      SetColor(0,63,0,0);
    }
    else player.energy=0;
    return(TRUE);
  }
  return(FALSE);
}

/***************************************************************************/

/*
  Doel      : Controleert of player/enemy/item/bom geraakt wordt door bom explosie
  Invoer    : -
  Uitvoer   : true/false
  Opmerking : -
*/
BYTE CheckBombHit(void)
{
  BYTE i,j,power;

  for(i=0;i<4;i++)
  if(bomb[i].time==1)
  {

    /* items */
    for(j=1;j<=bomb[i].power;j++)
    {
      /* omhoog */
      if(in((bomb[i].x-XM)>>4,((bomb[i].y-YM)>>4)-j,0,0,18,10))
      if(map.treasure[(bomb[i].x-XM>>4)][((bomb[i].y-YM)>>4)-j]||map.item[(bomb[i].x-XM>>4)][((bomb[i].y-YM)>>4)-j]<9)
      {
        PutSprite(2,bomb[i].x,bomb[i].y-(j<<4),sprite.background[map.background[(bomb[i].x-XM)>>4][((bomb[i].y-YM)>>4)-j]]);
        map.item[(bomb[i].x-XM)>>4][((bomb[i].y-YM)>>4)-j]=0;
	map.treasure[(bomb[i].x-XM)>>4][((bomb[i].y-YM)>>4)-j]=0;
      }
      /* omlaag */
      if(in((bomb[i].x-XM)>>4,((bomb[i].y-YM)>>4)+j,0,0,18,10))
      if(map.treasure[(bomb[i].x-XM)>>4][((bomb[i].y-YM)>>4)+j]||map.item[(bomb[i].x-XM)>>4][((bomb[i].y-YM)>>4)+j]<9)
      {
        PutSprite(2,bomb[i].x,bomb[i].y+(j<<4),sprite.background[map.background[(bomb[i].x-XM)>>4][((bomb[i].y-YM)>>4)+j]]);
        map.item[(bomb[i].x-XM)>>4][((bomb[i].y-YM)>>4)+j]=0;
        map.treasure[(bomb[i].x-XM)>>4][((bomb[i].y-YM)>>4)+j]=0;
      }
      /* links */
      if(in(((bomb[i].x-XM)>>4)-j,(bomb[i].y-YM)>>4,0,0,18,10))
      if(map.treasure[((bomb[i].x-XM)>>4)-j][(bomb[i].y-YM)>>4]||map.item[((bomb[i].x-XM)>>4)-j][(bomb[i].y-YM)>>4]<9)
      {
	PutSprite(2,bomb[i].x-(j<<4),bomb[i].y,sprite.background[map.background[((bomb[i].x-XM)>>4)-j][(bomb[i].y-YM)>>4]]);
	map.item[((bomb[i].x-XM)>>4)-j][(bomb[i].y-YM)>>4]=0;
        map.treasure[((bomb[i].x-XM)>>4)-j][(bomb[i].y-YM)>>4]=0;
      }
      /* rechts */
      if(in(((bomb[i].x-XM)>>4)+j,(bomb[i].y-YM)>>4,0,0,18,10))
      if(map.treasure[((bomb[i].x-XM)>>4)+j][(bomb[i].y-YM)>>4]||map.item[((bomb[i].x-XM)>>4)+j][(bomb[i].y-YM)>>4]<9)
      {
        PutSprite(2,bomb[i].x+(j<<4),bomb[i].y,sprite.background[map.background[((bomb[i].x-XM)>>4)+j][(bomb[i].y-YM)>>4]]);
	map.item[((bomb[i].x-XM)>>4)+j][(bomb[i].y-YM)>>4]=0;
        map.treasure[((bomb[i].x-XM)>>4)+j][(bomb[i].y-YM)>>4]=0;
      }
    }

    /* bombs */
    for(j=0;j<4;j++)
    {
      /* omhoog */
      power=(bomb[i].power<<4)+8;
      if(power>bomb[i].y) power=bomb[i].y-YM;
      if(in(bomb[j].x,bomb[j].y,bomb[i].x-8,bomb[i].y-power,bomb[i].x+8,bomb[i].y+8)&&bomb[j].time>1)
      { bomb[j].time=1; PutSprite(2,bomb[j].x,bomb[j].y,sprite.background[map.background[(bomb[j].x-XM)>>4][(bomb[j].y-YM)>>4]]); }
      /* beneden */
      power=(bomb[i].power<<4)+8;
      if(power>180-bomb[i].y) power=180-bomb[i].y;
      if(in(bomb[j].x,bomb[j].y,bomb[i].x-8,bomb[i].y-4,bomb[i].x+8,bomb[i].y+power)&&bomb[j].time>1)
      { bomb[j].time=1; PutSprite(2,bomb[j].x,bomb[j].y,sprite.background[map.background[(bomb[j].x-XM)>>4][(bomb[j].y-YM)>>4]]); }
      /* links */
      power=(bomb[i].power<<4)+8;
      if(power>bomb[i].x) power=bomb[i].x-XM;
      if(in(bomb[j].x,bomb[j].y,bomb[i].x-power,bomb[i].y-4,bomb[i].x+8,bomb[i].y+8)&&bomb[j].time>1)
      { bomb[j].time=1; PutSprite(2,bomb[j].x,bomb[j].y,sprite.background[map.background[(bomb[j].x-XM)>>4][(bomb[j].y-YM)>>4]]); }
      /* rechts */
      power=(bomb[i].power<<4)+8;
      if(power>312-bomb[i].x) power=312-bomb[i].x;
      if(in(bomb[j].x,bomb[j].y,bomb[i].x-8,bomb[i].y-4,bomb[i].x+power,bomb[i].y+8)&&bomb[j].time>1)
      { bomb[j].time=1; PutSprite(2,bomb[j].x,bomb[j].y,sprite.background[map.background[(bomb[j].x-XM)>>4][(bomb[j].y-YM)>>4]]); }
    }

    /* enemy */
    for(j=0;j<16;j++)
    {
      /* omhoog */
      power=(bomb[i].power<<4)+8;
      if(power>bomb[i].y) power=bomb[i].y-YM;
      if(enemy[j].number && in(enemy[j].x,enemy[j].y,bomb[i].x-8,bomb[i].y-power,bomb[i].x+8,bomb[i].y+8))
      {
	enemy[j].number=0;
        player.points+=75;
      }
      /* beneden */
      power=(bomb[i].power<<4)+8;
      if(power>180-bomb[i].y) power=180-bomb[i].y;
      if(enemy[j].number && in(enemy[j].x,enemy[j].y,bomb[i].x-8,bomb[i].y-4,bomb[i].x+8,bomb[i].y+power))
      {
        enemy[j].number=0;
	player.points+=75;
      }
      /* links */
      power=(bomb[i].power<<4)+8;
      if(power>bomb[i].x) power=bomb[i].x-XM;
      if(enemy[j].number && in(enemy[j].x,enemy[j].y,bomb[i].x-power,bomb[i].y-4,bomb[i].x+8,bomb[i].y+8))
      {
        enemy[j].number=0;
        player.points+=75;
      }
      /* rechts */
      power=(bomb[i].power<<4)+8;
      if(power>312-bomb[i].x) power=312-bomb[i].x;
      if(enemy[j].number && in(enemy[j].x,enemy[j].y,bomb[i].x-8,bomb[i].y-4,bomb[i].x+power,bomb[i].y+8))
      {
        enemy[j].number=0;
        player.points+=75;
      }
    }

    /* player */
    /* omhoog */
    power=(bomb[i].power<<4)+8;
    if(power>bomb[i].y) power=bomb[i].y-YM;
    if(in(player.x,player.y,bomb[i].x-8,bomb[i].y-power,bomb[i].x+8,bomb[i].y+8))
    {
      if(player.lives) { player.energy=0; }
      else player.energy=0;
      SetColor(0,63,0,0);
      return(TRUE);
    }
    /* beneden */
    power=(bomb[i].power<<4)+8;
    if(power>180-bomb[i].y) power=180-bomb[i].y;
    if(in(player.x,player.y,bomb[i].x-8,bomb[i].y-4,bomb[i].x+8,bomb[i].y+power))
    {
      if(player.lives) { player.energy=0; }
      else player.energy=0;
      SetColor(0,63,0,0);
      return(TRUE);
    }
    /* links */
    power=(bomb[i].power<<4)+8;
    if(power>bomb[i].x) power=bomb[i].x-XM;
    if(in(player.x,player.y,bomb[i].x-power,bomb[i].y-4,bomb[i].x+8,bomb[i].y+8))
    {
      if(player.lives) { player.energy=0; }
      else player.energy=0;
      SetColor(0,63,0,0);
      return(TRUE);
    }
    /* rechts */
    power=(bomb[i].power<<4)+8;
    if(power>312-bomb[i].x) power=312-bomb[i].x;
    if(in(player.x,player.y,bomb[i].x-8,bomb[i].y-4,bomb[i].x+power,bomb[i].y+8))
    {
      if(player.lives) { player.energy=0; }
      else player.energy=0;
      SetColor(0,63,0,0);
      return(TRUE);
    }
  }
  return(FALSE);
}

/***************************************************************************/

/*
  Doel      : Telt de tijd van elke bom af
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void CheckBombs(void)
{
  BYTE i;
  for(i=0;i<4;i++)
  if(bomb[i].time)
  {
    bomb[i].time--;
    if(!bomb[i].time)
    {
      map.bomb[(bomb[i].x-XM)>>4][(bomb[i].y-YM>>4)]=0;
      player.bombs++;
    } else
    if(bomb[i].time==1) PutSprite(2,bomb[i].x,bomb[i].y,sprite.background[map.background[(bomb[i].x-XM)>>4][(bomb[i].y-YM)>>4]]);
  }
}

/***************************************************************************/

/*
  Doel      : Het spel CaveRace (ALONE) main loop
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void StartGame(void)
{
  BYTE key=0,i,j;

  SetTypematicRate(0,0);
  randomize();

  levelnr=0;
  player.bombs=1;
  player.power=1;
  player.energy=8;
  player.lives=4;
  player.points=0;

  for(i=0;i<16;i++) enemy[i].number=0;
  for(i=0;i<4;i++)  bomb[i].time=0;
  for(j=0;j<19;j++)
  for(i=0;i<11;i++)
  {
    map.background[i][j]=0;
    map.item[i][j]=0;
    map.enemy[i][j]=0;
    map.treasure[i][j]=0;
    map.player[i][j]=0;
    map.bomb[i][j]=0;
  }

  LoadMap(levels[levelnr]);
  LoadSprites(random(5));
  GetSpritesXY();
  MakeBackGround();

  FadeIn(PaletteMem);

  while(key!=ESC && player.lives)
  {
    key=0;
    while(kbhit())
    {
      key=(GetKey()>>8);
      if(cheat_enabled) Cheat(key);
      if(key==25)
      {
	SetColor(0,32,32,32);
	key=(GetKey()>>8);
      }
      if(key==31)
      {
	FILE *pnf=fopen("screen.raw","wb");
	fwrite(VideoMem[0],64000,1,pnf);
	fclose(pnf);
      }
    }

    GetEnemyMove();
    GetPlayerMove(key);
    CheckBombs();
    MoveSprites(key);
    SetColor(0,0,0,0);
    CheckLevelComplete();
  }
  if(player.lives) FadeOut(PaletteMem);
  if(!player.points) player.points=5;
}

/***************************************************************************/

/*
  Doel      : Controleert of een punt zich in een vlak bevindt
  Invoer    : punt , vlak
  Uitvoer   : true/false
  Opmerking : -
*/
BYTE in(WORD x,WORD y,WORD x1,WORD y1,WORD x2,WORD y2)
{
  if(x>=x1&&x<=x2&&y>=y1&&y<=y2) return(TRUE);
  return(FALSE);
}

/***************************************************************************/

/*
  Doel      :
  Invoer    :
  Uitvoer   :
  Opmerking :
*/
void CheckLevelComplete(void)
{
  BYTE i,enemycount=0;

  for(i=0;i<16;i++) if(enemy[i].number) enemycount++;

  if(!enemycount)                      /* Nieuw level */
  {
    if(levelnr<MAXLEVEL) levelnr++;
    else levelnr=0;

    FadeOut(PaletteMem);

    for(i=0;i<4;i++)
    { bomb[i].time=0; map.bomb[(bomb[i].x-XM)>>4][(bomb[i].y-YM)>>4]=0; }
    for(i=0;i<16;i++) enemy[i].number=0;

    player.bombs=1;
    player.power=1;
    player.energy=8;
    LoadMap(levels[levelnr]);
    LoadSprites(random(5));
    GetSpritesXY();
    MakeBackGround();

    FadeIn(PaletteMem);
    player.points+=100;

  } else
  if(!player.energy)                   /* Level opnieuw */
  {
    FadeOut(PaletteMem);
    player.lives--;
    if(player.lives)
    {
      for(i=0;i<16;i++) enemy[i].number=0;
      for(i=0;i<4;i++)
      { bomb[i].time=0; map.bomb[(bomb[i].x-XM)>>4][(bomb[i].y-YM)>>4]=0; }
      player.bombs=1;
      player.power=1;
      player.energy=8;
      LoadMap(levels[levelnr]);
      LoadSprites(random(5));
      GetSpritesXY();
      MakeBackGround();
      FadeIn(PaletteMem);
      if(player.points>49) player.points-=50;
    }
  } else                               /* Pak item op */
  if(map.item[(player.x-XM)>>4][(player.y-YM)>>4])
  {
    if(map.item[(player.x-XM)>>4][(player.y-YM)>>4]==1 && player.power<10)
    {
      SetColor(0,0,63,0);
      PutSprite(2,player.x,player.y,sprite.background[map.background[(player.x-XM)>>4][(player.y-YM)>>4]]);
      map.item[(player.x-XM)>>4][(player.y-YM)>>4]=0;
      player.power++;
      player.points+=50;
    }
    if(map.item[(player.x-XM)>>4][(player.y-YM)>>4]==2 && player.bombs<4)
    {
      SetColor(0,0,63,0);
      PutSprite(2,player.x,player.y,sprite.background[map.background[(player.x-XM)>>4][(player.y-YM)>>4]]);
      map.item[(player.x-XM)>>4][(player.y-YM)>>4]=0;
      player.bombs++;
      player.points+=50;
    }
    if(map.item[(player.x-XM)>>4][(player.y-YM)>>4]==3 && player.energy<8)
    {
      SetColor(0,0,63,0);
      PutSprite(2,player.x,player.y,sprite.background[map.background[(player.x-XM)>>4][(player.y-YM)>>4]]);
      map.item[(player.x-XM)>>4][(player.y-YM)>>4]=0;
      player.energy=8;
      player.points+=50;
    }
    if(map.item[(player.x-XM)>>4][(player.y-YM)>>4]==4 && player.lives<4)
    {
      SetColor(0,0,63,0);
      PutSprite(2,player.x,player.y,sprite.background[map.background[(player.x-XM)>>4][(player.y-YM)>>4]]);
      map.item[(player.x-XM)>>4][(player.y-YM)>>4]=0;
      player.lives++;
      for(i=0;i<player.lives;i++) PutSprite(2,8+(i<<3)+(i<<1),182,sprite.status[0]);
      player.points+=50;
    }
  } else
  if(map.treasure[(player.x-XM)>>4][(player.y-YM)>>4])
  {
    SetColor(0,0,0,63);
    PutSprite(2,player.x,player.y,sprite.background[map.background[(player.x-XM)>>4][(player.y-YM)>>4]]);
    map.treasure[(player.x-XM)>>4][(player.y-YM)>>4]=0;
    player.points+=100;
  }
}

/***************************************************************************/

/*
  Doel      : Variabelen bijwerken voor het testen van bepaalde situaties
  Invoer    : De toets
  Uitvoer   : -
  Opmerking : Om deze functies te kunnen gebruiken moet een bepaald argument
	      aan het programma worden meegegeven.
*/
void Cheat(BYTE key)
{
  BYTE i;
  switch(key)
  {
    case 59 :                                 // F1 = next level
      for(i=0;i<16;i++) enemy[i].number=0;
      break;
    case 60 :                                 // F2 = Max. health
      player.lives=4; player.energy=8;
      for(i=0;i<4;i++) PutSprite(2,8+(i<<3)+(i<<1),182,sprite.status[0]);
      break;
    case 61 :                                 // F3 = Max. bombs
      player.bombs=4;
      break;
    case 62 :
      player.power++;                         // F4 = more bombpower
      break;
    case 63 :
      player.points=player.points<<1;         // F5 = double points
      break;
  }
}