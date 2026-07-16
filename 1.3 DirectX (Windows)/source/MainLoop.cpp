#include "MainLoop.h"

/************************************************************************/

extern mmGraphics		Graphics;
extern mmControls		Controls;
extern mmAudio			Audio;

extern volatile bool	g_bDoAbort;
extern volatile bool	g_bIsAppActive;

/************************************************************************/

// Sprites
IMAGE	*imgBomb		= NULL;
IMAGE	*imgEnemy		= NULL;
IMAGE	*imgPlayer		= NULL;
IMAGE	*imgObjects		= NULL;
IMAGE	*imgTools		= NULL;
IMAGE	*imgTreasure	= NULL;

// Interface
IMAGE	*imgGame		= NULL;
IMAGE	*imgMenu		= NULL;
IMAGE	*imgScore		= NULL;
IMAGE	*imgSelect		= NULL;

// Background
IMAGE	*imgBackground[5]= {0};

// Game variable
BYTE	g_GameStatus	= GAME_MENU;

// Sounds
AUDIO	*sndBomb[4]		= {0};
AUDIO	*sndTicking		= NULL;
AUDIO	*sndItem		= NULL;
AUDIO	*sndMenu		= NULL;
AUDIO	*sndSquish		= NULL;

/************************************************************************/

// Old game code !

struct
{
  BYTE background[MAP_WIDTH][MAP_HIGHT];
  BYTE item[MAP_WIDTH][MAP_HIGHT];
  BYTE treasure[MAP_WIDTH][MAP_HIGHT];
  BYTE enemy[MAP_WIDTH][MAP_HIGHT];
  BYTE player[MAP_WIDTH][MAP_HIGHT];
  BYTE bomb[MAP_WIDTH][MAP_HIGHT];
} map={0};

struct
{
  BYTE lives;
  BYTE energy;
  BYTE bombs;
  BYTE power;
  WORD x,y;
  char xmov,ymov;
  WORD points;
} player={0};

struct
{
  BYTE number;
  WORD x,y;
  char xmov,ymov;
} enemy[MAX_ENEMY]={0};

struct
{
  BYTE time;
  BYTE power;
  WORD x,y;
} bomb[MAX_BOMB]={0};


char levels[10][20]={
	"levels\\caverace.s01","levels\\caverace.s02",
	"levels\\caverace.s03","levels\\caverace.s04",
	"levels\\caverace.s05","levels\\caverace.s06",
	"levels\\caverace.s07","levels\\caverace.s08",
	"levels\\caverace.s09","levels\\caverace.s10"
};

BYTE levelnr=0;
BYTE currentbg=0;

// End old game code !

/************************************************************************/

void MainLoop(void)
{
	while(!g_bDoAbort)
	{
		switch(g_GameStatus)
		{
			case GAME_MENU:
				ShowMenu();
				break;

			case GAME_SCORE:
				ShowScore();
				break;

			case GAME_EXIT:
				g_bDoAbort = true;
				break;

			case GAME_START:
				ShowGame();
				break;
		}
	}
}

/************************************************************************/

bool InitBuffers(void)
{
	// Sprites
	if((imgBomb		= Graphics.LoadImage("Media\\Sprites\\Bomb.png"))			== NULL) return false;
	if((imgEnemy	= Graphics.LoadImage("Media\\Sprites\\Enemy.png"))			== NULL) return false;
	if((imgObjects	= Graphics.LoadImage("Media\\Sprites\\Objects.png"))		== NULL) return false;
	if((imgPlayer	= Graphics.LoadImage("Media\\Sprites\\Player.png"))			== NULL) return false;
	if((imgTools	= Graphics.LoadImage("Media\\Sprites\\Tools.png"))			== NULL) return false;
	if((imgTreasure	= Graphics.LoadImage("Media\\Sprites\\Treasure.png"))		== NULL) return false;

	// Interface
	if((imgGame		= Graphics.LoadImage("Media\\Interface\\Game.png"))			== NULL) return false;
	if((imgMenu		= Graphics.LoadImage("Media\\Interface\\Menu.png"))			== NULL) return false;
	if((imgScore	= Graphics.LoadImage("Media\\Interface\\Score.png"))		== NULL) return false;
	if((imgSelect	= Graphics.LoadImage("Media\\Interface\\Select.png"))		== NULL) return false;

	// Background
	if((imgBackground[0] = Graphics.LoadImage("Media\\Background\\Desert.png"))	== NULL) return false;
	if((imgBackground[1] = Graphics.LoadImage("Media\\Background\\Forest.png"))	== NULL) return false;
	if((imgBackground[2] = Graphics.LoadImage("Media\\Background\\Lava.png"))	== NULL) return false;
	if((imgBackground[3] = Graphics.LoadImage("Media\\Background\\Oil.png"))	== NULL) return false;
	if((imgBackground[4] = Graphics.LoadImage("Media\\Background\\Winter.png"))	== NULL) return false;

	// Sounds
	if((sndBomb[0]	= Audio.LoadAudio(L"Media\\Sounds\\Bomb01.wav"))			== NULL) return false;
	if((sndBomb[1]	= Audio.LoadAudio(L"Media\\Sounds\\Bomb02.wav"))			== NULL) return false;
	if((sndBomb[2]	= Audio.LoadAudio(L"Media\\Sounds\\Bomb03.wav"))			== NULL) return false;
	if((sndBomb[3]	= Audio.LoadAudio(L"Media\\Sounds\\Bomb04.wav"))			== NULL) return false;
	if((sndItem		= Audio.LoadAudio(L"Media\\Sounds\\Item.wav"))				== NULL) return false;
	if((sndMenu		= Audio.LoadAudio(L"Media\\Sounds\\Menu.wav"))				== NULL) return false;
	if((sndTicking	= Audio.LoadAudio(L"Media\\Sounds\\Ticking.wav"))			== NULL) return false;
	if((sndSquish	= Audio.LoadAudio(L"Media\\Sounds\\Squish.wav"))			== NULL) return false;
	
	return true;
}

/************************************************************************/

void ReleaseBuffers(void)
{
	// Sprites
	Graphics.ReleaseImage(imgBomb);
	Graphics.ReleaseImage(imgEnemy);
	Graphics.ReleaseImage(imgObjects);	
	Graphics.ReleaseImage(imgPlayer);
	Graphics.ReleaseImage(imgTools);
	Graphics.ReleaseImage(imgTreasure);

	// Interface
	Graphics.ReleaseImage(imgGame);
	Graphics.ReleaseImage(imgMenu);
	Graphics.ReleaseImage(imgSelect);

	// Background
	Graphics.ReleaseImage(imgBackground[0]);
	Graphics.ReleaseImage(imgBackground[1]);
	Graphics.ReleaseImage(imgBackground[2]);
	Graphics.ReleaseImage(imgBackground[3]);
	Graphics.ReleaseImage(imgBackground[4]);

	// Sounds
	Audio.ReleaseAudio(sndBomb[0]);
	Audio.ReleaseAudio(sndBomb[1]);
	Audio.ReleaseAudio(sndBomb[2]);
	Audio.ReleaseAudio(sndBomb[3]);
	Audio.ReleaseAudio(sndItem);
	Audio.ReleaseAudio(sndMenu);
	Audio.ReleaseAudio(sndTicking);
	Audio.ReleaseAudio(sndSquish);
}

/************************************************************************/

void DrawMouse(void)
{
	if(Controls.MouseBuffer.x>Graphics.Display.Width)	Controls.MouseBuffer.x = Graphics.Display.Width;
	if(Controls.MouseBuffer.y>Graphics.Display.Height)	Controls.MouseBuffer.y = Graphics.Display.Height;
	if(Controls.MouseBuffer.x<0)						Controls.MouseBuffer.x = 0;
	if(Controls.MouseBuffer.y<0)						Controls.MouseBuffer.y = 0;

	Graphics.BlitSprite(Controls.MouseBuffer.x,Controls.MouseBuffer.y,imgTools,4,imgTools->Width,255);
}

/************************************************************************/

void ShowMenu(void)
{
	BYTE menu = 0;

	while(g_GameStatus==GAME_MENU)
	{
		Controls.Update();

		if(Controls.KeyboardBuffer[KEY_1])				{ RemoveMenu(menu); menu=0; DrawMenu(menu); }
		if(Controls.KeyboardBuffer[KEY_2])				{ RemoveMenu(menu); menu=1; DrawMenu(menu); }
		if(Controls.KeyboardBuffer[KEY_3])				{ RemoveMenu(menu); menu=2; DrawMenu(menu); }
		if(Controls.KeyboardBuffer[KEY_DOWN] && menu<2)	{ RemoveMenu(menu); menu++; DrawMenu(menu); }
		if(Controls.KeyboardBuffer[KEY_UP]   && menu>0)	{ RemoveMenu(menu); menu--; DrawMenu(menu); }

		if(Controls.KeyboardBuffer[KEY_RETURN] && menu==0) { RemoveMenu(menu); g_GameStatus = GAME_START; }
		if(Controls.KeyboardBuffer[KEY_RETURN] && menu==1) { RemoveMenu(menu); g_GameStatus = GAME_SCORE; }
		if(Controls.KeyboardBuffer[KEY_RETURN] && menu==2) { RemoveMenu(menu); g_GameStatus = GAME_EXIT; }

		if(Controls.MouseIn(120,220,imgSelect->Width,imgSelect->Height) && Controls.MouseBuffer.Button[0]) { RemoveMenu(menu); menu=0; DrawMenu(menu); g_GameStatus = GAME_START; }
		if(Controls.MouseIn(120,265,imgSelect->Width,imgSelect->Height) && Controls.MouseBuffer.Button[0]) { RemoveMenu(menu); menu=1; DrawMenu(menu); g_GameStatus = GAME_SCORE; }
		if(Controls.MouseIn(120,320,imgSelect->Width,imgSelect->Height) && Controls.MouseBuffer.Button[0]) { RemoveMenu(menu); menu=2; DrawMenu(menu); g_GameStatus = GAME_EXIT; }

		Graphics.Blit(0,0,imgMenu);
		Graphics.Blit(120,220+(menu*45),imgSelect);

		DrawMouse();

		Graphics.Flip();

		if(g_bDoAbort) g_GameStatus = GAME_EXIT;
	}
}

void RemoveMenu(BYTE menu)
{
	Audio.Play(sndMenu);

	for(BYTE i=255;i>16;i-=16)
	{
		Controls.Update();

		Graphics.Blit(0,0,imgMenu);
		Graphics.Blit(120,220+(menu*45),imgSelect,i);

		DrawMouse();

		Graphics.Flip();
	}
}


void DrawMenu(BYTE menu)
{
	for(BYTE i=0;i<239;i+=16)
	{
		Controls.Update();

		Graphics.Blit(0,0,imgMenu);
		Graphics.Blit(120,220+(menu*45),imgSelect,i);

		DrawMouse();

		Graphics.Flip();
	}
}

/************************************************************************/

void ShowScore(void)
{
	while(g_GameStatus==GAME_SCORE)
	{
		Controls.Update();
		if(Controls.KeyboardBuffer[KEY_ESC])	g_GameStatus=GAME_MENU;
		if(Controls.KeyboardBuffer[KEY_SPACE])	g_GameStatus=GAME_MENU;

		if(Controls.MouseBuffer.Button[0])		g_GameStatus=GAME_MENU;
		if(Controls.MouseBuffer.Button[1])		g_GameStatus=GAME_MENU;

		Graphics.Blit(0,0,imgScore);

		DrawMouse();

		Graphics.Flip();

		if(g_bDoAbort) g_GameStatus = GAME_EXIT;
	}
}

/************************************************************************/

void ShowGame(void)
{
	srand((unsigned)time(NULL));

	levelnr	= 0;

	player.bombs=1;
	player.power=1;
	player.energy=8;
	player.lives=4;
	player.points=0;

	LoadMap(levels[levelnr]);

	GetSpritesXY();

	while(g_GameStatus==GAME_START)
	{
		Controls.Update();
		if(Controls.KeyboardBuffer[KEY_ESC]) g_GameStatus=GAME_MENU;

		GetEnemyMove();
		GetPlayerMove();
		CheckBombs();
		MoveSprites();
		CheckLevelComplete();

		if(!player.points) player.points=5;

		if(!player.lives) g_GameStatus = GAME_SCORE;
		if(g_bDoAbort) g_GameStatus = GAME_EXIT;
	}
}

/************************************************************************/

void DrawMap(void)
{
	BYTE x,y;

	for(y=0;y<MAP_HIGHT;y++)
		for(x=0;x<MAP_WIDTH;x++)
		{
			Graphics.BlitSprite(OFFSET_X+x*imgBackground[currentbg]->Width,OFFSET_Y+y*imgBackground[currentbg]->Width,imgBackground[currentbg],map.background[x][y],imgBackground[currentbg]->Width,255);
			Graphics.BlitSprite(OFFSET_X+x*imgTreasure->Width,OFFSET_Y+y*imgTreasure->Width,imgTreasure,map.treasure[x][y],imgTreasure->Width,255);
			Graphics.BlitSprite(OFFSET_X+x*imgObjects->Width,OFFSET_Y+y*imgObjects->Width,imgObjects,map.item[x][y],imgObjects->Width,255);
			Graphics.BlitSprite(OFFSET_X+x*imgBomb->Width,OFFSET_Y+y*imgBomb->Width,imgBomb,map.bomb[x][y],imgBomb->Width,255);
		}
}

/************************************************************************/

// Old code
void LoadMap(char *filename)
{
  FILE *pnf;

  pnf=fopen(filename,"rb");
  fread(&map,1045,1,pnf);
  fclose(pnf);

  currentbg = random(5);
}

/************************************************************************/

void GetSpritesXY(void)
{
  BYTE j=0,px,py;

  for(py=0;py<MAP_HIGHT;py++)
  for(px=0;px<MAP_WIDTH;px++)
  if(map.player[px][py]==1)
  {
    player.x=(px<<5)+OFFSET_X;
    player.y=(py<<5)+OFFSET_Y;
  }

  for(py=0;py<MAP_HIGHT;py++)
  for(px=0;px<MAP_WIDTH;px++)
  if(j<MAX_ENEMY)
  {
    enemy[j].number=map.enemy[px][py];
    enemy[j].x=(px<<5)+OFFSET_X;
    enemy[j].y=(py<<5)+OFFSET_Y;
    if(map.enemy[px][py]) j++;
  }
}

/************************************************************************/

void GetEnemyMove(void)
{
  BYTE d,i;

  for(i=0;i<MAX_ENEMY;i++) if(enemy[i].number)
  {
    d=random(4);

    if(d==0)
    {
      if(((enemy[i].y-OFFSET_Y)>>5<10)&&(map.background[((enemy[i].x-OFFSET_X)>>5)][((enemy[i].y-OFFSET_Y)>>5)+1]<25)&&(map.item[((enemy[i].x-OFFSET_X)>>5)][((enemy[i].y-OFFSET_Y)>>5)+1]<=4)&&(!map.bomb[((enemy[i].x-OFFSET_X)>>5)][((enemy[i].y-OFFSET_Y)>>5)+1]))
      { enemy[i].xmov=0;  enemy[i].ymov=2; } // omlaag
      else { enemy[i].xmov=0;  enemy[i].ymov=0; }
    }
    else
    if(d==1)
    {
      if(((enemy[i].y-OFFSET_Y)>>5>0)&&(map.background[((enemy[i].x-OFFSET_X)>>5)][((enemy[i].y-OFFSET_Y)>>5)-1]<25)&&(map.item[((enemy[i].x-OFFSET_X)>>5)][((enemy[i].y-OFFSET_Y)>>5)-1]<=4)&&(!map.bomb[((enemy[i].x-OFFSET_X)>>5)][((enemy[i].y-OFFSET_Y)>>5)-1]))
      { enemy[i].xmov=0;  enemy[i].ymov=-2; } // omhoog
      else { enemy[i].xmov=0; enemy[i].ymov=0; }
    }
    else
    if(d==2)
    {
      if(((enemy[i].x-OFFSET_X)>>5<18)&&(map.background[((enemy[i].x-OFFSET_X)>>5)+1][((enemy[i].y-OFFSET_Y)>>5)]<25)&&(map.item[((enemy[i].x-OFFSET_X)>>5)+1][((enemy[i].y-OFFSET_Y)>>5)]<=4)&&(!map.bomb[((enemy[i].x-OFFSET_X)>>5)+1][((enemy[i].y-OFFSET_Y)>>5)]))
      { enemy[i].xmov=2; enemy[i].ymov=0;  } // rechts
      else { enemy[i].xmov=0;  enemy[i].ymov=0; }
    }
    else
    if(d==3)
    {
      if(((enemy[i].x-OFFSET_X)>>5>0)&&(map.background[((enemy[i].x-OFFSET_X)>>5)-1][((enemy[i].y-OFFSET_Y)>>5)]<25)&&(map.item[((enemy[i].x-OFFSET_X)>>5)-1][((enemy[i].y-OFFSET_Y)>>5)]<=4)&&(!map.bomb[((enemy[i].x-OFFSET_X)>>5)-1][((enemy[i].y-OFFSET_Y)>>5)]))
      { enemy[i].xmov=-2; enemy[i].ymov=0;  } // links
      else { enemy[i].xmov=0; enemy[i].ymov=0; }
    }
    else
    { enemy[i].xmov=0; enemy[i].ymov=0;  }  // blijf staan
  }
}

/************************************************************************/

int random(int max)
{	
	return rand() % max;
}

/************************************************************************/

void GetPlayerMove(void)
{
  BYTE i;
  /* move-variabelen van speler instellen  */
  if(Controls.KeyboardBuffer[KEY_SPACE])                         // een bom leggen
  {
    if(player.bombs&&!map.bomb[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5])
    {
      for(i=0;i<MAX_BOMB;i++)
      if(!bomb[i].time)                  // bom beschikbaar ?
      {
	 map.bomb[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5]=1;
	 bomb[i].time=BOMBTIME;
	 bomb[i].x=player.x;
	 bomb[i].y=player.y;
	 bomb[i].power=player.power;
	 player.bombs--;
	 if(player.points>4) player.points-=5;
	 Audio.Play(sndTicking);
	 break;                         // bom gelegd -> stoppen
      }
    }
    player.xmov=0; player.ymov=0;
  }
  else
  if(Controls.KeyboardBuffer[KEY_DOWN])                          // beweeg omlaag
  {
    if(((player.y-OFFSET_Y)>>5<10)&&(map.background[((player.x-OFFSET_X)>>5)][((player.y-OFFSET_Y)>>5)+1]<25)&&(map.item[((player.x-OFFSET_X)>>5)][((player.y-OFFSET_Y)>>5)+1]<=4)&&(!map.bomb[((player.x-OFFSET_X)>>5)][((player.y-OFFSET_Y)>>5)+1]))
    { player.xmov=0; player.ymov=2; }
    else { player.xmov=0; player.ymov=0; }
  }
  else
  if(Controls.KeyboardBuffer[KEY_UP])                            // beweeg omhoog
  {
    if(((player.y-OFFSET_Y)>>5>0)&&(map.background[((player.x-OFFSET_X)>>5)][((player.y-OFFSET_Y)>>5)-1]<25)&&(map.item[((player.x-OFFSET_X)>>5)][((player.y-OFFSET_Y)>>5)-1]<=4)&&(!map.bomb[((player.x-OFFSET_X)>>5)][((player.y-OFFSET_Y)>>5)-1]))
    { player.xmov=0; player.ymov=-2; }
    else { player.xmov=0; player.ymov=0; }
  }
  else
  if(Controls.KeyboardBuffer[KEY_RIGHT])                         // beweeg rechts
  {
    if(((player.x-OFFSET_X)>>5<18)&&(map.background[((player.x-OFFSET_X)>>5)+1][((player.y-OFFSET_Y)>>5)]<25)&&(map.item[((player.x-OFFSET_X)>>5)+1][((player.y-OFFSET_Y)>>5)]<=4)&&(!map.bomb[((player.x-OFFSET_X)>>5)+1][((player.y-OFFSET_Y)>>5)]))
    { player.xmov=2; player.ymov=0; }
    else { player.xmov=0; player.ymov=0; }
  }
  else
  if(Controls.KeyboardBuffer[KEY_LEFT])                          // beweeg links
  {
    if(((player.x-OFFSET_X)>>5>0)&&(map.background[((player.x-OFFSET_X)>>5)-1][((player.y-OFFSET_Y)>>5)]<25)&&(map.item[((player.x-OFFSET_X)>>5)-1][((player.y-OFFSET_Y)>>5)]<=4)&&(!map.bomb[((player.x-OFFSET_X)>>5)-1][((player.y-OFFSET_Y)>>5)]))
    { player.xmov=-2; player.ymov=0; }
    else { player.xmov=0; player.ymov=0; }
  }
  else { player.xmov=0; player.ymov=0; } // blijf staan
}

/************************************************************************/

void MoveSprites(void)
{
  BYTE power,i,j,k;
  BYTE enemyhit=FALSE,bombhit=FALSE;
//  BYTE score[5];

  /* beweeg alle vijanden + speler in 32 stappen */
  for(i=0;i<32;i+=2)
  {
    /* scherm opbouwen */
	Graphics.Blit(0,0,imgGame);
	DrawMap();

    /* speler kan 1 keer per beweging worden geraakt */
    if(!enemyhit) enemyhit=CheckEnemyHit();
    if(!bombhit) bombhit=CheckBombHit();

    /* Teken status */
    for(j=0;j<player.energy;j++)	Graphics.BlitSprite(106+(j<<3)+(j<<1),366,imgTools,1,imgTools->Width,255);
    for(j=0;j<player.bombs;j++)		Graphics.BlitSprite(196+(j<<3)+(j<<2),366,imgTools,3,imgTools->Width,255);
    for(j=0;j<player.power;j++)		Graphics.BlitSprite(254+(j<<4),366,imgTools,2,imgTools->Width,255);
	for(j=0;j<player.lives;j++)		Graphics.BlitSprite(16+(j<<4)+(j<<2),374,imgTools,0,imgTools->Width,255);

    /* Druk score af */
//    font.bgColor=0;
 //   Word2Str(player.points,score);
  //  PutString(1,202,188,score);

    /* Beweeg mannetje */
    player.x+=player.xmov;
    player.y+=player.ymov;

    /* Teken mannetje */
    if(Controls.KeyboardBuffer[KEY_UP])			Graphics.BlitSprite(player.x,player.y,imgPlayer,(i>>2)%4+5,imgPlayer->Width,255);
    else if(Controls.KeyboardBuffer[KEY_DOWN])  Graphics.BlitSprite(player.x,player.y,imgPlayer,(i>>2)%4+1,imgPlayer->Width,255);
    else if(Controls.KeyboardBuffer[KEY_LEFT])  Graphics.BlitSprite(player.x,player.y,imgPlayer,(i>>3)%4+9,imgPlayer->Width,255);
    else if(Controls.KeyboardBuffer[KEY_RIGHT]) Graphics.BlitSprite(player.x,player.y,imgPlayer,(i>>3)%4+13,imgPlayer->Width,255);
    else Graphics.BlitSprite(player.x,player.y,imgPlayer,2,imgPlayer->Width,255);

    /* Beweeg vijanden */
    for(j=0;j<MAX_ENEMY;j++)
		if(enemy[j].number)
    {
      enemy[j].x+=enemy[j].xmov;
      enemy[j].y+=enemy[j].ymov;
	  Graphics.BlitSprite(enemy[j].x,enemy[j].y,imgEnemy,enemy[j].number,imgEnemy->Width,255);
    }

    /* Teken Bom explosie */
    for(k=0;k<MAX_BOMB;k++)
    if(bomb[k].time==1)
    {
		if(i==0) Audio.Play(sndBomb[random(4)]);

      for(power=1;power<=bomb[k].power;power++)
      {
  if(i<6)                                               // frame 1
	{

	  Graphics.BlitSprite(bomb[k].x,bomb[k].y,imgBomb,2,imgBomb->Width,255);
	  if(bomb[k].y<360-(power<<5)) Graphics.BlitSprite(bomb[k].x,bomb[k].y+(power<<5),imgBomb,3,imgBomb->Width,255);
	  if(bomb[k].x>(power<<5)) Graphics.BlitSprite(bomb[k].x-(power<<5),bomb[k].y,imgBomb,4,imgBomb->Width,255);
	  if(bomb[k].y>(power<<5)) Graphics.BlitSprite(bomb[k].x,bomb[k].y-(power<<5),imgBomb,5,imgBomb->Width,255);
	  if(bomb[k].x<624-(power<<5)) Graphics.BlitSprite(bomb[k].x+(power<<5),bomb[k].y,imgBomb,6,imgBomb->Width,255);
	}
	else
	if(i<12)                                               // frame 2
	{
	  Graphics.BlitSprite(bomb[k].x,bomb[k].y,imgBomb,7,imgBomb->Width,255);
	  if(bomb[k].y<360-(power<<5)) Graphics.BlitSprite(bomb[k].x,bomb[k].y+(power<<5),imgBomb,8,imgBomb->Width,255);
	  if(bomb[k].x>(power<<5)) Graphics.BlitSprite(bomb[k].x-(power<<5),bomb[k].y,imgBomb,9,imgBomb->Width,255);
	  if(bomb[k].y>(power<<5)) Graphics.BlitSprite(bomb[k].x,bomb[k].y-(power<<5),imgBomb,10,imgBomb->Width,255);
	  if(bomb[k].x<624-(power<<5)) Graphics.BlitSprite(bomb[k].x+(power<<5),bomb[k].y,imgBomb,11,imgBomb->Width,255);
	}
	else
	if(i<20)                                              // frame 3
	{
	  Graphics.BlitSprite(bomb[k].x,bomb[k].y,imgBomb,12,imgBomb->Width,255);
	  if(bomb[k].y<360-(power<<5)) Graphics.BlitSprite(bomb[k].x,bomb[k].y+(power<<5),imgBomb,13,imgBomb->Width,255);
	  if(bomb[k].x>(power<<5)) Graphics.BlitSprite(bomb[k].x-(power<<5),bomb[k].y,imgBomb,14,imgBomb->Width,255);
	  if(bomb[k].y>(power<<5)) Graphics.BlitSprite(bomb[k].x,bomb[k].y-(power<<5),imgBomb,15,imgBomb->Width,255);
	  if(bomb[k].x<624-(power<<5)) Graphics.BlitSprite(bomb[k].x+(power<<5),bomb[k].y,imgBomb,16,imgBomb->Width,255);
	}
	else
	if(i<26)                                              // frame 2
	{
	  Graphics.BlitSprite(bomb[k].x,bomb[k].y,imgBomb,7,imgBomb->Width,255);
	  if(bomb[k].y<360-(power<<5)) Graphics.BlitSprite(bomb[k].x,bomb[k].y+(power<<5),imgBomb,8,imgBomb->Width,255);
	  if(bomb[k].x>(power<<5)) Graphics.BlitSprite(bomb[k].x-(power<<5),bomb[k].y,imgBomb,9,imgBomb->Width,255);
	  if(bomb[k].y>(power<<5)) Graphics.BlitSprite(bomb[k].x,bomb[k].y-(power<<5),imgBomb,10,imgBomb->Width,255);
	  if(bomb[k].x<624-(power<<5)) Graphics.BlitSprite(bomb[k].x+(power<<5),bomb[k].y,imgBomb,11,imgBomb->Width,255);
	}
	else                                                  // frame 1
	{
	  Graphics.BlitSprite(bomb[k].x,bomb[k].y,imgBomb,2,imgBomb->Width,255);
	  if(bomb[k].y<360-(power<<5)) Graphics.BlitSprite(bomb[k].x,bomb[k].y+(power<<5),imgBomb,3,imgBomb->Width,255);
	  if(bomb[k].x>(power<<5)) Graphics.BlitSprite(bomb[k].x-(power<<5),bomb[k].y,imgBomb,4,imgBomb->Width,255);
	  if(bomb[k].y>(power<<5)) Graphics.BlitSprite(bomb[k].x,bomb[k].y-(power<<5),imgBomb,5,imgBomb->Width,255);
	  if(bomb[k].x<624-(power<<5)) Graphics.BlitSprite(bomb[k].x+(power<<5),bomb[k].y,imgBomb,6,imgBomb->Width,255);
	}
      }
    }
  Graphics.Flip();
  }
}

/************************************************************************/

BYTE CheckEnemyHit(void)
{
  BYTE i;

  for(i=0;i<MAX_ENEMY;i++)
  if(enemy[i].number&&player.x==enemy[i].x&&player.y==enemy[i].y)
  {
    if(player.energy>HITPOINTS)
    {
      player.energy-=HITPOINTS;
     }
    else player.energy=0;
    return(TRUE);
  }
  return(FALSE);
}

/************************************************************************/

void CheckBombs(void)
{
  BYTE i;

  for(i=0;i<MAX_BOMB;i++)
  if(bomb[i].time)
  {
    bomb[i].time--;
    if(!bomb[i].time)
    {
      map.bomb[(bomb[i].x-OFFSET_X)>>5][(bomb[i].y-OFFSET_Y)>>5]=0;
      player.bombs++;
    }
  }
}

/************************************************************************/

void CheckLevelComplete(void)
{
  BYTE i,enemycount=0;

  for(i=0;i<MAX_ENEMY;i++) if(enemy[i].number) enemycount++;

  if(!enemycount)                      /* Nieuw level */
  {
    if(levelnr<MAX_LEVEL) levelnr++;
    else levelnr=0;

    for(i=0;i<MAX_BOMB;i++)
    { bomb[i].time=0; map.bomb[(bomb[i].x-OFFSET_X)>>5][(bomb[i].y-OFFSET_Y)>>5]=0; }
    for(i=0;i<MAX_ENEMY;i++) enemy[i].number=0;

    player.bombs=1;
    player.power=1;
    player.energy=8;
    LoadMap(levels[levelnr]);
    GetSpritesXY();

    player.points+=100;

  } else
  if(!player.energy)                   /* Level opnieuw */
  {
    player.lives--;
    if(player.lives)
    {
      for(i=0;i<MAX_ENEMY;i++) enemy[i].number=0;
      for(i=0;i<MAX_BOMB;i++)
      { bomb[i].time=0; map.bomb[(bomb[i].x-OFFSET_X)>>5][(bomb[i].y-OFFSET_Y)>>5]=0; }
      player.bombs=1;
      player.power=1;
      player.energy=8;
      LoadMap(levels[levelnr]);
      GetSpritesXY();
      if(player.points>49) player.points-=50;
    }
  } else                               /* Pak item op */
  if(map.item[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5])
  {
    if(map.item[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5]==1 && player.power<10)
    {
      Audio.Play(sndItem);
      map.item[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5]=0;
      player.power++;
      player.points+=50;
    }
    if(map.item[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5]==2 && player.bombs<4)
    {
		Audio.Play(sndItem);
      map.item[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5]=0;
      player.bombs++;
      player.points+=50;
    }
    if(map.item[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5]==3 && player.energy<8)
    {
		Audio.Play(sndItem);
      map.item[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5]=0;
      player.energy=8;
      player.points+=50;
    }
    if(map.item[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5]==4 && player.lives<4)
    {
		Audio.Play(sndItem);
      map.item[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5]=0;
      player.lives++;
      for(i=0;i<player.lives;i++) Graphics.BlitSprite(16+(i<<4)+(i<<2),364,imgTools,0,imgTools->Width,255);
      player.points+=50;
    }
  } else
  if(map.treasure[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5])
  {
	  Audio.Play(sndItem);
    map.treasure[(player.x-OFFSET_X)>>5][(player.y-OFFSET_Y)>>5]=0;
    player.points+=100;
  }
}

/************************************************************************/

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
      if(in((bomb[i].x-OFFSET_X)>>5,((bomb[i].y-OFFSET_Y)>>5)-j,0,0,18,10))
      if(map.treasure[(bomb[i].x-OFFSET_X)>>5][((bomb[i].y-OFFSET_Y)>>5)-j]||map.item[(bomb[i].x-OFFSET_X)>>5][((bomb[i].y-OFFSET_Y)>>5)-j]<9)
      {
		  map.item[(bomb[i].x-OFFSET_X)>>5][((bomb[i].y-OFFSET_Y)>>5)-j]=0;
		  map.treasure[(bomb[i].x-OFFSET_X)>>5][((bomb[i].y-OFFSET_Y)>>5)-j]=0;
      }
      /* omlaag */
      if(in((bomb[i].x-OFFSET_X)>>5,((bomb[i].y-OFFSET_Y)>>5)+j,0,0,18,10))
      if(map.treasure[(bomb[i].x-OFFSET_X)>>5][((bomb[i].y-OFFSET_Y)>>5)+j]||map.item[(bomb[i].x-OFFSET_X)>>5][((bomb[i].y-OFFSET_Y)>>5)+j]<9)
      {
        map.item[(bomb[i].x-OFFSET_X)>>5][((bomb[i].y-OFFSET_Y)>>5)+j]=0;
        map.treasure[(bomb[i].x-OFFSET_X)>>5][((bomb[i].y-OFFSET_Y)>>5)+j]=0;
      }
      /* links */
      if(in(((bomb[i].x-OFFSET_X)>>5)-j,(bomb[i].y-OFFSET_Y)>>5,0,0,18,10))
      if(map.treasure[((bomb[i].x-OFFSET_X)>>5)-j][(bomb[i].y-OFFSET_Y)>>5]||map.item[((bomb[i].x-OFFSET_X)>>5)-j][(bomb[i].y-OFFSET_Y)>>5]<9)
      {
		map.item[((bomb[i].x-OFFSET_X)>>5)-j][(bomb[i].y-OFFSET_Y)>>5]=0;
        map.treasure[((bomb[i].x-OFFSET_X)>>5)-j][(bomb[i].y-OFFSET_Y)>>5]=0;
      }
      /* rechts */
      if(in(((bomb[i].x-OFFSET_X)>>5)+j,(bomb[i].y-OFFSET_Y)>>5,0,0,18,10))
      if(map.treasure[((bomb[i].x-OFFSET_X)>>5)+j][(bomb[i].y-OFFSET_Y)>>5]||map.item[((bomb[i].x-OFFSET_X)>>5)+j][(bomb[i].y-OFFSET_Y)>>5]<9)
      {
		map.item[((bomb[i].x-OFFSET_X)>>5)+j][(bomb[i].y-OFFSET_Y)>>5]=0;
        map.treasure[((bomb[i].x-OFFSET_X)>>5)+j][(bomb[i].y-OFFSET_Y)>>5]=0;
      }
    }

    /* bombs */
    for(j=0;j<MAX_BOMB;j++)
    {
      /* omhoog */
      power=(bomb[i].power<<5)+16;
      if(power>bomb[i].y) power=bomb[i].y-OFFSET_Y;
      if(in(bomb[j].x,bomb[j].y,bomb[i].x-16,bomb[i].y-power,bomb[i].x+16,bomb[i].y+8)&&bomb[j].time>1)
      {
		  bomb[j].time=1;
	  }
      /* beneden */
      power=(bomb[i].power<<5)+16;
      if(power>360-bomb[i].y) power=360-bomb[i].y;
      if(in(bomb[j].x,bomb[j].y,bomb[i].x-16,bomb[i].y-8,bomb[i].x+16,bomb[i].y+power)&&bomb[j].time>1)
      {
		  bomb[j].time=1;
	  }
      /* links */
      power=(bomb[i].power<<5)+16;
      if(power>bomb[i].x) power=bomb[i].x-OFFSET_X;
      if(in(bomb[j].x,bomb[j].y,bomb[i].x-power,bomb[i].y-8,bomb[i].x+16,bomb[i].y+16)&&bomb[j].time>1)
      {
		  bomb[j].time=1;
	  }
      /* rechts */
      power=(bomb[i].power<<5)+16;
      if(power>624-bomb[i].x) power=624-bomb[i].x;
      if(in(bomb[j].x,bomb[j].y,bomb[i].x-16,bomb[i].y-8,bomb[i].x+power,bomb[i].y+16)&&bomb[j].time>1)
      {
		  bomb[j].time=1;
	  }
    }

    /* enemy */
    for(j=0;j<16;j++)
    {
      /* omhoog */
      power=(bomb[i].power<<5)+16;
      if(power>bomb[i].y) power=bomb[i].y-OFFSET_Y;
      if(enemy[j].number && in(enemy[j].x,enemy[j].y,bomb[i].x-16,bomb[i].y-power,bomb[i].x+16,bomb[i].y+16))
      {
		enemy[j].number=0;
        player.points+=75;
		Audio.Play(sndSquish);
      }
      /* beneden */
      power=(bomb[i].power<<5)+16;
      if(power>360-bomb[i].y) power=360-bomb[i].y;
      if(enemy[j].number && in(enemy[j].x,enemy[j].y,bomb[i].x-16,bomb[i].y-8,bomb[i].x+16,bomb[i].y+power))
      {
        enemy[j].number=0;
		player.points+=75;
		Audio.Play(sndSquish);
      }
      /* links */
      power=(bomb[i].power<<5)+16;
      if(power>bomb[i].x) power=bomb[i].x-OFFSET_X;
      if(enemy[j].number && in(enemy[j].x,enemy[j].y,bomb[i].x-power,bomb[i].y-8,bomb[i].x+16,bomb[i].y+16))
      {
        enemy[j].number=0;
        player.points+=75;
		Audio.Play(sndSquish);
      }
      /* rechts */
      power=(bomb[i].power<<5)+16;
      if(power>624-bomb[i].x) power=624-bomb[i].x;
      if(enemy[j].number && in(enemy[j].x,enemy[j].y,bomb[i].x-16,bomb[i].y-8,bomb[i].x+power,bomb[i].y+16))
      {
        enemy[j].number=0;
        player.points+=75;
		Audio.Play(sndSquish);
      }
    }

    /* player */
    /* omhoog */
    power=(bomb[i].power<<5)+16;
    if(power>bomb[i].y) power=bomb[i].y-OFFSET_Y;
    if(in(player.x,player.y,bomb[i].x-16,bomb[i].y-power,bomb[i].x+16,bomb[i].y+16))
    {
      if(player.lives) { player.energy=0; }
      else player.energy=0;
      return(TRUE);
    }
    /* beneden */
    power=(bomb[i].power<<5)+16;
    if(power>360-bomb[i].y) power=360-bomb[i].y;
    if(in(player.x,player.y,bomb[i].x-16,bomb[i].y-8,bomb[i].x+16,bomb[i].y+power))
    {
      if(player.lives) { player.energy=0; }
      else player.energy=0;
      return(TRUE);
    }
    /* links */
    power=(bomb[i].power<<5)+16;
    if(power>bomb[i].x) power=bomb[i].x-OFFSET_X;
    if(in(player.x,player.y,bomb[i].x-power,bomb[i].y-8,bomb[i].x+16,bomb[i].y+16))
    {
      if(player.lives) { player.energy=0; }
      else player.energy=0;
      return(TRUE);
    }
    /* rechts */
    power=(bomb[i].power<<5)+16;
    if(power>624-bomb[i].x) power=624-bomb[i].x;
    if(in(player.x,player.y,bomb[i].x-16,bomb[i].y-8,bomb[i].x+power,bomb[i].y+16))
    {
      if(player.lives) { player.energy=0; }
      else player.energy=0;
      return(TRUE);
    }
  }
  return(FALSE);
}

/************************************************************************/

BYTE in(WORD x,WORD y,WORD x1,WORD y1,WORD x2,WORD y2)
{
  if(x>=x1&&x<=x2&&y>=y1&&y<=y2) return(TRUE);
  return(FALSE);
}

/************************************************************************/