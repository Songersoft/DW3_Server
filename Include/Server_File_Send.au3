
Func send_file_dialog_create_controls(ByRef $hGui2, $file_name)

	GUISwitch($hGui2)
	;$hGui2 = GUICreate("Send File: " & $file_name, 420, 280, $gui_rect[0]+25, $gui_rect[1]+25, Default, Default, $ghGui_monitor_folder)
	Local $gui_rect = WinGetPos($hGui2)

	; GUI Controls
	Local $margin_x = 10, $margin_y = 15
	Local $curser = 0
	Local $pad_y = 45

	Local $label_x = $margin_x, $label_y = $margin_y, $label_w = $gui_rect[2] - 50, $label_h = 15
	Local $data_x = $margin_x, $data_offset_y = 30, $data_w = $gui_rect[2] - 25, $data_h = 55

	;Enum $eSend_control_file_name, $eSend_control_progress, $eSend_control_error
	Local $aControl = [[0, "File_name:", "edit readonly", $file_name, "The Name of the File Transfering to Server.", 200, 55], _
			[0, "0kb / 0kb", "progress bar", "", "File Transfering to Server.", 300, 25], _
			[0, "Error", "edit readonly", "No Error", "Error Output Pane", 300, 85, 0, 20] _
			]

	For $i = 0 To UBound($aControl) - 1
		;label_control($aControl, $iControl_id, $label_x, $label_y, $label_w, $label_h, $data_x, $data_y, $data_w, $data_h)
		label_control($aControl, $i, $label_x, $label_y + $curser - $aControl[$i][$eControl_pad_y], $label_w, $label_h, _
				$data_x, $data_offset_y + $curser - $aControl[$i][$eControl_pad_y], $data_w, $aControl[$i][$eControl_height])

		$curser += $aControl[$i][$eControl_height] + $pad_y
	Next

	; Misc Font and ToolTips
	GUICtrlSetFont($aControl[$eSend_control_progress][$eControl_label], 10)
	GUICtrlSetTip($aControl[$eSend_control_progress][$eControl_label], "Bytes in File Buffer")

	GUISetState(@SW_SHOW, $hGui2); Show GUI

	Return $aControl
EndFunc   ;==>send_file_dialog_create_controls

Func _SendFile($file_path, $file_name, $resent_i, $aIP_controls, $MaxLen)

	$gStop = 0
	$gFile_sent = 0
	Local $FileHandle = 0
	Local $socket = 0
	Local $error = 0
	Local $BytesRead = 0
	Local $timed_out = 0
	Local $BytesRead_last = 0

	Local $hGui2 = 0
	Local $Reg = 0
	Local $error_str
	Local $file_send_timer = 0
	Local $data = ""

	Local $ghGui_monitor_folder = 0
	$file_path &= '\' & $file_name

	If FileExists($file_path) = 0 Then
		MsgBox(0, "_SendFile", "FileExists"" Error: " & $file_path & @CRLF & "Attempt: " & $resent_i, Default, $ghGui)
		Return
	Else
		;MsgBox(0, "_SendFile", "FileExists: " & $file_path&@CRLF&"The File is there"&@CRLF&"Attempt: "&$resent_i, Default, $ghGui)
	EndIf
	out("Upload File: " & $file_path)

	; File Size
	Local $file_size = FileGetSize($file_path)
	$error = @error

	If $error <> 0 Then
		$gStop = 1

		MsgBox(0, @ScriptName & " Error: " & $error, "File Size: " & $file_size & @CRLF & $file_path, 5, $ghGui)
		;Return SetError(1, 0, -1)
	EndIf

	If $gStop = 0 Then

		;$ghGui_send_file = GUICreate("Send File", 320, 280, Default, Default, Default, Default, $ghGui_monitor_folder);, default, default, Default, Default, $ghGui_monitor_folder)
		Local $gui_rect = WinGetPos($ghGui_monitor_folder)

		Local $aControl = send_file_dialog_create_controls($ghGui_send_file, $file_name)
		; Create GUI

		Local $ip = $aIP_controls[$eidSettings_server_ip][$eControl_data_val];InputBox("IP Address", "What is the IP address of the server?", "")

		Local $port = $aIP_controls[$eidSettings_server_port][$eControl_data_val]

		$socket = TCPConnect($ip, $port)
		$error = @error

		If $error Then
			$gStop = 1

			$error_str = "Unknown Error"
			Switch $error
				Case 1; ip
					$error_str = "Incorrect IP"

				Case 2; port
					$error_str = "Incorrect Port"

				Case 10060; Server not Listening on specified IP address
					$error_str = "Server not Listening on: " & $ip & " : " & $port & @CRLF & "Is the Server Running and Listening?"

			EndSwitch

			GUICtrlSetData($aControl[$eSend_control_error][$eControl_data], "TCPConnect(): Error: " & $error & @CRLF & "Attempt: " & $resent_i & @CRLF & $error_str)

			;Return SetError(3, $error, -1)
		EndIf

		Local $Receive = ""
		If $gStop = 0 Then

			;wait until something is sent
			Do
				$Receive = TCPRecv($socket, 1000)
				$error = @error

				If $error Then

					$gStop = 1
					GUICtrlSetData($aControl[$eSend_control_error][$eControl_data], "TCPRecv(): Error: " & $error & @CRLF & "Attempt: " & $resent_i & @CRLF & $error_str)

					ExitLoop

					;Return SetError(4, 0, -1)
				EndIf

				Sleep(10)
			Until $Receive <> ""

			If $Receive <> "Sending Data" Then
				$gStop = 1

				$error_str = "Expected: Sending Data" & @CRLF & "Received: " & $Receive

				GUICtrlSetData($aControl[$eSend_control_error][$eControl_data], $error_str & @CRLF & "Attempt: " & $resent_i)

				;Return SetError(5, $Receive, -1)
			EndIf

			If $gStop = 0 Then

				; Send Name and File Size to Server (reciever)
				TCPSend($socket, $file_name & ":" & $file_size)

				;Wait for confirmation from receiver
				Do

					$Receive = TCPRecv($socket, 1000)
					$error = @error
					If $error Then

						$gStop = 1

						GUICtrlSetData($aControl[$eSend_control_error][$eControl_data], "TCPRecv(): " & $error & @CRLF & "Attempt: " & $resent_i)

						;SetError(6, 0, -1)

						ExitLoop

					EndIf
				Until $Receive <> ""

				If $Receive <> "Start Upload" Then

					$gStop = 1

					$error_str = "Expected: Start Upload, Received: " & $Receive

					GUICtrlSetData($aControl[$eSend_control_error][$eControl_data], $error_str & @CRLF & "Attempt: " & $resent_i)

					;SetError(7, $Receive, -1)
				EndIf

				If $gStop = 0 Then

					; Open file to read in binary
					$FileHandle = FileOpen($file_path, $FO_BINARY)

					; Time out
					$file_send_timer = TimerInit()

					; Loop until the whole file is received
					While 1;$BytesRead< $file_size

						$data = FileRead($FileHandle, $MaxLen)
						$error = @error

						; Catch EOF Error and Exit
						If $error Then
							ExitLoop
						EndIf

						$BytesRead_last = $BytesRead
						$BytesRead += TCPSend($socket, $data)

						; Reset Timer if Recieved Bytes
						If $BytesRead <> $BytesRead_last Then
							;out("Timer Reset")
							$file_send_timer = TimerInit()
						EndIf

						; Update the GUI Progress Bar
						If GUICtrlRead($aControl[$eSend_control_progress][$eControl_data]) <> Round($BytesRead / $file_size * 100) Then
							GUICtrlSetData($aControl[$eSend_control_progress][$eControl_data], Round($BytesRead / $file_size * 100))
							GUICtrlSetData($aControl[$eSend_control_progress][$eControl_label], Round($BytesRead / 1024) & " kb / " & Round($file_size / 1024) & " kb")
						EndIf

						; Time to drop
						;If TimerDiff($file_send_timer) > $gaProgram_controls[$eProgram_controls_send_file_timeout][$eControl_data_val] * 1000 Then
						If TimerDiff($file_send_timer) > 1000 * 30 Then
							GUICtrlSetData($aControl[$eSend_control_error][$eControl_data], "Error in ByteRead Loop from FileRead():" & @CRLF & $file_path & @CRLF & "Attempt: " & $resent_i)
							ExitLoop
						EndIf
					WEnd

					If $BytesRead >= $file_size Then
						$gFile_sent = 1

						GUICtrlSetData($aControl[$eSend_control_error][$eControl_data], "File Sent." & @CRLF & "Attempt: " & $resent_i)
						out($gFile_sent)
					Else
						$gFile_sent = 0

						GUICtrlSetData($aControl[$eSend_control_error][$eControl_data], "File not Sent." & @CRLF & $file_path & "\" & $file_name & @CRLF & "Attempt: " & $resent_i)
					EndIf

					FileClose($FileHandle)
				EndIf; gStop = 0
			EndIf; gStop= 0
		EndIf; gStop = 0
	EndIf; gStop= 0

	TCPCloseSocket($socket)

	;win_po_save(@ScriptDir & "\System\" & $gScriptName & "_SendFile_Win_Po.txt", $hGui2)

	; Rest bewteen files
	Local $timer = TimerInit()
	Do
		Sleep(10)
	Until TimerDiff($timer) > 700

	;GUIDelete($hGui2)
	;guisetstate(@sw_hide, $ghGui_send_file)

	Return SetError(0, 0, 1)
EndFunc   ;==>_SendFile

; Always send file
Func world_file_share()

	; All files in memory should be saved to Server Disk
	For $i = 0 To $world_max - 1
		world_area_save($aWorld, 0, $aArea, $aHotspot, 0, $i)
	Next

	;Func world_area_save($aWorld, $aTile, $aArea, $aHotspot, $player, $filepath = "")
	out("gPath_game_files: " & $gPath_game_playing)
	Local $aFile = _FileListToArrayRec($gPath_game_playing, "*||Sprites;tiles", $fltar_filesfolders, $fltar_recur, $fltar_relpath)
	Local $aIP_controls = $gaidIP_controls
	Local $send_retry_attempts = 5

	; Show
	;guisetstate(@SW_SHOW, $ghGui_send_file)

	;For $i = 1 To $aFile[0]
	;;For $resent_i = 0 To $gaProgram_controls[$eProgram_controls_send_file_resend_attempts][$eControl_data_val] - 1
	;For $resent_i = 0 To $send_retry_attempts - 1
	;_SendFile($gPath_game_playing, $aFile[$i], $resent_i, $aIP_controls, $gFile_send_max_len)
	;Next
	;Next

	; hide
	;guisetstate(@SW_HIDE, $ghGui_send_file)
EndFunc   ;==>world_file_share