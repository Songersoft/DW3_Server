
#include-once

Global $aiGui_rect[4];										Main GUI Window Size
Global $ghGui = 0;											Handle to Main GUI Window
Global $screen = 0;											SDL_Surface

Global $colorblack = 0
Global $mouse_x = 0, $mouse_y = 0
Global $rectarraymax = 10
Global $rectarray[$rectarraymax]
Global $kmax = 257, $k[$kmax]
Global $mbdownmax = 6, $mbdown[$mbdownmax]
Global $mb_scroll_down = 0, $mb_scroll_up = 0, $mb_left_doubleclick = 0

#include "SDL v14\SDL.au3";AdmiralAlkex
#include "SDL v14\SDL_image.au3";AdmiralAlkex
#include "SDL v14\SDL_sge.au3";AdmiralAlkex
#include "SDL v14\SDL_sprig.au3";AdmiralAlkex
#include "SDL v14\SDL_gfx.au3";AdmiralAlkex
#include "Print.au3"
;#include "SDL_contextmenu_class.au3"
#include "SDL_window_class v1.0.au3"
#include <misc.au3>
#include <WindowsConstants.au3>
#include <File.au3>

Func SDL_Template_init($font_filepath)

	Opt("GUICloseOnESC", 0)

	_SDL_Init_image()
	_SDL_Startup_sge()
	_SDL_Startup_sprig()
	_SDL_Startup_gfx()

	_SDL_Init($_SDL_INIT_VIDEO)

	out("SDL_Template_init() Font: " & $font_filepath)
	$font = font_load($font_filepath)

	$screen = _SDL_SetVideoMode($aiGui_rect[2], $aiGui_rect[3], 32, $_SDL_SWSURFACE)

EndFunc   ;==>SDL_Template_init

Func mouseoverrect($x, $y, $w, $h)

	_SDL_GetMouseState($mouse_x, $mouse_y)

	If $mouse_x > $x - 1 Then

		If $mouse_x < $x + $w + 1 Then

			If $mouse_y > $y - 1 Then

				If $mouse_y < $y + $h + 1 Then

					Return 1

				EndIf

			EndIf

		EndIf

	EndIf

	Return 0

EndFunc   ;==>mouseoverrect

Func spredline($surf, $red, $green, $blue, $lowcolor, $highcolor, $x, $y, $x2, $y2, $vertcal, $halfcolor, $colorup)

	If $vertcal = 1 Then

		If $halfcolor = 1 Then

			For $i = 0 To $x2 - $x

				$col = Int($lowcolor + $i) * $highcolor / ($x2 - $x) * 2
				If $col > $highcolor Then $col = $highcolor

				If $colorup = 1 Then

					;sge_VLine(destsurf, x+i+1, y, y2, col*red, col*green, col*blue);
					;sge_VLine(destsurf, x2-i-1, y, y2, col*red, col*green, col*blue);
					_sge_VLine($surf, $x + $i + 1, $y, $y2, _SDL_MapRGB($screen, $col * $red, $col * $green, $col * $blue))
					_sge_VLine($surf, $x2 - $i - 1, $y, $y2, _SDL_MapRGB($screen, $col * $red, $col * $green, $col * $blue))

				Else

					_sge_VLine($surf, $x + $i + 1, $y, $y2, _SDL_MapRGB($screen, ($highcolor - $col) * $red, ($highcolor - $col) * $green, ($highcolor - $col) * $blue))
					_sge_VLine($surf, $x2 - $i - 1, $y, $y2, _SDL_MapRGB($screen, ($highcolor - $col) * $red, ($highcolor - $col) * $green, ($highcolor - $col) * $blue))

				EndIf;endif $colorup

			Next

		Else

			For $i = 0 To $i < ($x2 - $x)

				$col = Int(($lowcolor + $i) * $highcolor / ($x2 - $x));
				If $col > $highcolor Then $col = $highcolor;

				If $colorup = 1 Then

					_sge_VLine($surf, $x + $i, $y, $y2, _SDL_MapRGB($screen, $col * $red, $col * $green, $col * $blue))

				Else

					_sge_VLine($surf, $x + $i, $y, $y2, _SDL_MapRGB($screen, ($highcolor - $col) * $red, ($highcolor - $col) * $green, ($highcolor - $col) * $blue))

				EndIf

			Next

		EndIf;endif $halfcolor

	Else

		If $halfcolor = 1 Then;fixing color here

			For $i = 0 To ($y2 - $y) / 2

				$col = Int(($lowcolor + $i) * $highcolor / ($y2 - $y) * 2);

				If $col > $highcolor Then $col = $highcolor

				If $colorup = 1 Then

					_sge_HLine($surf, $x, $x2, $y + $i + 1, _SDL_MapRGB($screen, $col * $red, $col * $green, $col * $blue))
					_sge_HLine($surf, $x, $x2, $y2 - $i - 1, _SDL_MapRGB($screen, $col * $red, $col * $green, $col * $blue))

				Else

					_sge_HLine($surf, $x, $x2, $y + $i, _SDL_MapRGB($screen, ($highcolor - $col) * $red, ($highcolor - $col) * $green, ($highcolor - $col) * $blue))
					_sge_HLine($surf, $x, $x2, $y2 - $i - 1, _SDL_MapRGB($screen, ($highcolor - $col) * $red, ($highcolor - $col) * $green, ($highcolor - $col) * $blue))

				EndIf

			Next

		Else

			For $i = 0 To $y2 - $y

				$col = Int(($lowcolor + $i) * $highcolor / ($y2 - $y))

				If $col > $highcolor Then $col = $highcolor;

				If $colorup = 1 Then

					_sge_HLine($surf, $x, $x2, $y + $i, _SDL_MapRGB($screen, $col * $red, $col * $green, $col * $blue))

				Else

					_sge_HLine($surf, $x, $x2, $y + $i, _SDL_MapRGB($screen, ($highcolor - $col) * $red, ($highcolor - $col) * $green, ($highcolor - $col) * $blue))

				EndIf

			Next

		EndIf;endif $halfcolor

	EndIf;endif $vertical

EndFunc   ;==>spredline

Func out($output = "");debug tool
	ConsoleWrite(@CRLF & $output);to console new line, value of $output
EndFunc   ;==>out

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

Func showsurf($surf, $x = 0, $y = 0, $sleep = 500, $dontclear = 0)
	Local $w = 0, $h = 0
	surf_size_get($surf, $w, $h)
	If $dontclear = 0 Then _SDL_FillRect($screen, 0, $colorblack)
	$rect = _SDL_Rect_Create($x, $y, $w, $h)
	_SDL_BlitSurface($surf, $rect, $screen, 0)
	_SDL_Flip($screen)
	Sleep($sleep)
EndFunc   ;==>showsurf

Func getnumber($caption, $text, $default, $min, $max, $hGui_p = "")
	While 1
		$x = InputBox($caption, $text, $default, Default, Default, Default, Default, Default, Default, $hGui_p)
		If @error = 1 Then Return $default
		$x = Number($x)
		If $x >= $min And $x <= $max Then
			If $x = "" Then $x = 0
			Return $x
		Else
			MsgBox(0, "Out of bounds", "The Range for this setting " & $min & " \ " & $max, Default, $hGui_p)
		EndIf
	WEnd
	Return -1
EndFunc   ;==>getnumber

Func getfilename($path)
	Return StringMid($path, StringInStr($path, "\", 0, -1) + 1)
EndFunc   ;==>getfilename

Func getfolder($path)
	$pathreturn = StringMid($path, 1, StringInStr($path, "\", 0, -1))
	Return $pathreturn
EndFunc   ;==>getfolder

Func getfileext($filename)
	$pathreturn = StringMid($filename, StringLen($filename) - 3)
	Return $pathreturn
EndFunc   ;==>getfileext

Func surf_size_get($surf, ByRef $w, ByRef $h)
	$struct = DllStructCreate($tagSDL_SURFACE, $surf)
	$w = DllStructGetData($struct, "w")
	$h = DllStructGetData($struct, "h")
	$struct = 0
EndFunc   ;==>surf_size_get

; [File Section]
Func read_chunk($file); Remove Label from File Line Label Data pair.
	Local $chunk = FileReadLine($file)
	If @error <> 0 Then
		Return "File EOF"
	EndIf
	Local $chunk_po = StringInStr($chunk, ": "); Find the string position of the first ": "
	Return StringMid($chunk, $chunk_po + 2); Return String 2 spaces right from the chunk_po
EndFunc   ;==>read_chunk

Func flip($surf, $delay = 500, $x = 0, $y = 0)
	Local $tw, $th
	surf_size_get($surf, $tw, $th)
	_SDL_BlitSurface($surf, 0, $screen, _SDL_Rect_Create($x, $y, $tw, $th))
	_SDL_Flip($screen)
	Sleep($delay)
EndFunc   ;==>flip
