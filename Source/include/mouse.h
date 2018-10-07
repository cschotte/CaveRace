/***************************************************************************
 *                                                                         *
 *        Name : Mouse.h                                                   *
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
 * Description : Muis besturings functions                                 *
 *                                                                         *
 *        Note : Dit is een uitbreiding op 'Graphics.inc' en               *
 *               werkt niet zonder                                         *
 *                                                                         *
 ***************************************************************************/

#define _MOUSE

#ifndef _MAIN
#include "include\main.h"
#endif

#ifndef _GRAPHICS
#include "include\graphics.h"
#endif

/***************************************************************************/

typedef BYTE CURSOR[16][16];

struct mouse
{
  WORD x,y;                             // x,y positie
  BYTE k,h,b;                           // Knop,hoogte,breedte
  CURSOR c;                             // Cursor
  CURSOR a;                             // Achtergrond
  BYTE moved;                           // Bewogen? 0/1 resp. ja/nee
}m;

/***************************************************************************/

void MouseInit(void);                   // Muis instellingen

void StdCursor(void);                   // Standaard cursor laden
void GetMouse(void);                    // Muisstatus inlezen + bewegen
void HideCursor(void);                  // Muis verbergen
BYTE MouseIn(WORD,WORD,WORD,WORD);      // Positie controle
void LoadCursor(BYTE *,CURSOR);         // Laad een cursor van schijf
void SwitchCursor(CURSOR);              // Omschakelen naar andere cursor

void GetMouseStatus(void);              // Muisstatus inlezen
void GetBackground(void);               // Achtergrond inlezen
void GetSize(void);                     // Grootte bepalen
void PutBackground(WORD,WORD);          // Achtergrond terug zetten
void PutCursor(void);                   // Cursor tekenen
void EraseCursor(void);                 // Cursor wissen

void ResetMouse(void);                   // Reset de muis
void SetMouse(WORD,WORD);                // Plaats de muis op een positie
void SetMouseX(WORD,WORD);               // Max x-waarde instellen
void SetMouseY(WORD,WORD);               // Max y-waarde instellen
void MouseSpeed(int,int);                // Muissnelheid instellen
void MouseSense(int,int);                // Muisgevoeligheid instellen

/***************************************************************************/

// Doel      : Muis instellingen
// Invoer    : -
// Uitvoer   : -
// Opmerking : -
void MouseInit(void)
{
  SetMouseX(0,639);
  SetMouseY(0,199);
  MouseSense(10,10);
  StdCursor();
}

/***************************************************************************/

// Doel      : Het gebruik van een muiscursor
// Invoer    : Geen
// Uitvoer   : Geen
// Opmerking : De kleurnummers 254 en 255 zijn gereserveerd voor de
//             standaard muiscursor, de kleur 0 is transparant
#define W 254
#define Z 255
void StdCursor(void)
{
CURSOR std_cur={
  {Z,Z,Z,Z,Z,Z,Z,Z,Z,0,0,0,0,0,0,0},
  {Z,W,W,W,W,W,W,W,Z,0,0,0,0,0,0,0},
  {0,Z,W,W,W,W,W,Z,0,0,0,0,0,0,0,0},
  {0,0,Z,W,W,W,Z,0,0,0,0,0,0,0,0,0},
  {0,0,0,Z,W,W,Z,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,Z,W,Z,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,Z,Z,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
  {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
  };
  SetColor(W,63,63,63);
  SetColor(Z,0,0,0);
  SwitchCursor(std_cur);
}

/***************************************************************************/

// Doel      : Leest de muisstatus uit en beweegt de cursor
// Invoer    : Geen
// Uitvoer   : Geen (wijzigd muis-variabelen)
// Opmerking : Geen
void GetMouse()
{
  WORD x=m.x, y=m.y;                        // oude positie onthouden
  GetMouseStatus();                         // muisstatus inlezen

  if(x!=m.x || y!=m.y) m.moved=1;           // test of de muis verplaatst is
  else m.moved=0;

  if(m.moved)
  {
    PutBackground(x,y);                    // oude achtergrond terug zetten
    GetBackground();                       // nieuwe achtergrond inlezen
    PutCursor();                           // cursor tekenen
  }
}

/***************************************************************************/

// Doel      : De muiscursor verbergen
// Invoer    : Geen
// Uitvoer   : Geen
// Opmerking : De coordinaten van de muiscursor zijn nog wel beschikbaar
void HideCursor(void)
{
  PutBackground(m.x,m.y);
  EraseCursor();
  m.h=0; m.b=0;
}

/***************************************************************************/

// Doel      : Testen of de muiscursor zich in een bepaald gebied bevindt
// Invoer    : x,y coordinaat 1e punt en x,y coordinaat 2e punt
// Uitvoer   : 0/1 resp. nee/ja
// Opmerking : Geen
BYTE MouseIn(WORD x1,WORD y1,WORD x2,WORD y2)
{
  BYTE d;
  if(m.x>x1 && m.x<x2 && m.y>y1 && m.y<y2) d=1;
  else d=0;
  return(d);
}

/***************************************************************************/

// Doel      : Een muiscursor (16*16) laden vanuit een bestand naar een array
// Invoer    : Bestandsnaam, cursor
// Uitvoer   : Geen (leest cursor in array).
// Opmerking : Om over te schakelen naar de geladen cursor moet de functie
//             'switch_cursor' worden gebruikt
void LoadCursor(BYTE *filename,CURSOR cursor)
{
  FILE *pnf;
  pnf=fopen(filename,"rb");
  fread(&cursor,256,1,pnf);
  fclose(pnf);
}

/***************************************************************************/

// Doel      : Omschakelen naar een andere cursor in een array
// Invoer    : Cursor
// Uitvoer   : Geen (wijzigd muisvariabelen)
// Opmerking : Door meerdere cursors te laden en deze om de beurt
//             om te schakelen kan een cursor-animatie gemaakt worden
void SwitchCursor(CURSOR cursor)
{
  BYTE i,j;
  PutBackground(m.x,m.y);
  for(j=0;j<16;j++)
  for(i=0;i<16;i++)
  m.c[i][j]=cursor[i][j];
  GetSize();
  GetMouseStatus();
  GetBackground();
  PutCursor();
}

/***************************************************************************/

// Doel      : Leest de muisstatus uit
// Invoer    : Geen
// Uitvoer   : Geen (wijzigd muisvariabelen)
// Opmerking : Subfunctie van o.a. 'getmouse', ook geschikt voor
//             zelfstandig gebruik
void GetMouseStatus(void)
{
  WORD x,y,k;
  asm{
    mov ax,0x3;
    int(0x33);
    mov [k],bx;
    shr cx,1;
    mov [x],cx;
    mov [y],dx;
  }
  m.x=x;
  m.y=y;
  m.k=k;
}

/***************************************************************************/

// Doel      : Inlezen van de achtergrond waar de muiscursor komt te staan
// Invoer    : Geen
// Uitvoer   : Geen (wijzigd muisvariabelen)
// Opmerking : Deze funtie moet eenmalig uitgevoert worden voor de functie
//             'getmouse' wordt uitgevoerd.
void GetBackground(void)
{
  BYTE i,j;
  for(j=0;j<m.h;j++)
  for(i=0;i<m.b;i++)
  if(m.c[i][j]) GetPixel((m.x+i),(m.y+j),(m.a[i][j]));
}

/***************************************************************************/

// Doel      : Berekend de maximale x en y
// Invoer    : Geen
// Uitvoer   : Geen (wijzigd muisvariabelen)
// Opmerking : Levert een snelheidswinst op bij kleine cursors (mits deze
//             linksboven in het cursorvlak zit)
void GetSize(void)
{
  BYTE i,j;
  m.h=0; m.b=0;
  for(j=0;j<16;j++)
  for(i=0;i<16;i++)
  {
    if(m.c[i][j] && i>m.b) m.b=i;
    if(m.c[i][j] && j>m.h) m.h=j;
  }
  m.b++; m.h++;
}

/***************************************************************************/

// Doel      : Zet de achtergrond van de muiscursor terug
// Invoer    : x,y coordinaat
// Uitvoer   : Geen (beelscherm)
// Opmerking : Subfunctie van o.a. 'getmouse', heeft geen nut voor
//             zelfstandig gebruik
void PutBackground(WORD x,WORD y)
{
  BYTE i,j;
  for(j=0;j<m.h;j++)
  for(i=0;i<m.b;i++)
  if(m.c[i][j]) PutPixel((x+i),(y+j),m.a[i][j]);
}

/***************************************************************************/

// Doel      : Tekent de muiscursor
// Invoer    : Geen
// Uitvoer   : Geen (beeldscherm)
// Opmerking : Sub-functie van o.a. 'getmouse'
void PutCursor(void)
{
  BYTE i,j;
  if(m.x<(320-m.b) && m.y<(200-m.h))
  {
    for(j=0;j<m.h;j++)
    for(i=0;i<m.b;i++)
    if(m.c[i][j]) PutPixel((m.x+i),(m.y+j),m.c[i][j]);
  }
  else
  {
    for(j=0;j<m.h;j++)
    for(i=0;i<m.b;i++)
    if(m.x+i<320 && m.y+j<200 && m.c[i][j]) PutPixel((m.x+i),(m.y+j),m.c[i][j]);
  }
}

/***************************************************************************/

// Doel      : Wissen van de geladen muiscursor
// Invoer    : Geen
// Uitvoer   : Geen (wijzigd muisvariabelen)
// Opmerking : Subfunctie van o.a. 'hidecursor'
void EraseCursor(void)
{
  BYTE i,j;
  for(j=0;j<16;j++)
  for(i=0;i<16;i++)
  m.c[i][j]=0;
}

/***************************************************************************/

// Doel      : Reset de muis
// Invoer    : Geen
// Uitvoer   : Geen
// Opmerking : Geen
void ResetMouse(void)
{
  asm{
    mov ax,0;
    int(0x33);
  }
}

/***************************************************************************/

// Doel      : Zet de muiscursor op een bepaalde positie
// Invoer    : x, y coordinaat
// Uitvoer   : Geen
// Opmerking : Geen
void SetMouse(WORD x,WORD y)
{
  asm{
    mov ax,4;
    mov cx,[x];
    mov dx,[y];
    int(0x33);
  }
}

/***************************************************************************/

// Doel      : Beperkt het muisbereik in de x-richting
// Invoer    : minimale en maximale x-waarde
// Uitvoer   : Geen
// Opmerking : Geen
void SetMouseX(WORD min,WORD max)
{
  asm{
    mov ax,7;
    mov cx,[min];
    mov dx,[max];
    int(0x33);
  }
}

/***************************************************************************/

// Doel      : Beperkt het muisbereik in de y-richting
// Invoer    : Minimale en maximale y-waarde
// Uitvoer   : Geen
// Opmerking : Geen
void SetMouseY(WORD min,WORD max)
{
  asm{
    mov ax,8;
    mov cx,[min];
    mov dx,[max];
    int(0x33);
  }
}

/***************************************************************************/

// Doel      : Stelt de snelheid van de muis in
// Invoer    : Snelheid in de x en y richting
// Uitvoer   : Geen
// Opmerking : Geen
void MouseSpeed(int vx,int vy)
{
  asm{
    mov ax,11;
    int(0x33);
    mov [vx],cx;
    mov [vy],dx;
  }
}

/***************************************************************************/

// Doel      : Stelt de gevoeligheid van de muis in
// Invoer    : Gevoeligheid in x en y richting
// Uitvoer   : Geen
// Opmerking : Een negatief getal levert een beweging in de
//             tegengestelde richting op
void MouseSense(int sx,int sy)
{
  asm{
    mov ax,15;
    mov cx,[sx];
    mov dx,[sy];
    int(0x33);
  }
}

/***************************************************************************/