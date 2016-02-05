#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:         myName

	Script Function:
	To copy files to a backup folder.

#ce ----------------------------------------------------------------------------

#include <File.au3>

Global $gBackup_dir_path = "..\Backup\"

; Todo
; Add notes, options notes in file name

main()
func main()

	; File list remember to remove extentions from file_name
	; or add file extention as second parameter
	backup("Map_Editor")
	backup("DW_Server")

EndFunc

Func backup($spFile_name, $spFile_ext = ".au3")

	Local $error = 0
	Local $iFile_num = 0

	; Make source file path
	Local $sFile_path_source = $spFile_name & $spFile_ext

	Local $sFile_path_dest = ""

	; Sample the contents of the backup directory before creating a file there
	Local $aFile = _FileListToArray($gBackup_dir_path, $spFile_name&"*"&$spFile_ext, $FLTA_FILES)
	$error = @error

	If $error = 0 Then

		$iFile_num = $aFile[0]

	EndIf

	out("Found: " & $iFile_num & " files named: " & $spFile_name)

	Do

		; Incroment file_num to find available file_name
		$iFile_num += 1

		; Path to Write File Copy
		$sFile_path_dest = $gBackup_dir_path & $spFile_name & "_" & $iFile_num & $spFile_ext

		; Refuse to Overwrite File
		If FileExists($sFile_path_dest) = 0 Then

			ExitLoop

		EndIf

		; Am I right?
		Sleep(30)

	Until 0

	; Create the file
	FileCopy($sFile_path_source, $sFile_path_dest, $FC_CREATEPATH)
	$error = @error

	If $error Then out("FileCopy() error: " & $error)

	out("sFile_path_source: " & $sFile_path_source & " sFile_path_dest: " & $sFile_path_dest)

EndFunc   ;==>backup

Func out($output = "", $user = 0);debug tool

	ConsoleWrite(@CRLF & $output);to console new line, value of $output

EndFunc   ;==>out
