$aRemoteShellGUI[$iRemoteShellGUIIndex][0] = $iSocket
$aRemoteShellGUI[$iRemoteShellGUIIndex][1] = $sPCName
$aRemoteShellGUI[$iRemoteShellGUIIndex][2] = GUICreate("RemoteShell on " & $sPCName,820,440,-1,-1,-1,-1)
$aRemoteShellGUI[$iRemoteShellGUIIndex][3] = GUICtrlCreateEdit("Loading..." & @CRLF,0,0,820,410,BitOr($ES_AUTOVSCROLL,$ES_READONLY,$WS_VSCROLL),-1)
GUICtrlSetColor(-1,"0x00FF00")
GUICtrlSetBkColor(-1,"0x000000")
$aRemoteShellGUI[$iRemoteShellGUIIndex][4] = GUICtrlCreateButton("send",785,410)
GUICtrlSetColor(-1,"0x00FF00")
GUICtrlSetBkColor(-1,"0x000000")
GUICtrlSetOnEvent($aRemoteShellGUI[$iRemoteShellGUIIndex][4], "RemoteShellSend")
$aRemoteShellGUI[$iRemoteShellGUIIndex][5] = GUICtrlCreateInput("",0,410,783,30,-1,$WS_EX_CLIENTEDGE)
GUICtrlSetColor(-1,"0x00FF00")
GUICtrlSetBkColor(-1,"0x000000")
$aRemoteShellGUI[$iRemoteShellGUIIndex][6] = GUICtrlCreateButton("CTRL+C",785,410)
GUICtrlSetOnEvent($aRemoteShellGUI[$iRemoteShellGUIIndex][6], "RemoteShellCtrlC")
GUICtrlSetState($aRemoteShellGUI[$iRemoteShellGUIIndex][6], $GUI_HIDE)
$aRemoteShellGUI[$iRemoteShellGUIIndex][7] = GUICtrlCreateButton("UP",785,410)
GUICtrlSetOnEvent($aRemoteShellGUI[$iRemoteShellGUIIndex][7], "RemoteShellUp")
GUICtrlSetState($aRemoteShellGUI[$iRemoteShellGUIIndex][7], $GUI_HIDE)
$aRemoteShellGUI[$iRemoteShellGUIIndex][8] = GUICtrlCreateButton("DOWN",785,410)
GUICtrlSetOnEvent($aRemoteShellGUI[$iRemoteShellGUIIndex][8], "RemoteShellDown")
GUICtrlSetState($aRemoteShellGUI[$iRemoteShellGUIIndex][8], $GUI_HIDE)

$aRemoteShellGUI[$iRemoteShellGUIIndex][38] = 0 ; 0 till 10
$aRemoteShellGUI[$iRemoteShellGUIIndex][39] = 40 ;39 till 49

Local $aAccels[4][2] = [["{ENTER}", $aRemoteShellGUI[$iRemoteShellGUIIndex][4]],["^c", $aRemoteShellGUI[$iRemoteShellGUIIndex][6]], ["{UP}", $aRemoteShellGUI[$iRemoteShellGUIIndex][7]], ["{DOWN}", $aRemoteShellGUI[$iRemoteShellGUIIndex][8]]]
GUISetAccelerators($aAccels, $aRemoteShellGUI[$iRemoteShellGUIIndex][2])
ControlFocus($aRemoteShellGUI[$iRemoteShellGUIIndex][2], "", $aRemoteShellGUI[$iRemoteShellGUIIndex][5])

GUISetState()

GUISetOnEvent($GUI_EVENT_CLOSE, "CLOSEClickedRemoteShell")


;$aRemoteShellGUI[$iRemoteShellGUIIndex][38] count of last commands
;$aRemoteShellGUI[$iRemoteShellGUIIndex][39] index of last commands
;$aRemoteShellGUI[$iRemoteShellGUIIndex][40] till $aRemoteShellGUI[$iRemoteShellGUIIndex][49] saving last 10 commands to select with up arrow key
