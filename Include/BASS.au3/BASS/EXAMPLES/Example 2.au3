#include <Bass.au3>
#include <BassConstants.au3>
#include <GUIConstantsEx.au3>
Global $playing_state = -1
;Open Bass.DLL.  Required for all function calls.
_BASS_STARTUP ("BASS.dll")

;Initalize bass.  Required for most functions.
_BASS_Init (0, -1, 44100, 0, "")

;Check if bass iniated.  If not, we cannot continue.
If @error Then
	MsgBox(0, "Error", "Could not initialize audio")
	Exit
EndIf

;Prompt the user to select a MP3 file
$file = FileOpenDialog("Open...", "", "MP3 Files (*.mp3)")

;Create a stream from that file.
$MusicHandle = _BASS_StreamCreateFile (False, $file, 0, 0, 0)

;Check if we opened the file correctly.
If @error Then
	MsgBox(0, "Error", "Could not load audio file" & @CR & "Error = " & @error)
	Exit
EndIf

;Create GUI and controls
$Form1 = GUICreate("Example 2", 380, 190, 193, 115)
$lblFileName = GUICtrlCreateLabel($file, 8, 8, 379, 17)
$progress_slider = GUICtrlCreateSlider(8, 32, 374, 29)
GUICtrlSetLimit(-1, 100, 0)
$rightVol = GUICtrlCreateProgress(8, 88, 366, 17)
GUICtrlSetLimit(-1, 100, 0)
$LeftVol = GUICtrlCreateProgress(8, 136, 366, 17)
GUICtrlSetLimit(-1, 100, 0)
GUICtrlCreateLabel("Right Channel Volume Level", 8, 64, 150, 17)
GUICtrlCreateLabel("Left Channel Volume Level", 8, 112, 150, 17)
$Close = GUICtrlCreateButton("Close", 296, 160, 75, 25, 0)
$Play_pause = GUICtrlCreateButton("Play/Pause", 216, 160, 75, 25, 0)
$Stop = GUICtrlCreateButton("Stop", 136, 160, 75, 25, 0)
;Show GUI
GUISetState(@SW_SHOW)

;Get the length of the song in bytes.
$song_length = _BASS_ChannelGetLength ($MusicHandle, $BASS_POS_BYTE)

While 1
	;Get Current playback position
	$current = _BASS_ChannelGetPosition ($MusicHandle, $BASS_POS_BYTE)
	;Calculate the percentage
	$percent = Round(($current / $song_length) * 100, 0)
	;Set the slider to show percent
	GUICtrlSetData($progress_slider, $percent)

	;Get Right/Left Playback Levels
	$levels = _BASS_ChannelGetLevel ($MusicHandle)
	;Get Right and calculate percentage
	$rightChLvl = _LoWord ($levels)
	$rightChLvlper = Round(($rightChLvl / 32768) * 100, 0)
	;Get Left and calculate percentage
	$LeftChLvl = _HiWord ($levels)
	$leftChLvlper = Round(($LeftChLvl / 32768) * 100, 0)
	;Set the levels on GUI.
	GUICtrlSetData($rightVol, $rightChLvlper)
	GUICtrlSetData($LeftVol, $leftChLvlper)

	;Get GUI Message
	$nMsg = GUIGetMsg()
	Switch $nMsg
		;If Close button or red x, then exit.  Alway remember to free resources
		Case $GUI_EVENT_CLOSE, $Close
			Exit
		Case $Play_pause
			;Check if playing or paused, then take appropriate action
			Switch $playing_state
				Case 0; Song Paused, Resume.
					;Resume Song
					_BASS_Pause ()
					$playing_state = 1
				Case - 1 ; Song stopped, start from begining.
					;Play Song
					_BASS_ChannelPlay ($MusicHandle, 1)
					$playing_state = 1
				Case 1 ; Song Playing, Pause
					;Pause song
					_BASS_Pause ()
					$playing_state = 0
			EndSwitch
		Case $Stop
			;Stop Song
			_BASS_ChannelStop ($MusicHandle)
			$playing_state = -1
	EndSwitch
WEnd

Func OnAutoItExit()
	;Free Resources
	_BASS_Free()
EndFunc   ;=
