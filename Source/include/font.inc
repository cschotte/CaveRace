/***************************************************************************
 *                                                                         *
 *        Name : Font.inc                                                  *
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
 * Description : Font functions                                            *
 *                                                                         *
 ***************************************************************************/

#define _FONT

#ifndef _GRAPHICS
#include "include\graphics.inc"
#endif

#include <ctype.h>

/***************************************************************************/

struct
{
  BYTE character[26][3][5];
  BYTE digit[10][3][5];
  BYTE other[2][3][5];
  BYTE fgColor,bgColor;
} font;

/***************************************************************************/

void LoadFont(void);
void PutString(BYTE,WORD,WORD,BYTE *);

/***************************************************************************/

/*
  Doel      : Leest font in
  Invoer    : -
  Uitvoer   : -
  Opmerking : -
*/
void LoadFont(void)
{
  FILE *pnf;

  if((pnf=fopen("graphics\\fnt.bin","rb"))==NULL) error();
  fread(&font,sizeof(font),1,pnf);
  fclose(pnf);

  font.fgColor=1;
  font.bgColor=0;
}

/***************************************************************************/

/*
  Doel      : Drukt een string af op een grafisch scherm
  Invoer    : x,y,string
  Uitvoer   : -
  Opmerking : -
*/
void PutString(BYTE VideoBuffer,WORD x,WORD y,BYTE *string)
{
  BYTE c,i,j;

  for(c=0;string[c]!='\0';c++)
  for(j=0;j<5;j++)
  for(i=0;i<3;i++)
  {
    /* Druk letter af */
    if(string[c]>64 && string[c]<91)
    if(font.character[string[c]-65][i][j]&&font.fgColor) PutBufferPixel(VideoBuffer,x+(c<<2)+i,y+j,font.fgColor)
    else if(font.bgColor) PutBufferPixel(VideoBuffer,x+(c<<2)+i,y+j,font.bgColor);

    /* Druk cijfer af */
    if(string[c]>47 && string[c]<58)
    if(font.digit[string[c]-48][i][j]&&font.fgColor) PutBufferPixel(VideoBuffer,x+(c<<2)+i,y+j,font.fgColor)
    else if(font.bgColor) PutBufferPixel(VideoBuffer,x+(c<<2)+i,y+j,font.bgColor);

    if(string[c]=='_')
    if(font.other[0][i][j]&&font.fgColor) PutBufferPixel(VideoBuffer,x+(c<<2)+i,y+j,font.fgColor)
    else if(font.bgColor) PutBufferPixel(VideoBuffer,x+(c<<2)+i,y+j,font.bgColor);

    if(string[c]==' ')
    if(font.other[1][i][j]&&font.fgColor) PutBufferPixel(VideoBuffer,x+(c<<2)+i,y+j,font.fgColor)
    else if(font.bgColor) PutBufferPixel(VideoBuffer,x+(c<<2)+i,y+j,font.bgColor);
  }
}

/***************************************************************************/

/*
  Doel      : Een string inlezen vanaf het toetsenbord
  Invoer    : x,y coordinaat, string, max. lengte van de in te lezen string
  Uitvoer   : - (wijzigd de meegeven string)
  Opmerking : -
*/
void ReadString(WORD x,WORD y,BYTE *string,BYTE length)
{
  BYTE key=0,i=0;

  PutString(0,x,y,"_");
  while(key!=13)
  {
    key=toupper((BYTE)getch());
    if(key==8 && i)
    {
      i--;
      string[i]='\0';
      PutString(0,x,y,string);
      PutString(0,x+(i<<2),y,"_ ");
    }

    if(i<length && ((key>47 && key<58) || (key>64 && key<91) || key==32))
    {
      string[i]=key;
      string[i+1]='\0';
      PutString(0,x,y,string);
      PutString(0,x+((i+1)<<2),y,"_");
      i++;
    }
  }
}

/***************************************************************************/