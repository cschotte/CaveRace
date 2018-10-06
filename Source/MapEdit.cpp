/***************************************************************************
 *                                                                         *
 *        Name : MapEdit.cpp                                               *
 *                                                                         *
 *     Version : 1.1                                                       *
 *                                                                         *
 *     Made on : 15-04-98                                                  *
 *                                                                         *
 *     Made by : Clemens Schotte                                           *
 *               Harro Lock                                                *
 *               Paul Bosselaar                                            *
 *               Paul van Croonenburg                                      *
 *                                                                         *
 * Description : Map-editor for CaveRace maps                              *
 *                                                                         *
 ***************************************************************************/

#include "include\keyboard.inc"
#include "include\mouse.inc"


#define XM 8                           // Marge in de x en y richting
#define YM 4                           // i.v.m. het kader

/***************************************************************************/

BYTE key=0,pos=0,currentbg=0,grid=1,mode=0;
BYTE veld[5][19][11]={0};
BYTE bgs[50][16][16];                    // Array met achtergronden
BYTE itm[13][16][16];
BYTE trs[7][16][16];
BYTE enm[15][16][16];
BYTE man[2][16][16];
char size[5]={50,13,7,15,2};

/***************************************************************************/

void screen(void);
void balk(void);
void keuze(void);
void makescreen(void);
void ShowGrid(void);

void kiesbg(void);
void tekenbg(void);
void pakbg(void);

void Mouse(void);
void LoadMap(int,BYTE *);
void SaveMap(BYTE *);

void readbgs(WORD);                      // Leest achtergronden in
void crpalette(void);                    // Leest palette in + setpalette
void putbgs(BYTE,BYTE,BYTE);             // Teken achtergrondvlakje

/***************************************************************************/

void main(int argc,char *argv[])
{
  printf("CaveRace MapEditor (1.1) Copyright 1997-2018 NavaTron.\n\n");

  LoadMap(argc,argv[1]);                                // Map laden
  screen();                                             // Schermopbouw
  while(key!=ESC)
  {
    Mouse();                                            // Muisbesturing
    if(kbhit()) keuze();                                // Toetsafhandeling
    if(m.k==1 && m.y>182) kiesbg();
    if(m.k==1 && m.y<179 && m.y>4 && m.x>8 && m.x<312) tekenbg();
    if(m.k==2 && m.y<179 && m.y>4 && m.x>8 && m.x<312) pakbg();
  }
  SetVideoMode(TEXT);
  SaveMap(argv[1]);                                     // Map bewaren
}

/***************************************************************************/

void screen(void)
{
  SetVideoMode(MCGA);
  crpalette();
  SetColor(253,63,0,0);
  readbgs(0);
  MouseInit();
  StdCursor();
  makescreen();
  balk();
  ShowGrid();
}

/***************************************************************************/

void balk(void)
{
  BYTE bgx,i,j;

  WaitScreenRefresh();
  if(m.y>174) HideCursor();                      // verberg cursor
  MemFill(VideoMem[0]+58240,5760,255);        // wis oude balk

  for(bgx=0;bgx<18;bgx++)                        // teken nieuwe balk
  if((bgx+pos)%256<size[mode])
  {
    if(mode==0) for(j=0;j<16;j++) for(i=0;i<16;i++) PutPixel((XM+bgx*17+i),(183+j),bgs[bgx+pos][i][j]);
    if(mode==1) for(j=0;j<16;j++) for(i=0;i<16;i++) PutPixel((XM+bgx*17+i),(183+j),itm[bgx+pos][i][j]);
    if(mode==2) for(j=0;j<16;j++) for(i=0;i<16;i++) PutPixel((XM+bgx*17+i),(183+j),trs[bgx+pos][i][j]);
    if(mode==3) for(j=0;j<16;j++) for(i=0;i<16;i++) PutPixel((XM+bgx*17+i),(183+j),enm[bgx+pos][i][j]);
    if(mode==4) for(j=0;j<16;j++) for(i=0;i<16;i++) PutPixel((XM+bgx*17+i),(183+j),man[bgx+pos][i][j]);
  }

  if(pos<=currentbg && currentbg<pos+18)        // vierkantje om huidige bg
  for(i=0;i<18;i++)
  {
    PutPixel(XM+(currentbg-pos)*17+i-1,182,253);
    PutPixel(XM+(currentbg-pos)*17+i-1,199,253);
    PutPixel(XM+(currentbg-pos)*17-1,183+i,253);
    PutPixel(XM+(currentbg-pos)*17+16,183+i,253);
  }

  StdCursor();
}

/***************************************************************************/

void keuze(void)
{
  key=(GetKey()>>8);
  switch(key)
  {
    case UP    : if(mode>0) mode--; pos=0; currentbg=0;	   break;
    case DOWN  : if(mode<4) mode++; pos=0; currentbg=0;    break;
    case LEFT  : if(pos>0)  pos--;                         break;
    case RIGHT : if(pos<size[mode]-18) pos++;              break;
    case 2     : readbgs(0); makescreen(); ShowGrid();     break; // 1
    case 3     : readbgs(1); makescreen(); ShowGrid();     break; // 2
    case 4     : readbgs(2); makescreen(); ShowGrid();     break; // 3
    case 5     : readbgs(3); makescreen(); ShowGrid();     break; // 4
    case 6     : readbgs(4); makescreen(); ShowGrid();     break; // 5
    case 34    : if(grid) grid=0; else grid=1; ShowGrid(); break; // g van Grid
  }
  balk();
}

/***************************************************************************/

void makescreen()
{
  BYTE i,j,x,y;

  HideCursor();

  for(y=0;y<11;y++)
  for(x=0;x<19;x++)
  for(j=0;j<16;j++)
  for(i=0;i<16;i++)
  {
    PutPixel(XM+(x*16+i),(YM+y*16+j),bgs[veld[0][x][y]][i][j]);
    if(itm[veld[1][x][y]][i][j]) PutPixel(XM+(x*16+i),(YM+y*16+j),itm[veld[1][x][y]][i][j]);
    if(trs[veld[2][x][y]][i][j]) PutPixel(XM+(x*16+i),(YM+y*16+j),trs[veld[2][x][y]][i][j]);
    if(enm[veld[3][x][y]][i][j]) PutPixel(XM+(x*16+i),(YM+y*16+j),enm[veld[3][x][y]][i][j]);
    if(man[veld[4][x][y]][i][j]) PutPixel(XM+(x*16+i),(YM+y*16+j),man[veld[4][x][y]][i][j]);
  }

  StdCursor();
}

/***************************************************************************/

void kiesbg(void)
{
  if(((m.x-8)/(17+pos))<size[mode])
  {
    currentbg=((m.x-8)/17+pos);
    while(m.k) GetMouse();
    balk();
  }
}

/***************************************************************************/

void tekenbg(void)
{
  BYTE i,j,x=(m.x-XM)/16,y=(m.y-YM)/16;

  HideCursor();
  veld[mode][(m.x-XM)/16][(m.y-YM)/16]=currentbg;

  for(j=0;j<16;j++)
  for(i=0;i<16;i++)
  {
    PutPixel(XM+(x*16+i),(YM+y*16+j),bgs[veld[0][x][y]][i][j]);
    if(itm[veld[1][x][y]][i][j]) PutPixel(XM+(x*16+i),(YM+y*16+j),itm[veld[1][x][y]][i][j]);
    if(trs[veld[2][x][y]][i][j]) PutPixel(XM+(x*16+i),(YM+y*16+j),trs[veld[2][x][y]][i][j]);
    if(enm[veld[3][x][y]][i][j]) PutPixel(XM+(x*16+i),(YM+y*16+j),enm[veld[3][x][y]][i][j]);
    if(man[veld[4][x][y]][i][j]) PutPixel(XM+(x*16+i),(YM+y*16+j),man[veld[4][x][y]][i][j]);
  }

  if(grid) ShowGrid();
  while(!m.moved && m.k) GetMouse();
  StdCursor();
}

/*
void tekenbg(void)
{
  HideCursor();
  veld[mode][(m.x-XM)/16][(m.y-YM)/16]=currentbg;
  makescreen();
  while(!m.moved && m.k) GetMouse();
  if(grid) ShowGrid();
  StdCursor();
}
*/
/***************************************************************************/

void pakbg(void)
{
  currentbg=veld[mode][(m.x-8)/16][m.y/16];
  balk();
}

/***************************************************************************/

void Mouse(void)
{
  WORD i,j;
  WORD x=m.x, y=m.y;                        // oude positie onthouden
  GetMouseStatus();                         // muisstatus inlezen

  if(x!=m.x || y!=m.y) m.moved=1;          // test of de muis verplaatst is
  else m.moved=0;

  if(m.moved)
  {
    PutBackground(x,y);                    // oude achtergrond terug zetten
    GetBackground();                       // nieuwe achtergrond inlezen
    PutCursor();                           // cursor tekenen
  }
}

/***************************************************************************/

void LoadMap(int argcount,BYTE *filename)
{
  FILE *pnf;

  if(argcount!=2)
  {
    printf("USAGE: mapedit <filename.map>\n");
    printf("       arrow keys - Objects\n");
    printf("       1 to 5     - Face 1 to 5\n");
    printf("       g          - Grid on/off\n");
    printf("       ESC        - Quit and save\n");
    printf("       MOUSE      - Making the map\n\n");

    printf("www.caverace.com\n");

    exit(1);
  }
  if((pnf=fopen(filename,"rb"))!=NULL)
  {
    fread(veld,sizeof(veld),1,pnf);
    fclose(pnf);
  }
}

/***************************************************************************/

void SaveMap(BYTE *filename)
{
  FILE *pnf;
  
  printf("Map name: %s\n",filename);
  printf("Save map ? (y/n)");
  
  while(key!='y'&&key!='n'&&key!='Y'&&key!='N')
  {
    key=getch();
    if(key=='Y'||key=='y')
    {
      printf("\nSaving...");
      pnf=fopen(filename,"wb");
      fwrite(veld,sizeof(veld),1,pnf);
      fclose(pnf);
      printf(" OK\n");
    }
  }
  printf("\n");
}

/***************************************************************************/

void ShowGrid(void)
{
  WORD i,j;
  if(grid)
  for(j=1;j<11;j++)
  for(i=1;i<19;i++)
  PutPixel((i*16+XM),(j*16+YM),253)
  else makescreen();
}

void crpalette(void)
{
  FILE *pnf;
  WORD i;

  pnf=fopen("..\\graphics\\PAL.bin","rb");
  fread(PaletteMem,768,1,pnf);
  fclose(pnf);
  SetPalette(PaletteMem);
}

void readbgs(WORD nr)
{
  FILE *pnf;

  pnf=fopen("..\\graphics\\BGS.bin","rb");
  fseek(pnf,nr*12800,1);
  fread(bgs,12800,1,pnf);
  fclose(pnf);

  pnf=fopen("..\\graphics\\ENM.bin","rb");
  fread(enm,sizeof(enm),1,pnf);
  fclose(pnf);

  pnf=fopen("..\\graphics\\MAN.bin","rb");
  fread(man,sizeof(man),1,pnf);
  fclose(pnf);

  pnf=fopen("..\\graphics\\ITM.bin","rb");
  fread(itm,sizeof(itm),1,pnf);
  fclose(pnf);

  pnf=fopen("..\\graphics\\TRS.bin","rb");
  fread(trs,sizeof(trs),1,pnf);
  fclose(pnf);
}