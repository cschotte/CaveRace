/***************************************************************************
 *                                                                         *
 *        Name : String.h                                                  *
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
 * Description : String functions                                          *
 *                                                                         *
 ***************************************************************************/

#define _STRING

#ifndef _MAIN
#include "include\main.h"
#endif

/***************************************************************************/

void StringCopy(char *str1, char *str2); //Plakt 2 strings aan elkaar
BYTE StringComp(char *str1, char *str2); //Vergelijkt 2 strings met elkaar
void Word2Str(WORD nr,char *str);        //Zet een getal in een string
WORD Str2Word(char *str);                //Zet een string om in een getal
void StringSwap(BYTE *,BYTE *);

/***************************************************************************/

/*
  Doel      : Plakt 2 strings aan elkaar
  Invoer    : string1,string2
  Uitvoer   : string1 = string1+string2
  Opmerking : -
*/
void StringCopy(char *str1, char *str2)
{
  BYTE i,j;
  for(i=0;str1[i]!='\0';i++);
  for(j=0;str2[j]!='\0';j++) str1[i+j]=str2[j];
  str1[i+j]='\0';
}

/***************************************************************************/

/*
  Doel      : Vergelijkt 2 strings met elkaar
  Invoer    : string1,string2
  Uitvoer   : 0 bij ongelijk, anders 1
  Opmerking : -
*/
BYTE StringComp(char *str1, char *str2)
{
  BYTE i,j;
  for(i=0;str1[i]!='\0';i++)
  if(str1[i]!=str2[i]) return(FALSE);
  return(TRUE);
}

/***************************************************************************/

/*
  Doel      : Zet een getal in een string
  Invoer    : getal string
  Uitvoer   : -
  Opmerking : -
*/
void Word2Str(WORD nr,char *str)
{
  WORD i,j=nr;
  for(i=1;j/10;j/=10,i++);              // bepaal aantal decimalen

  if(i>0) str[i-1]=nr%10+48;
  if(i>1) str[i-2]=nr%100/10+48;
  if(i>2) str[i-3]=nr%1000/100+48;
  if(i>3) str[i-4]=nr%10000/1000+48;
  if(i>4) str[i-5]=nr/10000+48;
  str[i]='\0';
}

/***************************************************************************/

/*
  Doel      : Zet een string om in een getal
  Invoer    : getal string
  Uitvoer   : -
  Opmerking : De string wordt niet gecontroleerd
*/
WORD Str2Word(char *str)
{
  WORD i,j=1,som=0;
  for(i=0;str[i]!='\0';i++);
  for(;i>0;i--,j*=10) som=som+(str[i-1]-48)*j;
  return(som);
}

/***************************************************************************/

void StringSwap(BYTE string1[21],BYTE string2[21])
{
  BYTE i,temp;

  for(i=0;i<21;i++)
  {
    temp=string1[i];
    string1[i]=string2[i];
    string2[i]=temp;
  }
}