#ifndef __mmFunctions_h__
#define __mmFunctions_h__

/************************************************************************/

#include <basetsd.h>
#include <stdlib.h>
#include <math.h>

/************************************************************************/

#define SAFE_DELETE(p)        { if(p) { delete (p);      (p)=NULL; } }
#define SAFE_DELETE_ARRAY(p)  { if(p) { delete[] (p);    (p)=NULL; } }
#define SAFE_DELETE_OBJECT(p) { if(p) { DeleteObject(p); (p)=NULL; } }
#define SAFE_RELEASE(p)       { if(p) { (p)->Release();  (p)=NULL; } }
#define SAFE_UNACQUIRE(p)     { if(p) { (p)->Unacquire();          } }

/************************************************************************/

int		RandomNumber(int iMin, int iMax);
float	RandomNumber(float fMin, float fMax);

/************************************************************************/

#endif