#include "mmFunctions.h"

/************************************************************************/

int RandomNumber(int iMin, int iMax)
{
  if (iMin == iMax) return(iMin);
  return((rand() % (abs(iMax-iMin)+1))+iMin);
}

/************************************************************************/

float RandomNumber(float fMin, float fMax)
{
  if (fMin == fMax) return(fMin);
  float fRandom = (float)rand() / (float)RAND_MAX;
  return((fRandom * (float)fabs(fMax-fMin))+fMin);
}

/************************************************************************/