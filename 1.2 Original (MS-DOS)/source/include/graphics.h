/***************************************************************************
 *                                                                         *
 *        Name : Graphics.h                                                *
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
 * Description : Graphic functions for MCGA video mode 0x13 (320x200x256)  *
 *                                                                         *
 *        Note : This program will only work on DOS- or Windows-based      *
 *               systems with a MCGA, VGA or compatible video adapter      *
 *                                                                         *
 ***************************************************************************/

#define _GRAPHICS

#ifndef _MAIN
#include "include\main.h"
#endif

#ifndef _MEMORY
#include "include\memory.h"
#endif

#ifndef _KEYBOARD
#include "include\keyboard.h"
#endif

/***************************************************************************/

#define MCGA 0x13
#define TEXT 0x03

/***************************************************************************/

#define PutPixel(x,y,color) VideoMem[0][(y<<8)+(y<<6)+x]=color;
#define GetPixel(x,y,color) color=VideoMem[0][(y<<8)+(y<<6)+x];

#define PutBufferPixel(buffer,x,y,color) VideoMem[buffer][(y<<8)+(y<<6)+x]=color;
#define GetBufferPixel(buffer,x,y,color) color=VideoMem[buffer][(y<<8)+(y<<6)+x];

#define PutSprite(buffer,x,y,sprite)                               \
 for(PSY=0,PSOFFSET=x+(y<<8)+(y<<6);PSY<16;PSY++,PSOFFSET+=304)    \
 for(PSX=0;PSX<16;PSX++,PSOFFSET++)                                \
 if(sprite[PSX][PSY]) VideoMem[buffer][PSOFFSET]=sprite[PSX][PSY];

/***************************************************************************/

BYTE far *VideoMem[3]={(BYTE far *)0xA0000000L,(BYTE far *)0xA0000000L,(BYTE far *)0xA0000000L};
BYTE far *PaletteMem=(BYTE far *)0xA000FA00L;
WORD PSOFFSET,PSX,PSY;

/***************************************************************************/

void AllocateVideoBuffers(void);             // Reserveer memory voor buffers
void FreeVideoBuffers(void);                 // Geef memory terug
void SetVideoMode(WORD);                     // Video mode instellen
void SetColor(BYTE,BYTE,BYTE,BYTE);          // Kleur veranderen
void SetPalette(BYTE *);                     // Compleet palette instellen
void FadeIn(BYTE *);                         // Infaden van kleuren
void FadeOut(BYTE *);                        // Uitfaden van kleuren
void Line(WORD,WORD,WORD,WORD,BYTE);         // Een lijn tekenen
void WaitScreenRefresh(void);                // Wacht op schermopbouw
void Rectangle(WORD,WORD,WORD,WORD,BYTE);    // Een vierkant tekenen
void FillRectangle(WORD,WORD,WORD,WORD,BYTE);// Een vlak tekenen

/***************************************************************************/

/*
  Doel      : Het reserveren van extra video memory
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void AllocateVideoBuffers(void)
{
  /* Reserveer videobuffers */
  if((VideoMem[1]=(BYTE *) malloc(64000))==NULL||(VideoMem[2]=(BYTE *) malloc(64000))==NULL)
  {
    printf("Not enough memory for Video Buffer(s).\n");
    exit(1); // Stop het programma
  }

  /* Maak videobuffers leeg */
  MemFill(VideoMem[0],64000,0);
  MemFill(VideoMem[1],64000,0);
  MemFill(VideoMem[2],64000,0);
}

/***************************************************************************/

/*
  Doel      : Het terug geven van het gereserveerde video memory
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void FreeVideoBuffers(void)
{
  free(VideoMem[1]);
  free(VideoMem[2]);
}

/***************************************************************************/

/*
  Doel      : Videomode instellen
  Invoer    : De gewenste videomode
  Uitvoer   : -
  Opmerking : MCGA (0x13) = 320*200*256 (grafisch)
	      TEXT (0x03) = 80*25*16    (text)
*/
void SetVideoMode(WORD mode)
{
  asm{
    mov ax,[mode];
    int(0x10);
  }
}

/***************************************************************************/

/*
  Doel      : Kleur aanpassen
  Invoer    : Kleurnummer (0-255), rood, groen en blauw-waarden (elk 0-63)
  Uitvoer   : -
  Opmerking : -
*/
void SetColor(BYTE color,BYTE red,BYTE green,BYTE blue)
{
  asm{
    mov dx,0x3c8;
    mov al,[color];
    out dx,al;
    inc dx;
    mov al,[red];
    out dx,al;
    mov al,[green];
    out dx,al;
    mov al,[blue];
    out dx,al;
  }
}

/***************************************************************************/

/*
  Doel      : Alle kleuren aanpassen van uit een array
  Invoer    : Pointer naar een Palette array
  Uitvoer   : -
  Opmerking : -
*/
void SetPalette(BYTE *palette)
{
  asm{
    lds si,[palette]
    mov dx,0x3c8
    mov al,0
    out dx,al
    inc dx
    mov ax,256
    mov cx,768
    rep outsb
  }
}

/***************************************************************************/

/*
  Doel      : Alle kleuren van zwart naar originele kleur faden
  Invoer    : Pointer naar een Palette array
  Uitvoer   : -
  Opmerking : -
*/
void FadeIn(BYTE *palette)
{
  BYTE color;
  BYTE number;

  for(color=0;color<64;color+=2)
  {
    for(number=0;number<254;number++)
    {
      SetColor(number,palette[number*3]*color/63,palette[number*3+1]*color/63,palette[number*3+2]*color/63);
      ClearKbBuffer();
    }
    WaitScreenRefresh();
  }
  SetPalette(PaletteMem);
}

/***************************************************************************/

/*
  Doel      : Alle kleuren van originele kleur naar zwart faden
  Invoer    : Een pointer naar een palette array
  Uitvoer   : -
  Opmerking : -
*/
void FadeOut(BYTE *palette)
{
  BYTE color;
  BYTE number;

  for(color=63;color>1;color-=2)
  {
    for(number=0;number<254;number++)
    {
      SetColor(number,palette[number*3]*color/63,palette[number*3+1]*color/63,palette[number*3+2]*color/63);
      ClearKbBuffer();
    }
    WaitScreenRefresh();
  }
  SetPalette(PaletteMem+768);
}

/***************************************************************************/

/*
  Doel      : Een lijn teken van een punt naar een ander punt
  Invoer    : Begin punt (x1,x2) en het eind punt (x2,y2) plus de kleur
  Uitvoer   : -
  Opmerking : -
*/
void Line(WORD x1,WORD y1,WORD x2,WORD y2,BYTE color)
{
  int i,dx,dy,sdx,sdy,dxabs,dyabs,x,y,px,py;

  dx=x2-x1;      // De horizontaale afstand van de lijn
  dy=y2-y1;      // De verticaale afstand van de lijn
  dxabs=abs(dx);
  dyabs=abs(dy);
  sdx=sgn(dx);
  sdy=sgn(dy);
  x=dyabs>>1;
  y=dxabs>>1;
  px=x1;
  py=y1;

  PutPixel(px,py,color);

  if(dxabs>=dyabs) // Is lijn is meer horizontaal dan verticaal
  for(i=0;i<dxabs;i++)
  {
    y+=dyabs;
    if(y>=dxabs)
    {
      y-=dxabs;
      py+=sdy;
    }
    px+=sdx;
    PutPixel(px,py,color);
  }
  else // Is lijn is meer verticaal dan horizontaal
  for(i=0;i<dyabs;i++)
  {
    x+=dxabs;
    if (x>=dyabs)
    {
      x-=dyabs;
      px+=sdx;
    }
    py+=sdy;
    PutPixel(px,py,color);
  }
}

/***************************************************************************/

/*
  Doel      : Wacht tot schermopmaak klaar is. (60Hz)
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void WaitScreenRefresh(void)
{
  while((inp(0x03da) & 0x08));
  while(!(inp(0x03da) & 0x08));
}

/***************************************************************************/

/*
  Doel      : Tekent een vierkant
  Invoer    : de linker bovenhoek en de rechter benedenhoek plus de kleur
  Uitvoer   : -
  Opmerking : -
*/
void Rectangle(WORD left,WORD top,WORD right,WORD bottom,BYTE color)
{
  WORD top_offset,bottom_offset,i,temp;

  if (top>bottom)
  {
    temp=top;
    top=bottom;
    bottom=temp;
  }
  if (left>right)
  {
    temp=left;
    left=right;
    right=temp;
  }

  top_offset=(top<<8)+(top<<6);
  bottom_offset=(bottom<<8)+(bottom<<6);

  for(i=left;i<=right;i++)
  {
    VideoMem[0][top_offset+i]=color;
    VideoMem[0][bottom_offset+i]=color;
  }
  for(i=top_offset;i<=bottom_offset;i+=320)
  {
    VideoMem[0][left+i]=color;
    VideoMem[0][right+i]=color;
  }
}

/***************************************************************************/

/*
  Doel      : Tekent een gevuld vlak
  Invoer    : de linker bovenhoek en de rechter benedenhoek
  Uitvoer   : -
  Opmerking : -
*/
void FillRectangle(WORD left,WORD top,WORD right,WORD bottom,BYTE color)
{
  WORD top_offset,bottom_offset,i,j,temp,width;

  if (top>bottom)
  {
    temp=top;
    top=bottom;
    bottom=temp;
  }
  if (left>right)
  {
    temp=left;
    left=right;
    right=temp;
  }

  top_offset=(top<<8)+(top<<6)+left;
  bottom_offset=(bottom<<8)+(bottom<<6)+left;
  width=right-left+1;

  for(i=top_offset;i<=bottom_offset;i+=320)
  MemFill(&VideoMem[0][i],width,color);
}

/***************************************************************************/