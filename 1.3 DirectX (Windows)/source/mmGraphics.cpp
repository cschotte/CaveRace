#include "mmGraphics.h"

/************************************************************************/

mmGraphics::mmGraphics(void)
{
	m_lpD3D					= NULL;
	m_lpD3DSprite			= NULL;

	m_bBegunScene			= false;
	
	Display.Width			= 640;
	Display.Height			= 400;
	Display.BitsPerPixel	= 16;

	Display.Pointer			= NULL;
}

/************************************************************************/

bool mmGraphics::Init(HWND		hWindow,
					  HINSTANCE	hInstance)
{
	D3DPRESENT_PARAMETERS	D3Dpp				= {0};
	D3DDISPLAYMODE			D3DDesktopMode		= {0};
	D3DFORMAT               D3DFormatScreen;
	D3DFORMAT				D3DFormatArray[8];

	if((m_lpD3D = Direct3DCreate8(D3D_SDK_VERSION)) == NULL)
		return ErrorMsg(MSG_D3DFAILD);
	
    if(FAILED(m_lpD3D->GetAdapterDisplayMode(D3DADAPTER_DEFAULT,&D3DDesktopMode)))
		return ErrorMsg(MSG_D3DGETFAILD);
	
	switch(Display.BitsPerPixel)
	{
		case 16:
			D3DFormatArray[0] = D3DFMT_X1R5G5B5;
			D3DFormatArray[1] = D3DFMT_A1R5G5B5;
			D3DFormatArray[2] = D3DFMT_R5G6B5;
			D3DFormatArray[3] = D3DFMT_A4R4G4B4;
			D3DFormatArray[4] = D3DFMT_R8G8B8;
			D3DFormatArray[5] = D3DFMT_A8R8G8B8;
			D3DFormatArray[6] = D3DFMT_X8R8G8B8;
			D3DFormatArray[7] = D3DDesktopMode.Format;
			break;
		
		case 24:
			D3DFormatArray[0] = D3DFMT_R8G8B8;
			D3DFormatArray[1] = D3DFMT_A8R8G8B8;
			D3DFormatArray[2] = D3DFMT_X8R8G8B8;
			D3DFormatArray[3] = D3DFMT_A4R4G4B4;
			D3DFormatArray[4] = D3DFMT_R5G6B5;
			D3DFormatArray[5] = D3DFMT_X1R5G5B5;
			D3DFormatArray[6] = D3DFMT_A1R5G5B5;
			D3DFormatArray[7] = D3DDesktopMode.Format;
			break;

		case 32:
			D3DFormatArray[0] = D3DFMT_A8R8G8B8;
			D3DFormatArray[1] = D3DFMT_X8R8G8B8;
			D3DFormatArray[2] = D3DFMT_R8G8B8;
			D3DFormatArray[3] = D3DFMT_X1R5G5B5;
			D3DFormatArray[4] = D3DFMT_A1R5G5B5;
			D3DFormatArray[5] = D3DFMT_R5G6B5;
			D3DFormatArray[6] = D3DFMT_A4R4G4B4;
			D3DFormatArray[7] = D3DDesktopMode.Format;
			break;
		
		default:
			return ErrorMsg(MSG_D3DPIXEL);
	}

	for(int i=0;i<8;i++)
	{
		if(SUCCEEDED(m_lpD3D->CheckDeviceType(D3DADAPTER_DEFAULT,D3DDEVTYPE_HAL,D3DFormatArray[i],D3DFormatArray[i],FALSE)))
		{
			D3DFormatScreen = D3DFormatArray[i];
			break;
		}
        else D3DFormatScreen = D3DFMT_R5G6B5;
	}

	D3Dpp.Windowed				= FALSE;
	D3Dpp.BackBufferCount		= 1;
	D3Dpp.SwapEffect			= D3DSWAPEFFECT_FLIP ;
	D3Dpp.EnableAutoDepthStencil= FALSE;
	D3Dpp.hDeviceWindow			= hWindow;
	D3Dpp.BackBufferWidth		= Display.Width;
	D3Dpp.BackBufferHeight		= Display.Height;
	D3Dpp.BackBufferFormat		= D3DFormatScreen;

	if(FAILED(m_lpD3D->CreateDevice(D3DADAPTER_DEFAULT,D3DDEVTYPE_HAL,hWindow,D3DCREATE_HARDWARE_VERTEXPROCESSING,&D3Dpp,&Display.Pointer)))
	{
		if(FAILED(m_lpD3D->CreateDevice(D3DADAPTER_DEFAULT,D3DDEVTYPE_HAL,hWindow,D3DCREATE_SOFTWARE_VERTEXPROCESSING,&D3Dpp,&Display.Pointer)))
			return ErrorMsg(MSG_D3DDISPLAY);
	}

	if(FAILED(D3DXCreateSprite(Display.Pointer,&m_lpD3DSprite)))
		return ErrorMsg(MSG_D3DSPRITE);

	return true;
}

/************************************************************************/

void mmGraphics::Release(void)
{
	SAFE_RELEASE(m_lpD3DSprite);
	SAFE_RELEASE(Display.Pointer);
	SAFE_RELEASE(m_lpD3D);
}

/************************************************************************/

void mmGraphics::Clear(DWORD Color)
{
	Display.Pointer->Clear(0,NULL,D3DCLEAR_TARGET,(D3DCOLOR) Color,1.0f,0);
}

/************************************************************************/

void mmGraphics::Flip(void)
{
	EndScene();

	Display.Pointer->Present(NULL,NULL,NULL,NULL);
}

/************************************************************************/

bool mmGraphics::BeginScene(void)
{
	if(!m_bBegunScene)
	{
		if(FAILED(Display.Pointer->BeginScene())) return false;
		m_lpD3DSprite->Begin();
		m_bBegunScene = true;
	}

	return true;
}

/************************************************************************/

void mmGraphics::EndScene(void)
{
	if(m_bBegunScene)
	{
		m_lpD3DSprite->End();
		Display.Pointer->EndScene();		
		m_bBegunScene = false;
	}
}

/************************************************************************/

IMAGE *mmGraphics::LoadImage(string strFileName)
{
	IMAGE				*pImage		= NULL;
	D3DXIMAGE_INFO		ImageInfo	= {0};
	LPDIRECT3DTEXTURE8	lpTexture	= NULL;

	if(FAILED(D3DXCreateTextureFromFileEx(Display.Pointer,strFileName.c_str(),D3DX_DEFAULT,D3DX_DEFAULT,1,0,D3DFMT_UNKNOWN,D3DPOOL_MANAGED,D3DX_FILTER_NONE,D3DX_FILTER_NONE,0,&ImageInfo,NULL,&lpTexture)))
	{
		ErrorMsg(MSG_D3DLOAD);
		return NULL;
	}

	pImage = new IMAGE;
	pImage->Height	= ImageInfo.Height;
	pImage->Width	= ImageInfo.Width;
	pImage->Buffer	= lpTexture;

	return pImage;
}

/************************************************************************/

void mmGraphics::ReleaseImage(IMAGE *pImage)
{
	if(pImage != NULL)
	{
		SAFE_RELEASE(pImage->Buffer);
		SAFE_DELETE_ARRAY(pImage);
	}
}

/************************************************************************/

void mmGraphics::Blit(LONG x,LONG y,IMAGE *pImage)
{
	BeginScene();

	if(pImage) m_lpD3DSprite->Draw(pImage->Buffer,NULL,NULL,NULL,0.0f,&D3DXVECTOR2(x,y),0xFFFFFFFF);
}

/************************************************************************/

void mmGraphics::Blit(LONG x,LONG y,IMAGE *pImage,BYTE nAlpha)
{
	D3DCOLOR	dwColor = 0x00FFFFFF | (DWORD(nAlpha)<<24);

	BeginScene();

	if(pImage) m_lpD3DSprite->Draw(pImage->Buffer,NULL,NULL,NULL,0.0f,&D3DXVECTOR2(x,y),dwColor);
}

/************************************************************************/

void mmGraphics::Blit(LONG x,LONG y,IMAGE *pImage,BYTE nAlpha, float Scaling)
{
	D3DCOLOR	dwColor = 0x00FFFFFF | (DWORD(nAlpha)<<24);

	BeginScene();

	if(pImage) m_lpD3DSprite->Draw(pImage->Buffer,NULL,&D3DXVECTOR2(Scaling,Scaling),NULL,0.0f,&D3DXVECTOR2(x,y),dwColor);
}

/************************************************************************/

void mmGraphics::Blit(LONG x,LONG y,IMAGE *pImage,DWORD SrcX,DWORD SrcY,DWORD Width,DWORD Height,BYTE nAlpha)
{
	D3DCOLOR	dwColor = 0x00FFFFFF | (DWORD(nAlpha)<<24);
	RECT		SrcRect = {SrcX,SrcY,SrcX+Width,SrcY+Height};

	BeginScene();

	if(pImage) m_lpD3DSprite->Draw(pImage->Buffer,&SrcRect,NULL,NULL,0.0f,&D3DXVECTOR2(x,y),dwColor);
}

/************************************************************************/

void mmGraphics::BlitSprite(LONG x,LONG y,IMAGE *pImage,DWORD Index,DWORD Pixels)
{
	LONG		Width	= pImage->Width/Pixels;
	LONG		Xpos	= (Index % Width)*Pixels;
	LONG		Ypos	= Index?(Index / Width)*Pixels:0;

	RECT		SrcRect = {Xpos,Ypos,Xpos+Pixels,Ypos+Pixels};

	BeginScene();

	if(pImage) m_lpD3DSprite->Draw(pImage->Buffer,&SrcRect,NULL,NULL,0.0f,&D3DXVECTOR2(x,y),0xFFFFFFFF);
}

/************************************************************************/

void mmGraphics::BlitSprite(LONG x,LONG y,IMAGE *pImage,DWORD Index,DWORD Pixels,BYTE nAlpha)
{
	LONG		Width	= pImage->Width/Pixels;
	LONG		Xpos	= (Index % Width)*Pixels;
	LONG		Ypos	= Index?(Index / Width)*Pixels:0;

	D3DCOLOR	dwColor = 0x00FFFFFF | (DWORD(nAlpha)<<24);
	RECT		SrcRect = {Xpos,Ypos,Xpos+Pixels,Ypos+Pixels};

	BeginScene();

	if(pImage) m_lpD3DSprite->Draw(pImage->Buffer,&SrcRect,NULL,NULL,0.0f,&D3DXVECTOR2(x,y),dwColor);
}

/************************************************************************/

void mmGraphics::BlitSprite(LONG x,LONG y,IMAGE *pImage,DWORD Index,DWORD Pixels,BYTE nAlpha, WORD Rotation)
{
	D3DXVECTOR2	vCenter;

	LONG		Width	= pImage->Width/Pixels;
	LONG		Xpos	= (Index % Width)*Pixels;
	LONG		Ypos	= Index?(Index / Width)*Pixels:0;

	D3DCOLOR	dwColor = 0x00FFFFFF | (DWORD(nAlpha)<<24);
	RECT		SrcRect = {Xpos,Ypos,Xpos+Pixels,Ypos+Pixels};

	vCenter.x = float(Pixels/2);
	vCenter.y = float(Pixels/2);

	BeginScene();

	if(pImage) m_lpD3DSprite->Draw(pImage->Buffer,&SrcRect,NULL,&vCenter,D3DXToRadian(Rotation),&D3DXVECTOR2(x,y),dwColor);
}

/************************************************************************/