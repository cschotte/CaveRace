/***************************************************************************
 *                                                                         *
 *        Name : Network.h                                                 *
 *                                                                         *
 *     Version : 1.0 (13-06-97)                                            *
 *                                                                         *
 *     Made on : 17-03-97                                                  *
 *                                                                         *
 *     Made by : Clemens Schotte                                           *
 *               Harro Lock                                                *
 *               Paul Bosselaar                                            *
 *               Paul van Croonenburg                                      *
 *                                                                         *
 * Description : Functions for IPX network                                 *
 *                                                                         *
 *        Note : This program will only work with IPX 2.0 +                *
 *                                                                         *
 ***************************************************************************/

#define _NETWORK

#ifndef _MAIN
#include "include\main.h"
#endif

/***************************************************************************/

typedef struct
{
  BYTE Network[4];
  BYTE Node[6];
  WORD Socket;
} IPXADDRESS;

typedef struct
{
  WORD CheckSum;
  WORD Length;
  BYTE TransportControl;
  BYTE PacketType;
  IPXADDRESS Destination;
  IPXADDRESS Source;
} IPXHEADER;

typedef struct
{
  void far *Address;
  WORD Size;
} ECBFRAGMENT;

typedef struct
{
  void far *LinkAddress;
  void (far *ESRAddress)();
  BYTE InUseFlag;
  BYTE CompletionCode;
  WORD SocketNumber;
  BYTE IPXWorkspace[4];
  BYTE DriverWorkspace[12];
  BYTE ImmediateAddress[6];
  WORD FragmentCount;
  ECBFRAGMENT FragmentDescriptor[4];
} IPXECB;

/***************************************************************************/

GetIPXInformation()
IPXCancelEvent()
IPXCloseSocket()
IPXDisconnectFromTarget()
IPXGenerateChecksum()
IPXGetInternetworkAddress()
IPXGetIntervalMarker()
IPXGetLocalTarget()
IPXGetMaxPacketSize()
IPXListenForPacket()
IPXOpenLookAheadSocket()
IPXOpenSocket()
IPXRelinquishControl()
IPXScheduleAESEvent()
IPXScheduleIPXEvent()
IPXSendPacket()
IPXSendWithChecksum()
IPXVerifyChecksum
ReceiveLookAheadHandler()

/***************************************************************************/
