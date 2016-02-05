#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Settings\DW_Server.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****
; when client joins download how many ppl are in the world.
; Send all the people to new client

; Menus
Global $gGui_menu_max= 2

Enum $eGui_menu_file, $eGui_menu_settings

Global $gClient_join_lastIP = ""
Global $gClient_join_lastIP_timer = 0

; Packet Types:
Enum 	$ePacket_type_pos, _
		$ePacket_type_connect_port= 200, _
		$ePacket_type_connect_player = 		201, _
		$ePacket_type_disconnect_player	= 	202, _
		$ePacket_type_chat = 203, _
		$ePacket_type_download_players = 205

Enum $eSocket_open_method_bind, $eSocket_open_method_open

enum 	$eClient_join_send_retry_attemps, _;0
		$eClient_chat_send_packets, _;1
		$eClient_connection_timeout_len, _;2
		$eClient_join_lastIP_timeout_len, _;3
		$eClient_send_join_messages, _;4
		$eClient_join_timer_len, _;5
		$eClient_join_upload_player_timeout_len, _;6
		$eClient_listen_timeout_len, _;7
		$eClient_send_timeout_len;8

Global $gNetwork_settings_max= 9

If @Compiled = 0 Then
	; start other network app for testing
	;Run("E:\Programming\AutoIt\Dragon Warrior 3 Remake\Map_Editor\Map_Editor.exe", "E:\Programming\AutoIt\Dragon Warrior 3 Remake\Map_Editor")
EndIf

; UDP Server just enable UPD here
UDPStartup()

; Other Includes in Global
; Global Included in DW_Server_h.au3
#include "Include\DW_Server_h.au3"

; Define Cleanup function to run at program exit
OnAutoItExitRegister("_Exit")

; Disable Escape closing GUI
Opt("guicloseonesc", 0)

; This Captures a double-click event on a listview item
GUIRegisterMsg($WM_NOTIFY, "WM_NOTIFY")

;test_server()

;exit
main()

Func main()

	Local $confirm = 0

	; Strip Extention from filename
	$gScriptName = file_remove_ext(@ScriptName)

	$gaGui_rect = win_po_load()

	; Load Last Settings
	Local $sIPAddress = @IPAddress1;"127.0.0.1"
	Local $iPort = 18000
	Local $sGame_name = ""

	$aRet = server_load_config()
	If $aRet[1] <> "" And $aRet[1] <> "EOF" Then $sIPAddress = $aRet[1]
	If $aRet[2] <> "" And $aRet[2] <> "EOF" Then $iPort = $aRet[2]
	If $aRet[3] <> "" And $aRet[3] <> "EOF" Then $sGame_name = $aRet[3]

	; Load Settings
	$aNetwork_settings= network_settings_load(@ScriptDir & $gPath_network_settings)

	player_init($gaPlayer)

	; Start or Load a Game File Directory
	$sGame_name = game_load_dialog($sGame_name)

	Switch $sGame_name

		Case $gMSG_new_game; New Game

			$confirm = 1
			$sGame_name = "New\"

	EndSwitch;aGame_name

	; Set Global Path to the Game Files Playing
	$gPath_game_playing = $gPath_game_files & $sGame_name

	If $sGame_name <> "" Then

		$confirm = game_start($sIPAddress, $iPort, $sGame_name)

		If $confirm = 1 Then

			$confirm = server_dialog($sIPAddress, $iPort, $sGame_name)

		EndIf

	EndIf

	If $confirm Then

		server_run($sIPAddress, $iPort, $sGame_name, $aNetwork_settings)

	EndIf

	; On Close
	win_po_save($ghGui)

EndFunc   ;==>main

Func game_start($sIPAddress, $iPort, $sGame_name)

	out("game_start()")

	copy_game_files($gPath_game_files_source, $gPath_game_playing)

	; Rename Overworld to 0
	DirMove($gPath_game_playing & "Overworld", $gPath_game_playing & "0")

	; Rename Aliahan to 1
	DirMove($gPath_game_playing & "Aliahan", $gPath_game_playing & "1")

	Return 1

EndFunc   ;==>game_start

Func copy_game_files($source, $dest)

	out("copy_game_files()")

	If $gDebug_game_file_create_off = 0 Then

		DirCopy($source, $dest, $fc_overwrite)

		out("copy_game_files(): Created Game Files at: " & $dest)

	EndIf

EndFunc   ;==>copy_game_files

Func game_load_dialog($sGame_name)

	; Read save file list
	Local $aFile_list = _FileListToArrayRec($gPath_game_files, '*', $fltar_folders)

	$ghGui = GUICreate("Load Game", 420, 320, $gaGui_rect[0], $gaGui_rect[0], Default, Default)
	$gaGui_rect = WinGetPos($ghGui)

	$new_game_button = GUICtrlCreateButton("New Game", 5, 5, 65, 20)

	; Setup ListView for File List of Saved Games
	$gListview = GUICtrlCreateListView("Saved Games", 5, 40, 200, 150)

	; Set Colume Width of ListView
	_GUICtrlListView_SetColumnWidth($gListview, 0, 200)

	; Add Directory Files to Save Game List
	If $aFile_list <> "" Then
		For $i = 1 To $aFile_list[0]
			GUICtrlCreateListViewItem($aFile_list[$i], $gListview)
		Next
	EndIf

	_GUICtrlListView_SetItemSelected($gListview, _GUICtrlListView_FindText($gListview, $sGame_name))

	GUISetState()

	Sleep(300)
	WinActivate($ghGui)

	Local $get_name = 0

	Local $msg = 0

	Do

		If WinActive($ghGui) Then

			$msg = GUIGetMsg()

			Switch $msg

				Case $new_game_button

					$sGame_name = $gMSG_new_game

					ExitLoop

			EndSwitch;msg

			If _IsPressed('0d') Then

				keyreleased('0d')

				$get_name = 1

			EndIf

			If $gListview_double_click > 0 Then

				; Turn off the global listview double-click event
				$gListview_double_click = 0

				$get_name = 1

			EndIf

			If $get_name = 1 Then

				; Read the File Name Clicked from ListView
				$sGame_name = GUICtrlRead(GUICtrlRead($gListview))

				; Remove the colume Seporater Char '|' by Trimming Right Most Char
				$sGame_name = StringTrimRight($sGame_name, 1)

				ExitLoop
			EndIf

		EndIf; winactivate(ghGui)

	Until $msg = $gui_event_close

	; If ALT+F4 hang until released
	keyreleased("73");f4

	gui_close($ghGui)

	Return $sGame_name

EndFunc   ;==>game_load_dialog

Func server_dialog($sIPAddress, $iPort, $sGame_name)

	Local $pad_y = 40
	Local $margin_x = 15, $margin_y = 5
	Local $margin_data_x = 90, $margin_data_y = 35
	Local $label_width = 80

	; GUI
	$ghGui = GUICreate("Server Listening", 420, 220, $gaGui_rect[0], $gaGui_rect[1], Default, Default)
	$gaGui_rect = WinGetPos($ghGui)

	Local $label_control_width = $gaGui_rect[2] - 10
	Enum $eSettings_load_path, $eSettings_text_1, $eSettings_server_ip, $eSettings_server_port

	Local $aidSettings = [[0, "Loading Game: ", "edit readonly", $gPath_game_playing, "The Game File Selected to Load" & @CRLF & "Exit Window to Change", $gaGui_rect[2] - $margin_data_x - 5, 40], _
			[0, "You are the Server Listening with the Information Below:", "label", "", "The Game File Selected to Load" & @CRLF & "Exit Window to Change", $gaGui_rect[2], 20], _
			[0, "Server IP: ", "input", $sIPAddress, "Listen for Clients on this IP Address", 95, 20], _
			[0, "Port: ", "input", $iPort, "This is the Base Port." & @CRLF & "Additional Clients will use the next ports in the order that they connect.", 65, 20] _
			]

	Local Const $iSettings_max = UBound($aidSettings)

	Local $control_pad_y = 10
	Local $cursor_y = 0
	For $i = 0 To $iSettings_max - 1
		Switch $aidSettings[$i][$eControl_type]
			Case 'label'
				label_control($aidSettings, $i, $margin_x, $margin_y + $cursor_y, $label_control_width, 20, 0, -100, $aidSettings[$i][$eControl_width], $aidSettings[$i][$eControl_height])
			Case Else; all other controls
				label_control($aidSettings, $i, $margin_x, $margin_y + $cursor_y, $label_width, 20, $margin_data_x, $margin_y + $cursor_y, $aidSettings[$i][$eControl_width], $aidSettings[$i][$eControl_height])
		EndSwitch

		$cursor_y += $aidSettings[$i][$eControl_height] + $control_pad_y
	Next

	; Ip
	$aPos = ControlGetPos($ghGui, "", $aidSettings[$eSettings_server_ip][$eControl_data])
	$machine_ip_combo = GUICtrlCreateCombo("", $aPos[0] + $aPos[2] + 5, $aPos[1], 105, 20)
	GUICtrlSetTip($machine_ip_combo, "Select an IP from this Machine")

	GUICtrlSetData($machine_ip_combo, @IPAddress1)
	GUICtrlSetData($machine_ip_combo, @IPAddress2)
	GUICtrlSetData($machine_ip_combo, @IPAddress3)
	GUICtrlSetData($machine_ip_combo, @IPAddress4)
	_GUICtrlComboBox_SetCurSel($machine_ip_combo, 1)

	; Confirm Button
	Local $confirm_button = GUICtrlCreateButton("Confirm", $gaGui_rect[2] - 80, $gaGui_rect[3] - 80, 50, 20)

	; Dummy Control t0 steal focus
	$focus_off_input = GUICtrlCreateInput("", 0, -100, 1, 1)

	; Hide focus
	GUICtrlSetState($focus_off_input, $gui_focus)

	GUISetState()

	Local $confirm = 0
	Local $msg
	Do
		If WinActive($ghGui) Then
			$msg = GUIGetMsg()

			Switch $msg
				Case $confirm_button
					$confirm = 1
					ExitLoop

				Case $machine_ip_combo; Button to set to IP 1
					GUICtrlSetData($aidSettings[$eSettings_server_ip][$eControl_data], GUICtrlRead($machine_ip_combo))
					$aidSettings[$eSettings_server_ip][$eControl_data_val] = GUICtrlRead($aidSettings[$eSettings_server_ip][$eControl_data])

			EndSwitch

			If _IsPressed('0d') Then

				keyreleased('0d')

				$confirm = 1

				ExitLoop
			EndIf
		EndIf
	Until $msg = $gui_event_close Or _IsPressed("1B")

	If $confirm = 1 Then

		$gServer_Ip = GUICtrlRead($aidSettings[$eSettings_server_ip][$eControl_data])
		$gServer_port_base = GUICtrlRead($aidSettings[$eSettings_server_port][$eControl_data])

		; Bind open port and ip address
		socket_open($gSocket_join_recv, $eSocket_open_method_bind, $gServer_Ip, $gServer_port_base, "server_dialog() gSocket_join_recv")

	EndIf; confirm= 1

	; Save Settings
	$file = FileOpen(@ScriptDir & "\Settings\" & $gScriptName & "_Last_IP_Port.txt", BitOR($FO_OVERWRITE, $FO_CREATEPATH))
	FileWriteLine($file, $gServer_Ip)
	FileWriteLine($file, $gServer_port_base)
	FileWriteLine($file, $sGame_name)

	FileClose($file)

	; If ALT+F4 hang until released
	keyreleased("73");f4

	; Delete the Server Window
	gui_close($ghGui)

	Return $confirm

EndFunc   ;==>server_dialog

Func server_load_config()

	Local $aRet[4]; ip, port, game_name

	$file = FileOpen(@ScriptDir & "\Settings\" & $gScriptName & "_Last_IP_Port.txt")

	$aRet[0] = UBound($aRet)
	$aRet[1] = FileReadLine($file)
	$aRet[2] = FileReadLine($file)

	FileClose($file)

	Return $aRet

EndFunc   ;==>server_load_config

Func server_open_port($ip)

	Local $error = 0

	; Assign new player port
	For $i = 1 To $gSocket_max - 1

		; Find Open Socket
		If $gaSocket_send[$i][$eSocket_connected] = 0 Then

			; Find Open Port
			$port_join = port_bind($ip)

			; Upload Socket
			$error = socket_open($gaSocket_send[$i][$eSocket], $eSocket_open_method_open, $ip, $port_join + 1)

			; Download Socket
			$error = socket_open($gaSocket_recv[$i][$eSocket], $eSocket_open_method_bind, $gServer_Ip, $port_join, "server_open_port()")

			; Connect
			If $error = 0 Then

				$gaSocket_send[$i][$eSocket_connected] = 1
				$gaSocket_recv[$i][$eSocket_connected] = 1

				; Incroment Sockets Connected
				$gSockets_connected_num += 1
				guictrlsetdata($gSockets_connected_input, $gSockets_connected_num)

				out("connect: " & $i)

			EndIf; error= 0

			ExitLoop

		EndIf; gaSocket_send[i][$eSocket_connected] = 0
	Next

	; If an error occurred display the error code and return False.
	If $error Then

		; Someone is probably already binded on this IP Address and Port (script already running?).
		MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), @ScriptName, _
				"Server: gaSocket: " & $i & @CRLF & "gServer_Ip: " & $gServer_Ip & " Port: " & $port_join & @CRLF & "Could not bind, Error code: " & _
				@CRLF & "Someone is probably already binded on this IP Address and Port (script already running?). ERROR CODE: " & $error)

		; Turn connection variable off
		$gaSocket_send[$i][$eSocket_connected] = 0
		$gaSocket_recv[$i][$eSocket_connected] = 0

		; Decroment Sockets Connected
		;$gSockets_connected_num-= 1

		Return 0
	EndIf

	Return $i; Socket Index

EndFunc   ;==>server_open_port

; Returns an unused Port
Func port_bind($ip)

	; Join port
	For $i = 2 To $gServer_port_max Step 2

		;UDPBind($ip, $port + $i)
		$iSocket = UDPBind($ip, $gServer_port_base + $i)

		$error = @error
		UDPCloseSocket($iSocket)

		If $error = 0 Then
			ExitLoop
		EndIf

	Next

	Return $gServer_port_base + $i

EndFunc   ;==>port_bind

Func server_listen_join($aNetwork_settings)

	Local $x = 0
	Local $client_join_msg = 0
	Local $dont_add = 0

	Local $aReceived = ""
	Local $timer_send_delay = 0
	Local $timer_send_delay_len = 100

	Local $port = -1
	Local $socket_join_open = 0

	Local $socket_id = -1

	Local $packet_player_str= ""
	Local $packet_player_header_data= ""

	Local $aPlayer_indexs_cur = 0
	Local $aPlayer_indexs_max= 2
	Local $aPlayer_indexs[$gSockets_connected_num+1][$aPlayer_indexs_max]; 0 index, 1 player datat str

	; Listen for connection
	$aReceived = UDPRecv($gSocket_join_recv, 30, $UDP_DATA_ARRAY)

	If IsArray($aReceived) Then

		; We get Signal
		$aSplit = StringSplit($aReceived[0], $gPacket_Seporator)

		; Someone Joined!
		If $aSplit[$ePacket_header_data_num] > 0 Then; If anything received

			If $aSplit[$ePacket_header_key] = $gPacket_key Then; key

				If $aSplit[2] = $gsNet_join Then; type

					$client_join_msg = 1

				EndIf

			EndIf

		EndIf

		If $client_join_msg = 1 Then

			out("Inspect a IP: " & $aReceived[1])
			out("Inspect a Port: " & $aReceived[2])

			If $gClient_join_lastIP = $aReceived[1] Then $dont_add = 1

			If $dont_add = 0 Then

				out("Added Inspected")

				$socket_id = server_open_port($aReceived[1])

				$aPointer = $gaSocket_recv[$socket_id][$eSocket]
				out("socket_recv: IP: " & $aPointer[2])
				out("socket_recv: Port: " & $aPointer[3])

				$port_player = $aPointer[3]

				$gClient_join_lastIP = $aPointer[2]

				; Assign return signal socket
				$socket_join_open = UDPOpen($aReceived[1], $gServer_port_base + 1); 18001

				If $socket_id > 0 And $socket_id < $gSocket_max Then

					; GUI Message
					console_out("Network Player " & $socket_id & " joined.")

					; Make packet
					$packet_data = packet_header($socket_id, $ePacket_type_connect_port)

					$packet_data&= 	$port_player & $gPacket_Seporator & _
									$gSockets_connected_num & $gPacket_Seporator & _
									$socket_id

					out("pd: "&$packet_data)

					; Send assigned Port, Current Number of Players, and it's own Socket Index to help me debug
					; to Client

					;packet_send($packet_data, $aNetwork_settings[$eClient_join_send_retry_attemps] + 15)

					For $i = 0 To $aNetwork_settings[$eClient_join_send_retry_attemps]

						UDPSend($socket_join_open, $packet_data)

					Next

				Else

					$socket_id = -1

				EndIf; port range

				$gClient_join_lastIP_timer = TimerInit()

				;Return $socket_id

			Else

				out("Inspected IP is Timed Out")

			EndIf; dont_add= 0

			;Return 1

		EndIf; client_join_msg = 1

	EndIf; aRecieved isarray()

	UDPCloseSocket($socket_join_open)

	Return $socket_id

EndFunc   ;==>server_listen_join

Func console_out($sMsg)

	If @HOUR > 12 Then
		$hour = @HOUR - 12
	Else
		$hour = @HOUR
	EndIf

	$time = $hour & ":" & @MIN & ":" & @SEC
	GUICtrlRead($gConsole)
	GUICtrlSetData($gConsole, GUICtrlRead($gConsole) & @CRLF & "[ " & $time & " ] " & $sMsg & @CRLF)

	Sleep(100)

	ControlSend($ghGui, "", $gConsole, "^{END}")

EndFunc   ;==>console_out

Func gui_close(ByRef $hGui)

	; Save win po
	win_po_save($hGui)

	; Delete window
	GUIDelete($hGui)

EndFunc   ;==>gui_close

Func socket_match($apSocket)

	out("aSocket[0]: " & $apSocket[0])
	out("aSocket[1]: " & $apSocket[1])
	out("aSocket[2]: " & $apSocket[2])
	out("aSocket[3]: " & $apSocket[3])

	Local $aSplit = 0
	Local $match = 0

	For $i = 1 To $gSocket_max - 1
		$aSplit = $gaSocket_send[$i][$eSocket]
		If $aSplit[2] = $apSocket[2] Then
			$match = 1
			ExitLoop
		EndIf
	Next

	out("Address in Socket Array: " & $match)

	Return $match

EndFunc   ;==>socket_match

func packet_header($iPlayer_source, $iCommand_type= 0)

	Local $time_created

	; Send header
	Local $packet_data = $gPacket_key & $gPacket_Seporator & _				; 1 Key
			$gSequence_frame & $gPacket_Seporator & _ 	 					; 2 Sequence Frame
			$iPlayer_source & $gPacket_Seporator & _	 					; 3 Player Source
			$gaPlayer[$iPlayer_source][$ePlayer_x] & $gPacket_Seporator & _	; 4 X
			$gaPlayer[$iPlayer_source][$ePlayer_y] & $gPacket_Seporator & _	; 5 Y
			$iCommand_type & $gPacket_Seporator								; 6 Command Type

	Return $packet_data

EndFunc

Func packet_create($iPlayer_source, $ePacket_command_type = 0, $data = "")

	Local $packet_data = packet_header($iPlayer_source, $ePacket_command_type)

	Switch $ePacket_command_type

		Case $ePacket_type_connect_player

			$packet_data &= $data

		Case $ePacket_type_disconnect_player

			; All you do is make a disconnect packet

		case $ePacket_type_chat



	EndSwitch; cmd_type

	Return $packet_data

EndFunc   ;==>packet_create

Func socket_info($apSocket, $index = "", $msgbox = 0)

	out($index & " Socket_info() 0: " & $apSocket[0] & " 1: " & $apSocket[1] & " 2: " & $apSocket[2] & " 3: " & $apSocket[3])

EndFunc   ;==>socket_info

Func player_position($i, $apData_split)

	Local $remote_sequence_frame = $apData_split[$ePacket_header_sequence]; Get sequence frame

	if sequence_more_recent($remote_sequence_frame, $gaSocket_recv[$i][$eSocket_position_sequence]) = 1 Then

		$gaSocket_recv[$i][$eSocket_position_sequence]= $remote_sequence_frame

		$gaPlayer[$i][$ePlayer_x] = $apData_split[$ePacket_header_x]; Get x
		$gaPlayer[$i][$ePlayer_y] = $apData_split[$ePacket_header_y]; Get y

	endif; sequence_more_recent()

	; Force
	$gaPlayer[$i][$ePlayer_x] = $apData_split[$ePacket_header_x]; Get x
	$gaPlayer[$i][$ePlayer_y] = $apData_split[$ePacket_header_y]; Get y


EndFunc   ;==>player_net_pos

Func sequence_more_recent($sequence_frame, $last_sequence_frame, $max = $gSequence_frame_max)

	If $sequence_frame > $last_sequence_frame Then

		Return 1

	EndIf

	If abs($last_sequence_frame - $sequence_frame) > $max / 2 Then

		Return 1

	EndIf

EndFunc   ;==>sequence_more_recent

Func socket_open(ByRef $socket, $iMethod, $sIPAddress, $iPort, $sCalled_from_function = "")

	; Close Socket
	UDPCloseSocket($socket)

	Switch $iMethod

		Case $eSocket_open_method_open; Send
			$socket = UDPOpen($sIPAddress, $iPort)

		Case $eSocket_open_method_bind; Receive
			$socket = UDPBind($sIPAddress, $iPort)

	EndSwitch
	$error = @error

	Local $aError_text = ["UDPOpen", "UDPBind"]

	; UDPBind Error
	If $error <> 0 Then

		Local $socket_info = socket_info($socket)


		Local $error_help_text= ""

		switch $error

			Case 10048

				$error_help_text= 	"IP Address and Port already in use." & @CRLF & _
									"Make sure program isn't already running and or using the IP and PORT already."

			case 10049

				$error_help_text= 	"IP or Port unavailable." & @CRLF & _
									"Check correct IP, sometimes the router assigns you a new one, like when I return from taking my computer to a friends house :)"

			case else

				$error_help_text= ""

		EndSwitch

		MsgBox(0, @ScriptName,	"socket = " & $aError_text[$iMethod] & "("&$sIPAddress&" , "&$iPort&") Error: " & $error & @CRLF & _
								$error_help_text & @CRLF & _
								$socket_info & @CRLF & $sCalled_from_function)

	EndIf;udpbind error

	Return $error

EndFunc   ;==>socket_open

Func out_delay($text, $delay = 1000)

	If TimerDiff($gOut_delay_timer) >= $delay Then

		out($text)

		$gOut_delay_timer = TimerInit()

	EndIf

EndFunc   ;==>out_delay

func packet_send($packet_data, $send_packet_amount= 10)

	for $ii = 0 to $send_packet_amount - 1

		for $i= 1 to $gSocket_max-1

			if $gaSocket_send[$i][$eSocket_connected]> 0 then; Connected

				out("packet_send(): "&$i&" "&$packet_data)

				UDPSend($gaSocket_send[$i][$eSocket], $packet_data)
				$error= @error

				if $error<> 0 then

					;MsgBox(0, @ScriptName, "", 1, $ghGui)

					out("Packet_send(): Socket["&$i&"] Error: " & $error)

				endif

			endif; connected

		next

	next; send_packet_amount

EndFunc

Func server_run($sIPAddress, $iPort, $sGame_name, $aNetwork_settings)

	;$ghGui_send_file = GUICreate("Send File", 320, 280, Default, Default, Default, Default);, default, default, Default, Default, $ghGui_monitor_folder)
	;GUISetState()

	structure_define()

	;Local $aFile = _FileListToArrayRec($gPath_game_files, "*||Sprites;tiles", $fltar_filesfolders, $fltar_recur, $fltar_relpath)

	; Main World Array
	Local $aFile = _FileListToArrayRec($gPath_game_files, "*||Sprites;tiles", $fltar_filesfolders, $fltar_recur, $fltar_relpath)
	$world_max = $aFile[0]

	world_array_redim($world_max)

	For $i = 0 To $world_max - 1
		;out($gPath_game_playing & $i)
		world_area_load($aWorld, 0, $aArea, $i, $gPath_game_playing & $i)
	Next

	; Test world_file_share()
	;world_file_share()

	; World Array
	Local $world_max_layer = 2, $world_max_x = 500, $world_max_y = 500
	Local $aWorld[$world_max][$world_max_layer][$world_max_x][$world_max_y]

	; Area Array
	Local $area_max = 60
	Local $area_data_max = 11;x, y, w, h, outbounds_tile, outbounds_goto_world, outbounds_goto goto_x, goto_y, hotspots, items, people
	Local $aArea[$world_max][$area_max][$area_data_max]

	; Hotspot Array
	Local $hotspot_max = 50
	Local $hotspot_data_max = 5
	Local $aHotspot[$world_max][$area_max][$hotspot_max][$hotspot_data_max]

	; Create GUI
	Local $margin_x = 5, $margin_y = 5
	Local $control_pad_y = 10
	Local $label_width = 65
	Local $margin_data_x = 55

	; GUI Controls
	$ghGui = GUICreate(@ScriptName, 320, 270, $gaGui_rect[0], $gaGui_rect[1])
	$gaGui_rect = WinGetPos($ghGui)

	$idListening_edit = control_create('edit readonly', _
			$gServer_Ip & @CRLF & "Port: " & $gServer_port_base, _
			$margin_data_x, $margin_y, $gaGui_rect[2] - 100 - $margin_data_x, 60, _
			"Server Listening:", "Listening:", _
			$margin_x, $margin_y, 45, 20)

	; Buttons
	$restart_button = control_create('button', "Restart", $gaGui_rect[2] - 90, $margin_y, 70, 20, "Frees all the sockets Disconneting every client" & @CRLF & "Restarts the Server")
	$change_button = control_create('button', "Change", $gaGui_rect[2] - 90, $margin_y + 20 + 5, 70, 20, "Frees all the sockets Disconneting every client" & @CRLF & "Load dialog to change IP and Port of Sever")
	$gSockets_connected_input = control_create('input readonly', "", $margin_x, $margin_y + 40, 40, 20, "Number of Sockets Connected", "Players", $margin_x, $margin_y + 25, 45, 15)

	; Create Console
	$gConsole = GUICtrlCreateEdit("", 5, 80, $gaGui_rect[2] - 15, $gaGui_rect[3] - 80 - 50)

	; Dummy Control to steal control focus
	$focus_off_input = GUICtrlCreateInput("", 0, -100, 1, 1)

	; Menus
	Local $aGui_menu[$gGui_menu_max]

	$aGui_menu[$eGui_menu_file]= guictrlcreatemenu("File")

	Local $gui_menu_file_exit= GUICtrlCreateMenuItem("&Exit", $aGui_menu[$eGui_menu_file])

	$aGui_menu[$eGui_menu_settings]= guictrlcreatemenu("Settings")

	Local $gui_menu_settings_network = GUICtrlCreateMenuItem("&Network", $aGui_menu[$eGui_menu_settings])

	GUISetState()

	GUICtrlSetState($focus_off_input, $gui_focus)

	console_out("Listening")

	Local $timer_join
	;Local $timer_join_len = 1000 * 6

	Local $join_upload_player_timeout = 0
	;Local $join_upload_player_timeout_len = 1000 * 7

	Local $listen_timeout_timer = 0
	;Local $listen_timeout_timer_len = 0

	Local $send_timeout_timer = 0
	;Local $send_timeout_timer_len = 499

	Local $socket_join_index = 0
	Local $x = 0
	Local $player_info_recv = 0

	Local $str = ""
	Local $send_data = ""

	Local $player_join_index = 0
	Local $player_join_str = ""

	Local $packet_split_index = 0
	Local $packet_split_index_offset = 0

	Local $packet_player_str= ""
	Local $packet_player_header_data= ""

	Local $aPlayer_indexs_cur = 0
	Local $aPlayer_indexs_max= 2
	Local $aPlayer_indexs[$gSocket_max][$aPlayer_indexs_max]; 0 index, 1 player datat str

	Do

		$msg = GUIGetMsg()

		Switch $msg

			Case $gui_menu_settings_network

				ShellExecute(@ScriptDir&$gPath_network_settings, "", @ScriptDir&"\Settings", "open")

			Case $change_button

				server_dialog($sIPAddress, $iPort, $sGame_name)

				; Update Server Information Edit Control
				GUICtrlSetData($idListening_edit, $gServer_Ip & @CRLF & "Port: " & $gServer_port_base)

		EndSwitch;msg

		If WinActive($ghGui) Then

			If _IsPressed('0d') Then

				; Make the packet data
				;$data = packet_create(1, $ePacket_type_disconnect_player); 1 is test socket

				; Send a disconnect message
				;packet_send($data, $gSend_join_messages)

			EndIf

			If _IsPressed('70') Then; F1

				_ArrayDisplay($gaSocket_recv)

			endif

		EndIf

		; Accept Incoming Connections
		If TimerDiff($timer_join) >= $aNetwork_settings[$eClient_join_timer_len] Then

			$socket_join_index = server_listen_join($aNetwork_settings)

			If $socket_join_index > 0 Then

				; Collect Player Information
				$join_upload_player_timeout = TimerInit()

				out("Get player info")
				Do

					$player_info_recv = UDPRecv($gaSocket_recv[$socket_join_index][$eSocket], 1024)

					If $player_info_recv <> "" Then out("Index: " & $socket_join_index & " player_info_recv: " & $player_info_recv)

					$aSplit = StringSplit($player_info_recv, $gPacket_Seporator)
					If $aSplit[$ePacket_header_data_num] > 0 Then

						If $aSplit[$ePacket_header_key] = $gPacket_key Then; Key

							If $aSplit[$ePacket_header_type] = $ePacket_type_connect_player Then

								; Extract Player Information form Packet
								For $i = 0 To $player_data_max - 1

									$gaPlayer[$socket_join_index][$i] = $aSplit[$ePacket_header_type + 1 + $i]

								Next

								; Seporate Items from Packet
								$packet_split_index = $ePacket_header_type + $i
								$packet_split_index_offset = 0

								For $i = 0 To $player_item_max - 1

									For $ii = 0 To $player_item_data_max - 1

										$packet_split_index_offset += 1

										$gaPlayer_item[$socket_join_index][$i][$ii] = $aSplit[$packet_split_index + $packet_split_index_offset]

									Next

								Next

								; aPlayer_indexs holds the socket indexs that are connected and the player charater data sheet
								; Get all the players connected
								$aPlayer_indexs_cur= 0

								for $i= 1 to $gSocket_max-1

									if $gaSocket_send[$i][$eSocket_connected]> 0 then

										; Save Connected Index
										$aPlayer_indexs[$aPlayer_indexs_cur][0]= $i

										$aPlayer_indexs[$aPlayer_indexs_cur][1]= ""

										; Make player data string
										for $ii= 0 to $player_data_max-1

											$aPlayer_indexs[$aPlayer_indexs_cur][1]&= $gaPlayer[$i][$ii]&$gPacket_Seporator

										next; ii

										$aPlayer_indexs_cur+=1

									endif; connected

								next; i

								for $i = 1 to $aNetwork_settings[$eClient_join_send_retry_attemps]

									for $ii= 0 to $gSockets_connected_num-1

										; Player_source is [0] Player charater data is [1]
										$packet_player_header_data= packet_header($aPlayer_indexs[$ii][0], $ePacket_type_download_players)

										out("> "&$packet_player_header_data & $aPlayer_indexs[$ii][1])

										UDPSend($gaSocket_send[$socket_join_index][$eSocket], $packet_player_header_data & $aPlayer_indexs[$ii][1])

									next

								next

								; Join message to broadcast
								$player_join_str = StringMid($player_info_recv, StringInStr($player_info_recv, $gPacket_Seporator, 0, $ePacket_header_type) + 1)

								$player_join_index = $socket_join_index
								out("gJoin_message: " & $player_join_index)
								MsgBox(0, @ScriptName, "Player File: " & $player_join_index & @CRLF & $player_join_str, 2, $ghGui)

								ExitLoop

							EndIf

						EndIf

					EndIf

				Until TimerDiff($join_upload_player_timeout) > $aNetwork_settings[$eClient_join_upload_player_timeout_len]

				out("Done")

			EndIf

			$timer_join = TimerInit()

		EndIf

		If TimerDiff($listen_timeout_timer) >= $aNetwork_settings[$eClient_listen_timeout_len] Then

			; Listen to Clients
			For $i = 1 To $gSocket_max - 1

				; Is Socket Connected
				If $gaSocket_send[$i][$eSocket_connected] > 0 Then

					; Receive the data
					$data = UDPRecv($gaSocket_recv[$i][$eSocket], 255);bind

					out("Recieved: " & $i & " " & $data)

					$aSplit = StringSplit($data, $gPacket_Seporator)

					If $aSplit[$ePacket_header_data_num] > 1 Then

						If $aSplit[$ePacket_header_key] = $gPacket_key Then

							; Revive Connection
							$gaSocket_recv[$i][$eSocket_connected] = 1

							switch $aSplit[$ePacket_header_type]

								case 0 to $ePacket_type_connect_player-1

									player_position($i, $aSplit)

								case $ePacket_type_chat

									; If new chat sequence frame not equal last chat sequence frame
									If $gaSocket_recv[$i][$eSocket_chat_sequence] <> $aSplit[$ePacket_header_y] Then; y is chat sequence frame

										; Record last chat sequence frame from client
										$gaSocket_recv[$i][$eSocket_chat_sequence] = $aSplit[$ePacket_header_y]

										;MsgBox(0, @ScriptName, $data, 2, $ghGui)

										; mark socket array index with sequence frame
										; Don't issue a resend per sequence frame

										; Make outbound chat packet
										;
										$packet_data =	$gPacket_key & $gPacket_Seporator & _
														$gSequence_frame & $gPacket_Seporator & _
														$i & $gPacket_Seporator & _
														$gaPlayer[$i][$ePlayer_x] & $gPacket_Seporator & _
														$gaPlayer[$i][$ePlayer_y] & $gPacket_Seporator & _
														$ePacket_type_chat & $gPacket_Seporator & _
														$aSplit[$ePacket_header_x] & $gPacket_Seporator & _; x text data
														$aSplit[$ePacket_header_y]; chat sequence

										; send packets loop

										out("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")
										out("!!!!!  RECEIVED: CHAT PACKET  !!!!! "&$i& " " & $gaPlayer[$i][$ePlayer_name])
										out("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!")

										packet_send($packet_data, $aNetwork_settings[$eClient_chat_send_packets])

										out("Done: SENDING")

									endif; sequence frame

								case $ePacket_type_disconnect_player

									; Adjust socket structure
									disconnect_socket($i, $aNetwork_settings)

									; Make disconnect messages
									$packet_data = packet_create($i, $ePacket_type_disconnect_player)

									; Alert other clients
									packet_send($packet_data, $aNetwork_settings[$eClient_send_join_messages])

									; Output
									out("Terminate packet: " & $packet_data)

							EndSwitch; type

							;EndIf; type has player coords

						EndIf; packet_key

					Else; no key data received

						; Incroment packet loss
						$gaSocket_recv[$i][$eSocket_connected] += 1

						; Terminate Connection
						If $gaSocket_recv[$i][$eSocket_connected] >= $aNetwork_settings[$eClient_connection_timeout_len] Then

							disconnect_socket($i, $aNetwork_settings)

						EndIf; connection timeout disconnect

					EndIf; aSplit[$ePacket_header_data_num]> 1

					If TimerDiff($send_timeout_timer) >= $aNetwork_settings[$eClient_send_timeout_len] Then

						; Share Client info with Clients
						For $ii = 1 To $gSocket_max - 1

							; If socket connected send packets
							If $gaSocket_send[$ii][$eSocket_connected] > 0 Then

								; If not client self, but if only 1 player don't starve it's packets
								if $ii <> $i or $gSockets_connected_num = 1 then

									$send_data = packet_create($i)

									out_delay("Send_data: " & $send_data)

									;socket_info($gaSocket_send[$ii][$eSocket], $ii)

									UDPSend($gaSocket_send[$ii][$eSocket], $send_data)
									$error = @error

									if $error then

										out("socket_send["&$ii&"] UDPSend() Error: "&$error)

									endif; error

								EndIf; not self

							endif; connected

						Next; ii to gSocket_max - 1

						$gSequence_frame += 1

						If $gSequence_frame > $gSequence_frame_max Then $gSequence_frame = 0

						$send_timeout_timer = TimerInit()

					EndIf; send timeout

				EndIf; connected

			Next

		EndIf; listen_timeout

		; Send Join Messages
		If $player_join_index > 0 Then

			$packet_data = packet_create($player_join_index, $ePacket_type_connect_player, $player_join_str)

			For $i = 1 To $gSocket_max - 1

				If $gaSocket_send[$i][$eSocket_connected] > 0 Then

					For $ii = 0 To $aNetwork_settings[$eClient_send_join_messages]

						out("Player join send: " & $player_join_str)

						UDPSend($gaSocket_send[$i][$eSocket], $packet_data)

					Next

				EndIf; gaSocket_send[i][eSocket_connected]

			Next; i

			$player_join_index = 0
			$player_join_str = ""

		EndIf; join_index > 0

		; Join Connection IP Timer Reset
		If $gClient_join_lastIP <> "" Then

			If TimerDiff($gClient_join_lastIP_timer) >= $aNetwork_settings[$eClient_join_lastIP_timeout_len] Then

				out("IP refresh")

				;$aNetwork_settings[$eClient_join_lastIP_timeout_len] = ""

				$gClient_join_lastIP= ""

			EndIf

		EndIf

	Until $msg = $gui_event_close

	; If ALT+F4 hang until released
	keyreleased("73");f4

EndFunc   ;==>server_run

func disconnect_socket($i, $aNetwork_settings)

	; Unbind Sockets
	UDPCloseSocket($gaSocket_recv[$i][$eSocket])
	UDPCloseSocket($gaSocket_send[$i][$eSocket])

	; Disconnect
	$gaSocket_send[$i][$eSocket_connected] = 0
	$gaSocket_recv[$i][$eSocket_connected] = 0

	; Decroment Sockets Connected
	$gSockets_connected_num -= 1
	guictrlsetdata($gSockets_connected_input, $gSockets_connected_num)

	; Disconnect Message
	console_out("Network Player " & $i & " disconnected.")

EndFunc

func network_settings_load($file_path)

	$file= FileOpen($file_path)

	enum $eNetwork_settings_file_data, $eNetwork_settings_file_type, $eNetwork_settings_file_enum_label
	Local $aSetting[$gNetwork_settings_max]

	for $i= 0 to $gNetwork_settings_max-1

		; Read data line
		$data = filereadline($file)

		; Split to Array
		$data= StringSplit($data, ":", $STR_NOCOUNT); zero based flag

		; Strip White-Space
		for $ii=0 to 3-1

			$data[$ii]= StringStripWS($data[$ii], $STR_STRIPALL)

		next

		; Assign control data based on type
		switch $data[$eNetwork_settings_file_type]; type

			Case "Int"

				$aSetting[eval($data[$eNetwork_settings_file_enum_label])]= int($data[$eNetwork_settings_file_data])

			case "string"

				$aSetting[eval($data[$eNetwork_settings_file_enum_label])]= $data[$eNetwork_settings_file_data]

		EndSwitch; data[2] type

	next

	FileClose($file)

	;_ArrayDisplay($aSetting)

	Return $aSetting

EndFunc

func player_init($aPlayer)

	for $i= 0 to UBound($aPlayer)-1

		for $ii= 0 to UBound($aPlayer, 2)-1

			$gaPlayer[$i][$ii]= 0

		Next

	next

EndFunc