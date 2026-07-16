#include "mmAudio.h"

/************************************************************************/

mmAudio::mmAudio(void)
{
	m_lpDALoader		= NULL;
	m_lpDAPerformance	= NULL;
}

/************************************************************************/

bool mmAudio::Init(HWND			hWindow,
				   HINSTANCE	hInstance)
{
	if(CoCreateInstance(CLSID_DirectMusicLoader, NULL, CLSCTX_INPROC, IID_IDirectMusicLoader8, (void**)&m_lpDALoader) != S_OK)
		return ErrorMsg(MSG_DMLOADER);

	if(CoCreateInstance(CLSID_DirectMusicPerformance, NULL, CLSCTX_INPROC, IID_IDirectMusicPerformance8, (void**)&m_lpDAPerformance) != S_OK)
		return ErrorMsg(MSG_DMPERFORM);

	if(FAILED(m_lpDAPerformance->InitAudio(NULL, NULL, hWindow, DMUS_APATH_SHARED_STEREOPLUSREVERB, 64, DMUS_AUDIOF_ALL, NULL)))
		return ErrorMsg(MSG_DMINIT);

	return true;
}

/************************************************************************/

void mmAudio::Release(void)
{
	if(m_lpDAPerformance)
	{
		m_lpDAPerformance->Stop(NULL,NULL,0,0);
		m_lpDAPerformance->CloseDown();
	}

	SAFE_RELEASE(m_lpDALoader);
	SAFE_RELEASE(m_lpDAPerformance);
}

/************************************************************************/

AUDIO *mmAudio::LoadAudio(WCHAR *FileName)
{
	IDirectMusicSegment8*	lpBuffer= NULL;
	AUDIO					*pAudio	= NULL;

	if(FAILED(m_lpDALoader->LoadObjectFromFile(CLSID_DirectMusicSegment,IID_IDirectMusicSegment8,FileName,(LPVOID*) &lpBuffer)))
	{
		ErrorMsg(MSG_DMLOAD);
		return NULL;
	}

	pAudio = new AUDIO;
	pAudio->Buffer = lpBuffer;

	lpBuffer->Download(m_lpDAPerformance);

	return pAudio;
}

/************************************************************************/

void mmAudio::ReleaseAudio(AUDIO *pAudio)
{
	if(pAudio != NULL)
	{
		SAFE_RELEASE(pAudio->Buffer);
		SAFE_DELETE_ARRAY(pAudio);
	}
}

/************************************************************************/

void mmAudio::Play(AUDIO *pAudio)
{
	if(pAudio) m_lpDAPerformance->PlaySegmentEx(pAudio->Buffer,NULL,NULL,0,0,NULL,NULL,NULL);
}

/************************************************************************/

void mmAudio::Stop(AUDIO *pAudio)
{
	if(pAudio) m_lpDAPerformance->Stop(pAudio->Buffer,NULL,0,0);
}

/************************************************************************/

void mmAudio::StopAll(void)
{
	m_lpDAPerformance->Stop(NULL,NULL,0,0);
}

/************************************************************************/