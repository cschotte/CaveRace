#include "include\keyboard.inc"

void main(void)
{
  BYTE key=0;

  printf("\nGeeft de hooge waarde terug van een toets.\nBij gebruik van GetKey()>>8;\nESC is stop.\n\n");

  while(key!=ESC)
  {
    key=(GetKey()>>8);
    printf("%d\n",key);
  }
}