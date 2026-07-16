#ifndef __mmAudio_h__
#define __mmAudio_h__

/************************************************************************/

//#include <basetsd.h>
#include <dmusici.h>

#include "WinMain.h"
#include "mmFunctions.h"

/************************************************************************/

#define MSG_DMLOADER	"Can't Create Instance for DirectMusicLoader!"
#define MSG_DMPERFORM	"Can't Create Instance for DirectMusicPerformance!"
#define MSG_DMINIT		"Can't Init Audio!"
#define MSG_DMLOAD		"Can't Load Audio Files!\n(Re)install CaveRace."

/************************************************************************/

struct AUDIO
{
	IDirectMusicSegment8*	Buffer;
};

/************************************************************************/

class mmAudio
{
private:
	IDirectMusicLoader8*		m_lpDALoader;
	IDirectMusicPerformance8*	m_lpDAPerformance;

public:
			mmAudio(void);

	bool	Init(HWND hWindow, HINSTANCE hInstance);
	void	Release(void);

	AUDIO	*LoadAudio(WCHAR *FileName);
	void	ReleaseAudio(AUDIO *pAudio);

	void	Play(AUDIO *pAudio);
	void	Stop(AUDIO *pAudio);
	void	StopAll(void);
};

/************************************************************************/

#endif