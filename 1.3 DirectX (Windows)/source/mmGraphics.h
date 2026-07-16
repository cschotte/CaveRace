#ifndef __mmGraphics_h__
#define __mmGraphics_h__

/************************************************************************/

#include <basetsd.h>
#include <d3dx8.h>
#include <string>

#include "WinMain.h"
#include "mmFunctions.h"

using namespace std;

/************************************************************************/

#define MSG_D3DFAILD	"Faild to use DirectX 3D!\nInstall Miscosoft DirectX 8.1 or later."
#define MSG_D3DGETFAILD	"Can't Get Display Mode!"
#define MSG_D3DDISPLAY	"Can't Create Display Device!"
#define	MSG_D3DSPRITE	"Can't Create Sprites!"
#define MSG_D3DLOAD		"Can't Load Image Files!\n(Re)install CaveRace."
#define MSG_D3DPIXEL	"Only 16, 24 or 32 BitsPerPixel support!"

/************************************************************************/

struct DISPLAY
{
	LONG				Width;
	LONG				Height;
	BYTE				BitsPerPixel;
	LPDIRECT3DDEVICE8	Pointer;
};

struct IMAGE
{
	DWORD				Width;
	DWORD				Height;
	LPDIRECT3DTEXTURE8	Buffer;
};

/************************************************************************/

class mmGraphics
{
private:
	LPDIRECT3D8             m_lpD3D;
	LPD3DXSPRITE            m_lpD3DSprite;

	bool					m_bBegunScene;

public:
	DISPLAY					Display;

public:
							mmGraphics(void);

	bool					Init(HWND hWindow,HINSTANCE hInstance);
	void					Release(void);

	void					Clear(DWORD Color);
	void					Flip(void);

	IMAGE					*LoadImage(string strFileName);
	void					ReleaseImage(IMAGE *pImage);

	void					Blit(LONG x,LONG y,IMAGE *pImage);
	void					Blit(LONG x,LONG y,IMAGE *pImage,BYTE nAlpha);
	void					Blit(LONG x,LONG y,IMAGE *pImage,BYTE nAlpha, float Scaling);
	void					Blit(LONG x,LONG y,IMAGE *pImage,DWORD SrcX,DWORD SrcY,DWORD Width,DWORD Height,BYTE nAlpha);

	void					BlitSprite(LONG x,LONG y,IMAGE *pImage,DWORD Index,DWORD Pixels);
	void					BlitSprite(LONG x,LONG y,IMAGE *pImage,DWORD Index,DWORD Pixels,BYTE nAlpha);
	void					BlitSprite(LONG x,LONG y,IMAGE *pImage,DWORD Index,DWORD Pixels,BYTE nAlpha,WORD Rotation);

private:
	bool					BeginScene(void);
	void					EndScene(void);
};

/************************************************************************/

#endif