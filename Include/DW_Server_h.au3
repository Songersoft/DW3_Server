#include-once
#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:         Joshua Songer

	Script Function:
	A big Include header type file to help manage the main.au3 source

#ce ----------------------------------------------------------------------------
#include "DW_Server_Global.au3"

Func out($output = "", $user = 0);debug tool
	ConsoleWrite(@CRLF & $output);to console new line, value of $output
	If $user = 1 Then MsgBox(0, "Error", $output, 0, $ghGui)
EndFunc   ;==>out

Func label_control(ByRef $aControl, $iControl_id, $label_x, $label_y, $label_w, $label_h, $data_x, $data_y, $data_w, $data_h)
	; Create Label Control
	;If $sData_control_type <> 'button' Then
	$aControl[$iControl_id][$eControl_label] = GUICtrlCreateLabel($aControl[$iControl_id][$eControl_label], $label_x, $label_y, $label_w, $label_h)
	;GUICtrlSetBkColor(-1, 0xff0000)
	;EndIf
	; Create Data Control
	Switch $aControl[$iControl_id][$eControl_type]; Select Control Type
		Case 'input'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateInput($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h)
		Case 'input numonly'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateInput($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h, $es_number)
		Case 'input readonly'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateInput($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h)
			GUICtrlSendMsg($aControl[$iControl_id][$eControl_data], $EM_SETREADONLY, 1, 0); Send Readonly Message to the control
		Case 'input readonly center'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateInput($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h, $ES_CENTER)
			GUICtrlSendMsg($aControl[$iControl_id][$eControl_data], $EM_SETREADONLY, 1, 0); Send Readonly Message to the control
		Case 'input password'; Hide Passwords
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateInput($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h, $es_password)
		Case 'checkbox'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateCheckbox("", $data_x, $data_y, $data_w, $data_h)
			If $aControl[$iControl_id][$eControl_data_val] = $GUI_Checked Then GUICtrlSetState($aControl[$iControl_id][$eControl_data], $gui_checked)
		Case 'combo'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateCombo("", $data_x, $data_y, $data_w, $data_h, $CBS_DROPDOWNLIST)
			;_GUICtrlComboBox_SetCurSel($aControl[$iControl_id][1], $data_value)
		Case 'edit'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateEdit($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h, $WS_VSCROLL)
		Case 'edit readonly'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateEdit($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h, $WS_VSCROLL)
			GUICtrlSendMsg($aControl[$iControl_id][$eControl_data], $EM_SETREADONLY, 1, 0); Send Readonly Message to the control
		Case 'label'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateLabel($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h)
		Case 'label center'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateLabel($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h, $ES_CENTER)
		Case 'listview'
			;Example data_value: "col1        |col2       |col3 "
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateListView($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h, -1, $LVS_EX_CHECKBOXES)
		Case 'button'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateButton($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h)
		Case 'button multiline'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateButton($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h, $BS_MULTILINE)

		Case 'group'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateGroup($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h)
		Case 'hyperlink'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateLabel($aControl[$iControl_id][$eControl_data_val], $data_x, $data_y, $data_w, $data_h)
			GUICtrlSetColor($aControl[$iControl_id][$eControl_data], 0x0000ff)
	EndSwitch; sData_control_type
	GUICtrlSetTip($aControl[$iControl_id][$eControl_data], $aControl[$iControl_id][$eControl_tip])
EndFunc   ;==>label_control

Func _exit()
	out("_exit()")

	for $i= 0 to $gSocket_max-1

		UDPCloseSocket($gaSocket_send[$i][$eSocket])
		UDPCloseSocket($gaSocket_recv[$i][$eSocket])

	next

	;win sock
	DllClose($gDll_Ws2_32)

	If UDPShutdown() Then
		out("UDPShutdown()")
	else
		out("Error - UDPShutdown()")
	EndIf
EndFunc   ;==>_exit

Func file_remove_ext($sFile_path)

	; Find the last "." in sFile_path
	$str_po = StringInStr($sFile_path, ".", 0, -1) - 1

	; If no "." found use entire string
	If $str_po = 0 Then $str_po = StringLen($sFile_path)

	; Return the string section
	Return StringMid($sFile_path, 1, $str_po)

	;$aSplit = StringSplit($sFile_path, ".")
	;If $aSplit[0] > 1 Then $aSplit[0] = $aSplit[0] - 1
	;Return $aSplit[$aSplit[0]]
EndFunc   ;==>file_remove_ext

Func keyreleased($key, $key2 = "", $key3 = "", $key4 = "")
	While _IsPressed($key)
		Sleep(20)
	WEnd
	While _IsPressed($key2)
		Sleep(20)
	WEnd
	While _IsPressed($key3)
		Sleep(20)
	WEnd
	While _IsPressed($key4)
		Sleep(20)
	WEnd
EndFunc   ;==>keyreleased

Func error_out($string)
	If $gError_one = 0 Then
		MsgBox(0, "Error", $string, 2)
		$error_one = 1
	EndIf
EndFunc   ;==>error_out

Func control_create($type, $data_value, $data_x, $data_y, $data_width, $data_height, $data_tip = "", $label_text = Null, $label_x = 0, $label_y = -100, $label_w = 150, $label_h = 20, $label_tip = "")

	Local $idCtrl = Null

	Switch $type

		Case 'button'
			$idCtrl = GUICtrlCreateButton($data_value, $data_x, $data_y, $data_width, $data_height)

		Case 'edit'
			$idCtrl = GUICtrlCreateEdit($data_value, $data_x, $data_y, $data_width, $data_height, $ws_vscroll)

		Case 'edit readonly'
			$idCtrl = GUICtrlCreateEdit($data_value, $data_x, $data_y, $data_width, $data_height, $ws_vscroll)
			GUICtrlSendMsg($idCtrl, $EM_SETREADONLY, 1, 0); Send Readonly Message to the control

		Case 'label'
			$idCtrl = GUICtrlCreateLabel($data_value, $data_x, $data_y, $data_width, $data_height)

		Case 'combo'
			$idCtrl = GUICtrlCreateCombo($data_value, $data_x, $data_y, $data_width, $data_height, $CBS_DROPDOWNLIST)
			_GUICtrlComboBox_SetCurSel($idCtrl, $data_value)

		Case 'input'
			$idCtrl = GUICtrlCreateInput($data_value, $data_x, $data_y, $data_width, $data_height)

		Case 'input numonly'
			$idCtrl = GUICtrlCreateInput($data_value, $data_x, $data_y, $data_width, $data_height, $es_number)

		Case 'input readonly'
			$idCtrl = GUICtrlCreateInput($data_value, $data_x, $data_y, $data_width, $data_height)
			GUICtrlSendMsg($idCtrl, $EM_SETREADONLY, 1, 0)

		;Case 'comboex'
		;	$idCtrl = _GUICtrlComboBoxEx_Create($gui, $data_value, $data_x, $data_y, $data_w, $data_h, $CBS_DROPDOWNLIST);$CBN_SELCHANGE
		;	_GUICtrlComboBox_SetCurSel($aControl[$iControl_id][1], $data_value)

		;Case 'comboex tilelist'
		;	$idCtrl = _GUICtrlComboBoxEx_Create($gui, $data_value, $data_x, $data_y, $data_width, $data_height, $CBS_DROPDOWNLIST);$CBN_SELCHANGE

	EndSwitch

	; Data control Tip
	GUICtrlSetTip($idCtrl, $data_tip)

	If $label_text <> Null Then

		GUICtrlCreateLabel($label_text, $label_x, $label_y, $label_w, $label_h)

		; Label control Tip
		GUICtrlSetTip(-1, $label_tip)

	EndIf

	Return $idCtrl

EndFunc   ;==>control_create

Func win_po_save($hGui)
	out("save po")
	$gaGui_rect = WinGetPos($ghGui)
	If IsArray($gaGui_rect) Then
		$file = FileOpen(@ScriptDir & "\Settings\" & $gScriptname & "_Win_Po.txt", BitOR($FO_OVERWRITE, $FO_CREATEPATH))
		FileWriteLine($file, $gaGui_rect[0]); Window Position X
		FileWriteLine($file, $gaGui_rect[1]); Window Position Y
		FileClose($file)
	EndIf
EndFunc   ;==>win_po_save

Func win_po_load()
	Local $aWin_po = [0, 0]
	$file = FileOpen(@ScriptDir & "\Settings\" & $gScriptname & "_Win_Po.txt")
	$aWin_po[0] = Int(FileReadLine($file))
	$aWin_po[1] = Int(FileReadLine($file))
	FileClose($file)
	; Try to force window on visible screen
	If $aWin_po[0] < 0 Then $aWin_po[0] = 0
	If $aWin_po[1] < 0 Then $aWin_po[1] = 0
	If $aWin_po[0] > @DesktopWidth - 30 Then $aWin_po[0] = 0
	If $aWin_po[1] > @DesktopHeight - 30 Then $aWin_po[1] = 0
	Return $aWin_po
EndFunc   ;==>win_po_load

Func WM_NOTIFY($hWnd, $iMsg, $iwParam, $ilParam)
	#forceref $hWnd, $iMsg, $iwParam

	Local $tNMHDR = 0, $iIDFrom = 0, $iCode = 0

	$tNMHDR = DllStructCreate($tagNMHDR, $ilParam)

	$iIDFrom = DllStructGetData($tNMHDR, "IDFrom")
	$iCode = DllStructGetData($tNMHDR, "Code")

	Switch $iCode
		Case $NM_DBLCLK
			Switch $iIDFrom
				Case $gListview
					$gListview_double_click = True
					;Case $listview2
					;    $double_click2 = True
			EndSwitch
	EndSwitch

	Return $GUI_RUNDEFMSG
EndFunc   ;==>WM_NOTIFY

Func structure_define()

	Global $tagPlayer_struct = "ptr surf;" & _
			"int iScr_x;" & _		; The area of screen to draw the board                      1[  ]2[__]4[][]
			"int iScr_y;" & _		; this area is important if the game moves to split screen 1[  ]2[  ]4[][]
			"int iScr_w;" & _		; Single player Scr_w is equal to Gui_rect[2] window width
			"int iScr_h;" & _		; Single player Scr_h is equal to Gui_rect[3] height
			"int iBoard_world_x;" & _;	 Top Left of world[0][0] drawn to board
			"int iBoard_world_y;" & _
			"float fCamera_x;" & _	; Area of Board Viewed
			"float fCamera_y;" & _
			"int iMod_x;" & _		; Camera distance into Tile
			"int iMod_y;" & _
			"int iX;" & _			; World Position
			"int iY;" & _
			"int iArea_cur;" & _
			"int iWorld_cur;"

	Global $tagWorld_struct = "int iTile;" & _	; Tile Index of Graphic
			"int iX;" & _						; Graphic subset
			"int iY;" & _
			"int iWall_level;" ; Wall Strength

	Global $tagBG_struct = "float fFrame_timer;" & _
			"int iFrame_timer_max;" & _
			"int iWay;" & _
			"int iWay_max;" & _
			"int iWay_ticks;" & _
			"int iWay_tick_max;" & _
			"int iWay_invert;"

	Global $tagSun_struct = "ptr surf;" & _
			"float fAlpha;" & _
			"float fTimer;" & _
			"int iTimer_max;" & _
			"int iAlpha_index;" & _
			"int iTicks;" & _
			"bool bSun_up;" & _
			"float fAlpha_incroment;" & _
			"bool bSun_off;"

	Global $tagPerson_struct = "char name[10];" & _
			"int iWorld_x;" & _
			"int iWorld_y;" & _
			"int iPic_type;" & _
			"int iWay;" & _
			"int iFrame;" & _
			"float fFrame_change_speed;" & _
			"float fMovement_speed;" & _
			"int iDialog_type;" & _
			"char caDialog_text[1000];"

EndFunc   ;==>structure_define

Func read_chunk($file); Remove Label from File Line Label Data pair.

	Local $chunk = FileReadLine($file)
	If @error <> 0 Then
		Return "File EOF"
	EndIf
	Local $chunk_po = StringInStr($chunk, ": "); Find the string position of the first ": "
	Return StringMid($chunk, $chunk_po + 2); Return String 2 spaces right from the chunk_po

EndFunc   ;==>read_chunk



; Heard this could help me get around NAT issues
; IDK what it's about yet
;
; Send a udp packet to a specific address originating from an existing socket
; parameters : $udpsocket : socket (as returned by UDBbind)
; $data : binary to send
; $IP : destination IP
; $Port : destination Port
; $allowbroadcast : If True, allow sending broadcasts
;
; Returns : number of bytes sent, or check @Error if <0
Func _UDPSendto($udpsocket, $data, $ip, $port, $allowbroadcast = False)

	out("we get signal")
	If Not IsDeclared("gDll_Ws2_32") Then ; If not already declared, open Dll ws2_32.dll and set up auto close at program exit
		;Global $gDll_Ws2_32=DllOpen("ws2_32.dll")
		If $gDll_Ws2_32 = -1 Then
			MsgBox(0, "DllOpen()", "", 0)
			SetError(10101)
			Return -1
		EndIf
		OnAutoItExitRegister("_Close_ws2_32")
	EndIf

	If $allowbroadcast Then
		Local $char = DllStructCreate("char")
		DllStructSetData($char, 1, 1)
		DllCall($gDll_Ws2_32, "int", "setsockopt", "uint", $udpsocket[1], "int", 0xffff, "int", 0x0020, "ptr", DllStructGetPtr($char), "int", 1)
	EndIf

	; create and populate a sockaddr struct from $IP and $Port
	Local $stAddress = DllStructCreate("short; ushort; uint; char[8]")
	DllStructSetData($stAddress, 1, 2)
	Local $iRet = DllCall($gDll_Ws2_32, "ushort", "htons", "ushort", $port)
	If Not IsArray($iRet) Then
		MsgBox(0, "sendto()", "1", 0)
		Return -1
	EndIf
	DllStructSetData($stAddress, 2, $iRet[0])
	If Not IsArray($iRet) Then
		MsgBox(0, "sendto", "2", 0)
		Return -1
	EndIf
	$iRet = DllCall($gDll_Ws2_32, "uint", "inet_addr", "str", $ip)
	DllStructSetData($stAddress, 3, $iRet[0])

	; Create buffer with data
	Local $hBuf = DllStructCreate("byte[" & BinaryLen($data) & "]")
	DllStructSetData($hBuf, 1, $data)

	; Send packet
	$iRet = DllCall($gDll_Ws2_32, "int", "sendto", "uint", $udpsocket[1], "ptr", DllStructGetPtr($hBuf), "int", DllStructGetSize($hBuf), "int", 0, "ptr", DllStructGetPtr($stAddress), "int", DllStructGetSize($stAddress))

	If Not IsArray($iRet) Then
		MsgBox(0, "sendto", "3", 0)
		Return -1
	EndIf
	; check for error
	If $iRet[0] < 0 Then ; Set @error with last error from WSAGetLastError
		MsgBox(0, "2", "2", 0)
		Local $errno = DllCall($gDll_Ws2_32, "int", "WSAGetLastError")
		SetError($errno[0])
	EndIf

	Return $iRet[0]
EndFunc   ;==>_UDPSendto

; A test server to go with _UDPSendto()
Func test_server()

	; Listen Socket
	Local $socket = UDPBind(@IPAddress1, 18000)
	If @error <> 0 Then
		$error = @error
		MsgBox(0, $error, "", 0)
		Exit
	EndIf

	While 1
		Local $data = UDPRecv($socket, 1024, 2)
		If IsArray($data) Then
			out($data[1] & " " & $data[2])
			_UDPSendto($socket, $data[0], $data[1], $data[2]) ; answer the same packet to the client...
		EndIf
		Sleep(100)
	WEnd

EndFunc   ;==>test_server

; and close the DLL it uses
Func _Close_ws2_32()
	DllClose($gDll_Ws2_32)
EndFunc   ;==>_Close_ws2_32

Func getfolder($path)

	$pathreturn = StringMid($path, 1, StringInStr($path, "\", 0, -1))
	Return $pathreturn

EndFunc   ;==>getfolder

Func world_area_save($aWorld, $aTile, $aArea, $aHotspot, $iWorld_info_ID, $filepath = "")

	Local $aField_labels = ["eArea_iX: ", "eArea_iY: ", "eArea_iW: ", "eArea_iH: ", _
			"eArea_iOb_tile: ", "eArea_sOb_world: ", "eArea_iOb_x: ", "eArea_iOb_y: ", _
			"eArea_hotspots: ", "eArea_items: ", "eArea_people: "]
	;If $filepath = "" Then;																On NULL Filepath Launch GUI File Browser Dialog
	;	If $folder_world_last_path = "" Then
	;		$filepath = FileSaveDialog("Save World File Info", $folder_graphics, "World Info txt (*.txt)", Default, "", $ghGui)
	;	Else
	;		$filepath = FileSaveDialog("Save World File Info", $folder_world_last_path, "World Info txt (*.txt)", Default, "", $ghGui)
	;	EndIf
	;EndIf
	Local $file = FileOpen($filepath, $fo_overwrite);											Okay Open the Area File For Writing and Overwrite that Bitch
	; Write World Header
	FileWriteLine($file, "Layers: " & $world_info[$iWorld_info_ID][$eWi_layers]); 1 								How many Layers
	FileWriteLine($file, "Width: " & $world_info[$iWorld_info_ID][$eWi_w]); 2								Width (how many Tiles Wide)
	FileWriteLine($file, "Height: " & $world_info[$iWorld_info_ID][$eWi_h]); 3							Height ( ^ ) ( ^ )
	FileWriteLine($file, "Tiles: " & $world_info[$iWorld_info_ID][$eWi_tiles]); 4									Maximume Tile Index Stored in World

	; Write Area Data
	For $i = 1 To $aArea[$iWorld_info_ID][0][0]
		FileWriteLine($file, "Area: " & $i); 5											Area Label Labels the Areas Index
		For $ii = 0 To $area_data_max - 1
			FileWriteLine($file, $aField_labels[$ii] & $aArea[$iWorld_info_ID][$i][$ii])
		Next
	Next
	FileClose($file); Close Area File

	Local $folder_path = getfolder($filepath)

	$file = FileOpen($folder_path & "\World_Hotspots.txt", $fo_overwrite)
	; Write Hotspot Data Per Area

	For $i = 1 To $aArea[$iWorld_info_ID][0][0]
		For $ii = 0 To $aArea[$iWorld_info_ID][$iWorld_info_ID][$eArea_hotspots] - 1
			For $iii = 0 To $hotspot_data_max - 1
				FileWriteLine($file, $aHotspot[$iWorld_info_ID][$i][$ii][$iii])
			Next
		Next
	Next

	FileClose($file); Close Hotspot File

EndFunc   ;==>world_area_save

Func world_area_load(ByRef $aWorld, $aTile, ByRef $aArea, $iWorld_info_ID, $world_folder_path = "")

	Local $timer = TimerInit(); Start Timer by Recording the Time
	Local $aField_labels = ["iX: ", "iY: ", "iW: ", "iH: ", "iTile: "]
	;If $world_folder_path = "" Then; If No File Path is Directed then Launch Dialog File Browser
	;	$world_folder_path = FileSelectFolder("Select World Folder", $folder_graphics) & "\"
	;	out("world_folder_path: " & $world_folder_path)
	;	If @error <> 0 Then Return 1; If error<> 0 then return 1
	;EndIf

	Local $world_area_file_path = $world_folder_path & "\World_Area.txt";					Open World_Area File
	Local $file = FileOpen($world_area_file_path); Open the World_Area.txt File
	If $file = -1 Then
		MsgBox(0, "world_area_load()", $world_area_file_path & " World_Area.txt NOT Found", Default, $ghGui)
		Return
	EndIf
	; Read Header
	$world_info[$iWorld_info_ID][$eWi_layers] = Int(read_chunk($file)); 1 WORLD LAYERS
	$world_info[$iWorld_info_ID][$eWi_w] = Int(read_chunk($file)); 2 WORLD WIDTH
	$world_info[$iWorld_info_ID][$eWi_h] = Int(read_chunk($file)); 3 WORLD HEIGHT
	$world_info[$iWorld_info_ID][$eWi_tiles] = Int(read_chunk($file)); 4 MAX TILE

	; Read List of Areas
	$aArea[$iWorld_info_ID][0][0] = 0; Area Total

	Local $area_label
	Do
		$area_label = read_chunk($file); Area Label String in File line 5
		If $area_label = "File EOF" Then ExitLoop

		$aArea[$iWorld_info_ID][0][0] += 1
		For $i = 0 To $area_data_max - 1; x, y, w, h, +..
			$aArea[$iWorld_info_ID][$aArea[$iWorld_info_ID][0][0]][$i] = read_chunk($file)
			If $area_label = "File EOF" Then
				MsgBox(0, "Error", "Corrupt Area: " & $aArea[$iWorld_info_ID][0][0] & " segment: " & $aField_labels[$i] & " or " & $i, Default, $ghGui)
			EndIf
		Next
		$aArea[$iWorld_info_ID][$aArea[$iWorld_info_ID][0][0]][$eArea_hotspots] = Int($aArea[$iWorld_info_ID][$aArea[$iWorld_info_ID][0][0]][$eArea_hotspots]); Hotspots to Integer
	Until @error <> 0
	FileClose($file)

	$world_folder_path = getfolder($world_folder_path)
	$world_info[$iWorld_info_ID][$eWi_filename] = StringMid($world_folder_path, StringInStr($world_folder_path, "\", Default, -3) + 1)
	out("World_Filename: " & $world_info[$iWorld_info_ID][$eWi_filename])

	; Create World Struct
	Local $file2; File_2 is the World Tile X Y data
	; World Tile X Y Data Reflects where to draw from within a tile greater then Tile_w, h
	; It is just a subset of Tile stored in World IE: The Overworld Forests have differant pictures of sized trees
	; I store it in it's own special file b/c I want to keep the base map file managable by hand
	Local $world_dest_w
	Local $world_dest_h
	Local $world_dest_tiles
	Local $cells
	Local $file_data
	For $z = 0 To $world_info[$iWorld_info_ID][$eWi_layers] - 1
		$file2 = FileOpen($world_folder_path & $z & " Tile_X_Y.txt")
		out("World_Tile_X_Y: " & $world_folder_path & $z & " Tile_X_Y.txt")
		; Open the World File
		$file = FileOpen($world_folder_path & "\" & $z & ".txt")
		If $file < 0 Then; Error check Loading File
			MsgBox(0, "Error", "World File Not Opened: " & $world_folder_path & $z & ".txt", Default, $ghGui)
			Return 1;				Exit If Error Opening File
		EndIf
		; Read Header
		$world_dest_w = Int(FileReadLine($file)); World Width
		$world_dest_h = Int(FileReadLine($file)); World Height
		$world_dest_tiles = Int(FileReadLine($file)); World Max Tile
		$cells = StringLen($world_dest_tiles) + 1; Formats File Rows and Coloms
		; Read the World Tile ID Data
		For $y = 0 To $world_dest_h - 1
			For $x = 0 To $world_dest_w - 1
				$aWorld[$iWorld_info_ID][$z][$x][$y] = DllStructCreate($tagWorld_struct); Create Struct

				$file_data = Int(FileRead($file, $cells))
				$aWorld[$iWorld_info_ID][$z][$x][$y].iTile = $file_data
				$aWorld[$iWorld_info_ID][$z][$x][$y].iX = FileReadLine($file2)
				$aWorld[$iWorld_info_ID][$z][$x][$y].iY = FileReadLine($file2)
			Next;x
			FileRead($file, 2); Read the Carrage Return at End of File Line
		Next;y
		FileClose($file2)
		FileClose($file)
	Next;z
	$folder_world_last_path = $world_folder_path
	;tile_load_folder($aTile, $iWorld_info_ID, $folder_world_last_path & "Tiles\", $world_dest_tiles);			Tile Array
	out("Load_world_area: aTile:" & $world_info[$iWorld_info_ID][$eWi_tiles])
	out("world_area_load() Completed in: " & TimerDiff($timer))

	Return $aWorld; Return dynamic World Size of File Header

EndFunc   ;==>world_area_load

Func world_array_redim($world_max)

	ReDim $aWorld[$world_max][$world_max_layer][$world_max_x][$world_max_y]
	ReDim $world_info[$world_max][$world_info_data_max]
	ReDim $aArea[$world_max][$area_max][$area_data_max]
	ReDim $aHotspot[$world_max][$area_max][$hotspot_max][$hotspot_data_max]

EndFunc   ;==>world_array_redim
