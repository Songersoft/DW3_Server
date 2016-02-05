#include-once
#include "SDL_Template v1.0.au3"

Global $tagFont_struct=		"ptr surf;"& _
							"int iW;"& _
							"int iH;"

Global $font= 0
Global $iFont_char_max= 95
Global $aFont_char[$iFont_char_max]
;Global $font_surf= 0
Global $sdlt_rectreturn= 0

func font_load($font_filepath)

	; Create dllFont Struct
	$dllFont= DllStructCreate($tagFont_struct)
	$file= fileopen($font_filepath); Open Font Description File
	if @error> 0 then
		msgbox(0, "Font Error", "Font Description File NOT FOUND "&@crlf&$font_filepath)
		return 1
	endif

	out($font_filepath)
	$sFont_bmp_filepath= stringreplace($font_filepath, ".txt", ".png", -1)
	; Replace '.txt.' with '.bmp' and Load the Font Surface BMP
	$dllFont.surf= _IMG_Load($sFont_bmp_filepath)
	if $dllFont.surf= 0 then
		msgbox(0, "Font Error", "Font Surface File NOT FOUND "&@crlf&$sFont_bmp_filepath)
		return 1
	endif
	_SDL_SetColorKey($dllFont.surf, $_SDL_SRCCOLORKEY, 0)

	$dllFont.iW= filereadline($file)
	$dllFont.iH= filereadline($file)
	fileclose($file)
	$iFont_char_max= 95
	$aFont_Char[0]= '0'
	$aFont_Char[1]= '1'
	$aFont_Char[2]= '2'
	$aFont_Char[3]= '3'
	$aFont_Char[4]= '4'
	$aFont_Char[5]= '5'
	$aFont_Char[6]= '6'
	$aFont_Char[7]= '7'
	$aFont_Char[8]= '8'
	$aFont_Char[9]= '9'
	$aFont_Char[10]= 'a'
	$aFont_Char[11]= 'b'
	$aFont_Char[12]= 'c'
	$aFont_Char[13]= 'd'
	$aFont_Char[14]= 'e'
	$aFont_Char[15]= 'f'
	$aFont_Char[16]= 'g'
	$aFont_Char[17]= 'h'
	$aFont_Char[18]= 'i'
	$aFont_Char[19]= 'j'
	$aFont_Char[20]= 'k'
	$aFont_Char[21]= 'l'
	$aFont_Char[22]= 'm'
	$aFont_Char[23]= 'n'
	$aFont_Char[24]= 'o'
	$aFont_Char[25]= 'p'
	$aFont_Char[26]= 'q'
	$aFont_Char[27]= 'r'
	$aFont_Char[28]= 's'
	$aFont_Char[29]= 't'
	$aFont_Char[30]= 'u'
	$aFont_Char[31]= 'v'
	$aFont_Char[32]= 'w'
	$aFont_Char[33]= 'x'
	$aFont_Char[34]= 'y'
	$aFont_Char[35]= 'z'
	$aFont_Char[36]= 'A'
	$aFont_Char[37]= 'B'
	$aFont_Char[38]= 'C'
	$aFont_Char[39]= 'D'
	$aFont_Char[40]= 'E'
	$aFont_Char[41]= 'F'
	$aFont_Char[42]= 'G'
	$aFont_Char[43]= 'H'
	$aFont_Char[44]= 'I'
	$aFont_Char[45]= 'J'
	$aFont_Char[46]= 'K'
	$aFont_Char[47]= 'L'
	$aFont_Char[48]= 'M'
	$aFont_Char[49]= 'N'
	$aFont_Char[50]= 'O'
	$aFont_Char[51]= 'P'
	$aFont_Char[52]= 'Q'
	$aFont_Char[53]= 'R'
	$aFont_Char[54]= 'S'
	$aFont_Char[55]= 'T'
	$aFont_Char[56]= 'U'
	$aFont_Char[57]= 'V'
	$aFont_Char[58]= 'W'
	$aFont_Char[59]= 'X'
	$aFont_Char[60]= 'Y'
	$aFont_Char[61]= 'Z'
	$aFont_Char[62]= '!'
	$aFont_Char[63]= '@'
	$aFont_Char[64]= '#'
	$aFont_Char[65]= '$'
	$aFont_Char[66]= '%'
	$aFont_Char[67]= '^'
	$aFont_Char[68]= '&'
	$aFont_Char[69]= '*'
	$aFont_Char[70]= '('
	$aFont_Char[71]= ')'
	$aFont_Char[72]= '-'
	$aFont_Char[73]= '+'
	$aFont_Char[74]= '_'
	$aFont_Char[75]= '='
	$aFont_Char[76]= ' '
	$aFont_Char[77]= '~'
	$aFont_Char[78]= "'"
	$aFont_Char[79]= ','
	$aFont_Char[80]= '.'
	$aFont_Char[81]= '?'
	$aFont_Char[82]= '/'
	$aFont_Char[83]= '\'
	$aFont_Char[84]= ':'
	$aFont_Char[85]= ';'
	$aFont_Char[86]= '>'
	$aFont_Char[87]= '<'
	$aFont_Char[88]= '['
	$aFont_Char[89]= ']'
	$aFont_Char[90]= '{'
	$aFont_Char[91]= '}'
	$aFont_Char[92]= '|'
	$aFont_Char[93]= '?'
	$aFont_Char[94]= '"'
	Return $dllFont

EndFunc;ofontload()

func print($output, $surf, $x, $y, $r= 240, $g= 240, $b= 240, $scale_w= 1, $scale_h= 1, $bkcolor= -1)

	$letter= 0
	$letters= stringlen($output)
	$surf1= _SDL_CreateRGBSurface($_SDL_SWSURFACE, $font.iW * $letters, $font.iH, 32, $r, $g, $b, 255)
	$surf2= 0
	$outputstring= stringsplit($output, "")

	for $i= 1 to $letters; Find pixel data of 'string output'

		for $ii= 0 to $iFont_char_max-1; Find pixel data offset of string char

			if asc($outputstring[$i])= asc($aFont_Char[$ii]) then

				$letter= $ii
				exitloop

			endif
		next
		$srect= _SDL_Rect_Create($letter*$font.iW, 0, $font.iW, $font.iH)
		$drect= _SDL_Rect_Create(($i-1)*$font.iW, 0, $font.iW, $font.iH)

		_SDL_BlitSurface($font.surf, $srect, $surf1, $drect)

	next

	$surf1w= 0
	$surf1h= 0

	if $scale_w<> 1 or $scale_h<> 1 then

		;$surf2= _SDL_CreateRGBSurface($_SDL_SWSURFACE, $font.iW*$letters*$scale_w, $font.iH*$scale_h, 32, $r, $g, $b, 255)

		;_SDL_SetColorKey($surf2, $_SDL_SRCCOLORKEY, 0)

		$surf2= _SDL_zoomSurface($surf1, $scale_w, $scale_h, 0)
		$srect= surf_size_get($surf2, $surf1w, $surf1h)
		$drect= _SDL_Rect_Create($x, $y, $surf1w, $surf1h)

		_SDL_SetColorKey($surf2, $_SDL_SRCCOLORKEY, 0)

		_SDL_BlitSurface($surf2, 0, $surf, $drect)

	else

		$srect= surf_size_get($surf1, $surf1w, $surf1h)
		$drect= _SDL_Rect_Create($x, $y, $surf1w, $surf1h)
		_SDL_BlitSurface($surf1, 0, $surf, $drect)

	endif;endif scale

	$sdlt_rectreturn= _SDL_Rect_Create($x, $y, $surf1w, $surf1h)
	_SDL_FreeSurface($surf1)
	_SDL_FreeSurface($surf2)
EndFunc;print()

func print2($output, $destsurf, $x, $y, $r= 240, $g= 240, $b= 240, $sw= 1, $sh= 1)

	$letters= stringlen($output)

	local $surfcx= 0, $surfcy= 0, $cx= $x, $cy= $y, $surfw= 0,$surfh= 0

	surf_size_get($destsurf, $surfw, $surfh)

	$surf= _SDL_CreateRGBSurface($_SDL_HWSURFACE, $letters*$font.iW*$sw, $font.iH*$sh, 32, 0, 0, 0, 255)

	_SDL_SetColorKey($surf, $_SDL_SRCCOLORKEY, 0)

	Local $lines= 1

	print($output, $surf, 0, 0, $r, $g, $b, $sw, $sh)

	for $i= 0 to $letters

		$srect= _SDL_Rect_Create($surfcx, 0, $font.iW*$sw, $font.iH*$sh)
		$drect= _SDL_Rect_Create($cx, $cy, $font.iW*$sw, $font.iH*$sh)

		_SDL_BlitSurface($surf, $srect, $destsurf, $drect)

		$surfcx+= $font.iW*$sw
		$cx+= $font.iW*$sh

		if $cx+$sw*$font.iW> $surfw then

			$cx= 0
			$cy+= $font.iH*$sh
			$lines+= 1

		endif

	next

	$sdlt_rectreturn= _SDL_Rect_Create($x, $y, $surfw, $lines*$font.iH)

	_SDL_FreeSurface($surf)

EndFunc;print2()