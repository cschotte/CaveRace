#include "WinMain.h"

/************************************************************************/

DWORD			g_dwMainThreadId	= NULL;
HANDLE			g_hMainThread		= NULL;

volatile bool	g_bIsAppActive		= false;
volatile bool	g_bDoAbort			= false;

string			g_strError			= "";

mmGraphics		Graphics;
mmControls		Controls;
mmAudio			Audio;

/************************************************************************/

int APIENTRY WinMain(HINSTANCE	hThisInstance,
					 HINSTANCE	hPrevInstance,
					 LPSTR		lpCmdLine,
					 int		nCmdShow)
{
	MSG		Message	= {0};
	HWND	hWindow	= NULL;

	if((hWindow = InitApplication(hThisInstance)) == NULL) return FALSE;

	if(!StartMainLoop(hWindow, hThisInstance)) PostMessage(hWindow,WM_CLOSE,0,0);

	while(GetMessage(&Message, NULL, 0, 0) != NULL)
	{
		TranslateMessage(&Message);
		DispatchMessage(&Message);
	}

	UnregisterClass(APP_NAME,hThisInstance);

	if(!g_strError.empty()) MessageBox(NULL,g_strError.c_str(),MSG_TITLE,MB_OK | MB_ICONERROR);

	return Message.wParam;
}

/************************************************************************/

HWND InitApplication(HINSTANCE hInstance)
{
	HWND		hWindow		= NULL;
	WNDCLASSEX	WindowClass = {0};

	WindowClass.cbSize			= sizeof(WNDCLASSEX); 
	WindowClass.style			= CS_HREDRAW | CS_VREDRAW;
	WindowClass.lpfnWndProc		= (WNDPROC)MainWindowProc;
	WindowClass.hInstance		= hInstance;
	WindowClass.hIcon			= LoadIcon(hInstance, MAKEINTRESOURCE(IDI_MAIN));
	WindowClass.hCursor			= LoadCursor(NULL, IDC_ARROW);
	WindowClass.hbrBackground	= (HBRUSH)GetStockObject(BLACK_BRUSH);
	WindowClass.lpszClassName	= APP_NAME;
	WindowClass.hIconSm			= LoadIcon(hInstance, MAKEINTRESOURCE(IDI_MAIN));

	if(!RegisterClassEx(&WindowClass)) return NULL;

	hWindow = CreateWindowEx(WS_EX_TOPMOST,
							 APP_NAME,
							 APP_TITLE,
							 WS_POPUP,
							 0, 0,
							 GetSystemMetrics(SM_CXSCREEN), GetSystemMetrics(SM_CYSCREEN),
							 NULL,
							 NULL,
							 hInstance,
							 NULL);

	if(!hWindow) return NULL;

	ShowWindow(hWindow, SW_SHOWNORMAL);
	UpdateWindow(hWindow);
	SetFocus(hWindow);

	return hWindow;
}

/************************************************************************/

LRESULT CALLBACK MainWindowProc(HWND	hWindow,
								UINT	iMessage,
								WPARAM	wParam,
								LPARAM	lParam)
{
	switch(iMessage)
	{
		case WM_ACTIVATE:
			if(LOWORD(wParam) == WA_INACTIVE) g_bIsAppActive = false;
			else g_bIsAppActive = true;
			Controls.Acquire(g_bIsAppActive);
			return 0;

		case WM_SETCURSOR:
			SetCursor(NULL);
			return TRUE;

		case WM_CLOSE:
			StopMainLoop();			
			DestroyWindow(hWindow);
			return 0;

		case WM_DESTROY:			
			PostQuitMessage(0);			
			return 0;
	}

	return DefWindowProc(hWindow,iMessage,wParam,lParam);
}

/************************************************************************/

bool StartMainLoop(HWND			hWindow,
				   HINSTANCE	hInstance)
{
	CoInitializeEx(NULL,COINIT_MULTITHREADED | COINIT_SPEED_OVER_MEMORY);

	if(!Controls.Init(hWindow,hInstance))	return false;
	if(!Audio.Init(hWindow,hInstance))		return false;
	if(!Graphics.Init(hWindow,hInstance))	return false;

	if((g_hMainThread = CreateThread(NULL,0,MainThread,(LPVOID) hWindow,0,&g_dwMainThreadId)) == NULL)
		return ErrorMsg(MSG_THREAD);

	return true;
}

/************************************************************************/

void StopMainLoop(void)
{
	g_bDoAbort = true;

	if(g_hMainThread != NULL)
	{
		if(WaitForSingleObject(g_hMainThread,3000) == WAIT_TIMEOUT) TerminateThread(g_hMainThread,1);
		CloseHandle(g_hMainThread);
		g_hMainThread = NULL;
	}

	ReleaseBuffers();

	Graphics.Release();
	Audio.Release();
	Controls.Release();

	CoUninitialize();
}

/************************************************************************/

DWORD WINAPI MainThread(LPVOID lpParameter)
{
	CoInitializeEx(NULL,COINIT_MULTITHREADED | COINIT_SPEED_OVER_MEMORY);

	if(InitBuffers()) MainLoop();

	PostMessage((HWND) lpParameter,WM_CLOSE,0,0);

	CoUninitialize();

	return 0;
}

/************************************************************************/

bool ErrorMsg(string strMessage)
{
	g_strError = strMessage;

	return false;
}

/************************************************************************/