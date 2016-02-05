#include-once
#include "SDL_Template v1.0.au3"

Global $wdrag = 0;$wdrag= windowobject()
Global $dragid = -1
Global $dragn = 0
Global $windowclassdatamax = 9

Global $sdl_window_control_max = 30, $sdl_window_control_data_max = 4
$tagWindow_struct = "ptr surf;" & _
		"ptr _surf;" & _
		"int iX;" & _
		"int iY;" & _
		"int iW;" & _
		"int iH;" & _
		"bool bNo_drag;" & _
		"int iDrag_dis_x;" & _
		"int iDrag_dis_y;" & _
		"int iRects;" & _
		"int rect[" & $sdl_window_control_max * $sdl_window_control_data_max & "];"; Control_Max * 5[x,y,w,h,control_type]

Func window_make($vSurf, $x, $y, $w, $h, $alpha = 255, $highcolor = 255, $colorkey = -1, $red = 0, $green = 0, $blue = 0);0blank, if fileexists load bmp file, if fileexista= 0 then loadsurf
	$window_struct = DllStructCreate($tagWindow_struct)

	If FileExists($vSurf) = 1 Then;load an image for window surface
		$window_struct.surf = _IMG_Load($vSurf)
	ElseIf $vSurf = 0 Then
		$window_struct.surf = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $w, $h, 32, 0, 0, 0, $alpha)
		$color = _SDL_MapRGB($screen, $highcolor * $red, $highcolor * $green, $highcolor * $blue)
		_sge_filledrect($window_struct.surf, 0, 0, $w, $h, $color)
		_SDL_SetAlpha($window_struct.surf, $_SDL_SRCALPHA, $alpha)
	ElseIf $vSurf = 1 Then
		$window_struct.surf = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $w, $h, 32, 0, 0, 0, $alpha)
		spredline($window_struct.surf, $red, $green, $blue, 0, $highcolor, 0, 0, $w, $h, 0, 1, 1)
	ElseIf $vSurf = 2 Then
		$window_struct.surf = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $w, $h, 32, 0, 0, 0, $alpha)
		_SDL_FillRect($window_struct.surf, 0, _SDL_MapRGB($screen, $red, $green, $blue))
	Else;use a surface as window surface
		$window_struct.surf = _SDL_DisplayFormat($vSurf)
	EndIf
	$window_struct._surf = _SDL_DisplayFormat($window_struct.surf);make backup surf
	Local $ww = 0, $hh = 0
	surf_size_get($window_struct.surf, $ww, $hh)

	_SDL_SetAlpha($window_struct.surf, $_SDL_SRCALPHA, $alpha)
	_SDL_SetAlpha($window_struct._surf, $_SDL_SRCALPHA, 255)

	If $colorkey <> -1 Then _SDL_SetColorKey($window_struct.surf, $_SDL_SRCCOLORKEY, $colorkey)
	$window_struct.iX = $x
	$window_struct.iY = $y
	$window_struct.iW = $ww
	$window_struct.iH = $hh
	Return $window_struct
EndFunc   ;==>window_make

Func window_draw_array($aWindow)
	For $i = 0 To UBound($aWindow) - 1
		$drect = _SDL_Rect_Create($aWindow[$i].iX, $aWindow[$i].iY, $aWindow[$i].iW, $aWindow[$i].iH)
		_SDL_BlitSurface($aWindow[$i].surf, 0, $screen, $drect)
	Next
EndFunc   ;==>window_draw_array

Func window_draw($aWindow)
	$drect = _SDL_Rect_Create($aWindow.iX, $aWindow.iY, $aWindow.iW, $aWindow.iH)
	_SDL_BlitSurface($aWindow.surf, 0, $screen, $drect)
EndFunc   ;==>window_draw

Func window_drawbackup(ByRef $window)

	; Free Surface
	If $window._surf <> 0 Then _SDL_FreeSurface($window._surf)

	; Create Surface form Window
	$window._surf = _SDL_DisplayFormat($window.surf)

EndFunc   ;==>window_drawbackup

Func window_drag(ByRef $aWindow, ByRef $redraw)
	If $dragn = -1 Then
		If mouseoverrect($aWindow.iX, $aWindow.iY, $aWindow.iW, $aWindow.iH) = 1 Then
			$aWindow.iDrag_dis_x = $mouse_x - $aWindow.iX
			$aWindow.iDrag_dis_y = $mouse_y - $aWindow.iY
			$dragn = 0
			$wdrag = 0;$wdrag= $os
		EndIf
	Else
		If $dragn = 0 Then
			_SDL_GetMouseState($mouse_x, $mouse_y)
			$aWindow.iX = $mouse_x - $aWindow.iDrag_dis_x
			$aWindow.iY = $mouse_y - $aWindow.iDrag_dis_y
			$redraw = 1
			Return
		EndIf
	EndIf;endif dragging= 0
EndFunc   ;==>window_drag

Func window_drag_array(ByRef $aWindow, $iWindows, ByRef $redraw)
	For $i = $iWindows - 1 To 0 Step -1
		If $dragn = -1 Then
			If mouseoverrect($aWindow[$i].iX, $aWindow[$i].iY, $aWindow[$i].iW, $aWindow[$i].iH) = 1 Then
				$aWindow[$i].iDrag_dis_x = $mouse_x - $aWindow[$i].iX
				$aWindow[$i].iDrag_dis_y = $mouse_y - $aWindow[$i].iY
				$dragn = $i
				$wdrag = $aWindow[$i];$wdrag= $os
			EndIf
		Else
			If $dragn = $i Then
				_SDL_GetMouseState($mouse_x, $mouse_y)
				$aWindow[$i].iX = $mouse_x - $aWindow[$i].iDrag_dis_x
				$aWindow[$i].iY = $mouse_y - $aWindow[$i].iDrag_dis_y
				$redraw = 1
				Return
			EndIf
		EndIf;endif dragging= 0
	Next
EndFunc   ;==>window_drag_array

;Window _surf Should be clear
Func window_print_set_rect($sLabel, ByRef $window, $x, $y, $chr_w, $chr_h= $font.iH, $iControl_type = 0, $r= 255, $g=255, $b=255, $scale_x = 1, $scale_y= 1)

	; Print Label on Background Surface, take rect returned from that
	; Use width from after the return rect

	print($sLabel, $window.surf, $x, $y, $r, $g, $b, $scale_x, $scale_y)

	Local $xx = $sdlt_rectreturn.x + $sdlt_rectreturn.w

	; Rect Array
	DllStructSetData($window, "rect", $xx, $window.iRects * 4 + 1);x
	DllStructSetData($window, "rect", $sdlt_rectreturn.y, $window.iRects * 4 + 2);y
	DllStructSetData($window, "rect", $chr_w * $font.iW, $window.iRects * 4 + 3);w
	DllStructSetData($window, "rect", $chr_h, $window.iRects * 4 + 4);h

	; Rect Amount
	$window.iRects += 1
	; Assign Name
	Return $window.iRects - 1
EndFunc   ;==>window_print_set_rect

Func window_print($output, $window, $rectID, $r= 255, $g= 255, $b= 255, $scale_x = 1, $scale_y= 1)

	Local $drect = _SDL_Rect_Create(DllStructGetData($window, "rect", $rectID * 4 + 1), DllStructGetData($window, "rect", $rectID * 4 + 2), DllStructGetData($window, "rect", $rectID * 4 + 3), DllStructGetData($window, "rect", $rectID * 4 + 4))

	; Delete Area From Backup
	_SDL_BlitSurface($window._surf, $drect, $window.surf, $drect)

	; Print Output
	print($output, $window.surf, $drect.x, $drect.y, $r, $g, $b, $scale_x, $scale_y)

EndFunc   ;==>window_print

Func window_free_window($window)
	$window.iX = -100
	$window.iY = -100
	$window.iW = 0
	$window.iH = 0
	$window.bNo_drag = 0
	$window.iDrag_dis_x = 0
	$window.iDrag_dis_y = 0
	If $window.surf <> 0 Then
		out("window surf freed from class")
		_SDL_FreeSurface($window.surf)
	EndIf
	$window.surf = 0
	If $window._surf <> 0 Then _SDL_FreeSurface($window._surf)
	$window._surf = 0
EndFunc   ;==>window_freewindow

func window_copy_window($source_window)
	Local $dest_window= DllStructCreate($tagWindow_struct)
	$dest_window.iX= $source_window.iX
	$dest_window.iY= $source_window.iY
	$dest_window.iW= $source_window.iW
	$dest_window.iH= $source_window.iH
	$dest_window.bNo_drag= $source_window.bNo_drag
	$dest_window.iDrag_dis_x= $source_window.iDrag_dis_x
	$dest_window.iDrag_dis_y= $source_window.iDrag_dis_y
	$dest_window.surf= _SDL_DisplayFormat($source_window.surf)
	$dest_window._surf= _SDL_DisplayFormat($source_window._surf)
	$dest_window.iRects= $source_window.iRects
	for $i= 0 to $sdl_window_control_max-1
		for $ii= 0 to $sdl_window_control_data_max-1
			DllStructSetData($dest_window, "rect", DllStructGetData($source_window, "rect", $i+$ii), $i+$ii)
		next
	next
	Return $dest_window
EndFunc

;~ func window_copy_window($window)
;~ 	local $a[$windowclassdatamax]
;~ 	$a[0]= $window.iX
;~ 	$a[1]= $window.iY
;~ 	$a[2]= $window.iW
;~ 	$a[3]= $window.iH
;~ 	$a[4]= $window.bNo_drag
;~ 	$a[5]= $window.iDrag_dis_x
;~ 	$a[6]= $window.iDrag_dis_y
;~ 	$a[7]= 0
;~ 	$a[8]= 0
;~ 	if $window.surf<> 0 then $a[7]= _SDL_DisplayFormat($window.surf)
;~ 	if $window._surf<> 0 then $a[8]= _SDL_DisplayFormat($window._surf)
;~ 	return $a
;~ EndFunc

func window_paste_window($a, byref $window)
	;local $a[$windowclassdatamax]
	out("surf: "&$window.surf)
	out("a[7]: "&$a[7])
	$window.iX= $a[0]
	$window.iY= $a[1]
	$window.iW= $a[2]
	$window.iH= $a[3]
	$window.bNo_drag= $a[4]
	$window.iDrag_dis_x= $a[5]
	$window.iDrag_dis_y= $a[6]
	if $window.surf<> 0 then _SDL_FreeSurface($window.surf)
	if $window._surf<> 0 then _SDL_FreeSurface($window._surf)
	$window.surf= _SDL_DisplayFormat($a[7])
	$window._surf= _SDL_DisplayFormat($a[8])
EndFunc