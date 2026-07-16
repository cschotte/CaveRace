#include "mmControls.h"

/************************************************************************/

mmControls::mmControls(void)
{
	m_lpDirectInput	= NULL;

	m_lpDIDKeyboard	= NULL;
	m_lpDIDMouse	= NULL;
}

/************************************************************************/

bool mmControls::Init(HWND hWindow,HINSTANCE hInstance)
{
	// Direct Input
	if(FAILED(DirectInput8Create(hInstance,DIRECTINPUT_VERSION,IID_IDirectInput8,(void**)&m_lpDirectInput,NULL)))
		return ErrorMsg(MSG_DIFAILD);
	
	// KeyBoard
	if(FAILED(m_lpDirectInput->CreateDevice(GUID_SysKeyboard,&m_lpDIDKeyboard,NULL)))
		return ErrorMsg(MSG_DIKEYBOARD);

	if(FAILED(m_lpDIDKeyboard->SetDataFormat(&c_dfDIKeyboard)))
		return ErrorMsg(MSG_DIKEYDATA);

	if(FAILED(m_lpDIDKeyboard->SetCooperativeLevel(hWindow,DISCL_FOREGROUND | DISCL_EXCLUSIVE)))
		return ErrorMsg(MSG_DIKEYLEVEL);

	// Mouse
	if(FAILED(m_lpDirectInput->CreateDevice(GUID_SysMouse,&m_lpDIDMouse,NULL)))
		return ErrorMsg(MSG_DIMOUSE);

	if(FAILED(m_lpDIDMouse->SetDataFormat(&c_dfDIMouse2)))
		return ErrorMsg(MSG_DIMISDATA);

	if(FAILED(m_lpDIDMouse->SetCooperativeLevel(hWindow,DISCL_FOREGROUND | DISCL_EXCLUSIVE)))
		return ErrorMsg(MSG_DIMISLEVEL);

	return true;
}

/************************************************************************/

void mmControls::Update(void)
{
    if(m_lpDIDKeyboard != NULL)
		if(FAILED(m_lpDIDKeyboard->GetDeviceState(sizeof(KeyboardBuffer),&KeyboardBuffer))) Acquire(true);

    if(m_lpDIDMouse != NULL)
	{
		if(FAILED(m_lpDIDMouse->GetDeviceState(sizeof(m_MouseState),&m_MouseState))) Acquire(true);

		MouseBuffer.x += m_MouseState.lX;
		MouseBuffer.y += m_MouseState.lY;
		MouseBuffer.z += m_MouseState.lZ;
		MouseBuffer.Button[0] = m_MouseState.rgbButtons[0];
		MouseBuffer.Button[1] = m_MouseState.rgbButtons[1];
		MouseBuffer.Button[2] = m_MouseState.rgbButtons[2];
		MouseBuffer.Button[3] = m_MouseState.rgbButtons[3];
		MouseBuffer.Button[4] = m_MouseState.rgbButtons[4];
		MouseBuffer.Button[5] = m_MouseState.rgbButtons[5];
		MouseBuffer.Button[6] = m_MouseState.rgbButtons[6];
		MouseBuffer.Button[7] = m_MouseState.rgbButtons[7];
	}
}

/************************************************************************/

void mmControls::Release(void)
{
	SAFE_UNACQUIRE(m_lpDIDKeyboard);
	SAFE_RELEASE(m_lpDIDKeyboard);

	SAFE_UNACQUIRE(m_lpDIDMouse);
	SAFE_RELEASE(m_lpDIDMouse);

	SAFE_RELEASE(m_lpDirectInput);
}

/************************************************************************/

void mmControls::Acquire(bool bAppActive)
{
	if(m_lpDIDKeyboard != NULL)
	{
		if(bAppActive) m_lpDIDKeyboard->Acquire();
		else m_lpDIDKeyboard->Unacquire();
	}

	if(m_lpDIDMouse != NULL)
	{
		if(bAppActive) m_lpDIDMouse->Acquire();
		else m_lpDIDMouse->Unacquire();
	}
}

/************************************************************************/

bool mmControls::MouseIn(LONG x,LONG y,LONG Width,LONG Height)
{
	if(MouseBuffer.x>x && MouseBuffer.x<x+Width && MouseBuffer.y>y && MouseBuffer.y<y+Height) return true;

	return false;
}

/************************************************************************/