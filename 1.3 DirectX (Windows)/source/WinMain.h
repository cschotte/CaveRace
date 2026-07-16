#ifndef __WinMain_h__
#define __WinMain_h__

/************************************************************************/

#define APP_NAME	"CAVERACE"
#define APP_TITLE	"CaveRace Game"

#define MSG_TITLE	"Critical Information!"
#define MSG_THREAD	"Failed to create a thread!"

/************************************************************************/

#define WIN32_LEAN_AND_MEAN
#define _WIN32_DCOM

#include <windows.h>
#include <windowsx.h>
#include <objbase.h>
#include <string>

#include "Resource.h"
#include "MainLoop.h"
#include "mmGraphics.h"
#include "mmControls.h"
#include "mmAudio.h"

using namespace std;

/************************************************************************/

HWND					InitApplication(HINSTANCE hInstance);

LRESULT CALLBACK		MainWindowProc(HWND hWindow,UINT iMessage,WPARAM wParam,LPARAM lParam);

bool					StartMainLoop(HWND hWindow,HINSTANCE hInstance);
void					StopMainLoop(void);

DWORD WINAPI			MainThread(LPVOID lpParameter);

bool					ErrorMsg(string strMessage);

/************************************************************************/

#endif