#ifndef __mmControls_h__
#define __mmControls_h__

/************************************************************************/

#define DIRECTINPUT_VERSION 0x0800

#include <basetsd.h>
#include <dinput.h>

#include "WinMain.h"
#include "mmFunctions.h"

/************************************************************************/

#define MSG_DIFAILD		"Faild to use DirectX Input!\nInstall Miscosoft DirectX 8.1 or later."
#define MSG_DIKEYBOARD	"Can't Create Keyboard Device!"
#define MSG_DIKEYDATA	"Can't Set Keyboard Data Format!"
#define MSG_DIKEYLEVEL	"Can't Set Keyboard Cooperative Level!"
#define MSG_DIMOUSE		"Can't Create Mouse Device!"
#define MSG_DIMISDATA	"Can't Set Mouse Data Format!"
#define MSG_DIMISLEVEL	"Can't Set Mouse Cooperative Level!"

/************************************************************************/

#define KEY_ESC             0x01
#define KEY_1               0x02
#define KEY_2               0x03
#define KEY_3               0x04
#define KEY_4               0x05
#define KEY_5               0x06
#define KEY_6               0x07
#define KEY_7               0x08
#define KEY_8               0x09
#define KEY_9               0x0A
#define KEY_0               0x0B
#define KEY_MINUS           0x0C    /* - on main keyboard */
#define KEY_EQUALS          0x0D
#define KEY_BACK            0x0E    /* backspace */
#define KEY_TAB             0x0F
#define KEY_Q               0x10
#define KEY_W               0x11
#define KEY_E               0x12
#define KEY_R               0x13
#define KEY_T               0x14
#define KEY_Y               0x15
#define KEY_U               0x16
#define KEY_I               0x17
#define KEY_O               0x18
#define KEY_P               0x19
#define KEY_LBRACKET        0x1A
#define KEY_RBRACKET        0x1B
#define KEY_RETURN          0x1C    /* Enter on main keyboard */
#define KEY_LCONTROL        0x1D
#define KEY_A               0x1E
#define KEY_S               0x1F
#define KEY_D               0x20
#define KEY_F               0x21
#define KEY_G               0x22
#define KEY_H               0x23
#define KEY_J               0x24
#define KEY_K               0x25
#define KEY_L               0x26
#define KEY_SEMICOLON       0x27
#define KEY_APOSTROPHE      0x28
#define KEY_GRAVE           0x29    /* accent grave */
#define KEY_LSHIFT          0x2A
#define KEY_BACKSLASH       0x2B
#define KEY_Z               0x2C
#define KEY_X               0x2D
#define KEY_C               0x2E
#define KEY_V               0x2F
#define KEY_B               0x30
#define KEY_N               0x31
#define KEY_M               0x32
#define KEY_COMMA           0x33
#define KEY_PERIOD          0x34    /* . on main keyboard */
#define KEY_SLASH           0x35    /* / on main keyboard */
#define KEY_RSHIFT          0x36
#define KEY_MULTIPLY        0x37    /* * on numeric keypad */
#define KEY_LALT            0x38    /* left Alt */
#define KEY_SPACE           0x39
#define KEY_CAPSLOCK        0x3A
#define KEY_F1              0x3B
#define KEY_F2              0x3C
#define KEY_F3              0x3D
#define KEY_F4              0x3E
#define KEY_F5              0x3F
#define KEY_F6              0x40
#define KEY_F7              0x41
#define KEY_F8              0x42
#define KEY_F9              0x43
#define KEY_F10             0x44
#define KEY_NUMLOCK         0x45
#define KEY_SCROLLLOCK      0x46    /* Scroll Lock */
#define KEY_NUMPAD7         0x47
#define KEY_NUMPAD8         0x48
#define KEY_NUMPAD9         0x49
#define KEY_NUMPADMINUS     0x4A    /* - on numeric keypad */
#define KEY_NUMPAD4         0x4B
#define KEY_NUMPAD5         0x4C
#define KEY_NUMPAD6         0x4D
#define KEY_NUMPADPLUS      0x4E    /* + on numeric keypad */
#define KEY_NUMPAD1         0x4F
#define KEY_NUMPAD2         0x50
#define KEY_NUMPAD3         0x51
#define KEY_NUMPAD0         0x52
#define KEY_NUMPADPERIOD    0x53    /* . on numeric keypad */
#define KEY_F11             0x57
#define KEY_F12             0x58
#define KEY_NUMPADENTER     0x9C    /* Enter on numeric keypad */
#define KEY_RCONTROL        0x9D
#define KEY_NUMPADDIVID     0xB5    /* / on numeric keypad */
#define KEY_RALT            0xB8    /* right Alt */
#define KEY_PAUSE           0xC5    /* Pause */
#define KEY_HOME            0xC7    /* Home on arrow keypad */
#define KEY_UP              0xC8    /* UpArrow on arrow keypad */
#define KEY_GAGEUP          0xC9    /* PgUp on arrow keypad */
#define KEY_LEFT            0xCB    /* LeftArrow on arrow keypad */
#define KEY_RIGHT           0xCD    /* RightArrow on arrow keypad */
#define KEY_END             0xCF    /* End on arrow keypad */
#define KEY_DOWN            0xD0    /* DownArrow on arrow keypad */
#define KEY_PAGEDOWN        0xD1    /* PgDn on arrow keypad */
#define KEY_INSERT          0xD2    /* Insert on arrow keypad */
#define KEY_DELETE          0xD3    /* Delete on arrow keypad */
#define KEY_LWIN            0xDB    /* Left Windows key */
#define KEY_RWIN            0xDC    /* Right Windows key */
#define KEY_APPS            0xDD    /* AppMenu key */

/************************************************************************/

struct MOUSE
{
	LONG	x;
	LONG	y;
	LONG	z;
	BYTE	Button[8];
};

/************************************************************************/

class mmControls
{
private:
	LPDIRECTINPUT8  		m_lpDirectInput;

	LPDIRECTINPUTDEVICE8	m_lpDIDKeyboard;
	LPDIRECTINPUTDEVICE8	m_lpDIDMouse;
	DIMOUSESTATE2			m_MouseState;

public:
	BYTE					KeyboardBuffer[256];
	MOUSE					MouseBuffer;

public:
							mmControls(void);

	bool					Init(HWND,HINSTANCE);
	void					Release(void);

	void					Acquire(bool bAppActive);
	void					Update(void);

	bool					MouseIn(LONG x,LONG y,LONG Width,LONG Height);
};

/************************************************************************/

#endif