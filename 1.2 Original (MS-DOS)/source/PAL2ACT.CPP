#include "include/graphics.inc"

void main(void)
{
  BYTE Palette[768];
  WORD x;

  FILE *pnf=fopen("graphics/caverace.pal","rb");
  fread(Palette,768,1,pnf);
  fclose(pnf);

  for(x=0;x<768;x++) Palette[x]=Palette[x]<<2;

  pnf=fopen("caverace.act","wb");
  fwrite(Palette,768,1,pnf);
  fclose(pnf);
}