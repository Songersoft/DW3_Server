#include-once
#include "SDL_Template v1.0.au3"
$tagContextmenu_struct= "ptr surf;"& _
						"ptr cursurf;"& _
						"int cur;" & _
						"int w;"& _
						"int h;"
;~ func contextmenuobject($iStartup = False)
;~ 	local $oObj = _AutoItObject_Create()
;~ 	if $iStartup then $oObj.Startup
;~ 	_AutoItObject_AddProperty($oObj, "surf", $ELSCOPE_Public, 0)
;~ 	_AutoItObject_AddProperty($oObj, "cursurf", $ELSCOPE_Public, 0)
;~ 	_AutoItObject_AddProperty($oObj, "cur", $ELSCOPE_Public, -1)
;~     _AutoItObject_AddProperty($oObj, "w", $ELSCOPE_Public, 0)
;~ 	_AutoItObject_AddProperty($oObj, "h", $ELSCOPE_Public, 0)
;~ 	_AutoItObject_AddMethod($oObj, "make", "contextmenuo_make")
;~ 	_AutoItObject_AddMethod($oObj, "draw", "contextmenuo_draw")
;~ 	_AutoItObject_AddMethod($oObj, "getselection", "contextmenuo_getselection")
;~ 	return $oObj
;~ EndFunc;contextmenuobject()

func contextmenu_make($optionsarray= 0, $alpha= 155)
	$contextmenu_struct= DllStructCreate($tagContextmenu_struct)
	;find the length of text
	local $len= 0, $amax= ubound($optionsarray)-1
	for $i= 0 to $amax
		if $len< stringlen($optionsarray[$i]) then $len= stringlen($optionsarray[$i])
	next
	$contextmenu_struct.w= $len*$font.w+5
	$contextmenu_struct.h= ($amax+1)*$font.h+5
	;if $contextmenu_struct.surf<> "" then _SDL_FreeSurface($os.surf)
	;create surface and curser of size
	$contextmenu_struct.surf= _SDL_CreateRGBSurface($_SDL_SWSURFACE, $contextmenu_struct.w, $contextmenu_struct.h, 32, 0, 0, 0, $alpha)
	$contextmenu_struct.cursurf= _SDL_CreateRGBSurface($_SDL_SWSURFACE, $contextmenu_struct.w, $font.h, 32, 0, 0, 0, 175)
	_sge_FilledRect($contextmenu_struct.cursurf, 0, 0, $contextmenu_struct.w, $font.h, _SDL_MapRGB($screen, 200, 200, 200))
	for $i= 0 to $amax
		print($optionsarray[$i], $contextmenu_struct.surf, 5, 5+$font.h*$i)
	next
	Return $contextmenu_struct
EndFunc;contextmenuo_make()

func contextmenu_draw($contextmenu_struct, $xx, $yy)
	$redraw= 1
	_SDL_GetMouseState($mouse_x, $mouse_y)
	$oldcur= $contextmenu_struct.cur
	_SDL_SetAlpha($contextmenu_struct.cursurf, $_SDL_SRCALPHA, 55)
	_SDL_GetMouseState($mouse_x, $mouse_y)
	$contextmenu_struct.cur= -1
	for $i= 0 to ($contextmenu_struct.h-5)/$font.h-1
		if $mouse_x>= $xx+5 and $mouse_x<= $xx+$contextmenu_struct.w and $mouse_y>= $yy+5+$font.h*$i and $mouse_y<= $yy+5+$font.h*$i+$font.h then
			$contextmenu_struct.cur= $i
			exitloop
		endif
	next
	if $oldcur<> $contextmenu_struct.cur then
		$oldcur= $contextmenu_struct.cur
		$redraw= 1
	endif
	if $redraw= 1 then
		$redraw= 0
		$drect= _SDL_Rect_Create($xx, $yy, $contextmenu_struct.w, $contextmenu_struct.h)
		_SDL_BlitSurface($contextmenu_struct.surf, 0, $screen, $drect)
		if $contextmenu_struct.cur> -1 then
			$drect= _SDL_Rect_Create($xx, $yy+5+$font.h*$contextmenu_struct.cur, $contextmenu_struct.w, $font.h)
			_SDL_BlitSurface($contextmenu_struct.cursurf, 0, $screen, $drect)
		endif
		_SDL_Flip($screen)
	endif
	$redraw= 1
	return $contextmenu_struct.cur
EndFunc;contextmenuo_draw()