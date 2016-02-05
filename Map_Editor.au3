; Change to standard send recv packet format type
; Just always send player_source.  If you want to change it later fine.

#Region ;**** Directives created by AutoIt3Wrapper_GUI ****
#AutoIt3Wrapper_Icon=Settings\Map_Editor.ico
#EndRegion ;**** Directives created by AutoIt3Wrapper_GUI ****

Global $debug_songersoft = 0

If @Compiled = 0 Then
	; start other network app for testing
	;Run("E:\Programming\AutoIt\Dragon Warrior 3 Remake\Map_Editor\DW_Server.exe", "E:\Programming\AutoIt\Dragon Warrior 3 Remake\Map_Editor")
EndIf

Global $gScriptname = StringTrimRight(@ScriptName, 4)

Global $gVillian = "Dragon Lord"
Global $error_one = 0

OnAutoItExitRegister("_exit")

Global $default_value_max = 1
Enum $eDefault_value_area_ob_world
Global $aDefault_value[$default_value_max]

Global $gaGui_rect[4]
Global Enum $eInput, $eInput_numonly, $eInput_readonly, $eComboex_pic, $eButton

Global $world_max = 2 ; 0 Overworld, 1 Temp Sub World
Global $world_layer_max = 3, $world_x_max = 500, $world_y_max = 500
Global $world_info_data_max = 5 ; World_Info[][] Stores Dynamic Size of World
Enum $eWi_filename, $eWi_layers, $eWi_w, $eWi_h, $eWi_tiles;5
Global $world_info[$world_max][$world_info_data_max]

;
; Struct Global Declaration
; Defined in structure_setup()
Global $tagPerson_struct, $tagSun_struct, $tagBG_struct, $tagPlayer_struct, $tagWorld_struct

Global $tile_max = 255
Global $tile_w = 0, $tile_h = 0
Global $tiles_on_screen_w, $tiles_on_screen_h
Global $tile_cur = 0

Global $board_w = 0, $board_h = 0
Global $bg_w = 0, $bg_h = 0

; Area to segment world
Global $area_max = 60
Global Const $area_data_max = 11;x, y, w, h, outbounds_tile, outbounds_goto_world, outbounds_goto goto_x, goto_y, hotspots, items, people
Global Enum $eArea_x, $eArea_y, $eArea_w, $eArea_h, _						; Area World Bound Rect
		$eArea_ob_tile, $eArea_ob_world, $eArea_ob_x, $eArea_ob_y, _ 	; Out of Bounds Repeat Tile and World Destination if Out of Bounds
		$eArea_hotspots, $eArea_items, $eArea_people ; Total Hotspots per Area, Items and People

Global $folder_graphics = @ScriptDir & "\..\Graphics\"
Global $folder_worlds = @ScriptDir & "\..\Worlds\"
Global $folder_world_last_path = ""
Global $filter_pic = "BMP (*.BMP) | PNG (*.PNG) | GIF (*.GIF) | JPG(*.JPG)"

Global $control_data_max = 6
Global Enum $eControl_data, $eControl_label, $eControl_type, $eControl_tip, $eControl_data_val, $eControl_width

; Netplay
Global $gServer_ip = @IPAddress1
Global $gServer_port_base = 18000
Global $gServer_socket_id = 0; Probably only needed for early debug
Global $gServer_players = 0

Global $gClient_connected = 0

; Socket
Global $gSocket_max = 8
Global $gSocket_data_max = 5
Global Enum $eSocket, $eSocket_connected_sequence, $eSocket_disconnected_sequence, $eSocket_chat_sequence, $eSocket_ack_bits

Global $gaSocket_send[$gSocket_data_max]
Global $gaSocket_recv[$gSocket_data_max]

; Stores server infomation regarding players
Global $eServer_player_chat_sequenece
Global $eServer_player_data_max = 1
Global $gaServer_player[$gSocket_max][$eServer_player_data_max]



; I think I switch these for client and server
Global Enum $eSocket_open_method_open, $eSocket_open_method_bind

; Global Timeouts
Global $gDownload_players_timer = 0
Global $gDownload_players_timer_len = 1000 * 4

Global $gServer_timeout = 0
Global $gServer_timeout_len = 30

Global $gSocket_join_timeout = 0
Global $gSocket_join_timeout_len = 1000 * 6

Global $gNet_sequence_frame = 0
Global $gNet_sequence_frame_max = 99
Global $gNet_sequence_frame_recieved_last = -1

;Global $gLast_joined_timeout= 1000*20
Global $gLast_joined_sequence_frame = -1

;$packet_data = $gPacket_key & $gPacket_Seporator & _						; 1 Key
;			$gSequence_frame & $gPacket_Seporator & _ 	 					; 2 Sequence Frame
;			$iPlayer_source & $gPacket_Seporator & _	 					; 3 Player Source
;			$gaPlayer[$iPlayer_source][$ePlayer_x] & $gPacket_Seporator & _	; 4 X
;			$gaPlayer[$iPlayer_source][$ePlayer_y] & $gPacket_Seporator & _	; 5 Y
;			$iCommand_type & $gPacket_Seporator								; 6 Command Type

Global $gNet_command_data_max = 10
Global $gNet_connections = 0

Global $gNet_connection_timeout_len = 1000 * 10

; Net Role, None, Client, Server
Enum $eNet_role_private, $eNet_role_client, $eNet_role_server
Global $gNet_role = $eNet_role_private

; Stores Indexs of connected players
Global $gaPlayer_indexs[$gSocket_max]

; Packet Compose
; ---------------
; ATH CODE: This is fixed so can be stripted without seporator
; Packet Id: Packets need sent more than once, use this number to react only once to specific packet
; Instruction Type
;

; Example: DW;PKT_ID;TYPE;TYPE DATA..

Global $gPacket_Seporator = ";"
Global $gPacket_key = "DW"; Code to specify signal is for our netplay and not random
Global $gPacket_ack_max = 60

Global $aPacket_ack[$gSocket_max][$gPacket_ack_max]
Global $aPacket_ack_remote[$gSocket_max][$gPacket_ack_max]

; Packet CMD Types
Global Enum $eNet_cmd_type_change_tile_world, $eNet_cmd_type_change_tile_layer, $eNet_cmd_type_change_tile_x, $eNet_cmd_type_change_tile_y
;Global $aNet_player[$gNet_socket_max][$aNet_data_max]

Global $gsNet_join = 'hiya'

Enum $ePacket_header_read_data_num, _		; data num
		$ePacket_header_read_key, _				; Key
		$ePacket_header_read_sequence, _		; Sequence
		$ePacket_header_read_player_source, _	; Player source
		$ePacket_header_read_x, _				; X
		$ePacket_header_read_y, _				; Y
		$ePacket_header_read_type _				; Type

Enum $ePacket_header_send_data_num, _
		$ePacket_header_send_key, _
		$ePacket_header_send_sequence, _
		$ePacket_header_send_type, _
		$ePacket_header_send_x, _
		$ePacket_header_send_y

; Packet Types:
Enum $ePacket_type_pos, _
		$ePacket_type_connect_port = 200, _
		$ePacket_type_connect_player = 201, _
		$ePacket_type_disconnect_player = 202, _
		$ePacket_type_chat = 203, _
		$ePacket_type_download_players = 205

; Player Info Packet
Enum $ePacket_player_info_x = 3, $ePacket_player_info_y, $ePacket_player_info_world, _
		$ePacket_player_info_name, _
		$ePacket_player_info_lvl, _
		$ePacket_player_info_class, _
		$ePacket_player_info_xp, _
		$ePacket_player_info_gold

Global $playerNet_data_max = 8
Enum $ePlayerNet_x = 1, $ePlayerNet_y, $ePlayerNet_world, $ePlayerNet_name, $ePlayerNet_class, $ePlayerNet_lvl, $ePlayerNet_gold, $ePlayerNet_xp
Global $gaPlayerNet[$gSocket_max][$playerNet_data_max]

; Net Chat
Global $gChat_console_open = 0
Global $gChat_window_surf = Null
Global $gChat_window_drect = 0
Global $gChat_window_edit = 0
Global $gChat_window_edit_text = ""

Global $gChat_send_packets = 15

Global $player_class_chosen= 0

#include "Include\SDL_Template v1.0.au3"
#include "Include\loaddialog.au3"
#include "Include\TTS.au3"; Author: Beege, text to speach
#include <include\Bass.au3\Bass\Bass.au3>
#include <Color.au3>
#include <GUIConstantsEx.au3>; Defines gui_event_close
#include <file.au3>; Defines FO_OVERWRITE
#include <GuiImageList.au3>

;#include "BinaryImage.au3"
#include "GDIPlus.au3"
;opt("MustDeclareVars", 1)

; Misc Global
Global $player_base_movement_speed = 4

; Setup Structures
Global $player_item_max = 8
Global $player_item_data_max = 5
Global Enum $ePlayer_item_id, $ePlayer_item_quanity, $ePlayer_item_durability, $ePlayer_item_mod_1, $ePlayer_item_mod_2
Global $aPlayer_item[$player_item_max][$player_item_data_max]

Global $gaPlayerNet_items[$gSocket_max][$player_item_max][$player_item_data_max]

Global $player_name_len_max = 32

structure_define()

; Console
Global $gConsole_log_path = @ScriptDir & "\Settings\" & $gScriptname & "_Console_log.txt"
Global $gConsole_surf = 0
Global $gConsole_text_surf = 0
Global $gConsole_print_rect = 0

Global $gConsole_show = 0
Global $gConsole_show_timeout = 8000
Global $gConsole_timer
Global $gConsole_cursor = 0
;Global $gConsole_text_height= 25
Global $gConsole_text_pad_y = 5
Global $gConsole_line_max = 12
Global $gConsole_height = 0; Set in Main

FileDelete($gConsole_log_path); Fresh Log file

; Sound
Global $gSound_cur = 0
Global $gSound_max = 16
Global $gaSound[$gSound_max]
Global $gSounds_path = @ScriptDir & "\..\Sounds\"

; sun_alpha[][2] Set the level of sun alpha and the sun ticks to set next alpha
Global $aSun_alpha = [[0, 1], [100, 15], [200, 15], [255, 6]]
Global $aSun_alpha_max = UBound($aSun_alpha); Set max sun level indexs
Global $dw3_player_class_max = 8

Enum $ePlayer_class_hero, _
	 $ePlayer_class_wizard, _
	 $ePlayer_class_pilgrim, _
	 $ePlayer_class_sage, _
	 $ePlayer_class_soldier, _
	 $ePlayer_class_merchant, _
	 $ePlayer_class_fighter, _
	 $ePlayer_class_goofoff

Global $dw3_player_class_name[$dw3_player_class_max]
$dw3_player_class_name[$ePlayer_class_hero] = "Hero"
$dw3_player_class_name[$ePlayer_class_wizard]= "Wizard"
$dw3_player_class_name[$ePlayer_class_pilgrim]= "Pilgrim"
$dw3_player_class_name[$ePlayer_class_sage]= "Sage"
$dw3_player_class_name[$ePlayer_class_soldier]= "Soldier"
$dw3_player_class_name[$ePlayer_class_merchant]= "Merchant"
$dw3_player_class_name[$ePlayer_class_fighter]= "Fighter"
$dw3_player_class_name[$ePlayer_class_goofoff]= "Goof-off"

Global $person_surf; Person Surfaces

; HotSpot
Global Enum $eHSpot_iX, $eHSpot_iY, $eHSpot_sDest_world_file, $eHSpot_iDest_x, $eHSpot_iDest_y
Global $hotspot_max = 50, $hotspot_data_max = 5

; Item
Global $item_max = 128 + 1
Global $item_data_max = 3
Global $item[$item_max][$item_data_max]; [+1 to store n at zero][name, amount defence or attack, special]

Global Enum $eItem_name, $eItem_attordef, $eItem_special
items_define(); HARD CODED DEFAULT list of Item Data

settings_load(); Restores window position

Global $menu_max = 9
Global $voice_obj = _StartTTS(); A voice object

_BASS_STARTUP("BASS.dll")

;Initalize bass.  Required for most functions.
_BASS_Init(0, -1, 44100, 0, "")

main()

Func main()

	; Create Global Dialog Window
	;$ghGui = GUICreate(@ScriptName, 1400, 800, $gaGui_rect[0], $gaGui_rect[1])
	$ghGui = GUICreate(@ScriptName, 700, 400, $gaGui_rect[0], $gaGui_rect[1])
	$gaGui_rect = WinGetPos($ghGui); Returns Array x, y, w, h of the GUI Window Rect

	; Menus and Menu Items
	Enum $eMenu_view, $eMenu_board, $eMenu_tile, $eMenu_world, $eMenu_area, $eMenu_hotspot, $eMenu_item, $eMenu_netplay, $eMenu_settings; 8
	Local $aMenu[$menu_max]

	; View
	$aMenu[$eMenu_view] = GUICtrlCreateMenu("View")
	Local $menu_view_sun_toggle = GUICtrlCreateMenuItem("Sun Toggle", $aMenu[$eMenu_view]); Toggle the Drawing Sun Layer
	Local $menu_view_center_line_toggle = GUICtrlCreateMenuItem("Center Lines Toggle", $aMenu[$eMenu_view]); Toggles Center Lines

	; Board
	$aMenu[$eMenu_board] = GUICtrlCreateMenu("Board")
	Local $menu_board_size_set = GUICtrlCreateMenuItem("Board Size", $aMenu[$eMenu_board])

	; Tile
	$aMenu[$eMenu_tile] = GUICtrlCreateMenu("Tile")
	Local $menu_tile_scale = GUICtrlCreateMenuItem("Scale", $aMenu[$eMenu_tile]); Scale All Tiles
	Local $menu_tile_scale_file = GUICtrlCreateMenuItem("Scale File", $aMenu[$eMenu_tile])
	Local $menu_tile_replace_color = GUICtrlCreateMenuItem("Replace Color", $aMenu[$eMenu_tile])
	Local $menu_tile_swap_id = GUICtrlCreateMenuItem("Swap ID", $aMenu[$eMenu_tile]); Swap Tile
	Local $menu_tile_save = GUICtrlCreateMenuItem("Save", $aMenu[$eMenu_tile]); Tile Save
	Local $menu_tile_randomize_x_y = GUICtrlCreateMenuItem("Randomize Tile X_Y", $aMenu[$eMenu_tile]); Randomize Tile

	; Runtime
	Local $x = 0
	Local $msg = 0
	Local $hGui2 = 0
	Local $backup_aArea = 0
	Local $layer = 0
	Local $tile_rect = 0
	Local $camera_old_x = 0
	Local $camera_old_y = 0
	Local $srect = 0
	Local $drifter_x = 0
	Local $drifter_y = 0
	Local $drect = 0
	Local $confirm = 0
	Local $timer = 0

	; World
	$aMenu[$eMenu_world] = GUICtrlCreateMenu("World")
	$x = GUICtrlCreateMenu("World Layer", $aMenu[$eMenu_world])
	Local $menu_world_save_all_layers = GUICtrlCreateMenuItem("Save All World Layers", $x); Save All Layers
	Local $menu_world_save_layer = GUICtrlCreateMenuItem("Save World Layer", $x); Save Layer
	Local $menu_world_load_layer = GUICtrlCreateMenuItem("Load World Layer", $x); Load Layer
	$x = GUICtrlCreateMenu("World Area", $aMenu[$eMenu_world])
	Local $menu_world_area_save = GUICtrlCreateMenuItem("Save World Area File", $x); Save Area
	Local $menu_world_area_load = GUICtrlCreateMenuItem("Load World Area File", $x)
	Local $menu_world_manage_layers = GUICtrlCreateMenuItem("Manage World Layers", $aMenu[$eMenu_world]); Empty Layer
	Local $menu_world_find_replace = GUICtrlCreateMenuItem("Find and Replace", $aMenu[$eMenu_world])

	; Area
	$aMenu[$eMenu_area] = GUICtrlCreateMenu("Area")
	Local $menu_area_set = GUICtrlCreateMenuItem("Set Area", $aMenu[$eMenu_area])
	Local $menu_area_impose_toggle = GUICtrlCreateMenuItem("Area Impose", $aMenu[$eMenu_area])

	; Hotspot
	$aMenu[$eMenu_hotspot] = GUICtrlCreateMenu("Hotspot")
	Local $menu_hotspot_set = GUICtrlCreateMenuItem("Hotspot Set", $aMenu[$eMenu_hotspot])

	; Item
	$aMenu[$eMenu_item] = GUICtrlCreateMenu("Item")
	Local $menu_item_edit = GUICtrlCreateMenuItem("Insert / Edit Items in World", $aMenu[$eMenu_item]);

	; Netplay
	$aMenu[$eMenu_netplay] = GUICtrlCreateMenu("Netplay")
	Local $menu_netplay_client = GUICtrlCreateMenuItem("Client", $aMenu[$eMenu_netplay]);

	; Settings
	$aMenu[$eMenu_settings] = GUICtrlCreateMenu("Settings")
	Local $menu_settings_default = GUICtrlCreateMenuItem("Default Values", $aMenu[$eMenu_settings]); Default Settings

	; SDL Window
	If $debug_songersoft = 0 Then EnvSet("SDL_WINDOWID", $ghGui); Remark this to create AutoIt window and recieve error messages from AutoIt
	GUISetState(); Shows the Last GUI Created, See it starts out hidden :( But knowing is 1/2 the battle :)

	sound_play("windowopen.wav")

	Local $center_lines_draw = 1
	SDL_Template_init(@ScriptDir & "\..\Graphics\fonts\qbasic_font1.txt")

	; Player
	Local $players = 1
	Local $aPlayer = player_create_struct($players, 0, 0, $gaGui_rect[2], $gaGui_rect[3], 0, 0);	Player

	; Area
	Local $aArea[$world_max][$area_max][$area_data_max]
	Local $iArea_point = 0

	; World Array + tile + area
	Local $aTile[$world_max][$tile_max]
	Local $aWorld[$world_max][$world_layer_max][$world_x_max][$world_y_max]
	world_area_load($aWorld, $aTile, $aArea, 0, $folder_graphics & "DW3\Overworld\");	World Array
	world_area_load($aWorld, $aTile, $aArea, 1, $folder_graphics & "DW3\Aliahan\");	World Array

	$aPlayer[0].iWorld_cur = 1

	surf_size_get($aTile[0][0], $tile_w, $tile_h);														Record the size of tile[0]

	Local $aBoard[$world_layer_max];																	World[i][][] Data is Drawn to Board[i]

	board_create($aBoard, 2, $tile_w * 80, $tile_h * 80)

	; Console overlay
	$gConsole_height = $font.iH * 2 * $gConsole_line_max + (($gConsole_line_max) * $gConsole_text_pad_y)

	$gConsole_text_surf = _SDL_CreateRGBSurface($_SDL_SRCCOLORKEY, $gaGui_rect[2] - 15, $gConsole_height, 32, 0, 0, 0, 255)

	$gConsole_surf = _SDL_CreateRGBSurface($_SDL_SRCCOLORKEY, $gaGui_rect[2] - 15, $gConsole_height, 32, 0, 0, 0, 255)

	_SDL_SetColorKey($gConsole_text_surf, $_SDL_SRCCOLORKEY, 0) ; Set Colorkey

	_SDL_FillRect($gConsole_surf, 0, _SDL_MapRGB($screen, 10, 10, 10)); Clear Console

	_SDL_SetAlpha($gConsole_surf, $_SDL_SRCALPHA, 100)

	; Selection Surf
	Local $selection_surf = _SDL_DisplayFormat($aBoard[0])
	_SDL_SetAlpha($selection_surf, $_SDL_SRCALPHA, 150);				Surface to Show Area Selection

	board_draw($aBoard, $aWorld, $aTile, $aPlayer[0]);					Draw Board

	; Sun Shit
	Local $sun_layer = DllStructCreate($tagSun_struct)
	$sun_layer.surf = _SDL_CreateRGBSurface($_SDL_SRCCOLORKEY, $gaGui_rect[2], $gaGui_rect[3], 32, 0, 0, 0, 255)
	$sun_layer.iTimer_max = 1000 * 2
	$sun_layer.fAlpha_incroment = 10
	$sun_layer.bSun_off = 1

	$aSun_alpha_max = UBound($aSun_alpha); Set max sun level indexs

	_SDL_SetAlpha($sun_layer.surf, $_SDL_SRCALPHA, $sun_layer.fAlpha)

	; BG Surf ---------------------------------------------- Background Surf ------ Water
	Local $BG_struct = DllStructCreate($tagBG_struct)
	BG_setup($BG_struct, 50, 3); 											Redraw Tick Rate Set Here
	Local $BGrect = _SDL_Rect_Create(0, 0, $gaGui_rect[2], $gaGui_rect[3])
	Local $BGrect_go = BG_setup_rect_way_go()

	Local $apBG[1]
	$apBG[0] = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $gaGui_rect[2] + $tile_w, $gaGui_rect[3] + $tile_h, 32, 0, 0, 0, 255)
	tile_fill_surface($folder_graphics & "DW3\Overworld\Tiles\water.bmp", $apBG[0])
	Local $bg_w = 0, $bg_h = 0
	surf_size_get($apBG[0], $bg_w, $bg_h)

	Local $redraw = 1
	Local $temp_x, $temp_y

	$tiles_on_screen_w = $gaGui_rect[2] / $tile_w
	out("tiles_on_screen_w: " & $tiles_on_screen_w & " " & $tiles_on_screen_h)
	If Mod($tiles_on_screen_w, $tile_w) > 0 Then $tiles_on_screen_w = Int($tiles_on_screen_w) + 1
	$tiles_on_screen_w = $tiles_on_screen_w / 2
	$tiles_on_screen_w = Int($tiles_on_screen_w * 2)

	$tiles_on_screen_h = $gaGui_rect[3] / $tile_h

	$tiles_on_screen_h = $tiles_on_screen_h / 2
	If Mod($tiles_on_screen_h, $tile_h) > 0 Then $tiles_on_screen_h = Int($tiles_on_screen_h) + 1
	$tiles_on_screen_h = $tiles_on_screen_h * 2

	out("tiles_on_screen: " & $tiles_on_screen_w & " " & $tiles_on_screen_h)

	Local $player_way = 0
	Local $player_frame = 0

	; Sprite_sheet_create()
	Local $player_sprite = sprite_sheet_load(16, 16, $folder_graphics & "dw3\sprites\dw3_sprite_sheet.bmp")
	Local $player_sprite_animation_timer = TimerInit()
	Local $player_sprite_animation_timer_len = 600;200

	; Add People
	$person_surf = sprite_sheet_load(16, 16, $folder_graphics & "dw3\sprites\person_sprite_sheet.bmp")

	Local $aWorld_point = [0, 0], $target_layer = 0
	Local $aWorld_point_old = $aWorld_point, $target_old_layer = $target_layer

	; Area
	Local $area_set_point_1 = [-1, -1], $area_set_point_2 = [-1, -1]
	Local $area_edit_cur = 0
	Local $area_cur = 0
	Local $area_impose = 0

	; Hotspot
	Local $aHotspot[$world_max][$area_max][$hotspot_max][$hotspot_data_max]
	Local $hotspot_list_cur = 0
	Local $hotspot_dest_last_x = -1, $hotspot_dest_last_y = -1
	Local $aHotspot_list[$hotspot_max * $area_max + 1][$hotspot_data_max]

	; Windows
	Local $win_max = 1
	Local $win[$win_max];								 LABEL_LEN + DATA_LEN 21
	$win[0] = window_make(1, $gaGui_rect[2] - 320, 10, $font.iW * (16 + 21), 180, 180); Make Window

	; Network
	Local $sReceived = ""
	Local $packet = Null

	;Func window_print_set_rect($sLabel, $window, $x, $y, $chr_w, $chr_h= $font.iH, $iControl_type = 0, $r= 255, $g=255, $b=255, $scale_x = 1, $scale_y= 1)
	; Main Variable Output Window
	Local $iRect_tile_cur, $iRect_world_x, $iRect_world_source, $iRect_camera, $iRect_board_world, $iRect_world_cur, $iRect_world_w, $iRect_world_target, $iRect_world_filename

	$iRect_connected = window_print_set_rect("", $win[0], 5, 0, 16, 4, 0, 0, 255, 0) ; Online connected 'x'
	$iRect_tile_cur = window_print_set_rect("Tile_cur: ", $win[0], 5, $font.iH, 10) ; Tile_cur
	$iRect_world_source = window_print_set_rect("Source Layer X Y: ", $win[0], 5, 5 + $font.iH * 2, 10) ; World Source Sample target
	$iRect_world_target = window_print_set_rect("Target Layer X Y: ", $win[0], 5, 5 + $font.iH * 3, 10) ; World Target

	print("Player:", $win[0].surf, 5, 5 + $font.iH * 4) ; Player Label

	$iRect_world_x = window_print_set_rect("World_x: ", $win[0], 5, 5 + $font.iH * 5, 10) ; World X
	$iRect_camera = window_print_set_rect("camera_x: ", $win[0], 5, 5 + $font.iH * 6, 21) ; Cameria
	$iRect_board_world = window_print_set_rect("Board_world_x: ", $win[0], 5, 5 + $font.iH * 7, 21) ; World_Board_x
	$iRect_world_cur = window_print_set_rect("world_cur: ", $win[0], 5, 5 + $font.iH * 8, 21) ; World_cur
	$iRect_world_w = window_print_set_rect("  Width: ", $win[0], 5, 5 + $font.iH * 9, 21) ; World_w
	$iRect_world_filename = window_print_set_rect("  World_filename: ", $win[0], 5, 5 + $font.iH * 10, 21) ; World_filename

	window_drawbackup($win[0]); Draw Window Backup

	; Window Startup Data
	window_print($aPlayer[0].iWorld_cur, $win[0], $iRect_world_cur)
	window_print($world_info[$aPlayer[0].iWorld_cur][$eWi_w] & " " & $world_info[$aPlayer[0].iWorld_cur][$eWi_h] & " " & $world_info[$aPlayer[0].iWorld_cur][$eWi_tiles], $win[0], $iRect_world_w)
	window_print($world_info[$aPlayer[0].iWorld_cur][$eWi_filename], $win[0], $iRect_world_filename)
	; DONE: Output Window

	; Extra Window Type
	Local Enum $eControl_window_none, $eControl_window_area, $eControl_window_hotspot; One window at a time felles
	Local $control_window_type = $eControl_window_none

	Local $aControl_gui2
	Local $moving = 0
	Local $world_layer_target = 0

	Local $client_send_timer = TimerInit()
	Local $client_send_timer_len = 499

	Local $client_recv_timer = TimerInit()
	Local $client_recv_timer_len = 399

	UDPStartup(); Network Startup

	; Clear Item List
	item_list_clear($aPlayer_item)

	; Chat
	chat_console_create()

	Enum $eChat_window_surf, $eChat_window_rect, $eChat_window_edit
	Local $aChat_window_console[3]
	Local $iChat_sequence_frame = 0

	Local $connected_to_server = 0
	Local $udp_send_player_info_packets = 2

	Local $aDownload_player[$gSocket_max]

	;$gChat_window_surf= _SDL_CreateRGBSurface($_SDL_SWSURFACE, $window_width, $window_height, 32, 0, 0, 0, 255)
	;$gChat_window_drect= _SDL_Rect_Create($window_margin_x, $gaGui_rect[3]- ($window_height + 50), $window_width, $window_height)
	;$gChat_window_edit= GUICtrlCreateEdit("", 15, -200, 200, 50)

	;client_test_start()

	Do; Main Loop

		Switch $gNet_role

			Case $eNet_role_private

			Case $eNet_role_client

				; Send to Server
				If TimerDiff($client_send_timer) > $client_send_timer_len Then

					client_send($aPlayer[0])

					$client_send_timer = TimerInit()

				EndIf

				If TimerDiff($client_recv_timer) > $client_recv_timer_len Then

					; Recieve from Server
					$gNet_role = client_recv()

					; Disconnect
					If $gNet_role = $eNet_role_private Then

						; Tell Server we're through, it's over
						client_send_spears($aPlayer[0], $ePacket_type_disconnect_player)

						; Close Sockets
						UDPCloseSocket($gaSocket_send[$eSocket])
						UDPCloseSocket($gaSocket_recv[$eSocket])

						; Reset dropout counter
						$gClient_connected = 0

						; Mark is NOT Connected on win[0]
						window_connect_server_display($win[0], $iRect_connected, $gNet_role)

					EndIf

					$client_recv_timer = TimerInit()

				EndIf

		EndSwitch

		If TimerDiff($BG_struct.fFrame_timer) > $BG_struct.iFrame_timer_max Then; Update Water Frame

			BG_animate($BG_struct, $BGrect, $BGrect_go)

			$redraw = 1

		EndIf

		If $sun_layer.bSun_off = 0 Then

			sun_adjust_light($sun_layer)

		EndIf

		If WinActive($ghGui) Or $debug_songersoft = 1 Then

			; GUI Event Messages
			If $control_window_type = $eControl_window_none Then

				$msg = GUIGetMsg(); Returns GUI Dialog events
				Switch $msg

					Case $menu_netplay_client

						; Toggle off
						$gNet_role = $eNet_role_private

						; Stop timeout
						$gServer_timeout = 0

						$confirm = player_create_dialog($aPlayer[0], $player_sprite, $person_surf)

						if $confirm then

							; Client Connect
							$connected_to_server = client_connect()

						EndIf; confirm

						If $connected_to_server = 1 Then

							; Assign Net Role as Client
							$gNet_role = $eNet_role_client

							$x = packet_player($aPlayer[0], $aPlayer_item)
							out("player packet: " & $x)

							; Upload the Player Information to Server
							For $i = 0 To $udp_send_player_info_packets - 1

								UDPSend($gaSocket_send[$eSocket], $x)

							Next

							; Clear
							For $i = 0 To $gSocket_max - 1

								$aDownload_player[$i] = 0

							Next

							$gDownload_players_timer = TimerInit()

							$x = 0

							; Download other players from server
							Do; $i = 0 to $udp_send_player_info_packets-1

								; Get packet
								$recv = UDPRecv($gaSocket_recv[$eSocket], 1024)

								$aRecv = StringSplit($recv, $gPacket_Seporator)

								If $aRecv[$ePacket_header_read_data_num] >= $ePacket_header_read_type Then

									If $aRecv[$ePacket_header_read_key] = $gPacket_key Then; key

										If $aRecv[$ePacket_header_read_type] = $ePacket_type_download_players Then; type download_players

											$player_index = $aRecv[$ePacket_header_read_player_source]

											out("player_index: " & $player_index)

											If $aDownload_player[$player_index] = 0 Then

												$aDownload_player[$player_index] = 1

												For $ii = 1 To $playerNet_data_max - 1

													$gaPlayerNet[$player_index][$ii] = $aRecv[$ePacket_header_read_type + $ii]

												Next

												$gaPlayer_indexs[$x] = $player_index

												;MsgBox(0, @ScriptName, "server players: "&$gServer_players)

												;_ArrayDisplay($gaPlayerNet)

												$x += 1

												If $x >= $gServer_players Then

													; Leave before timeout
													ExitLoop

												EndIf

											EndIf

										EndIf; packet_type_download_players

									EndIf; has key

								EndIf; enough packet seporators

							Until TimerDiff($gDownload_players_timer) >= $gDownload_players_timer_len

							; Mark is Connected on win[0]
							window_connect_server_display($win[0], $iRect_connected, $connected_to_server)

						EndIf; connected_to_server

					Case $menu_item_edit


					Case $menu_hotspot_set

						; Create List
						$aHotspot_list[0][0] = hotspot_area_to_list($aArea, $aHotspot, $aHotspot_list, $aPlayer[0]); Convert aHotspot Sorted by Area to List
						$hGui2 = gui_hotspot_create($aControl_gui2, $aArea, $aHotspot_list, $aPlayer[0]); Setup Window
						; Startup Hotspot Data
						$control_window_type = $eControl_window_hotspot; Set Window Type to Hotspot
						$hotspot_list_cur = $aHotspot_list[0][0];		Cur Hotspot in List Set to Max

					Case $menu_area_set; 							Area Set

						$control_window_type = $eControl_window_area;	Turn On Window
						$iArea_point = 0;								Points Set On New Area
						$backup_aArea = $aArea;							Backup InCase Undo? Maybe Fix
						_SDL_FillRect($selection_surf, 0, 0);			Clear Selection Board Surface
						$area_cur = $aArea[$aPlayer[0].iWorld_cur][0][0]; Set cur to Max
						$aArea[$aPlayer[0].iWorld_cur][$area_cur][$eArea_ob_world] = $aDefault_value[$eDefault_value_area_ob_world]; Set Area Outbounds_World to Default Value
						$hGui2 = gui_area_create($aControl_gui2, $aArea, $aTile, $aPlayer[0], $aArea[$aPlayer[0].iWorld_cur][0][0])

					Case $menu_area_impose_toggle; Area_impose Toggle

						If $area_impose = 0 Then

							$area_impose = 1
							board_draw_area($aBoard, $aWorld, $aTile, $aPlayer[0], $aArea, 1)

						Else

							$area_impose = 0

						EndIf

					Case $menu_board_size_set; User Set Board Size

						$temp_x = gui_board_size_set($aBoard, $world_info[$aPlayer[0].iWorld_cur][$eWi_layers])
						If $temp_x = 1 Then board_draw($aBoard, $aWorld, $aTile, $aPlayer[0])

					Case $menu_view_center_line_toggle

						If $center_lines_draw = 0 Then

							$center_lines_draw = 1

						Else

							$center_lines_draw = 0

						EndIf

					Case $menu_view_sun_toggle; Toggle Sun Alpha Surface ON / OFF

						If $sun_layer.bSun_off = 0 Then
							$sun_layer.bSun_off = 1
						Else
							$sun_layer.bSun_off = 0
						EndIf;(0_o)

					Case $menu_tile_swap_id; Swap Tile Indexs

						If tile_swap_id_select($aTile, $aWorld, $aPlayer[0]) = 1 Then board_draw($aBoard, $aWorld, $aTile, $aPlayer[0])

					Case $menu_tile_scale; Scale Tiles

						tile_scale_array($aTile, 2, 2, $aPlayer[0]); Double Size of All Tiles
						surf_size_get($aTile[$aPlayer[0].iWorld_cur][0], $tile_w, $tile_h); Record the New Size of a Tile
						; Free and Re-create BG surf
						_SDL_FreeSurface($apBG[0])
						$apBG[0] = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $gaGui_rect[2] + $tile_w, $gaGui_rect[3] + $tile_h, 32, 0, 0, 0, 255)
						tile_fill_surface($folder_graphics & "DW3\Overworld\Tiles\water.bmp", $apBG[0])

					Case $menu_tile_scale_file

						file_scale()

					Case $menu_tile_replace_color

						tile_replace_color($aTile, $aPlayer[0])

					Case $menu_tile_save

						tile_save($aTile, $aPlayer[0])

					Case $menu_tile_randomize_x_y

						gui_world_random_tile_x_y($aWorld, $aPlayer[0], $aTile)

					Case $menu_world_find_replace

						world_find_replace($aWorld, $aTile, $aPlayer[0])

						board_redraw($aBoard, $aWorld, $aTile, $aPlayer[0], $aArea, $win, $area_impose)

						window_print($aPlayer[0].iBoard_world_x & " " & $aPlayer[0].iBoard_world_y, $win[0], $iRect_board_world)
						window_print($aPlayer[0].iX & " " & $aPlayer[0].iY, $win[0], $iRect_world_x)
						window_print(StringFormat("%.2f", $aPlayer[0].fCamera_X) & " " & StringFormat("%.2f", $aPlayer[0].fCamera_y), $win[0], $iRect_camera)

					Case $menu_world_save_layer

						$layer = InputBox("Enter Layer", "Enter Layer of World to Save", "", Default, Default, Default, Default, Default, Default, $ghGui)

						If $layer > -1 And $layer < $world_info[$aPlayer[0].iWorld_cur][$eWi_layers] Then

							world_save_layer($aWorld, $layer, $aTile, $aPlayer[0])

						Else

							MsgBox(0, "Outbounds", "Layer " & $layer & " does NOT Exist", Default, $ghGui)

						EndIf

					Case $menu_world_save_all_layers

						For $i = 0 To $world_info[$aPlayer[0].iWorld_cur][$eWi_layers] - 1

							world_save_layer($aWorld, $i, $aTile, $aPlayer[0], $folder_graphics & $world_info[$aPlayer[0].iWorld_cur][$eWi_filename] & $i & ".txt")

						Next

					Case $menu_world_load_layer

						$layer = InputBox("Enter Layer", "Enter Layer of World to Load to", "", Default, Default, Default, Default, Default, Default, $ghGui)

						If $layer > -1 And $layer < $world_info[$aPlayer[0].iWorld_cur][$eWi_layers] Then

							world_load_layer($aWorld, $aPlayer[0], $layer)

						Else

							MsgBox(0, "Outbounds", "Layer " & $layer & " does NOT Exist", Default, $ghGui)

						EndIf

					Case $menu_world_area_load

						world_area_load($aWorld, $aTile, $aArea, 0)

					Case $menu_world_area_save

						world_area_save($aWorld, $aTile, $aArea, $aHotspot, $aPlayer[0])

					Case $menu_world_manage_layers

						world_manage_layers($aWorld, $aTile, $aPlayer[0])

					Case $menu_settings_default

						settings_default_values_edit()

				EndSwitch;msg

				If _IsPressed(2) Then; Mouse Right Click

					; Places Tile_cur in world and immediately updates the board surface
					$aWorld_point = world_mouse_pos($aWorld, $aPlayer[0])

					If world_range($aWorld_point, $aPlayer[0]) Then

						world_tile_set($aWorld, $world_layer_target, $aWorld_point[0], $aWorld_point[1], $tile_cur, $aPlayer[0])
						world_tile_draw($aBoard, $aTile, $aPlayer[0], $aWorld, $aWorld_point[0], $aWorld_point[1])

					EndIf

					window_print($world_layer_target & " " & $aWorld_point[0] & " " & $aWorld_point[1], $win[0], $iRect_world_target)

				EndIf

				If _IsPressed(46) Then; F Insert Forground Tile

					; Places Tile_cur in world and immediately updates the board surface
					$aWorld_point = world_mouse_pos($aWorld, $aPlayer[0])

					If world_range($aWorld_point, $aPlayer[0]) Then

						world_tile_set($aWorld, 1, $aWorld_point[0], $aWorld_point[1], $tile_cur, $aPlayer[0])
						world_tile_draw($aBoard, $aTile, $aPlayer[0], $aWorld, $aWorld_point[0], $aWorld_point[1])

					EndIf

					window_print($world_layer_target & " " & $aWorld_point[0] & " " & $aWorld_point[1], $win[0], $iRect_world_target)

				EndIf

				If _IsPressed(11) Then; CTRL Down

					If _IsPressed('4d') Then; Map

						map_draw($aWorld, 0, $aTile, $aPlayer[0])

						$redraw = 1

					EndIf

					If _IsPressed('6D') Then; numpad - world_cur -

						player_world_cur_switch($aPlayer[0], -1)

						window_print($aPlayer[0].iWorld_cur, $win[0], $iRect_world_cur)
						window_print($world_info[$aPlayer[0].iWorld_cur][$eWi_filename], $win[0], $iRect_world_filename)
						board_draw($aBoard, $aWorld, $aTile, $aPlayer[0])
						keyreleased('6D')

					EndIf

					If _IsPressed('6B') Then; numpad + world_cur +

						player_world_cur_switch($aPlayer[0], +1)

						window_print($aPlayer[0].iWorld_cur, $win[0], $iRect_world_cur)
						window_print($world_info[$aPlayer[0].iWorld_cur][$eWi_filename], $win[0], $iRect_world_filename)
						board_draw($aBoard, $aWorld, $aTile, $aPlayer[0])
						keyreleased('6B')

					EndIf

				Else

					If _IsPressed('6B') Then; numpad + target_layer +

						$world_layer_target += 1
						If $world_layer_target >= $world_info[$aPlayer[0].iWorld_cur][$eWi_layers] Then $world_layer_target = $world_info[$aPlayer[0].iWorld_cur][$eWi_layers] - 1
						window_print($world_layer_target & " " & $aWorld_point[0] & " " & $aWorld_point[1], $win[0], $iRect_world_target)
						keyreleased('6B')

					EndIf

					If _IsPressed('6D') Then; numpad - target_layer +

						$world_layer_target -= 1
						If $world_layer_target < 0 Then $world_layer_target = 0
						window_print($world_layer_target & " " & $aWorld_point[0] & " " & $aWorld_point[1], $win[0], $iRect_world_target)
						keyreleased('6D')

					EndIf

				EndIf

				If _IsPressed(47) Then; G get tile

					$tile_rect = _SDL_Rect_Create($win[0].iW - $tile_w, 0, $tile_w, $tile_h); Tile Graphic Rect area of Window
					_SDL_BlitSurface($win[0]._surf, $tile_rect, $win[0].surf, $tile_rect); Clear Tile_cur
					$aWorld_point = world_mouse_pos($aWorld, $aPlayer[0])

					If world_range($aWorld_point, $aPlayer[0]) Then

						If $aWorld_point[0] = $aWorld_point_old[0] And $aWorld_point[1] = $aWorld_point_old[1] Then

							$target_layer -= 1
							If $target_layer < 0 Then $target_layer = $world_info[$aPlayer[0].iWorld_cur][$eWi_layers] - 1; Can't below 0

						Else

							$target_layer = $world_info[$aPlayer[0].iWorld_cur][$eWi_layers] - 1

						EndIf

						$tile_cur = $aWorld[$aPlayer[0].iWorld_cur][$target_layer][$aWorld_point[0]][$aWorld_point[1]].iTile
						$aWorld_point_old = $aWorld_point

					EndIf

					_SDL_BlitSurface($aTile[$aPlayer[0].iWorld_cur][$tile_cur], _SDL_Rect_Create(0, 0, $tile_w, $tile_h), $win[0].surf, $tile_rect); Blit Tile_cur

					window_print($tile_cur, $win[0], $iRect_tile_cur); Tile_cur Print
					window_print($target_layer & " " & $aWorld_point[0] & " " & $aWorld_point[1], $win[0], $iRect_world_source); Target Layer, X, Y
					keyreleased(47); G

				EndIf; G key

			EndIf; control_window_type = eControl_window_none

			; Hotkeys
			If _IsPressed('12') Then ; Alt key Down

				If _IsPressed('73') Then ; F4 Exit

					keyreleased('73') ; Force F4 up so we don't Exit Multiable Applications

					$msg = $gui_event_close ; Set a close event message

				EndIf; F4

			EndIf;ispressed ALT

			If _IsPressed(1) Then; Mouse Left Click

				window_drag_array($win, $win_max, $redraw)

				If $dragn = -1 Then

					_SDL_GetMouseState($mouse_x, $mouse_y)
					$camera_old_x = $aPlayer[0].fCamera_x
					$camera_old_y = $aPlayer[0].fCamera_y
					$aPlayer[0].fCamera_x -= ($gaGui_rect[2] / 2 - $mouse_x) / 5
					$aPlayer[0].fCamera_y -= ($gaGui_rect[3] / 2 - $mouse_y) / 5
					$temp_x = $camera_old_x - $aPlayer[0].fCamera_x
					$temp_y = $camera_old_y - $aPlayer[0].fCamera_y

					If Abs($temp_x) < Abs($temp_y) Then

						If $temp_y < 0 Then

							$player_way = 0

						Else

							$player_way = 3

						EndIf

					Else

						If $temp_x < 0 Then

							$player_way = 2

						Else

							$player_way = 1

						EndIf

					EndIf

					StringFormat("%.0d", $aPlayer[0].iX);
					$moving = 1

				EndIf

				$redraw = 1

			Else

				$dragn = -1

			EndIf

			If _IsPressed(65) Then;NP 5

				$aPlayer[0].fCamera_x = 0
				$aPlayer[0].fCamera_y = 0
				$aPlayer[0].iMod_x = 0
				$aPlayer[0].iMod_y = 0
				$moving = 1

			EndIf

			If _IsPressed(70) Then; F1 Redraw? World onto Board Surface

				$redraw = 1

				board_redraw($aBoard, $aWorld, $aTile, $aPlayer[0], $aArea, $win, $area_impose)

				; Update SDL window
				window_print($aPlayer[0].iBoard_world_x & " " & $aPlayer[0].iBoard_world_y, $win[0], $iRect_board_world)
				window_print($aPlayer[0].iX & " " & $aPlayer[0].iY, $win[0], $iRect_world_x)
				window_print(StringFormat("%.2f", $aPlayer[0].fCamera_X) & " " & StringFormat("%.2f", $aPlayer[0].fCamera_y), $win[0], $iRect_camera)

			EndIf

			If _IsPressed('0d') Then;enter

				If $gChat_console_open = 0 Then

					; Open Chat console
					$gChat_console_open = 1

					; Release open chat key
					keyreleased('0d')

					; Focus the hidden text control
					GUICtrlSetState($gChat_window_edit, $gui_focus)

				EndIf

			EndIf

			If _IsPressed('10') Then; Shift

				If _IsPressed(25) Then;left

					$aPlayer[0].fCamera_x -= 1
					$player_way = 1
					$moving = 1

				EndIf

				If _IsPressed(26) Then;up

					$aPlayer[0].fCamera_y -= 1
					$player_way = 3
					$moving = 1

				EndIf

				If _IsPressed(27) Then;right

					$aPlayer[0].fCamera_x += 1
					$player_way = 2
					$moving = 1

				EndIf

				If _IsPressed(28) Then;down

					$aPlayer[0].fCamera_y += 1
					$player_way = 0
					$moving = 1

				EndIf

			Else

				If _IsPressed(25) Then;left

					$aPlayer[0].fCamera_x -= $player_base_movement_speed
					$player_way = 1
					$moving = 1

				EndIf

				If _IsPressed(26) Then;up

					$aPlayer[0].fCamera_y -= $player_base_movement_speed
					$player_way = 3
					$moving = 1

				EndIf

				If _IsPressed(27) Then;right

					$aPlayer[0].fCamera_x += $player_base_movement_speed
					$player_way = 2
					$moving = 1

				EndIf

				If _IsPressed(28) Then;down

					$aPlayer[0].fCamera_y += $player_base_movement_speed
					$player_way = 0
					$moving = 1

				EndIf

			EndIf

			If _IsPressed('71') Then ; F2

				;_ArrayDisplay($gaPlayerNet)

				$str = ''

				For $i = 0 To 80

					$x = Random(100, 999, 1)

					$str &= $x

				Next

				console_out($str)

				keyreleased('71')

			EndIf

		EndIf; winactive(hgui)= 1


		If $moving = 1 Then

			; Board Bounds and Redraw Board
			board_redraw_auto($aBoard, $aWorld, $aTile, $aArea, $aPlayer[0], $win[0], $iRect_board_world, $area_impose)

			$aPlayer[0].iX = $aPlayer[0].iBoard_world_x + Int($aPlayer[0].fCamera_x / $tile_w)
			$aPlayer[0].iY = $aPlayer[0].iBoard_world_y + Int($aPlayer[0].fCamera_y / $tile_h)
			$aPlayer[0].iMod_x = Mod($aPlayer[0].fCamera_x, $tile_w)
			$aPlayer[0].iMod_y = Mod($aPlayer[0].fCamera_y, $tile_h)

			If $area_impose = 1 Then

				; Area Bounds
				If $aPlayer[0].iX < $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][0] Or $aPlayer[0].iX > $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][2] - 1 _
						Or $aPlayer[0].iY < $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][1] Or $aPlayer[0].iY > $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][3] - 1 Then

					out("OUTBOUNDS AREA: Load: " & $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$eArea_ob_world])
					player_camera_set($aPlayer[0], $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$eArea_ob_x], $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$eArea_ob_y])
					If $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$eArea_ob_world] = "dw3\Overworld\" Then
						$aPlayer[0].iWorld_cur = 0; Overworld
					Else

						;$aPlayer[0].iWorld_cur = 1; Sub World
						If $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$eArea_ob_world] <> $world_info[1][$eWi_filename] Then

							out("LOADED area: " & $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$eArea_ob_world])
							out("WASN'T World_info: " & $world_info[1][$eWi_filename])
							out("Area_cur: " & $aPlayer[0].iArea_cur)
							world_area_load($aWorld, $aTile, $aArea, 1, $folder_graphics & $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$eArea_ob_world]);	World Array
							$aPlayer[0].iWorld_cur = 1; Sub World

						EndIf

					EndIf

					$redraw = 1
					board_draw_area($aBoard, $aWorld, $aTile, $aPlayer[0], $aArea, 1)

					window_print($aPlayer[0].iWorld_cur, $win[0], $iRect_world_cur)

				EndIf; Area Outbounds
;~ 			 	If $hotspot_dest_last_x <> $aPlayer[0].iX Or $hotspot_dest_last_y <> $aPlayer[0].iY Then $hotspot_dest_standing = 0
;~ 				If $hotspot_dest_standing = 0 Then
;~ 					For $i = 1 To $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$eArea_hotspots]; Hotspot Checks
;~ 						If $aPlayer[0].iX = $aHotspot[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$i][$eHSpot_iX] And $aPlayer[0].iY = $aHotspot[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$i][$eHSpot_iY] Then
;~ 							out("HotSpot Triggered")
;~ 							$aPlayer[0].iX = $aHotspot[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$i][$eHSpot_iDest_x]
;~ 							$aPlayer[0].iY = $aHotspot[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$i][$eHSpot_iDest_y]
;~ 							$hotspot_dest_last_x = $aPlayer[0].iX
;~ 							$hotspot_dest_last_y = $aPlayer[0].iY
;~ 							$aPlayer[0].fCamera_x = 0
;~ 							$aPlayer[0].fCamera_y = 0
;~ 							$aPlayer[0].iMod_x= 0
;~ 							$aPlayer[0].iMod_y= 0
;~ 							If $aHotspot[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$i][$eHSpot_sDest_world_file] = "dw3\Overworld\" Then
;~ 								$aPlayer[0].iWorld_cur = 0; Overworld
;~ 							Else
;~ 								$aPlayer[0].iWorld_cur = 1; Sub World
;~ 								If $aHotspot[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$i][$eHSpot_sDest_world_file] <> $world_info[1][$eWi_filename] Then
;~ 									out("LOADED: " & $aHotspot[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$i][$eHSpot_sDest_world_file])
;~ 									out("WASN'T: " & $world_info[1][$eWi_filename])
;~ 									world_area_load($aWorld, $aTile, $aArea, 1, $folder_graphics & $aArea[$aPlayer[0].iWorld_cur][$aPlayer[0].iArea_cur][$eArea_ob_world]);	World Array
;~ 								EndIf
;~ 							EndIf
;~ 						EndIf
;~ 					Next
;~ 				EndIf
			EndIf; area_impose

			$moving = 0
			window_print($aPlayer[0].iX & " " & $aPlayer[0].iY, $win[0], $iRect_world_x)
			window_print(StringFormat("%.2f", $aPlayer[0].fCamera_X) & " " & StringFormat("%.2f", $aPlayer[0].fCamera_y), $win[0], $iRect_camera)

		EndIf; moving= 1

		; Redraw
		If $redraw > 0 Then; Redraw     ---------------------------- Redraw --------------------------------     Redraw

			If TimerDiff($player_sprite_animation_timer) > $player_sprite_animation_timer_len Then

				$player_sprite_animation_timer = TimerInit()
				$player_frame += 1
				If $player_frame > 1 Then $player_frame = 0

			EndIf

			_SDL_BlitSurface($apBG[0], $BGrect, $screen, 0)

			$srect = _SDL_Rect_Create($aPlayer[0].fCamera_x - $gaGui_rect[2] / 2, $aPlayer[0].fCamera_y - $gaGui_rect[3] / 2, $aPlayer[0].iScr_w, $aPlayer[0].iScr_h); Source Rect
			$drifter_x = 0; drifter is added b/c board[0] seemed to srect negitive x, y fine
			$drifter_y = 0; but board[1] became detached from [0] at negitive srect

			If $srect.x < 0 Then

				$drifter_x = $srect.x
				$srect.x = 0

			EndIf

			If $srect.y < 0 Then

				$drifter_y = $srect.y
				$srect.y = 0

			EndIf

			$drect = _SDL_Rect_Create($aPlayer[0].iScr_x - $drifter_x, $aPlayer[0].iScr_y - $drifter_y, $aPlayer[0].iScr_w, $aPlayer[0].iScr_h)

			; Draw the Board Layers
			_SDL_BlitSurface($aBoard[0], $srect, $screen, $drect)

			; Draw Person Layer
			;			person_draw($aPlayer[0], $aPerson, $people, $screen); Draw Person

			; Draw Additional World Layers
			For $i = 1 To $world_info[$aPlayer[0].iWorld_cur][$eWi_layers] - 1

				_SDL_BlitSurface($aBoard[$i], $srect, $screen, $drect)

			Next

			; Control Window
			Switch $control_window_type

				Case $eControl_window_area; Window to Setup an Area

					selection_surf_draw($selection_surf, $aArea[$aPlayer[0].iWorld_cur][$area_cur][$eArea_x], $aArea[$aPlayer[0].iWorld_cur][$area_cur][$eArea_y], _
							$aArea[$aPlayer[0].iWorld_cur][$area_cur][$eArea_w], $aArea[$aPlayer[0].iWorld_cur][$area_cur][$eArea_h], $aPlayer[0])

					_SDL_BlitSurface($selection_surf, $srect, $screen, $drect)

					$confirm = gui_area_message($aControl_gui2, $aArea, $aTile, $aPlayer[0], $area_cur, $iArea_point, $aWorld, $selection_surf)

					If $confirm > 0 Then; area_set_controls() caputures user input for this event

						If $confirm = 2 Then $aArea = $backup_aArea
						$control_window_type = $eControl_window_none

						GUIDelete($hGui2)

					EndIf

				Case $eControl_window_hotspot; Window to Setup a Hotspot

					$confirm = gui_hotspot_message($aControl_gui2, $aHotspot_list, $aArea, $aPlayer[0], $hotspot_list_cur, $aWorld)

					If $confirm > 0 Then

						If $confirm = 1 Then

							hotspot_list_to_area($aHotspot, $aArea, $aHotspot_list, $aPlayer[0])

						EndIf

						$control_window_type = $eControl_window_none

						GUIDelete($hGui2)

					EndIf

			EndSwitch;control_window

			If $sun_layer.bSun_off = 0 Then _SDL_BlitSurface($sun_layer.surf, 0, $screen, 0)

			; Draw Net players
			playerNet_draw($aPlayer[0], $player_sprite, $player_way, $player_frame)

			; Draw Player Party
			_SDL_BlitSurface($player_sprite[1][$aPlayer[0].iClass][$player_way][$player_frame], 0, $screen, _SDL_Rect_Create($gaGui_rect[2] / 2, $gaGui_rect[3] / 2, 32, 32))

			For $i = 0 To $win_max - 1; Draw Windows

				window_draw($win[$i])

			Next

			; Show Console
			If $gConsole_show = 1 Then

				_SDL_BlitSurface($gConsole_surf, $gConsole_print_rect, $screen, $gConsole_print_rect); Draw Console

				_SDL_BlitSurface($gConsole_text_surf, 0, $screen, 0); Draw Console

				; Timer to hide console
				If TimerDiff($gConsole_timer) >= $gConsole_show_timeout Then

					$gConsole_cursor = 0
					$gConsole_show = 0
					_SDL_FillRect($gConsole_text_surf, 0, 0); Clear Console

					$gaSocket_recv[$eSocket_connected_sequence] = 0
					$gaSocket_recv[$eSocket_disconnected_sequence] = 0

				EndIf

			EndIf

			; Chat window Console
			If $gChat_console_open = 1 Then

				chat_console($iChat_sequence_frame)

			Else; Look I don't want center lines on my chat console okay

				; Draw Center Lines
				If $center_lines_draw = 1 Then; Draw Center Lines

					_sge_Line($screen, $gaGui_rect[2] / 2, 0, $gaGui_rect[2] / 2, $gaGui_rect[3], _SDL_MapRGB($screen, 255, 0, 0)); Center X TOP BOTTOM
					_sge_Line($screen, 0, $gaGui_rect[3] / 2, $gaGui_rect[2], $gaGui_rect[3] / 2, _SDL_MapRGB($screen, 255, 0, 0)); Center Y LEFT RIGHT

				EndIf

			EndIf

			_SDL_Flip($screen)
			$redraw = 0
		EndIf;redraw> 0

	Until $msg = $gui_event_close; Main Loop

	; Send disconnect to Server
	If $gNet_role = $eNet_role_client Then

		client_send_spears($aPlayer[0], $ePacket_type_disconnect_player)

	EndIf

	; Shutdown
	settings_save($ghGui)
;~ 	If $__SDL_DLL <> -1 Then _SDL_Quit()
;~ 	If $__SDL_DLL_image <> -1 Then _SDL_Shutdown_image()
;~ 	If $__SDL_DLL_sge <> -1 Then _SDL_Shutdown_sge()
;~ 	If $__SDL_DLL_sprig <> -1 Then _SDL_Shutdown_sprig();)
;~ 	If $__SDL_DLL_GFX <> -1 Then _SDL_Shutdown_gfx()
EndFunc   ;==>main
;END PROGRAM

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
			"int iWorld_cur;" & _
			"char caName[" & $player_name_len_max & "];" & _
			"int iLvl;" & _
			"int iClass;" & _
			"int iXp;" & _
			"int iGold;"

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

Func board_draw_area(ByRef $aBoard, $aWorld, $aTile, ByRef $player, $aArea, $recenter = 0)
	Local $timer = TimerInit()
	If $aArea[$player.iWorld_cur][0][0] < 1 Then
		MsgBox(0, "Can't Do It", "board_draw_area(): You have no Areas Dog", Default, $ghGui)
		Return
	EndIf

	; Area Find
	$player.iArea_cur = 0
	For $i = 1 To $aArea[$player.iWorld_cur][0][0]
		If $player.iX > $aArea[$player.iWorld_cur][$i][0] - 1 And $player.iX < $aArea[$player.iWorld_cur][$i][2] And $player.iY > $aArea[$player.iWorld_cur][$i][1] - 1 And $player.iY < $aArea[$player.iWorld_cur][$i][3] Then
			$player.iArea_cur = $i
			ExitLoop
		EndIf
	Next

	; Store world position as camera_reset
	Local $camera_reset_x = $player.iX
	Local $camera_reset_y = $player.iY
	out("camera rest_x: " & $camera_reset_x & " " & $camera_reset_y)
	; The non integer part of the tile division used to mark the camera distance in tile
	$player.iMod_x = Mod($player.fCamera_x, $tile_w)
	$player.iMod_y = Mod($player.fCamera_y, $tile_h)

	; world_tile is the current tile address in loop world[layer][world_tile_x][world_tile_y]
	; They start at the board_world_x as Top Left of Board surface
	Local $world_tile_x = $player.iBoard_world_x, $world_tile_y = $player.iBoard_world_y

	; Choose the Top Left of world to draw from
	; Whatever board_world_x is it will become less by the entire width of the board then have the distance of camera added to board_world_x
	If $recenter = 0 Then
		$player.iBoard_world_x = $player.iBoard_world_x - ($board_w / 2) / $tile_w + $player.fCamera_x / $tile_w
		$player.iBoard_world_y = $player.iBoard_world_y - ($board_h / 2) / $tile_h + $player.fCamera_y / $tile_h
	Else
		$player.iBoard_world_x = $player.iX - ($board_w / 2) / $tile_w
		$player.iBoard_world_y = $player.iY - ($board_h / 2) / $tile_h
	EndIf
	out("iBoard_world_x: " & $player.iBoard_world_x & " " & $player.iBoard_world_y)
	out("player.iArea_cur: " & $player.iArea_cur)
	; Although the engine tolarates negivite board_world_x, remove the possibility
	;If $player.iBoard_world_x < 0 Then $player.iBoard_world_x = 0
	;If $player.iBoard_world_y < 0 Then $player.iBoard_world_y = 0
	Local $out = 0
	Local $tnum = 0
	Local $srect
	Local $drect
	For $layer = 0 To $world_info[$player.iWorld_cur][$eWi_layers] - 1
		_SDL_FillRect($aBoard[$layer], 0, 0)
		$world_tile_y = $player.iBoard_world_y
		For $draw_y = 0 To $board_h Step $tile_h
			$world_tile_x = $player.iBoard_world_x
			For $draw_x = 0 To $board_w Step $tile_w
				If $world_tile_x < 0 Or $world_tile_x > ($world_info[$player.iWorld_cur][$eWi_w] - 1) Or $world_tile_y < 0 Or $world_tile_y > ($world_info[$player.iWorld_cur][$eWi_h] - 1) Then $out = 1; Tile Outbounds of World
				If $world_tile_x < $aArea[$player.iWorld_cur][$player.iArea_cur][0] Or $world_tile_x > $aArea[$player.iWorld_cur][$player.iArea_cur][2] Or $world_tile_y < $aArea[$player.iWorld_cur][$player.iArea_cur][1] Or $world_tile_y > $aArea[$player.iWorld_cur][$player.iArea_cur][3] Then $out = 1; Tile Outbounds of Area
				If $out = 1 Then
					If $layer = 0 Then
						$tnum = $aArea[$player.iWorld_cur][$player.iArea_cur][4];
						$srect = _SDL_Rect_Create(0, 0, $tile_w, $tile_h)
						$drect = _SDL_Rect_Create($draw_x, $draw_y, $tile_w, $tile_h)
						_SDL_BlitSurface($aTile[$player.iWorld_cur][$tnum], $srect, $aBoard[$layer], $drect)
					EndIf
				Else; Tile in Range
					$tnum = $aWorld[$player.iWorld_cur][$layer][$world_tile_x][$world_tile_y].iTile
					$srect = _SDL_Rect_Create($aWorld[$player.iWorld_cur][$layer][$world_tile_x][$world_tile_y].iX, $aWorld[$player.iWorld_cur][$layer][$world_tile_x][$world_tile_y].iY, $tile_w, $tile_h)
					$drect = _SDL_Rect_Create($draw_x, $draw_y, $tile_w, $tile_h)
					_SDL_BlitSurface($aTile[$player.iWorld_cur][$tnum], $srect, $aBoard[$layer], $drect)
				EndIf;World range
				$out = 0
				$world_tile_x += 1
			Next;x
			$world_tile_y += 1
		Next;y
		;print("Layer: " & $layer, $aBoard[0], 0, 0)
	Next;layer
	; camera_reset is world position subtract the base board_world_x
	; The mod is added to adjust for the distance traversed in tile_w
	$player.fCamera_x = (($camera_reset_x - $player.iBoard_world_x) * $tile_w) + $player.iMod_x
	$player.fCamera_y = (($camera_reset_y - $player.iBoard_world_y) * $tile_h) + $player.iMod_y
	out("board_draw_area() Completed in: " & TimerDiff($timer))
EndFunc   ;==>board_draw_area

; Draw Board
Func board_draw(ByRef $aBoard, $aWorld, $aTile, ByRef $player)

	Local $timer = TimerInit()
	; Store world position as camera_reset
	Local $camera_reset_x = $player.iX
	Local $camera_reset_y = $player.iY
	; The non integer part of the tile division used to mark the camera distance in tile
	$player.iMod_x = Mod($player.fCamera_x, $tile_w)
	$player.iMod_y = Mod($player.fCamera_y, $tile_h)

	; world_tile is the current tile address in loop world[layer][world_tile_x][world_tile_y]
	; They start at the board_world_x as Top Left of Board surface
	Local $world_tile_x = $player.iBoard_world_x, $world_tile_y = $player.iBoard_world_y

	; Choose the Top Left of world to draw from
	; Whatever board_world_x is it will become less by the entire width of the board then have the distance of camera added to board_world_x
	$player.iBoard_world_x = $player.iBoard_world_x - ($board_w / 2) / $tile_w + $player.fCamera_x / $tile_w
	$player.iBoard_world_y = $player.iBoard_world_y - ($board_h / 2) / $tile_h + $player.fCamera_y / $tile_h

	; Although the engine tolarates negivite board_world_x, remove the possibility
	If $player.iBoard_world_x < 0 Then $player.iBoard_world_x = 0
	If $player.iBoard_world_y < 0 Then $player.iBoard_world_y = 0
	Local $tnum = 0
	Local $srect
	Local $drect

	For $layer = 0 To $world_info[$player.iWorld_cur][$eWi_layers] - 1

		out("layer: " & $layer)
		_SDL_FillRect($aBoard[$layer], 0, 0)
		$world_tile_y = $player.iBoard_world_y

		For $draw_y = 0 To $board_h Step $tile_h

			$world_tile_x = $player.iBoard_world_x

			For $draw_x = 0 To $board_w Step $tile_w

				If $world_tile_x < 0 Or $world_tile_x > ($world_info[$player.iWorld_cur][$eWi_w] - 1) Or $world_tile_y < 0 Or $world_tile_y > ($world_info[$player.iWorld_cur][$eWi_h] - 1) Then; Tile Outbounds of World

					If $layer = 0 Then

						$tnum = 1;
						$srect = _SDL_Rect_Create(0, 0, $tile_w, $tile_h)
						$drect = _SDL_Rect_Create($draw_x, $draw_y, $tile_w, $tile_h)
						_SDL_BlitSurface($aTile[$player.iWorld_cur][$tnum], $srect, $aBoard[$layer], $drect)

					EndIf

				Else; Tile in Range

					$tnum = $aWorld[$player.iWorld_cur][$layer][$world_tile_x][$world_tile_y].iTile
					$srect = _SDL_Rect_Create($aWorld[$player.iWorld_cur][$layer][$world_tile_x][$world_tile_y].iX, $aWorld[$player.iWorld_cur][$layer][$world_tile_x][$world_tile_y].iY, $tile_w, $tile_h)
					$drect = _SDL_Rect_Create($draw_x, $draw_y, $tile_w, $tile_h)
					_SDL_BlitSurface($aTile[$player.iWorld_cur][$tnum], $srect, $aBoard[$layer], $drect)

				EndIf;World range

				$world_tile_x += 1
			Next;x

			$world_tile_y += 1

		Next;y

		print("Layer: " & $layer, $aBoard[0], 0, 0)

	Next;layer

	; camera_reset is world position subtract the base board_world_x
	; The mod is added to adjust for the distance traversed in tile_w
	$player.fCamera_x = (($camera_reset_x - $player.iBoard_world_x) * $tile_w) + $player.iMod_x
	$player.fCamera_y = (($camera_reset_y - $player.iBoard_world_y) * $tile_h) + $player.iMod_y
	out("board_draw() Completed in: " & TimerDiff($timer))

EndFunc   ;==>board_draw

Func board_redraw_auto($aBoard, $aWorld, $aTile, $aArea, $player, ByRef $win, $rect, $area_impose)

	Local $redraw_auto = 0
	Local $sx = $player.iBoard_world_x * $tile_w + $board_w
	Local $sy = $player.iBoard_world_y * $tile_h + $board_h

	;$player.iBoard_world_x - ($board_w / 2) / $tile_w + $player.fCamera_x / $tile_w
	;out("Board Point: " & ($board_w / 2) / $tile_w)

	If $player.fCamera_x < 0 And $player.iBoard_world_x > ($board_w / 2) / $tile_w Then

		out("LOW x: " & $sx & " " & $sy)
		$redraw_auto = 1

	EndIf

	If $player.fCamera_y < 0 And $player.iBoard_world_y > 0 Then

		out("LOW y: " & $sx & " " & $sy)
		$redraw_auto = 1

	EndIf

	If $player.fCamera_x > $sx Or $player.fCamera_y > $sy Then

		out("High sx: " & $sx & " " & $sy)
		$redraw_auto = 1

	EndIf

	If $redraw_auto = 1 Then

		board_redraw($aBoard, $aWorld, $aTile, $player, $aArea, $win, $area_impose)

		window_print($player.iBoard_world_x & " " & $player.iBoard_world_y, $win, $rect)

	EndIf

EndFunc   ;==>board_redraw_auto

Func selection_surf_draw(ByRef $board, $x, $y, $w, $h, $player)

	_SDL_FillRect($board, 0, 0); Clear Board Surface
	; Check if area is located within the world drawn to board
	If $x > $player.iBoard_world_x - 1 And $x < $player.iBoard_world_x + $board_w / $tile_w Then

		If $y > $player.iBoard_world_y - 1 And $y < $player.iBoard_world_y + $board_h / $tile_h Then

			Local $selection_color = _SDL_MapRGB($screen, 255, 255, 0); Area selection color.
			; Calculate where on board it is
			Local $start_x = ($x - $player.iBoard_world_x) * $tile_w;       (oo)
			Local $start_y = ($y - $player.iBoard_world_y) * $tile_h;      J UU L-====E
			Local $end_w = (($w - $player.iBoard_world_x) + 1) * $tile_w;   {¥}
			Local $end_h = (($h - $player.iBoard_world_y) + 1) * $tile_h;  _| |_

			_sge_FilledRect($board, $start_x, $start_y, $end_w, $end_h, $selection_color); Show area

		EndIf

	EndIf

EndFunc   ;==>selection_surf_draw

; Setup the board
Func board_create(ByRef $aBoard, $board_layers, $board_width, $board_height, $colorkey = 0)

	out("board_create: Layers: " & $board_layers & " w: " & $board_width & " h: " & $board_height)
	$board_w = $board_width
	$board_h = $board_height

	For $i = 0 To $board_layers - 1

		If $aBoard[$i] <> 0 Then _SDL_FreeSurface($aBoard[$i]) ; Free Board Layer Surface
		$aBoard[$i] = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $board_w + $tile_w, $board_h + $tile_h, 32, 0, 0, 0, 255) ; Create Board Layer Surface
		_SDL_SetColorKey($aBoard[$i], $_SDL_SRCCOLORKEY, $colorkey) ; Set Colorkey

	Next

EndFunc   ;==>board_create

; Player Struct
Func player_create_struct($player_max, $x, $y, $w, $h, $world_x, $world_y)

	Local $aPlayer[$player_max]

	For $i = 0 To $player_max - 1

		$aPlayer[$i] = DllStructCreate($tagPlayer_struct)
		$aPlayer[$i].iScr_x = $x
		$aPlayer[$i].iScr_y = $y
		$aPlayer[$i].iScr_w = $w
		$aPlayer[$i].iScr_h = $h
		$aPlayer[$i].caName = "Test_Player"

	Next

	Return $aPlayer

EndFunc   ;==>player_create_struct

; World
Func world_save_layer($aWorld, $layer, $aTile, $player, $world_filepath = "", $save_tile_x_y = 1)

	If $world_filepath = "" Then

		$world_filepath = FileOpenDialog("Load World", @ScriptDir & "\..\Graphics\dw3\", "txt world (*.txt)", Default, "", $ghGui); Launch File Open Dialog Window
		If @error <> 0 Then Return 1; If error<> 0 then return 1

	EndIf

	Local $world_filepath_filename = StringLeft($world_filepath, StringLen($world_filepath) - 4)
	out("$world_filepath_filename " & $world_filepath_filename)
	Local $file = FileOpen($world_filepath, $fo_overwrite)
	;$file2 = FileOpen($world_filepath_filename & " Tile_X_Y.txt", $fo_overwrite)
	FileWriteLine($file, $world_info[$player.iWorld_cur][$eWi_w])
	FileWriteLine($file, $world_info[$player.iWorld_cur][$eWi_h])
	FileWriteLine($file, $world_info[$player.iWorld_cur][$eWi_tiles])
	Local $cells = StringLen($world_info[$player.iWorld_cur][$eWi_tiles]); Formats File Rows and Coloms
	Local $chunk
	Local $len

	If $save_tile_x_y = 1 Then

		Local $file2 = FileOpen($world_filepath_filename & " Tile_X_Y.txt", $fo_overwrite)

		For $y = 0 To $world_info[$player.iWorld_cur][$eWi_h] - 1

			For $x = 0 To $world_info[$player.iWorld_cur][$eWi_w] - 1

				$chunk = $aWorld[$player.iWorld_cur][$layer][$x][$y].iTile
				$len = StringLen($chunk)

				For $i = 0 To $cells - $len

					$chunk &= " "

				Next

				FileWrite($file, $chunk)
				FileWriteLine($file2, $aWorld[$player.iWorld_cur][$layer][$x][$y].iX)
				FileWriteLine($file2, $aWorld[$player.iWorld_cur][$layer][$x][$y].iY)

			Next

			FileWrite($file, @CRLF)

		Next

		FileClose($file2)

	Else; Don't Save X_Y File

		For $y = 0 To $world_info[$player.iWorld_cur][$eWi_h] - 1

			For $x = 0 To $world_info[$player.iWorld_cur][$eWi_w] - 1

				$chunk = $aWorld[$player.iWorld_cur][$layer][$x][$y].iTile
				$len = StringLen($chunk)

				For $i = 0 To $cells - $len

					$chunk &= " "

				Next

				FileWrite($file, $chunk)

			Next

			FileWrite($file, @CRLF)

		Next

	EndIf

	FileClose($file)

EndFunc   ;==>world_save_layer

Func world_load_layer(ByRef $aWorld, $player, $layer, $world_filepath = "", $start_x = 0, $start_y = 0)

	; If No File Path is Directed then Launch Dialog File Browser
	If $world_filepath = "" Then

		$world_filepath = FileOpenDialog("Load World", @ScriptDir & "\..\Graphics\dw3\", "txt world (*.txt)", Default, "", $ghGui); Launch File Open Dialog Window
		If @error <> 0 Then Return 1; If error<> 0 then return 1

	EndIf

	; Open the World File
	Local $file = FileOpen($world_filepath)

	If $file < 0 Then; Error check Loading File

		MsgBox(0, "Error", "World File Not Opened: " & $world_filepath, Default, $ghGui)
		Return 1;				Exit If Error Opening File

	EndIf

	; Read Header
	Local $world_header[3]
	$world_header[0] = Int(FileReadLine($file)); World Width
	$world_header[1] = Int(FileReadLine($file)); World Height
	$world_header[2] = Int(FileReadLine($file)); World Max Tile

	Local $cells = StringLen($world_header[2]) + 1; Formats File Rows and Coloms

	; Read the World Tile ID Data
	For $y = $start_y To $start_y + $world_header[1] - 1

		For $x = $start_x To $start_x + $world_header[0] - 1

			$aWorld[$player.iWorld_cur][$layer][$x][$y] = DllStructCreate($tagWorld_struct); Make Object

			$aWorld[$player.iWorld_cur][$layer][$x][$y].iTile = Int(FileRead($file, $cells))
			; Load default
			;$aWorld[$player.iWorld_cur][$layer][$x][$y].iX = 0
			;$aWorld[$player.iWorld_cur][$layer][$x][$y].iY = 0
			$aWorld[$player.iWorld_cur][$layer][$x][$y].iWall_level = 0
			; Special case tiles
			;If $aWorld[$player.iWorld_cur][$layer][$x][$y].iTile = 40 Then; Forest
			$aWorld[$player.iWorld_cur][$layer][$x][$y].iX = Random(0, 5, 1) * $tile_w
			$aWorld[$player.iWorld_cur][$layer][$x][$y].iY = Random(0, 5, 1) * $tile_h
			;EndIf
		Next

		FileRead($file, 2); Read the Carrage Return at End of File Line

	Next

	FileClose($file)

	Return $world_header

EndFunc   ;==>world_load_layer

Func player_world_cur_switch(ByRef $player, $modify_by)

	$player.iWorld_cur += $modify_by
	If $player.iWorld_cur < 0 Then $player.iWorld_cur = 0; Normalize?
	If $player.iWorld_cur >= UBound($world_info) Then $player.iWorld_cur = UBound($world_info) - 1
	player_camera_set($player, 0, 0)
	out("aPlayer[0].iWorld_cur " & $player.iWorld_cur); We get Signal

EndFunc   ;==>player_world_cur_switch

Func player_camera_set($player, $world_x, $world_y, $camera_x = 0, $camera_y = 0, $mod_x = 0, $mod_y = 0)

	$player.iX = $world_x
	$player.iY = $world_y
	$player.fCamera_x = $camera_x
	$player.fCamera_y = $camera_y
	$player.iMod_x = $mod_x
	$player.iMod_y = $mod_y

EndFunc   ;==>player_camera_set

Func gui_world_random_tile_x_y(ByRef $aWorld, $player, $aTile)

	Local $hGui2 = GUICreate("Randomize Tile", 320, 200, Default, Default, Default, Default, $ghGui)
	Local $gui2_rect = WinGetPos($hGui2)
	Local $aControl[10][2]

	label_control($hGui2, $aControl, 0, "Randomize Tile", 5, 5, 100, 20, "comboex", 100, 5, 200, 200)

	; ImageList For Tile Lists
	Local $hImage = _GUIImageList_Create($tile_w, $tile_h, 6)

	For $i = 0 To $world_info[$player.iWorld_cur][$eWi_tiles] - 1; Fill ImageList and ComboExs with Tile BMPs

		_GUIImageList_AddBitmap($hImage, $folder_graphics & $world_info[$player.iWorld_cur][$eWi_filename] & "Tiles\" & $i & ".bmp")
		_GUICtrlComboBoxEx_AddString($aControl[0][$eControl_data], $i, $i, $i); Populate Find Tile ComboBoxEx

	Next

	_GUICtrlComboBoxEx_SetImageList($aControl[0][$eControl_data], $hImage); Set ImageList to Find Tile ComboEx
	_GUICtrlComboBoxEx_SetCurSel($aControl[0][$eControl_data], 0)

	Local $confirm_button = GUICtrlCreateButton("Confirm", $gui2_rect[2] - 100, $gui2_rect[3] - 50, 55, 20)
	GUISetState()
	Local $confirm = 0
	Local $msg

	Do

		$msg = GUIGetMsg()

		Switch $msg

			Case $confirm_button
				$confirm = 1

		EndSwitch;msg

	Until $msg = $gui_event_close Or $confirm = 1

	If $confirm = 1 Then

		For $z = 0 To $world_info[$player.iWorld_cur][$eWi_layers] - 1

			For $y = 0 To $world_info[$player.iWorld_cur][$eWi_h] - 1

				For $x = 0 To $world_info[$player.iWorld_cur][$eWi_w] - 1

					If $aWorld[$player.iWorld_cur][$z][$x][$y].iTile = 40 Then; Forest

						$aWorld[$player.iWorld_cur][$z][$x][$y].iX = Random(0, 5, 1) * $tile_w
						$aWorld[$player.iWorld_cur][$z][$x][$y].iY = Random(0, 5, 1) * $tile_h

					EndIf

				Next;x

			Next;y

		Next;z

	EndIf

	GUIDelete($hGui2)

EndFunc   ;==>gui_world_random_tile_x_y

Func world_range($aiPoint, $player)

	If $aiPoint[0] > -1 And $aiPoint[0] < $world_info[$player.iWorld_cur][$eWi_w] And $aiPoint[1] > -1 And $aiPoint[1] < $world_info[$player.iWorld_cur][$eWi_h] Then

		Return 1

	EndIf

	Return 0; $aiPoint[0x], $aiPoint[0y] Out Bounds of World

EndFunc   ;==>world_range

; Draw Map
Func map_draw($aWorld, $layer, $aTile, $player)

	Local $scale = 2
	Local $redraw = 1
	Local $map_surf;
	Local $view_x = 0, $view_y = 0
	Local $bMap_scale = 1
	Local $tile_map_color[$world_info[$player.iWorld_cur][$eWi_tiles]]
	$tile_map_color[0] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[1] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[2] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[3] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[4] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[5] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[6] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[7] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[8] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[9] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[0] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[10] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[11] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[12] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[13] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[14] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[15] = _SDL_MapRGB($screen, 0, 0, 100)
	$tile_map_color[16] = _SDL_MapRGB($screen, 20, 20, 100);water shallow wall
	$tile_map_color[17] = _SDL_MapRGB($screen, 0, 0, 150);Ice
	$tile_map_color[18] = _SDL_MapRGB($screen, 100, 100, 100);moutain
	$tile_map_color[19] = _SDL_MapRGB($screen, 200, 200, 0);town
	$tile_map_color[20] = _SDL_MapRGB($screen, 100, 20, 20);hill
	$tile_map_color[21] = _SDL_MapRGB($screen, 200, 200, 0);town
	$tile_map_color[22] = _SDL_MapRGB($screen, 0, 100, 0);grass
	$tile_map_color[23] = _SDL_MapRGB($screen, 0, 0, 100);cave
	$tile_map_color[24] = _SDL_MapRGB($screen, 200, 200, 0);town little
	$tile_map_color[25] = _SDL_MapRGB($screen, 200, 200, 0);castle
	$tile_map_color[26] = _SDL_MapRGB($screen, 200, 200, 0);castle
	$tile_map_color[27] = _SDL_MapRGB($screen, 200, 200, 0);castle
	$tile_map_color[28] = _SDL_MapRGB($screen, 200, 200, 0);castle
	$tile_map_color[29] = _SDL_MapRGB($screen, 200, 200, 0);shrine
	$tile_map_color[30] = _SDL_MapRGB($screen, 0, 0, 200);bridge x left right
	$tile_map_color[31] = _SDL_MapRGB($screen, 200, 200, 0);Tower Top
	$tile_map_color[32] = _SDL_MapRGB($screen, 200, 200, 0);Tower bottom
	$tile_map_color[33] = _SDL_MapRGB($screen, 50, 50, 50);swamp
	$tile_map_color[34] = _SDL_MapRGB($screen, 0, 0, 100);sand
	$tile_map_color[35] = _SDL_MapRGB($screen, 150, 150, 150);pyramis
	$tile_map_color[36] = _SDL_MapRGB($screen, 0, 0, 100);march
	$tile_map_color[37] = _SDL_MapRGB($screen, 100, 0, 100);brown
	$tile_map_color[38] = _SDL_MapRGB($screen, 255, 255, 255);bridge down
	$tile_map_color[39] = _SDL_MapRGB($screen, 0, 0, 0);blank?
	$tile_map_color[40] = _SDL_MapRGB($screen, 0, 0, 100)

	Local $msg
	Local $srect
	Local $drect

	Do

		$msg = GUIGetMsg()

		If $redraw > 0 Then

			If $bMap_scale > 0 Then; Scale the Map

				If $map_surf <> 0 Then _SDL_FreeSurface($map_surf)
				$map_surf = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $world_info[$player.iWorld_cur][$eWi_w] * $scale, $world_info[$player.iWorld_cur][$eWi_h] * $scale, 32, 0, 0, 0, 255)
				$bMap_scale = 0

			EndIf;bMap_scale> 0

			If $redraw = 1 Then

				For $y = 0 To $world_info[$player.iWorld_cur][$eWi_h] - 1

					For $x = 0 To $world_info[$player.iWorld_cur][$eWi_w] - 1

						$drect = _SDL_Rect_Create($x * $scale, $y * $scale, $scale, $scale)
						_SDL_FillRect($map_surf, $drect, $tile_map_color[$aWorld[$player.iWorld_cur][$layer][$x][$y].iTile])

					Next;x

				Next;y

			EndIf

			_sge_rect($map_surf, $player.fCamera_x * $scale, $player.fCamera_y * $scale, _
					$player.fCamera_x * $scale + $player.iScr_w / $tile_w * $scale, $player.fCamera_y * $scale + $player.iScr_h / $tile_h * $scale, _SDL_MapRGB($screen, 255, 0, 0)); WorldSurf Start
			_sge_rect($map_surf, $player.fCamera_x * $scale, $player.fCamera_y * $scale, $player.fCamera_x * $scale, $player.fCamera_y * $scale + 10, _SDL_MapRGB($screen, 255, 255, 255)); player.fCamera_x, iY
			_sge_rect($map_surf, $player.iBoard_world_x * $scale, $player.iBoard_world_y * $scale, $player.iBoard_world_x * $scale, $player.iBoard_world_y * $scale + 10, _SDL_MapRGB($screen, 0, 255, 255)); worldsurf_x
			$srect = _SDL_Rect_Create($view_x, $view_y, $gaGui_rect[2], $gaGui_rect[3])
			_SDL_BlitSurface($map_surf, $srect, $screen, 0)
			_SDL_Flip($screen)
			$redraw = 0

		EndIf;redraw= 1

		If _IsPressed(21) Then; Scale Map + Page UP

			$bMap_scale = 1
			$redraw = 1
			$scale += 1

		EndIf

		If _IsPressed(22) Then; Scale Map - Page Down

			$bMap_scale = 1
			$redraw = 1
			$scale -= 1
			If $scale < 0 Then $scale = 0

		EndIf

		If _IsPressed(25) Then; Left

			$redraw = 2
			$view_x -= 1
			If $view_x < 0 Then $view_x = 0

		EndIf

		If _IsPressed(26) Then; Up

			$redraw = 2
			$view_y -= 1
			If $view_y < 0 Then $view_y = 0

		EndIf
		If _IsPressed(27) Then; Right

			$redraw = 2
			$view_x += 1

		EndIf
		If _IsPressed(28) Then; Down

			$redraw = 2
			$view_y += 1

		EndIf

	Until $msg = $gui_event_close Or _IsPressed('1b')

	If $map_surf <> 0 Then _SDL_FreeSurface($map_surf)

EndFunc   ;==>map_draw

Func tile_scale_array(ByRef $aTile, $scale_w, $scale_h, $player)

	Local $surf

	For $i = 0 To $world_info[$player.iWorld_cur][$eWi_tiles] - 1

		$surf = _SDL_DisplayFormat($aTile[$player.iWorld_cur][$i]); Copy Surface
		_SDL_FreeSurface($aTile[$player.iWorld_cur][$i]); Free Surface

		$aTile[$player.iWorld_cur][$i] = _SDL_zoomSurface($surf, $scale_w, $scale_h, 0); Scale and Copy Back

		_SDL_FreeSurface($surf); Free Surface Copy

	Next

	surf_size_get($aTile[$player.iWorld_cur][0], $tile_w, $tile_h)

EndFunc   ;==>tile_scale_array

Func tile_replace_color($aTile, $player)

	Local $hGui2 = GUICreate("Replace Tile Color", 340, 6 * 30 + $tile_h + 20, Default, Default, Default, Default, $ghGui); Window Replace Color
	Local $gui2_rect = WinGetPos($hGui2); Sub Window Rect

	Local Enum $eidTile_combo, $eidFind_red, $eidFind_green, $eidFind_blue, $eidReplace_red, $eidReplace_green, $eidReplace_blue, $eidConfirm, $eidTile_total

	Local $aControl[9][2]

	$aControl[$eidTile_total][$eControl_data] = GUICtrlCreateInput("/ " & $world_info[$player.iWorld_cur][$eWi_tiles], 220, 10, 75); Area Total Input (readonly)
	GUICtrlSendMsg($aControl[$eidTile_total][$eControl_data], $EM_SETREADONLY, 1, 0); ^ )

	$aControl[$eidConfirm][$eControl_data] = GUICtrlCreateButton("Replace the Color", $gui2_rect[2] - 70, $gui2_rect[3] - 50, 55, 20)
	label_control($hGui2, $aControl, $eidTile_combo, "Tile", 10, 10, 90, 20, "comboex", 100, 10, 100, 420)

	Local $hImage = _GUIImageList_Create($tile_w, $tile_h, 6); Image List for ComboboxEx

	For $i = 0 To $world_info[$player.iWorld_cur][$eWi_tiles] - 1;					Fill it with Tiles from the Last Loaded Tile Path

		_GUIImageList_AddBitmap($hImage, $folder_graphics & $world_info[$player.iWorld_cur][$eWi_filename] & "Tiles\" & $i & ".bmp")
		_GUICtrlComboBoxEx_AddString($aControl[$eidTile_combo][$eControl_data], $i, $i, $i)

	Next

	_GUICtrlComboBoxEx_SetImageList($aControl[$eidTile_combo][$eControl_data], $hImage)

	;label_control($hgui2, $aControl, $eidArea_id_combo, "Area Index:", 10, 10, 60, 20, "combo", 100, 10, 55, 20); Area Index [ 1..aArea[0][0] ] Combobox
	;For $i = 1 To $aArea[0][0];								Fill Area Index List Combobox [ 0 ] / 9001
	;	GUICtrlSetData($aControl[$eidArea_id_combo][$eControl_data], $i);					1
	;Next

	_GUICtrlComboBox_SetCurSel($aControl[$eidTile_combo][$eControl_data], 0);	ComboEx Outbounds Tile

	GUISetState();										Show Sub Window
	WinActivate($hGui2)


	GUISetState()

	Local $msg

	Do

		$msg = GUIGetMsg()

	Until $msg = $gui_event_close

	GUIDelete($hGui2)

EndFunc   ;==>tile_replace_color

Func tile_replace_color_array($aTile, $color_replace, $color_new, $player)

	Local $tile_temp_w = 0, $tile_temp_h = 0
	surf_size_get($aTile[$player.iWorld_cur][0], $tile_temp_w, $tile_temp_h)

	For $i = 0 To $world_info[$player.iWorld_cur][$eWi_tiles] - 1

		For $y = 0 To $tile_temp_h - 1

			For $x = 0 To $tile_temp_w - 1

				If _SPG_GetPixel($aTile[$player.iWorld_cur][$i], $x, $y) = $color_replace Then

					_sge_Rect($aTile[$player.iWorld_cur][$i], $x, $y, $x, $y, $color_new)

				EndIf
			Next;x

		Next;y

	Next;i

EndFunc   ;==>tile_replace_color_array

Func tile_swap_id_select(ByRef $aTile, ByRef $aWorld, $player)

	Local $layer = 0

	Do

		$layer = InputBox("Change Layer", "Choose the numeric layer to modify")

		If $layer > -1 And $layer < $world_info[$player.iWorld_cur][$eWi_layers] Then

			ExitLoop

		Else

			MsgBox(0, "Out of Range", "0 TO " & $world_info[$player.iWorld_cur][$eWi_layers] - 1, Default, $ghGui)

		EndIf

	Until $layer > -1 And $layer < $world_info[$player.iWorld_cur][$eWi_layers]

	keyreleased('0d')
	Local $tile_id_1 = tile_select($aTile, "Swap Tile IDs: Choose Tile 1", $player)
	If $tile_id_1 < 0 Then Return -1
	Local $tile_id_2 = tile_select($aTile, "Swap Tile IDs: Choose Tile 2!", $player)
	If $tile_id_2 < 0 Then Return -1
	If $tile_id_1 = $tile_id_2 Then MsgBox(0, "Wut", "You Fool!" & @CRLF & "Tile: " & $tile_id_1 & " cannot be swapped with Tile: " & $tile_id_2 & "!")
	tile_swap_id($layer, $tile_id_1, $tile_id_2, $aTile, $aWorld, $player)

	Return 1

EndFunc   ;==>tile_swap_id_select

; Written before I used comboex boxs for tile graphics
; I'm just not ready to get rid of this function
Func tile_select($aTile, $sCaption, $player)

	Local $tiles = $world_info[$player.iWorld_cur][$eWi_tiles], $tile_drawn = 0, $click_x = 0, $click_y = 0, $math = -1
	Local $tile_temp_w, $tile_temp_h

	surf_size_get($aTile[$player.iWorld_cur][0], $tile_temp_w, $tile_temp_h)

	Local $redraw = 1, $confirm = 0
	print($sCaption, $screen, 0, 0, 255, 255, 255, 2, 2); To Set the Rect Area

	Local $msg

	Do

		$msg = GUIGetMsg()

		If $redraw = 1 Then

			$tile_drawn = 0
			_SDL_FillRect($screen, 0, 0)

			For $y = 0 To $gaGui_rect[3] - $tile_temp_h Step $tile_temp_h

				For $x = 0 To $gaGui_rect[2] - $tile_temp_w Step $tile_temp_w

					_SDL_BlitSurface($aTile[$player.iWorld_cur][$tile_drawn], 0, $screen, _SDL_Rect_Create($x, $y + $sdlt_rectreturn.h, $tile_temp_w, $tile_temp_h))
					$tile_drawn += 1
					If $tile_drawn > $tiles - 1 Then ExitLoop

				Next

				If $tile_drawn > $tiles - 1 Then ExitLoop

			Next

			_sge_rect($screen, $click_x * $tile_temp_w, $click_y * $tile_temp_h + $sdlt_rectreturn.h, $click_x * $tile_temp_w + $tile_temp_w, $click_y * $tile_temp_h + $tile_temp_h + $sdlt_rectreturn.h, 255)
			print($sCaption & " " & $math, $screen, 0, 0, 255, 255, 255, 2, 2)
			_SDL_Flip($screen)
			$redraw = 0

		EndIf

		If _IsPressed(1) Then; Mouse Left Click

			_SDL_GetMouseState($click_x, $click_y)
			$click_x = Int($click_x / $tile_temp_w)
			$click_y = Int(($click_y - $sdlt_rectreturn.h) / $tile_temp_h)
			$math = Int($click_y * ($gaGui_rect[2] / $tile_temp_w) + $click_x)
			If $math > -1 And $math < $tiles Then $redraw = 1

		EndIf

		If _IsPressed('0d') Then

			$confirm = 1
			ExitLoop

		EndIf

	Until $msg = $gui_event_close Or _IsPressed('1b')

	If $confirm = 0 Then $math = -1
	keyreleased('0D')
	Return $math

EndFunc   ;==>tile_select

Func tile_swap_id($layer, $tile_id_1, $tile_id_2, ByRef $aTile, ByRef $aWorld, $player, $swap_tile_graphic = 0)

	Local $flag = 0

	; Find in world
	For $y = 0 To $world_info[$player.iWorld_cur][$eWi_h] - 1

		For $x = 0 To $world_info[$player.iWorld_cur][$eWi_w] - 1

			$flag = 0
			If $aWorld[$player.iWorld_cur][$layer][$x][$y].iTile = $tile_id_1 Then

				$aWorld[$player.iWorld_cur][$layer][$x][$y].iTile = $tile_id_2
				$flag = 1

			EndIf

			If $flag = 0 Then

				If $aWorld[$player.iWorld_cur][$layer][$x][$y].iTile = $tile_id_2 Then $aWorld[$layer][$x][$y].iTile = $tile_id_1

			EndIf

		Next

	Next

	; Swap Graphic
	Local $surf

	If $swap_tile_graphic = 1 Then

		$surf = _SDL_DisplayFormat($aTile[$player.iWorld_cur][$tile_id_1]); Backup Tile 1
		_SDL_FreeSurface($aTile[$player.iWorld_cur][$tile_id_1]); Free Tile 1

		$aTile[$player.iWorld_cur][$tile_id_1] = _SDL_DisplayFormat($aTile[$player.iWorld_cur][$tile_id_2]); Tile 1 equals Tile 2
		_SDL_FreeSurface($aTile[$player.iWorld_cur][$tile_id_2]); Free Tile 2

		$aTile[$player.iWorld_cur][$tile_id_2] = _SDL_DisplayFormat($surf); Tile 2 equals Backup Tile
		;_SDL_SaveBMP($aTile[$tile_id_1], @ScriptDir & "\..\Graphics\dw3\tiles\" & $tile_id_1 & ".bmp")
		;_SDL_SaveBMP($aTile[$tile_id_2], @ScriptDir & "\..\Graphics\dw3\tiles\" & $tile_id_2 & ".bmp")

	EndIf

EndFunc   ;==>tile_swap_id

Func tile_save($aTile, $player, $filepath = "")

	If $filepath = "" Then $filepath = FileSelectFolder("Select Folder to Save Tiles", $folder_graphics)

	If $filepath = "" Then

		MsgBox(0, "tile_save: Error", "filepath= NULL", Default, $ghGui)
		Return

	EndIf

	out("tile_Save: " & $filepath)
	DirCreate($filepath)

	For $i = 0 To $world_info[$player.iWorld_cur][$eWi_tiles] - 1

		_SDL_SaveBMP($aTile[$player.iWorld_cur][$i], $filepath & "\" & $i & ".bmp")

	Next

	out("Tried to Write: " & $world_info[$player.iWorld_cur][$eWi_tiles] & " Tiles")

EndFunc   ;==>tile_save

Func tile_scale_y($aTile, $tile, $x, $y, $w, $h, $y2, $h2, $frames, $player); Created the Forect Tile Sheet

	Local $surf_size_x = 0, $surf_size_y = 0, $ww, $hh
	Local $srect
	Local $drect
	$srect = _SDL_Rect_Create($x, $y, $w, $h)
	Local $surf_temp = _SDL_DisplayFormat($aTile[$player.iWorld_cur][$tile]);										Copy Tile
	surf_size_get($surf_temp, $surf_size_x, $surf_size_y)
	Local $srect_y = _SDL_Rect_Create($w, $y2, $surf_size_x - $w, $h2)
	Local $surf_zoom_prep_x = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $w, $h, 32, 0, 0, 0, 255);	Zoom Prep Surface X
	Local $surf_zoom_prep_y = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $srect_y.w, $srect_y.h, 32, 0, 0, 0, 255);	Zoom Prep Surface Y
	_SDL_BlitSurface($surf_temp, $srect, $surf_zoom_prep_x, 0);							Blit srect to Zoom Prep Surface
	_SDL_BlitSurface($surf_temp, $srect_y, $surf_zoom_prep_y, 0);							Blit srect to Zoom Prep Surface

	;Save surface without the srects
	_SDL_FillRect($surf_temp, $srect, 0)
	_SDL_FillRect($surf_temp, $srect_y, 0)
	Local $surf_save = _SDL_DisplayFormat($aTile[$player.iWorld_cur][$tile])
	Local $surf_output = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $frames * $surf_size_x, $frames * $surf_size_y, 32, 0, 0, 0, 255)
	Local $surf_zoom

	For $x = 0 To $frames

		For $y = 0 To $frames

			;_SDL_FillRect($surf_save, 0, 0);											Clear Final Output Surface
			_SDL_BlitSurface($surf_temp, 0, $surf_save, 0)
			$surf_zoom = _SDL_zoomSurface($surf_zoom_prep_x, 1, 1 - $x * .1, 0);					X zoom scale
			$drect = _SDL_Rect_Create($srect.x, $srect.y + ($x * 2.5), $srect.w, $srect.h);		X drect
			_SDL_BlitSurface($surf_zoom, 0, $surf_save, $drect);							Blit X surf onto save

			_SDL_FreeSurface($surf_zoom);													Free Zoom Surface
			$surf_zoom = _SDL_zoomSurface($surf_zoom_prep_y, 1, 1 - $y * .1, 0);					Y zoom scale
			$drect = _SDL_Rect_Create($srect_y.x, $srect_y.y + ($y * 2.5), $srect_y.w, $srect_y.h);		Y drect
			_SDL_BlitSurface($surf_zoom, 0, $surf_save, $drect);							Blit Y surf onto save

			_SDL_BlitSurface($surf_save, 0, $surf_output, _SDL_Rect_Create($x * $surf_size_x, $y * $surf_size_x, $surf_size_x, $surf_size_y))
			_SDL_FreeSurface($surf_zoom)

		Next

	Next

	_SDL_SaveBMP($surf_output, @ScriptDir & "\" & $tile & "_.bmp")
	_SDL_FreeSurface($surf_output)
	_SDL_FreeSurface($surf_zoom_prep_x)
	_SDL_FreeSurface($surf_zoom_prep_y)
	_SDL_FreeSurface($surf_temp)
	_SDL_FreeSurface($surf_save)

EndFunc   ;==>tile_scale_y

Func settings_save($hGui)

	Local $file = FileOpen(@ScriptDir & "\Settings\" & $gScriptname & "_Settings.txt", BitOR($FO_OVERWRITE, $FO_CREATEPATH)); Probably could just add them together bitor() is the way we are supposd
	; Window Posititon
	$aiGui_rect = WinGetPos($hGui); 					Return Window Position
	FileWriteLine($file, "win_x: " & $aiGui_rect[0]);	Save Window Position
	FileWriteLine($file, "win_y: " & $aiGui_rect[1])

	; Save Default User Values
	FileWriteLine($file, "Area_outbounds_world: " & $aDefault_value[$eDefault_value_area_ob_world]);	Area Outbounds World

	FileClose($file)

EndFunc   ;==>settings_save

Func settings_load()

	Local $file = FileOpen(@ScriptDir & "\Settings\" & $gScriptname & "_Settings.txt"); Default Open for Reading
	$gaGui_rect[0] = read_chunk($file); Load Windows Last Position
	$gaGui_rect[1] = read_chunk($file)
	If $gaGui_rect[0] < 0 Or $gaGui_rect[0] > @DesktopWidth Then $gaGui_rect[0] = 0
	If $gaGui_rect[1] < 0 Or $gaGui_rect[1] > @DesktopWidth Then $gaGui_rect[1] = 0

	; Load Default User Values
	For $i = 0 To $default_value_max - 1

		$aDefault_value[$eDefault_value_area_ob_world] = read_chunk($file)

	Next

	FileClose($file)

EndFunc   ;==>settings_load

; Load BMPs in Folder to Tile Array
Func tile_load_folder(ByRef $aTile, $iWorld_info_ID, $folder_path, $iTiles, $set_size = 1)

	out("tile_load_folder: " & $folder_path & " " & $iTiles)
	For $i = 0 To $iTiles - 1

		If $aTile[$iWorld_info_ID][$i] <> 0 Then _SDL_FreeSurface($aTile[$iWorld_info_ID][$i]); Free Tile Surface

		$aTile[$iWorld_info_ID][$i] = _IMG_Load($folder_path & $i & ".bmp"); Load

		If $aTile[$iWorld_info_ID][$i] = 0 Then

			MsgBox(0, "tile_load_folder", "Error Loading File: " & $folder_path & $i & ".bmp")

		EndIf

	Next

	If $set_size = 1 Then surf_size_get($aTile[$iWorld_info_ID][0], $tile_w, $tile_h)

EndFunc   ;==>tile_load_folder

Func tile_fill_surface($tile_filepath, ByRef $dsurf)

	Local $dsurf_w = 0, $dsurf_h = 0, $tile_temp_w = 0, $tile_temp_h = 0
	surf_size_get($dsurf, $dsurf_w, $dsurf_h)

	Local $tile = _img_load($tile_filepath)
	surf_size_get($tile, $tile_temp_w, $tile_temp_h)

	If $tile_temp_w < 1 Or $tile_temp_h < 1 Then

		MsgBox(0, "tile_fill_surface Error", "Filling a Surface of size w: " & $dsurf_w & " h: " & $dsurf_h & " with Tile Size w: " & $tile_temp_w & " h: " & $tile_temp_h & @CRLF & "Results in endless loop")
		Return

	EndIf
	; Fill Display Surface with Tile
	Local $drect

	For $y = 0 To $dsurf_h Step $tile_temp_h

		For $x = 0 To $dsurf_w Step $tile_temp_w

			$drect = _SDL_Rect_Create($x, $y, $tile_temp_w, $tile_temp_h)
			_SDL_BlitSurface($tile, 0, $dsurf, $drect)

		Next;x

	Next;y

	_SDL_FreeSurface($tile)

EndFunc   ;==>tile_fill_surface

Func sun_adjust_light(ByRef $sun_layer)

	If TimerDiff($sun_layer.fTimer) > $sun_layer.iTimer_max Then;						Sun Timer

		$sun_layer.fTimer = TimerInit();										Reset Timer
		$sun_layer.iTicks += 1;											Count a Sun Tick

		If $sun_layer.iTicks >= $aSun_alpha[$sun_layer.iAlpha_index][1] Then;	Change Sun Alpha Target

			$sun_layer.iTicks = 0;										Reset Sun Ticks
			If $sun_layer.bSun_up = 1 Then;

				$sun_layer.iAlpha_index += 1
				If $sun_layer.iAlpha_index >= $aSun_alpha_max Then

					$sun_layer.bSun_up = 0
					$sun_layer.iAlpha_index -= 1

				EndIf

			Else

				$sun_layer.iAlpha_index -= 1
				If $sun_layer.iAlpha_index < 0 Then

					$sun_layer.bSun_up = 1
					$sun_layer.iAlpha_index = 0

				EndIf

			EndIf; sun_up

		EndIf; sun_layer_ticks

		If $sun_layer.bSun_up = 1 Then

			If $sun_layer.fAlpha <> $aSun_alpha[$sun_layer.iAlpha_index][0] Then;			Sun up

				$sun_layer.fAlpha += $sun_layer.fAlpha_incroment

				If $sun_layer.fAlpha > 255 Then

					$sun_layer.fAlpha = 255
					$sun_layer.bSun_up = 0

				EndIf

			EndIf

		Else

			If $sun_layer.fAlpha <> $aSun_alpha[$sun_layer.iAlpha_index][0] Then

				$sun_layer.fAlpha -= $sun_layer.fAlpha_incroment

				If $sun_layer.fAlpha <= 0 Then

					$sun_layer.bSun_up = 1
					$sun_layer.fAlpha = 0

				EndIf

			EndIf

		EndIf

		_SDL_SetAlpha($sun_layer.surf, $_SDL_SRCALPHA, $sun_layer.fAlpha)

	EndIf

EndFunc   ;==>sun_adjust_light

Func BG_animate(ByRef $BG_struct, ByRef $BGrect, $BGrect_go)

	$BG_struct.fFrame_timer = TimerInit(); Restart Timer

	$BGrect.x += $BGrect_go[$BG_struct.iWay][0] * $BG_struct.iWay_invert
	$BGrect.y += $BGrect_go[$BG_struct.iWay][1] * $BG_struct.iWay_invert

	If $BG_struct.iWay_invert > 0 Then

		If $BGrect.x > $tile_w - 1 Then $BGrect.x = 0
		If $BGrect.y > $tile_h - 1 Then $BGrect.y = 0
		$BG_struct.iWay_ticks += 1

	Else

		If $BGrect.x < 0 Then $BGrect.x = $bg_w - $gaGui_rect[2]
		If $BGrect.y < 0 Then $BGrect.y = $bg_h - $gaGui_rect[3]
		$BG_struct.iWay_ticks += 1

	EndIf

	If $BG_struct.iWay_ticks >= $BG_struct.iWay_tick_max Then

		$BG_struct.iWay_tick_max = Random(0, 100, 1)
		$BG_struct.iWay_ticks = 0

		If Random(0, 1, 1) = 1 Then

			Switch $BG_struct.iWay
				Case 2
					$BG_struct.iWay = 1
				Case 0
					$BG_struct.iWay = 1
				Case 1
					$BG_struct.iWay += Random(-1, 1, 1)
			EndSwitch;bg_way

		EndIf

	EndIf

EndFunc   ;==>BG_animate

Func BG_setup(ByRef $BG_struct, $timer_max = 50, $way_max = 3)

	$BG_struct.iFrame_timer_max = $timer_max
	$BG_struct.iWay_max = $way_max
	$BG_struct.iWay_tick_max = Random(1, 25, 1)
	$BG_struct.iWay_invert = 1

EndFunc   ;==>BG_setup

Func BG_setup_rect_way_go()

	Local $BGrect_go[3][2]

	$BGrect_go[0][0] = 1
	$BGrect_go[0][1] = 0
	$BGrect_go[1][0] = 1
	$BGrect_go[1][1] = 1
	$BGrect_go[2][0] = 0
	$BGrect_go[2][1] = 1

	Return $BGrect_go

EndFunc   ;==>BG_setup_rect_way_go

Func world_tile_set(ByRef $aWorld, $world_layer, $world_x, $world_y, $tile_id, $player, $tile_sub_x = 0, $tile_sub_y = 0)

	$aWorld[$player.iWorld_cur][$world_layer][$world_x][$world_y].iTile = $tile_id
	$aWorld[$player.iWorld_cur][$world_layer][$world_x][$world_y].iX = $tile_sub_x
	$aWorld[$player.iWorld_cur][$world_layer][$world_x][$world_y].iY = $tile_sub_y

EndFunc   ;==>world_tile_set

Func world_tile_draw(ByRef $aBoard, $aTile, $player, $aWorld, $world_x, $world_y)

	Local $srect = 0; Subset Tile of Tile
	Local $drect = _SDL_Rect_Create(($world_x - $player.iBoard_world_x) * $tile_w, ($world_y - $player.iBoard_world_y) * $tile_h, $tile_w, $tile_h)

	For $i = 0 To $world_info[$player.iWorld_cur][$eWi_layers] - 1

		$srect = _SDL_Rect_Create($aWorld[$player.iWorld_cur][$i][$world_x][$world_y].iX * $tile_w, $aWorld[$player.iWorld_cur][$i][$world_x][$world_y].iY * $tile_h, $tile_w, $tile_h)
		_SDL_BlitSurface($aTile[$player.iWorld_cur][$aWorld[$player.iWorld_cur][$i][$world_x][$world_y].iTile], $srect, $aBoard[$i], $drect)

	Next

EndFunc   ;==>world_tile_draw

Func sprite_sheet_create()

	Local $way_max = 4
	Local $frame_max = 2
	Local $surf_w = 0, $surf_h = 0
	Local $gender_name = ["Male", "Female"]
	Local $surf_output = _SDL_CreateRGBSurface($_SDL_SWSURFACE, 16 * 8, 16 * 8 * 2, 32, 0, 0, 0, 255)

	Local $surf
	For $gender = 0 To 1

		For $i = 0 To $dw3_player_class_max - 1

			For $way = 0 To $way_max - 1

				For $frame = 0 To $frame_max - 1

					$surf = _img_load($folder_graphics & "dw3\sprites\" & $dw3_player_class_name[$i] & " " & $gender_name[$gender] & "\" & $way & " " & $frame & ".bmp")
					surf_size_get($surf, $surf_w, $surf_h)
					_SDL_BlitSurface($surf, 0, $surf_output, _SDL_Rect_Create($way * $surf_w * $frame_max + $surf_w * $frame, ($surf_h * $gender * $dw3_player_class_max) + $i * $surf_h, $surf_w, $surf_h))
					_SDL_FreeSurface($surf)

				Next;frame

			Next;way

		Next;i

	Next;gender

	_SDL_SaveBMP($surf_output, $folder_graphics & "\sprite_sheet_dw3.bmp")

	_SDL_FreeSurface($surf_output)

EndFunc   ;==>sprite_sheet_create

Func sprite_sheet_load($step_x, $step_y, $filepath)

	Local $surf_w = 16, $surf_h = 16
	Local $way_max = 4
	Local $frame_max = 2
	Local $sprite_sheet_w, $sprite_sheet_h
	Local $sprite_sheet = _IMG_Load($filepath)

	surf_size_get($sprite_sheet, $sprite_sheet_w, $sprite_sheet_h)

	Local $aSurf[2][$sprite_sheet_h / $step_y + 1][4][2]

	Local $srect = 0

	Local $player_sprite_type = 0

	For $y = 0 To $sprite_sheet_h - 1 Step $step_y

		For $way = 0 To $way_max - 1

			For $frame = 0 To $frame_max - 1

				$aSurf[0][$player_sprite_type][$way][$frame] = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $surf_w, $surf_h, 32, 0, 0, 0, 255)

				$srect = _SDL_Rect_Create($way * $surf_w * $frame_max + $surf_w * $frame, $player_sprite_type * $surf_h, $surf_w, $surf_h)

				_SDL_BlitSurface($sprite_sheet, $srect, $aSurf[0][$player_sprite_type][$way][$frame], 0)

				$aSurf[1][$player_sprite_type][$way][$frame] = _SDL_zoomSurface($aSurf[0][$player_sprite_type][$way][$frame], 2, 2, 0)

				_SDL_SetColorKey($aSurf[0][$player_sprite_type][$way][$frame], $_SDL_SRCCOLORKEY, 0)

				_SDL_SetColorKey($aSurf[1][$player_sprite_type][$way][$frame], $_SDL_SRCCOLORKEY, 0)

			Next

		Next

		$player_sprite_type += 1

	Next

	_SDL_FreeSurface($sprite_sheet)

	Return $aSurf

EndFunc   ;==>sprite_sheet_load

Func label_control($gui, ByRef $aControl, $iControl_id, $sLabel, $label_x, $label_y, $label_w, $label_h, $sData_control_type, $data_x, $data_y, $data_w, $data_h, $data_value = "")

	$aControl[$iControl_id][$eControl_label] = GUICtrlCreateLabel($sLabel, $label_x, $label_y, $label_w, $label_h); Label Control
	Local $hImage_return = 0

	Switch $sData_control_type
		Case 'label'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateLabel($data_value, $data_x, $data_y, $data_w, $data_h)
		Case 'comboex'
			$aControl[$iControl_id][$eControl_data] = _GUICtrlComboBoxEx_Create($gui, $data_value, $data_x, $data_y, $data_w, $data_h, $CBS_DROPDOWNLIST);$CBN_SELCHANGE
			_GUICtrlComboBox_SetCurSel($aControl[$iControl_id][1], $data_value)
		Case 'comboex tilelist'
			$aControl[$iControl_id][$eControl_data] = _GUICtrlComboBoxEx_Create($gui, $data_value, $data_x, $data_y, $data_w, $data_h, $CBS_DROPDOWNLIST);$CBN_SELCHANGE
		Case 'combo'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateCombo($data_value, $data_x, $data_y, $data_w, $data_h, $CBS_DROPDOWNLIST)
			_GUICtrlComboBox_SetCurSel($aControl[$iControl_id][1], $data_value)
		Case 'button'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateButton($data_value, $data_x, $data_y, $data_w, $data_h)
		Case 'input'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateInput($data_value, $data_x, $data_y, $data_w, $data_h)
		Case 'input numonly'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateInput($data_value, $data_x, $data_y, $data_w, $data_h, $es_number)
		Case 'input readonly'
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateInput($data_value, $data_x, $data_y, $data_w, $data_h)
			GUICtrlSendMsg($aControl[$iControl_id][$eControl_data], $EM_SETREADONLY, 1, 0)
		Case "edit"
			$aControl[$iControl_id][$eControl_data] = GUICtrlCreateEdit($data_value, $data_x, $data_y, $data_w, $data_h, $ws_vscroll)
	EndSwitch;$type_string

	If UBound($aControl, 2) > $eControl_tip Then
		GUICtrlSetTip($aControl[$iControl_id][$eControl_data], $aControl[$iControl_id][$eControl_tip])
	EndIf

	Return $hImage_return

EndFunc   ;==>label_control

Func world_find_replace(ByRef $aWorld, $aTile, $player, $iTile_find = 0, $iTile_find_layer = 0)

	;Select layer, Select Tile to Find, Select Tile for Layer 0..layer_max OR No Change
	Local $control_pad_h = 45
	Local $hGui2 = GUICreate("World Find and Replace Tile", 320 + $tile_w, 180 + $tile_h * 2, 10, 10, Default, Default, $ghGui)
	Local $gui2_rect = WinGetPos($hGui2)
	Local Enum $eTile_find_id_comboex, $eTile_find_layer_combo, $eTile_replace_layer_combo, $eTile_replace_id_comboex, $eTile_replace_layer_nochange_checkbox
	Local $aControl[5][2]
	label_control($hGui2, $aControl, $eTile_find_layer_combo, "Find on Layer", 10, 10, 100, 120, "combo", 110, 10, 50, 100); Layer to Replace Tile On Combo
	label_control($hGui2, $aControl, $eTile_find_id_comboex, "Find Tile", 10, $control_pad_h, 100, 120, "comboex", 110, $control_pad_h, 100 + $tile_w, 420); Tile to Find ComboEx
	label_control($hGui2, $aControl, $eTile_replace_layer_combo, "Replace on Layer", 10, $control_pad_h + $tile_h + 20, 100, 120, "combo", 110, $control_pad_h + $tile_h + 20, 50, 420); Layer Modified with
	label_control($hGui2, $aControl, $eTile_replace_id_comboex, "Replace with Tile", 10, $control_pad_h + $tile_h + 55, 100, 120, "comboex", 110, $control_pad_h + $tile_h + 55, 100 + $tile_w, 420); Tile Replacement per Layer
	$aControl[4][$eControl_data] = GUICtrlCreateCheckbox("Don't Change Layer", 170, $control_pad_h + $tile_h + 20)
	Local $idConfirm = GUICtrlCreateButton("Confirm", $gui2_rect[2] - 110, $gui2_rect[3] - 60, 100, 20)
	; ImageList For Tile Lists
	Local $hImage = _GUIImageList_Create($tile_w, $tile_h, 6)
	For $i = 0 To $world_info[$player.iWorld_cur][$eWi_tiles] - 1; Fill ImageList and ComboExs with Tile BMPs
		_GUIImageList_AddBitmap($hImage, $folder_graphics & $world_info[$player.iWorld_cur][$eWi_filename] & "Tiles\" & $i & ".bmp")
		_GUICtrlComboBoxEx_AddString($aControl[$eTile_find_id_comboex][$eControl_data], $i, $i, $i); Populate Find Tile ComboBoxEx
		_GUICtrlComboBoxEx_AddString($aControl[$eTile_replace_id_comboex][$eControl_data], $i, $i, $i); Populate Replace on Layer Tile ComboBoxEx
	Next
	_GUICtrlComboBoxEx_SetImageList($aControl[$eTile_find_id_comboex][$eControl_data], $hImage); Set ImageList to Find Tile ComboEx
	_GUICtrlComboBoxEx_SetImageList($aControl[$eTile_replace_id_comboex][$eControl_data], $hImage); Set ImageList to Replace Tile ComboEx
	_GUICtrlComboBox_SetCurSel($aControl[$eTile_find_id_comboex][$eControl_data], $iTile_find); Set Default Find Tile Combo Selection
	_GUICtrlComboBox_SetCurSel($aControl[$eTile_replace_id_comboex][$eControl_data], $iTile_find); Set Default Replace Tile Combo Selection
	; Populate Layer ComboBoxes
	For $i = 0 To $world_info[$player.iWorld_cur][$eWi_layers] - 1; World Layers
		GUICtrlSetData($aControl[$eTile_find_layer_combo][$eControl_data], $i); Populate Tile Find Layer Combo
		GUICtrlSetData($aControl[$eTile_replace_layer_combo][$eControl_data], $i); Populate eTile_replace_layer_combo
	Next
	_GUICtrlComboBox_SetCurSel($aControl[$eTile_find_layer_combo][$eControl_data], $iTile_find_layer)
	_GUICtrlComboBox_SetCurSel($aControl[$eTile_replace_layer_combo][$eControl_data], 0)
	GUISetState()

	Local $confirm = 0
	Local $tile_replace_last = $iTile_find
	Local $aLayer_Replace[$world_info[$player.iWorld_cur][$eWi_layers]][2];[layer][0 Tile, 1 Modify_Layer]
	Local $msg
	Do
		$msg = GUIGetMsg()
		Switch $msg
			Case $aControl[$eTile_replace_layer_combo][$eControl_data]; Replace on Layer Combo Changed, Record the Information and Output New Layer Info
				$aLayer_Replace[$tile_replace_last][0] = _GUICtrlComboBox_GetCurSel($aControl[$eTile_replace_id_comboex][$eControl_data]); Store Replacement Tile ComboEx
				$aLayer_Replace[$tile_replace_last][1] = GUICtrlRead($aControl[$eTile_replace_layer_nochange_checkbox][$eControl_data]); Store Modify Layer Checkbox

				$tile_replace_last = Int(GUICtrlRead($aControl[$eTile_replace_layer_combo][$eControl_data])); Set the Controls to the New Layer Data
				_GUICtrlComboBox_SetCurSel($aControl[$eTile_replace_id_comboex][$eControl_data], $aLayer_Replace[$tile_replace_last][0]); Set Replace Tile ComboEx
				If $aLayer_Replace[$tile_replace_last][1] = 1 Then; Set the Don't Modify Checkbox State
					GUICtrlSetState($aControl[$eTile_replace_layer_nochange_checkbox][$eControl_data], $gui_checked); Checkbox CHECKED
				Else
					GUICtrlSetState($aControl[$eTile_replace_layer_nochange_checkbox][$eControl_data], $gui_unchecked); Checkbox UNCHECKED
				EndIf
			Case $idConfirm
				$confirm = 1
		EndSwitch
	Until $msg = $gui_event_close Or $confirm = 1
	If $confirm = 1 Then
		$aLayer_Replace[$tile_replace_last][0] = _GUICtrlComboBox_GetCurSel($aControl[$eTile_replace_id_comboex][$eControl_data])
		$aLayer_Replace[$tile_replace_last][1] = GUICtrlRead($aControl[$eTile_replace_layer_nochange_checkbox][$eControl_data])
		Local $tile_find = _GUICtrlComboBox_GetCurSel($aControl[$eTile_find_id_comboex][$eControl_data])
		Local $find_layer = GUICtrlRead($aControl[$eTile_find_layer_combo][$eControl_data])
		For $y = 0 To $world_info[$player.iWorld_cur][$eWi_h] - 1;y
			For $x = 0 To $world_info[$player.iWorld_cur][$eWi_w] - 1;x
				If $aWorld[$player.iWorld_cur][$find_layer][$x][$y].iTile = $tile_find Then
					For $i = 0 To $world_info[$player.iWorld_cur][$eWi_layers] - 1; I think the Layer Loop Needs done Like this to Search and Change All Layers
						If $aLayer_Replace[$i][1] <> 1 Then
							$aWorld[$player.iWorld_cur][$i][$x][$y].iTile = $aLayer_Replace[$i][0]
						EndIf
					Next
				EndIf;layer i
			Next;x
		Next;y
	EndIf;confirm= 1
	GUIDelete($hGui2)
	keyreleased(73); F4 In Case User ALT+F4 Closes Window Don't Close hgui

EndFunc   ;==>world_find_replace

Func person_put(ByRef $aPerson, ByRef $people, $iPic_type, $world_x, $world_y)

	$aPerson[$people].iWorld_x = $world_x
	$aPerson[$people].iWorld_y = $world_y
	$aPerson[$people].iPic_type = $iPic_type
	$people += 1

EndFunc   ;==>person_put

Func person_click_set($player, ByRef $aPerson, ByRef $people, $iPic_type)

	_SDL_GetMouseState($mouse_x, $mouse_y)
	$aPerson[$people].iWorld_x = $player.iBoard_world_x + Int($mouse_x / $tile_w)
	$aPerson[$people].iWorld_y = $player.iBoard_world_y + Int($mouse_y / $tile_h)
	person_put($aPerson, $people, $iPic_type, $player.iBoard_world_x + Int($mouse_x / $tile_w), $player.iBoard_world_y + Int($mouse_y / $tile_h))
	$people += 1
	Sleep(1000)

EndFunc   ;==>person_click_set

Func person_draw($player, $aPerson, $people, ByRef $dest_surf)

	Local $dis_x
	Local $dis_y
	Local $drect

	For $i = 0 To $people - 1

		$dis_x = $aPerson[$i].iWorld_x - $player.iX
		$dis_y = $aPerson[$i].iWorld_y - $player.iY

		If Abs($dis_x) < $tiles_on_screen_w Then

			If Abs($dis_y) < $tiles_on_screen_h Then

				$drect = _SDL_Rect_Create($aPerson[$i].iWorld_x + $dis_x * $tile_w, $aPerson[$i].iWorld_y + $dis_y * $tile_h, 32, 32)
				_SDL_BlitSurface($person_surf[1][$aPerson[$i].iPic_type][$aPerson[$i].iWay][$aPerson[$i].iFrame], 0, $dest_surf, $drect)

			EndIf

		EndIf

	Next

EndFunc   ;==>person_draw

Func gui_board_size_set(ByRef $aBoard, $board_layers)

	Local $hGui2 = GUICreate("Change Board Size", 240, 100, Default, Default, Default, Default, $ghGui)
	Local $gui2_rect = WinGetPos($hGui2)
	Local $aControl[2][2]

	label_control($hGui2, $aControl, 0, "Board Width", 10, 10, 100, 20, "input numonly", 110, 10, 50, 20, $board_w)
	label_control($hGui2, $aControl, 1, "Board Height", 10, 40, 100, 20, "input numonly", 110, 40, 50, 20, $board_h)
	Local $confirm_button = GUICtrlCreateButton("Confirm", $gui2_rect[2] - 80, $gui2_rect[3] - 55, 55, 20)
	GUISetState()

	Local $confirm = 0
	Local $msg

	Do

		$msg = GUIGetMsg()
		If $msg = $confirm_button Or _IsPressed('0d') Then $confirm = 1

	Until $msg = $gui_event_close Or $confirm = 1

	If $confirm = 1 Then

		$board_w = Int(GUICtrlRead($aControl[0][$eControl_data]))
		$board_h = Int(GUICtrlRead($aControl[1][$eControl_data]))
		board_create($aBoard, $board_layers, $board_w, $board_h); Create resized Board

	EndIf

	keyreleased(73); F4

	GUIDelete($hGui2)

	Return $confirm

EndFunc   ;==>gui_board_size_set

Func file_scale()

	Local $hGui2 = GUICreate("Scale File", 350, 240, Default, Default, Default, Default, $ghGui)
	Local $gui2_rect = WinGetPos($hGui2)
	Local $aControl[5][2]
	label_control($hGui2, $aControl, 0, "Scale File", 5, 5, 60, 20, "edit", 5, 25, 345, 40)
	label_control($hGui2, $aControl, 1, "File Dimensions", 10, 70, 80, 20, "input readonly", 100, 70, 100, 20)
	label_control($hGui2, $aControl, 2, "Scale Width", 5, 120, 60, 20, "input numonly", 80, 120, 55, 20)
	label_control($hGui2, $aControl, 3, "Height", 180, 120, 60, 20, "input numonly", 220, 120, 55, 20)
	label_control($hGui2, $aControl, 4, "Output BMP", 5, 140, 60, 20, "edit", 5, 160, 345, 40)
	Local $browse_button = GUICtrlCreateButton("Browse", 295, 0, 55, 20)
	Local $confirm_button = GUICtrlCreateButton("Confirm", $gui2_rect[2] - 65, $gui2_rect[3] - 55, 55, 20)
	GUISetState()
	Local $read_pic = 0
	Local $surf, $w, $h
	Local $confirm = 0
	Local $msg
	Local $filepath = ""
	Local $filename = ""
	Local $surf_output

	Do

		$msg = GUIGetMsg()

		Switch $msg

			Case $aControl[0][$eControl_data]
				$read_pic = 1

			Case $browse_button

				$filepath = FileOpenDialog("Select Picture File", $folder_graphics, $filter_pic, Default, Default, $ghGui)

				If @error = 0 Then

					GUICtrlSetData($aControl[0][$eControl_data], $filepath)

					If GUICtrlRead($aControl[4][$eControl_data]) = "" Then

						$filepath = StringMid($filepath, 1, StringInStr($filepath, ".", Default, -1) - 1); Remove Extention
						$filename = " Scaled.bmp"
						GUICtrlSetData($aControl[4][$eControl_data], $filepath & $filename)

					EndIf

				EndIf

				$read_pic = 1
			Case $confirm_button
				$confirm = 1
		EndSwitch

		If $read_pic = 1 Then

			$read_pic = 0

			If $surf <> 0 Then _SDL_FreeSurface($surf)

			$surf = _IMG_Load(GUICtrlRead($aControl[0][$eControl_data]))
			surf_size_get($surf, $w, $h)

			GUICtrlSetData($aControl[1][$eControl_data], $w & " " & $h)

		EndIf

	Until $msg = $gui_event_close Or $confirm = 1

	If $confirm = 1 Then

		$surf_output = _SDL_zoomSurface($surf, GUICtrlRead($aControl[2][$eControl_data]), GUICtrlRead($aControl[3][$eControl_data]), 0); Scale and Copy Back
		_SDL_SaveBMP($surf_output, GUICtrlRead($aControl[4][$eControl_data]))

	EndIf

	GUIDelete($hGui2)

EndFunc   ;==>file_scale

Func world_manage_layers(ByRef $aWorld, $aTile, $player)

	Local $hGui2 = GUICreate("World New Empty Layer", 350, 200, Default, Default, Default, Default, $ghGui)
	Local $aControl[10][2]
	Local $confirm = 0
	Local $layer_combo_label = GUICtrlCreateLabel("World Layer", 10, 10, 65, 20)
	Local $layer_combo = GUICtrlCreateCombo(0, 75, 10, 45, 20, $CBS_DROPDOWNLIST)
	GUICtrlCreateLabel("/", 130, 10)
	Local $layer_max_input = GUICtrlCreateInput($world_info[$player.iWorld_cur][$eWi_layers], 160, 10, 40, 20)

	GUICtrlSendMsg($layer_max_input, $EM_SETREADONLY, 1, 0)

	For $i = 1 To $world_info[$player.iWorld_cur][$eWi_layers] - 1

		GUICtrlSetData($layer_combo, $i)

	Next

	Local $layer_view_button = GUICtrlCreateButton("View Layer As File", 250, 10)
	Local $layer_remove_button = GUICtrlCreateButton("X", 210, 10, 20, 20)

	label_control($hGui2, $aControl, 0, "World Width", 10, 45, 60, 20, "input numonly", 15, 65, 55, 20, $world_info[$player.iWorld_cur][$eWi_w])
	label_control($hGui2, $aControl, 1, "Height", 90, 45, 60, 20, "input numonly", 90, 65, 55, 20, $world_info[$player.iWorld_cur][$eWi_h])
	label_control($hGui2, $aControl, 2, "Tiles", 160, 45, 30, 20, "input numonly", 160, 65, 55, 20, $world_info[$player.iWorld_cur][$eWi_tiles])
	label_control($hGui2, $aControl, 3, "Fill With Tile", 150, 125, 75, 20, "input numonly", 220, 125, 45, 20, 0)
	Local $confirm_button = GUICtrlCreateButton("Add New Layer", 150, 100, 95, 20)

	GUISetState()

	Local $msg
	Local $layer
	Local $layer_max
	Local $filepath = ""
	Local $filename = ""
	Do

		$msg = GUIGetMsg()

		Switch $msg

			Case $layer_remove_button

				If $world_info[$player.iWorld_cur][$eWi_layers] > 0 Then

					$layer = _GUICtrlComboBox_GetCurSel($layer_combo)
					$layer_max = GUICtrlRead($layer_max_input)

					For $i = $layer To $layer_max - 2

						For $y = 0 To $world_info[$player.iWorld_cur][$eWi_h] - 1

							For $x = 0 To $world_info[$player.iWorld_cur][$eWi_w] - 1

								$aWorld[$player.iWorld_cur][$i][$x][$y] = $aWorld[$player.iWorld_cur][$i + 1][$x][$y]

							Next

						Next

					Next

					$world_info[$player.iWorld_cur][$eWi_layers] -= 1

					GUICtrlSetData($layer_max_input, $world_info[$player.iWorld_cur][$eWi_layers])

				EndIf; layers> 0

			Case $layer_view_button

				$layer = _GUICtrlComboBox_GetCurSel($layer_combo)
				$filepath = @ScriptDir & "\" & $layer & " Temp World.txt"
				world_save_layer($aWorld, $layer, $aTile, $player, $filepath, 0)
				ShellExecute("Notepad", $filepath, @ScriptDir, "open")
				$filename = getfilename($filepath)
				WinWait($filename & " - Notepad", "", 5)
				FileDelete($filepath)

			Case $confirm_button

				$confirm = 1

		EndSwitch

	Until $msg = $gui_event_close Or $confirm = 1

	If $confirm = 1 Then

		Local $tile_fill = GUICtrlRead($aControl[3][$eControl_data])
		Local $new_id = $world_info[$player.iWorld_cur][$eWi_layers]
		$world_info[$player.iWorld_cur][$eWi_layers] += 1
		$world_info[$player.iWorld_cur][$eWi_w] = Int(GUICtrlRead($aControl[0][$eControl_data]))
		$world_info[$player.iWorld_cur][$eWi_h] = Int(GUICtrlRead($aControl[1][$eControl_data]))

		For $y = 0 To $world_info[$player.iWorld_cur][$eWi_h] - 1

			For $x = 0 To $world_info[$player.iWorld_cur][$eWi_w] - 1

				out("Add cell: " & $player.iWorld_cur & " " & $new_id & " " & $x & " " & $y)
				$aWorld[$player.iWorld_cur][$new_id][$x][$y] = DllStructCreate($tagWorld_struct)
				$aWorld[$player.iWorld_cur][$new_id][$x][$y].iTile = $tile_fill

			Next

		Next

	EndIf

	GUIDelete($hGui2)

EndFunc   ;==>world_manage_layers

Func world_area_save($aWorld, $aTile, $aArea, $aHotspot, $player, $filepath = "")

	Local $aField_labels = ["eArea_iX: ", "eArea_iY: ", "eArea_iW: ", "eArea_iH: ", _
			"eArea_iOb_tile: ", "eArea_sOb_world: ", "eArea_iOb_x: ", "eArea_iOb_y: ", _
			"eArea_hotspots: ", "eArea_items: ", "eArea_people: "]
	If $filepath = "" Then;	On NULL Filepath Launch GUI File Browser Dialog

		If $folder_world_last_path = "" Then

			$filepath = FileSaveDialog("Save World File Info", $folder_graphics, "World Info txt (*.txt)", Default, "", $ghGui)

		Else

			$filepath = FileSaveDialog("Save World File Info", $folder_world_last_path, "World Info txt (*.txt)", Default, "", $ghGui)

		EndIf

	EndIf

	Local $file = FileOpen($filepath, $fo_overwrite);											Okay Open the Area File For Writing and Overwrite that Bitch

	; Write World Header
	FileWriteLine($file, "Layers: " & $world_info[$player.iWorld_cur][$eWi_layers]); 1 								How many Layers
	FileWriteLine($file, "Width: " & $world_info[$player.iWorld_cur][$eWi_w]); 2								Width (how many Tiles Wide)
	FileWriteLine($file, "Height: " & $world_info[$player.iWorld_cur][$eWi_h]); 3							Height ( ^ ) ( ^ )
	FileWriteLine($file, "Tiles: " & $world_info[$player.iWorld_cur][$eWi_tiles]); 4									Maximume Tile Index Stored in World

	; Write Area Data
	For $i = 1 To $aArea[$player.iWorld_cur][0][0]

		FileWriteLine($file, "Area: " & $i); 5											Area Label Labels the Areas Index

		For $ii = 0 To $area_data_max - 1

			FileWriteLine($file, $aField_labels[$ii] & $aArea[$player.iWorld_cur][$i][$ii])

		Next

	Next

	FileClose($file); Close Area File

	Local $folder_path = getfolder($filepath)

	$file = FileOpen($folder_path & "\World_Hotspots.txt", $fo_overwrite)

	; Write Hotspot Data Per Area
	For $i = 1 To $aArea[$player.iWorld_cur][0][0]

		For $ii = 0 To $aArea[$player.iWorld_cur][$player.iWorld_cur][$eArea_hotspots] - 1

			For $iii = 0 To $hotspot_data_max - 1

				FileWriteLine($file, $aHotspot[$player.iWorld_cur][$i][$ii][$iii])

			Next

		Next

	Next

	FileClose($file); Close Hotspot File

EndFunc   ;==>world_area_save

Func world_area_load(ByRef $aWorld, ByRef $aTile, ByRef $aArea, $iWorld_info_ID, $world_folder_path = "")

	Local $timer = TimerInit(); Start Timer by Recording the Time
	Local $aField_labels = ["iX: ", "iY: ", "iW: ", "iH: ", "iTile: "]

	If $world_folder_path = "" Then; If No File Path is Directed then Launch Dialog File Browser

		$world_folder_path = FileSelectFolder("Select World Folder", $folder_graphics) & "\"
		out("world_folder_path: " & $world_folder_path)

		If @error <> 0 Then Return 1; If error<> 0 then return 1

	EndIf

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
	tile_load_folder($aTile, $iWorld_info_ID, $folder_world_last_path & "Tiles\", $world_dest_tiles);			Tile Array
	out("Load_world_area: aTile:" & $world_info[$iWorld_info_ID][$eWi_tiles])
	out("world_area_load() Completed in: " & TimerDiff($timer))

	Return $aWorld; Return dynamic World Size of File Header

EndFunc   ;==>world_area_load

Func world_mouse_pos($aWorld, $player)

	Local $world_coords[2]

	_SDL_GetMouseState($mouse_x, $mouse_y)

	Local $top_left_x = $player.iX - ($tiles_on_screen_w / 2)
	Local $target_x = $top_left_x + ($mouse_x + $player.iMod_x) / $tile_w; - $aPlayer[0].iMod_x

	Local $top_left_y = $player.iY - ($tiles_on_screen_h / 2)
	Local $target_y = $top_left_y + ($mouse_y + $player.iMod_y) / $tile_h; - $aPlayer[0].iMod_y

	$world_coords[0] = Int($target_x)
	$world_coords[1] = Int($target_y)

	Return $world_coords

EndFunc   ;==>world_mouse_pos

Func world_mouse_pos_byref($aWorld, $player, ByRef $coord_x, ByRef $coord_y)

	_SDL_GetMouseState($mouse_x, $mouse_y)

	Local $top_left_x = $player.iX - ($tiles_on_screen_w / 2)
	Local $top_left_y = $player.iY - ($tiles_on_screen_h / 2)

	Local $target_x = $top_left_x + ($mouse_x + $player.iMod_x) / $tile_w
	Local $target_y = $top_left_y + ($mouse_y + $player.iMod_y) / $tile_h

	$coord_x = Int($target_x)
	$coord_y = Int($target_y)

EndFunc   ;==>world_mouse_pos_byref

Func world_area_find($aArea, $world_x, $world_y, $player)

	out("world_area_find() world_x: " & $world_x & " y: " & $world_y)

	For $i = 1 To $aArea[$player.iWorld_cur][0][0];area[0-3]xywh
		out("world_area_find() " & $i & " aArea[$i][0]: " & $aArea[$player.iWorld_cur][$i][0] & " y: " & $aArea[$player.iWorld_cur][$i][1] & " w " & $aArea[$player.iWorld_cur][$i][2] & " h " & $aArea[$player.iWorld_cur][$i][3])
		If $world_x > $aArea[$player.iWorld_cur][$i][0] - 1 And $world_x < $aArea[$player.iWorld_cur][$i][2] And $world_y > $aArea[$player.iWorld_cur][$i][1] - 1 And $world_y < $aArea[$player.iWorld_cur][$i][3] Then
			Return $i
		EndIf
	Next

	Return -1; Not In an Area

EndFunc   ;==>world_area_find

Func gui_area_create(ByRef $aControl_return, ByRef $aArea, $aTile, $player, $area_edit_cur = 1)

	; Create GUI Sub Window
	Local $hGui2 = GUICreate("Area Edit", 340, $area_data_max * 30 + $tile_h + 20, Default, Default, Default, Default, $ghGui)
	Local $gui2_rect = WinGetPos($hGui2); Sub Window Rect

	Local Enum $eidArea_id_combo = $area_data_max, $eidArea_confirm_button, $eidArea_delete_button, $eidArea_total_input, $eidArea_browse_button

	Local $aControl[$area_data_max + 5][4] = [[0, "X", $eInput_numonly, ""], [0, "Y", $eInput_numonly, ""], [0, "W", $eInput_numonly, ""], [0, "H", $eInput_numonly, ""], _
			[0, "Out Bounds Tile", $eComboex_pic, ""], [0, "Out Bounds World", $eInput, ""], [0, "Out Bounds X", $eInput_numonly, ""], [0, "Out Bounds Y", $eInput_numonly, ""], _
			[0, "Hotspots", $eInput_readonly, ""], [0, "Items", $eInput_readonly, ""], [0, "People", $eInput_readonly, ""], [0, "Area Index:", 9001, ""]]

	; Create GUI Controls
	Local $cursor = 40; The y axis to draw control

	For $i = 0 To $area_data_max - 1

		Switch $aControl[$i][$eControl_type]

			Case $eInput; Input

				out("string: " & $aArea[$player.iWorld_cur][$area_edit_cur][$i])
				label_control($hGui2, $aControl, $i, $aControl[$i][$eControl_label], 10, $cursor, 90, 20, "input", 100, $cursor, 155, 20, $aArea[$player.iWorld_cur][$area_edit_cur][$i])
				$cursor += 25

			Case $eInput_numonly; Input Numonly

				label_control($hGui2, $aControl, $i, $aControl[$i][$eControl_label], 10, $cursor, 90, 20, "input numonly", 100, $cursor, 90, 20, $aArea[$player.iWorld_cur][$area_edit_cur][$i])
				$cursor += 25

			Case $eInput_readonly; Input ReadOnly

				label_control($hGui2, $aControl, $i, $aControl[$i][$eControl_label], 10, $cursor, 90, 20, "input numonly", 100, $cursor, 90, 20, $aArea[$player.iWorld_cur][$area_edit_cur][$i])
				GUICtrlSendMsg($aControl[$i][$eControl_data], $EM_SETREADONLY, 1, 0)
				$cursor += 25

			Case $eComboex_pic; ComboEx Pic

				label_control($hGui2, $aControl, $i, $aControl[$i][$eControl_label], 10, $cursor, 90, 20, "comboex", 100, $cursor, 100, 420)
				$cursor += $tile_h + 10

		EndSwitch; type

	Next

	GUICtrlSetTip($aControl[$eArea_ob_tile][$eControl_label], "World Tiles will be drawn within the Area Defined Above.  This Tile will be Drawn Outside that Area Above. "); Tool Tip for eidArea_tile_comboex

	$aControl[$eidArea_total_input][$eControl_data] = GUICtrlCreateInput("/ " & $aArea[$player.iWorld_cur][0][0], 220, 10, 75); Area Total Input (readonly)
	GUICtrlSendMsg($aControl[$eidArea_total_input][$eControl_data], $EM_SETREADONLY, 1, 0); ^ )

	$aControl[$eidArea_delete_button][$eControl_data] = GUICtrlCreateButton("Delete", 20, $gui2_rect[3] - 50, 55, 20)
	$aControl[$eidArea_confirm_button][$eControl_data] = GUICtrlCreateButton("Confirm", $gui2_rect[2] - 70, $gui2_rect[3] - 50, 55, 20)
	$aControl[$eidArea_browse_button][$eControl_data] = GUICtrlCreateButton("Browse", 260, 40 + 4 * 25 + $tile_h + 10, 55, 20)

	Local $hImage = _GUIImageList_Create($tile_w, $tile_h, 6); Image List for ComboboxEx

	For $i = 0 To $world_info[$player.iWorld_cur][$eWi_tiles] - 1; Fill it with Tiles from the Last Loaded Tile Path

		_GUIImageList_AddBitmap($hImage, $folder_graphics & $world_info[$player.iWorld_cur][$eWi_filename] & "Tiles\" & $i & ".bmp")
		_GUICtrlComboBoxEx_AddString($aControl[$eArea_ob_tile][$eControl_data], $i, $i, $i)

	Next

	_GUICtrlComboBoxEx_SetImageList($aControl[$eArea_ob_tile][$eControl_data], $hImage)

	label_control($hGui2, $aControl, $eidArea_id_combo, "Area Index:", 10, 10, 60, 20, "combo", 100, 10, 55, 20); Area Index [ 1..aArea[0][0] ] Combobox
	control_populate_index_combo($aControl, $eidArea_id_combo, $aArea[$player.iWorld_cur][0][0]); Update Area Index Selection Combobox

	_GUICtrlComboBox_SelectString($aControl[$eidArea_id_combo][$eControl_data], $area_edit_cur);						Combo Area Selected
	_GUICtrlComboBox_SetCurSel($aControl[$eArea_ob_tile][$eControl_data], $aArea[$player.iWorld_cur][$area_edit_cur][$eArea_ob_tile]);	ComboEx Outbounds Tile

	GUISetState();										Show Sub Window

	WinActivate($hGui2)

	GUICtrlSetState($aControl[$eidArea_id_combo][$eControl_data], $gui_focus)

	$aControl_return = $aControl

	Return $hGui2

EndFunc   ;==>gui_area_create

Func gui_area_message(ByRef $aControl, ByRef $aArea, $aTile, $player, ByRef $area_edit_cur, ByRef $point, $aWorld, ByRef $selection_surf)

	Local $confirm = 0
	Local Enum $eidArea_id_combo = $area_data_max, $eidArea_confirm_button, $eidArea_delete_button, $eidArea_total_input, $eidArea_browse_button

	Local $msg = GUIGetMsg()

	Switch $msg

		Case $aControl[$eidArea_id_combo][$eControl_data]; Change Area Index Selection

			area_edit_controls_read($aControl, $aArea, $area_edit_cur, $player); Copy Current Data to Area Array
			$area_edit_cur = Int(GUICtrlRead($aControl[$eidArea_id_combo][$eControl_data]))
			area_edit_controls_set($aControl, $aArea, $area_edit_cur, $player)

		Case $aControl[$eidArea_confirm_button][$eControl_data]; Confirm Changes to Area Data

			$area_edit_cur = _GUICtrlComboBox_GetCurSel($aControl[$eidArea_id_combo][$eControl_data]) + 1; Read the Current Selected Control
			area_edit_controls_read($aControl, $aArea, $area_edit_cur, $player); Copy Current GUI Data to Area Array
			If $aArea[$player.iWorld_cur][$aArea[$player.iWorld_cur][0][0]][$eArea_x] <> "" Then
				out("This big: " & $aArea[$player.iWorld_cur][0][0])
				$aArea[$player.iWorld_cur][$aArea[$player.iWorld_cur][0][0]][$eArea_ob_tile] = $aWorld[$player.iWorld_cur][0][$aArea[$player.iWorld_cur][$aArea[$player.iWorld_cur][0][0]][$eArea_x]] _
						[$aArea[$player.iWorld_cur][$aArea[$player.iWorld_cur][0][0]][$eArea_y]].iTile
				$aArea[$player.iWorld_cur][0][0] += 1
			EndIf
			Return 1

		Case $aControl[$eidArea_delete_button][$eControl_data];	Remove an Area from the Area Array

			_GUICtrlComboBox_SelectString($aControl[$eidArea_id_combo][$eControl_data], $area_edit_cur)
			If $aArea[$player.iWorld_cur][0][0] > 0 Then $aArea[$player.iWorld_cur][0][0] -= 1
			; Copy Areas Down starting at area_edit_cur
			For $i = $area_edit_cur To $aArea[$player.iWorld_cur][0][0]
				For $ii = 0 To $area_data_max - 1; Copy All the Data
					$aArea[$player.iWorld_cur][$i][$ii] = $aArea[$player.iWorld_cur][$i + 1][$ii]
				Next
			Next
			If $aArea[$player.iWorld_cur][0][0] < 1 Then
				MsgBox(0, "Warning", "The last Area cannot be deleted unless you also save all of your Area Changes Now", Default, $ghGui)
				$confirm = 1
			EndIf
			control_populate_index_combo($aControl, $eidArea_id_combo, $aArea[$player.iWorld_cur][0][0]); Update Area Index Selection Combobox
			GUICtrlSetData($aControl[$eidArea_total_input][$eControl_data], "/ " & $aArea[$player.iWorld_cur][0][0]); 						Update GUI Total Areas Input
			If $area_edit_cur > $aArea[$player.iWorld_cur][0][0] Then $area_edit_cur = $aArea[$player.iWorld_cur][0][0];				If Deleted
			_GUICtrlComboBox_SetCurSel($aControl[$eidArea_id_combo][$eControl_data], $area_edit_cur - 1)
			area_edit_controls_set($aControl, $aArea, $area_edit_cur, $player)

		Case $gui_event_close

			Return 2

	EndSwitch;msg

	If _IsPressed('1B') Then; Escape
		Return 2
	EndIf

	If WinActive($ghGui) Then

		If _IsPressed(47) Then; g get outbound position of mouse cursor in world

			Local $world_po = world_mouse_pos($aWorld, $player)
			GUICtrlSetData($aControl[$eArea_ob_x][$eControl_data], $world_po[0])
			GUICtrlSetData($aControl[$eArea_ob_y][$eControl_data], $world_po[1])

		EndIf

	EndIf

	If _IsPressed(20) Then; SPACE Set Area

		Local $area_cur = Int(GUICtrlRead($aControl[$eidArea_id_combo][$eControl_data]))

		If $point = 0 Then
			world_mouse_pos_byref($aWorld, $player, $aArea[$player.iWorld_cur][$area_cur][0], $aArea[$player.iWorld_cur][$area_cur][1])
			world_mouse_pos_byref($aWorld, $player, $aArea[$player.iWorld_cur][$area_cur][2], $aArea[$player.iWorld_cur][$area_cur][3])
			$point += 1
		Else
			world_mouse_pos_byref($aWorld, $player, $aArea[$player.iWorld_cur][$area_cur][2], $aArea[$player.iWorld_cur][$area_cur][3])
			If $aArea[$player.iWorld_cur][$area_cur][0] > $aArea[$player.iWorld_cur][$area_cur][2] Then
				$i = $aArea[$player.iWorld_cur][$area_cur][2]
				$aArea[$player.iWorld_cur][$area_cur][2] = $aArea[$player.iWorld_cur][$area_cur][0]
				$aArea[$player.iWorld_cur][$area_cur][0] = $i
			EndIf
			If $aArea[$player.iWorld_cur][$area_cur][1] > $aArea[$player.iWorld_cur][$area_cur][3] Then
				$i = $aArea[$player.iWorld_cur][$area_cur][3]
				$aArea[$player.iWorld_cur][$area_cur][3] = $aArea[$player.iWorld_cur][$area_cur][1]
				$aArea[$player.iWorld_cur][$area_cur][1] = $i
			EndIf
			$point = 0
		EndIf

		GUICtrlSetData($aControl[$eArea_x][$eControl_data], $aArea[$player.iWorld_cur][$area_cur][0])
		GUICtrlSetData($aControl[$eArea_y][$eControl_data], $aArea[$player.iWorld_cur][$area_cur][1])
		GUICtrlSetData($aControl[$eArea_w][$eControl_data], $aArea[$player.iWorld_cur][$area_cur][2])
		GUICtrlSetData($aControl[$eArea_h][$eControl_data], $aArea[$player.iWorld_cur][$area_cur][3])
		selection_surf_draw($selection_surf, $aArea[$player.iWorld_cur][$area_cur][0], $aArea[$player.iWorld_cur][$area_cur][1], $aArea[$player.iWorld_cur][$area_cur][2], $aArea[$player.iWorld_cur][$area_cur][3], $player)
		keyreleased(20); SPACE

	EndIf

EndFunc   ;==>gui_area_message

Func area_edit_controls_read($aControl, ByRef $aArea, $area_edit_cur, $player)

	For $i = 0 To $area_data_max - 1
		Switch $aControl[$i][$eControl_type]
			Case $eInput, $eInput_numonly, $eInput_readonly
				$aArea[$player.iWorld_cur][$area_edit_cur][$i] = GUICtrlRead($aControl[$i][$eControl_data])
			Case $eComboex_pic; Pic ComboEx
				$aArea[$player.iWorld_cur][$area_edit_cur][$i] = _GUICtrlComboBox_GetCurSel($aControl[$i][$eControl_data]); Copy Tile
		EndSwitch
	Next

EndFunc   ;==>area_edit_controls_read

Func area_edit_controls_set(ByRef $aControl, $aArea, $area_edit_cur, $player)

	For $i = 0 To 3; 																								Update Area Rect GUI Controls
		GUICtrlSetData($aControl[$i][$eControl_data], $aArea[$player.iWorld_cur][$area_edit_cur][$i])
	Next
	_GUICtrlComboBox_SetCurSel($aControl[$eArea_ob_tile][$eControl_data], $aArea[$player.iWorld_cur][$area_edit_cur][$eArea_ob_tile]); Update Tile ComboEx Control
	For $i = 5 To $area_data_max - 1; 																					Convert rest of the Area Data
		GUICtrlSetData($aControl[$i][$eControl_data], $aArea[$player.iWorld_cur][$area_edit_cur][$i])
	Next

EndFunc   ;==>area_edit_controls_set

Func control_populate_index_combo(ByRef $aControl, $index, $max)

	GUICtrlSetData($aControl[$index][$eControl_data], "");		Clear Area Id Selection ComboBox

	For $i = 1 To $max
		GUICtrlSetData($aControl[$index][$eControl_data], $i);	Fill ComboBox with New Areas or Whatever
	Next

EndFunc   ;==>control_populate_index_combo

Func gui_hotspot_create(ByRef $aControl_return, ByRef $aArea, ByRef $aHotspot_list, $player)

	If $aArea[$player.iWorld_cur][0][0] < 1 Then; Hotspots are assigned to Areas
		MsgBox(0, "Alert", "There are no Areas to Edit or View" & @CRLF & "Hotspots must be set to an Area.  First Create an Area", Default, $ghGui)
		Return; No Areas No Hotspots!
	EndIf

	Local $hotspot_cur = $aHotspot_list[0][0]; Cur Set to Max

	; Create GUI Sub Window
	Local $hGui2 = GUICreate("Hotspot Edit", 340, 6 * 30 + $tile_h + 20, Default, Default, Default, Default, $ghGui); Sub GUI Window to Edit Hotspot Data
	Local $gui2_rect = WinGetPos($hGui2);																			 Rect Array Containing the Dimentions of the Sub GUI Window

	; 4 Extra controls confirm, delete, total
	Local $aControl[$hotspot_data_max + 4][3] = [[0, "iX", $eInput_numonly], [0, "iY", $eInput_numonly], _
			[0, "sDest_world_file", $eInput], [0, "iDest_x", $eInput_numonly], [0, "iDest_y", $eInput_numonly], _
			[0, "index_combo", 9001]]
	Local Enum $eidHotspot_id_combo = $hotspot_data_max, $eidHotspot_total_input, $eidHotspot_remove_button, $eidHotspot_confirm_button

	; Create GUI Controls
	Local $control_label_x = 10, $control_label_y = 40; Ahh the Label Colume
	Local $control_data_x = 115; and the Data x Colume

	For $i = 0 To $hotspot_data_max - 1

		Switch $aControl[$i][$eControl_type]

			Case $eInput; Input

				label_control($hGui2, $aControl, $i, $aControl[$i][$eControl_label], $control_label_x, $control_label_y, 90, 20, "input", $control_data_x, $control_label_y, 155, 20, $aHotspot_list[$hotspot_cur][$i])
				$control_label_y += 25

			Case $eInput_numonly; Input Numonly

				label_control($hGui2, $aControl, $i, $aControl[$i][$eControl_label], $control_label_x, $control_label_y, 90, 20, "input numonly", $control_data_x, $control_label_y, 90, 20, $aHotspot_list[$hotspot_cur][$i])
				$control_label_y += 25

			Case $eInput_readonly; Input ReadOnly

				label_control($hGui2, $aControl, $i, $aControl[$i][$eControl_label], $control_label_x, $control_label_y, 90, 20, "input numonly", $control_data_x, $control_label_y, 90, 20, $aHotspot_list[$hotspot_cur][$i])
				GUICtrlSendMsg($aControl[$i][$eControl_data], $EM_SETREADONLY, 1, 0)
				$control_label_y += 25

		EndSwitch; type

	Next; i

	label_control($hGui2, $aControl, $eidHotspot_id_combo, "Hotspot Index:", $control_label_x, 10, 70, 20, "combo", $control_data_x, 10, 55, 20); The GUI Combobox to Select a Hotspot

	$aControl[$eidHotspot_remove_button][$eControl_data] = GUICtrlCreateButton("Delete", 20, $gui2_rect[3] - 50, 55, 20); Delete Hotspot Button
	$aControl[$eidHotspot_confirm_button][$eControl_data] = GUICtrlCreateButton("Confirm", $gui2_rect[2] - 70, $gui2_rect[3] - 50, 55, 20); Confirm Changes to Hotspot_list

	control_populate_index_combo($aControl, $eidHotspot_id_combo, $aHotspot_list[0][0]); Adds Indexs to Hotspot Combobox [1..hotspot_max]
	_GUICtrlComboBox_SelectString($aControl[$eidHotspot_id_combo][$eControl_data], $hotspot_cur); Selects the Most Recent Hotspot from the Combobox

	$aControl[$eidHotspot_total_input][$eControl_data] = GUICtrlCreateInput("/ " & $aHotspot_list[0][0], 220, 10, 75); Hotspots Total

	GUICtrlSendMsg($aControl[$eidHotspot_total_input][$eControl_data], $EM_SETREADONLY, 1, 0); Make eidHotspot_total_input ReadOnly

	GUISetState()

	WinActivate($hGui2)

	hotspot_controls_set($aControl, $aHotspot_list, $hotspot_cur, $player); Load New Data into Control

	$aControl_return = $aControl

	Return $hGui2

EndFunc   ;==>gui_hotspot_create

Func gui_hotspot_message(ByRef $aControl, ByRef $aHotspot_list, $aArea, $player, ByRef $hotspot_cur, $aWorld)

	Local Enum $eidHotspot_id_combo = $hotspot_data_max, $eidHotspot_total_input, $eidHotspot_remove_button, $eidHotspot_confirm_button

	Local $msg = GUIGetMsg(1)

	Switch $msg[0]

		Case $aControl[$eidHotspot_id_combo][$eControl_data]; Select Hotspot Index ComboBox

			hotspot_controls_read($aControl, $aHotspot_list, $hotspot_cur, $player); Save data to array before switching data
			$hotspot_cur = _GUICtrlComboBox_GetCurSel($aControl[$eidHotspot_id_combo][$eControl_data]) + 1; Get New Data Index
			hotspot_controls_set($aControl, $aHotspot_list, $hotspot_cur, $player); Load New Data into Control

		Case $aControl[$eidHotspot_confirm_button][$eControl_data]; Confirm Button

			$hotspot_cur = _GUICtrlComboBox_GetCurSel($aControl[$eidHotspot_id_combo][$eControl_data]) + 1
			hotspot_controls_read($aControl, $aHotspot_list, $hotspot_cur, $player); Read the Controls into the Hotkey_cur
			If $aHotspot_list[$aHotspot_list[0][0]][$eHSpot_iX] <> "" Then $aHotspot_list[0][0] += 1
			Return 1

		Case $aControl[$eidHotspot_remove_button][$eControl_data]; Remove Hotspot Button

			If $aHotspot_list[0][0] > 1 Then
				$hotspot_cur = _GUICtrlComboBox_GetCurSel($aControl[$eidHotspot_id_combo][$eControl_data]) + 1
				; Sort Down
				For $i = $hotspot_cur To $aHotspot_list[0][0] - 1
					For $ii = 0 To $hotspot_data_max - 1
						$aHotspot_list[$i][$ii] = $aHotspot_list[$i + 1][$ii]
					Next
				Next
				$aHotspot_list[0][0] -= 1
				control_populate_index_combo($aControl, $eidHotspot_id_combo, $aHotspot_list[0][0]); Adds Indexs to Hotspot Combobox [1..hotspot_max]
				If $hotspot_cur > $aHotspot_list[0][0] Then $hotspot_cur = $aHotspot_list[0][0]
				_GUICtrlComboBox_SelectString($aControl[$eidHotspot_id_combo][$eControl_data], $hotspot_cur)
				GUICtrlSetData($aControl[$eidHotspot_total_input][$eControl_data], "/ " & $aHotspot_list[0][0]); Update Hotspot Total Input
				hotspot_controls_set($aControl, $aHotspot_list, $hotspot_cur, $player); Load New Data into Control
			EndIf;hotspot_total> 1

		Case $gui_event_close
			Return 2

	EndSwitch; msg

	If _IsPressed('1B') Then; Escape
		Return 2
	EndIf

	If _IsPressed('20') Then; Spacebar

		If GUICtrlRead($aControl[$eHSpot_iX][$eControl_data]) = "" Or GUICtrlRead($aControl[$eHSpot_iY][$eControl_data]) = "" Then

			world_mouse_pos_byref($aWorld, $player, $aHotspot_list[$hotspot_cur][$eHSpot_iX], $aHotspot_list[$hotspot_cur][$eHSpot_iY])

		Else

			world_mouse_pos_byref($aWorld, $player, $aHotspot_list[$hotspot_cur][$eHSpot_iDest_x], $aHotspot_list[$hotspot_cur][$eHSpot_iDest_y])
			If GUICtrlRead($aControl[$eHSpot_sDest_world_file][$eControl_data]) = "" Then $aHotspot_list[$hotspot_cur][$eHSpot_sDest_world_file] = $world_info[$player.iWorld_cur][$eWi_filename]

		EndIf; Fill Empty Point

		hotspot_controls_set($aControl, $aHotspot_list, $hotspot_cur, $player); Load New Data into Control
		keyreleased('20')

	EndIf; _ispressed() SPACEBAR

	Return 0

EndFunc   ;==>gui_hotspot_message

Func hotspot_controls_read($aControl, ByRef $aHotspot_list, $hotspot_cur, $player)

	Local $x

	For $i = 0 To $hotspot_data_max - 1

		Switch $aControl[$i][$eControl_type]

			Case $eInput, $eInput_readonly

				$aHotspot_list[$hotspot_cur][$i] = GUICtrlRead($aControl[$i][$eControl_data])

			Case $eInput_numonly

				$x = GUICtrlRead($aControl[$i][$eControl_data])
				If $x <> "" Then $aHotspot_list[$hotspot_cur][$i] = Int($x)

		EndSwitch; type

	Next

EndFunc   ;==>hotspot_controls_read

Func hotspot_controls_set(ByRef $aControl, $aHotspot_list, $hotspot_cur, $player)

	For $i = 0 To $hotspot_data_max - 1 ; Update Area Rect GUI Controls

		GUICtrlSetData($aControl[$i][$eControl_data], $aHotspot_list[$hotspot_cur][$i])

	Next

EndFunc   ;==>hotspot_controls_set

Func hotspot_count($aArea, $player); Count Total Hotspots

	Local $hotspot_total = 0; Forget How Many We Think We Have

	For $i = 1 To $aArea[$player.iWorld_cur][0][0]; 	Loop through all the Areas

		$hotspot_total += $aArea[$player.iWorld_cur][$i][$eArea_hotspots]; Add Up the Hotspots per Area

	Next

	Return $hotspot_total

EndFunc   ;==>hotspot_count

Func hotspot_area_to_list($aArea, $aHotspot, ByRef $aHotspot_list, $player)

	Local $HSList_n = 1

	For $i = 1 To $aArea[$player.iWorld_cur][0][0]; Copy Hotspot From Areas to Single List

		For $ii = 0 To $aArea[$player.iWorld_cur][$i][$eArea_hotspots] - 1

			For $iii = 0 To $hotspot_data_max - 1

				$aHotspot_list[$HSList_n][$iii] = $aHotspot[$player.iWorld_cur][$i][$ii][$iii]

			Next

			$HSList_n += 1

		Next

	Next

	Return $HSList_n;

EndFunc   ;==>hotspot_area_to_list

Func hotspot_list_to_area(ByRef $aHotspot, ByRef $aArea, $aHotspot_list, $player)

	For $i = 1 To $aArea[$player.iWorld_cur][0][0]; Clear Hotspot

		$aArea[$player.iWorld_cur][$i][$eArea_hotspots] = 0

	Next

	Local $hotspot_area

	For $i = 1 To $aHotspot_list[0][0] - 1; Copy List into Hotspot Array Sorted by Area

		$hotspot_area = world_area_find($aArea, $aHotspot_list[$i][$eHSpot_iX], $aHotspot_list[$i][$eHSpot_iY], $player); Find the Area the Hotspot is Located in

		If $hotspot_area > -1 Then

			For $ii = 0 To $hotspot_data_max - 1; Copy the Data

				$aHotspot[$player.iWorld_cur][$hotspot_area][$aArea[$player.iWorld_cur][$hotspot_area][$eArea_hotspots]][$ii] = $aHotspot_list[$i][$ii]

			Next

			$aArea[$player.iWorld_cur][$hotspot_area][$eArea_hotspots] += 1

		Else

			MsgBox(0, "", "Hotspot Not Located Within Any Area" & @CRLF & "HotSpot " & $i & "Removed X: " & $aHotspot_list[$i][$eHSpot_iX] & " Y: " & $aHotspot_list[$i][$eHSpot_iY], Default, $ghGui)

		EndIf

	Next

EndFunc   ;==>hotspot_list_to_area

Func settings_default_values_edit()

	; Create GUI Sub Window
	Local $hGui2 = GUICreate("Default Values Edit", 450, $default_value_max * 25 + 50, Default, Default, Default, Default, $ghGui); Sub GUI Window to Edit Default Values
	Local $gui2_rect = WinGetPos($hGui2);																			 Rect Array Containing the Dimentions of the Sub GUI Window
	Local $aControl = [[0, "Outbounds World", 0, "The default world assign if out of bounds of world"]]

	GUISetState(); Show Sub Window

	For $i = 0 To $default_value_max - 1

		Switch $aControl[$i][$eControl_type]

			Case $eInput

				label_control($hGui2, $aControl, $i, $aControl[$i][$eControl_label], 10, 10, 100, 20, "input", 125, 10, 185, 20, $aDefault_value[$i])

		EndSwitch

	Next

	Local $confirm_button = GUICtrlCreateButton("Confirm", $gui2_rect[2] - 80, $gui2_rect[3] - 55, 55, 20)
	Local $confirm = 0
	Local $msg

	Do

		$msg = GUIGetMsg()

		Switch $msg

			Case $confirm_button

				$confirm = 1

		EndSwitch

	Until $msg = $gui_event_close Or $confirm = 1

	If $confirm = 1 Then

		For $i = 0 To $default_value_max - 1

			Switch $aControl[$i][$eControl_type]

				Case $eInput

					$aDefault_value[$i] = GUICtrlRead($aControl[$i][$eControl_data])

			EndSwitch

		Next

	EndIf

	GUIDelete($hGui2)

EndFunc   ;==>settings_default_values_edit

Func item_define_routine($itemid, $name, $attordef, $special = 0)

	$item[$itemid][$eItem_name] = $name
	$item[$itemid][$eItem_attordef] = $attordef
	$item[$itemid][$eItem_special] = $special

EndFunc   ;==>item_define_routine

; Make sure to shift state save information + 1 to fit it in this chart!
Func items_define()

	Local $timer = TimerInit()

	item_define_routine(1, "Cypress Stick", 2);WEAPONS
	item_define_routine(2, "Club", 7)
	item_define_routine(3, "Copper Sword", 12)
	item_define_routine(4, "Magic Knife", 14)
	item_define_routine(5, "Iron Spear", 28)
	item_define_routine(6, "Battle Axe", 40)
	item_define_routine(7, "Broad Sword", 33)
	item_define_routine(8, "Wizard's Wand", 15, 1);Item - casts Blaze
	item_define_routine(9, "Poison Needle", 1, 2);chance to kill target instantly
	item_define_routine(10, "Iron Claw", 30)
	item_define_routine(11, "Thorn Whip", 18)
	item_define_routine(12, "Giant Shears", 48)
	item_define_routine(13, "Chain Sickle", 24)
	item_define_routine(14, "Thor's Sword", 95, 3);Item - casts firevolt
	item_define_routine(15, "Snowblast Sword", 80, 4);Item - casts snowblast
	item_define_routine(16, "Demon Axe", 90, 5);Powerful, but misses more often than a sword.
	item_define_routine(17, "Staff of Rain", 45, 6);couldn't match name to database
	item_define_routine(18, "Sword of Gaia", 48, 7);used to open path to Necrogond, cannot be dropped or sold
	item_define_routine(19, "Staff of Reflection", 33, 8);casts bounce
	item_define_routine(20, "Sword of Destruction", 110, 9);cause the weilder to freeze randomly
	item_define_routine(21, "Multi-Edge Sword", 100, 10);;cursed attacks wielder of sword
	item_define_routine(22, "Staff of Force", 55, 11);uses 3mp per attack
	item_define_routine(23, "Sword of Illusion", 50, 12);casts chaos, female only
	item_define_routine(24, "Zombie Slasher", 65, 13);Does extra damage to undead enemies
	item_define_routine(25, "Falcon Sword", 5, 14);Attacks twice per round; useful against Metal Babbles.
	item_define_routine(26, "Sledge Hammer", 55)
	item_define_routine(27, "Thunder Sword", 85, 15);casts boom
	item_define_routine(28, "Staff of Thunder", 30, 16);casts firebane when used as item by any class
	item_define_routine(29, "Sword of Kings", 120, 17);casts Firevolt, need to beat Zoma, sell Oricon to aquire
	item_define_routine(30, "Orochi Sword", 63, 18);casts defence
	item_define_routine(31, "Dragon Killer", 77, 19);Does extra damage to dragon enemies, including the armored tortoises
	item_define_routine(32, "Staff of Judgement", 35, 20);casts infernos
	item_define_routine(33, "Clothes", 4);ARMOR
	item_define_routine(34, "Training Suit", 10)
	item_define_routine(35, "Leather Armor", 12)
	item_define_routine(36, "Flashy Clothes", 28)
	item_define_routine(37, "Half Plate Armor", 25)
	item_define_routine(38, "Full Plate Armor", 32)
	item_define_routine(39, "Magic Armor", 40, 21);Magic Armor = +40 w/ reduction in magic damage. not verified not in database
	item_define_routine(40, "Cloak of Evasion", 20, 22);Wearer has increased evasion. An additional %20 chance the enemy will miss.
	item_define_routine(41, "Armor of Radiance", 75, 23);heal 1 hp per step, need to beat Zoma, cannot be sold or dropped
	item_define_routine(42, "Iron Apron", 22)
	item_define_routine(43, "Animal Suit", 8, 24);Makes the character look like a cat, but has no practical value
	item_define_routine(44, "Fighting Suit", 23)
	item_define_routine(45, "Sacred Robe", 30, 25);Protection against Blaze spells
	item_define_routine(46, "Armor of Hades", 65, 26);cursed immobalizes the wearer
	item_define_routine(47, "Water Flying Cloth", 40, 27);Protection against all fire attacks (magic or physical)
	item_define_routine(48, "Chain Mail", 20)
	item_define_routine(49, "Wayfarer's Clothes", 8)
	item_define_routine(50, "Revealing Swimsuit", 1, 28);Females only (when worn, the appearance will change) - no use at all
	item_define_routine(51, "Magic Bikini", 40, 29);Females only (when worn, the appearance will change). Cannot be sold or dropped.
	item_define_routine(52, "Shell Armor", 16)
	item_define_routine(53, "Armor of Terrafirma", 50, 30);cannot be sold or dropped
	item_define_routine(54, "Dragon Mail", 45, 31);Reduces Fire breath damage by 1/3. Does not affect any other type of breath attack.
	item_define_routine(55, "Swordedge Armor", 55, 32);Certain enemies are damaged when they attack someone wearing this armor. Cannot be sold or dropped.
	item_define_routine(56, "Angel's Robe", 35, 33);Slight protection against Defeat & Beat spells
	;shields
	item_define_routine(57, "Leather Shield", 4)
	item_define_routine(58, "Iron Shield", 12)
	item_define_routine(59, "Shield of Strength", 40, 34);Item - casts Healmore. Can be used as an item by ANY class.
	item_define_routine(60, "Shield of Heroes", 50, 35);The strongest shield, and needed to defeat Zoma. Cannot be sold or dropped.
	item_define_routine(61, "Shield of Sorrow", 35, 36);Cursed - damages allies when the wearer is attacked
	item_define_routine(62, "Bronze Shield", 7)
	item_define_routine(63, "Silver Shield", 30)
	;helmets
	item_define_routine(64, "Golden Crown", 6, 37);A special item that you won't have long enough to be of use. Cannot be sold or dropped.
	item_define_routine(65, "Iron Helmet", 16)
	item_define_routine(66, "Mysterious Hat", 8, 38);Reduces MP cost by 20tem_define_routine(67, "Unlucky Helmet", 35, 39);Cursed - luck is reduced to zero. Cannot be sold or dropped.
	item_define_routine(68, "Turban", 8)
	item_define_routine(69, "Noh Mask", 255, 40);Cursed - permanently confused and cannot cast spells outside of battle
	item_define_routine(70, "Leather Helmet", 2)
	item_define_routine(71, "Iron Mask", 25, 41);The strongest helmet

	item_define_routine(72, "Sacred Amulet", 0, 42);Reduces the effectiveness of Defeat family spells on its user.
	item_define_routine(73, "Ring of Life", 0, 43);Restores HP as you walk
	item_define_routine(74, "Shoes of Happiness", 0, 44);Wearer gains experience every few steps.
	item_define_routine(75, "Golden Claw", 55, 45);Dramatically increases your encounter rate, even if unequipped. Sell or store in the vault until you want it.
	item_define_routine(76, "Meteorite Armband", 0, 46);Doubles the agility of the person who wears it.
	item_define_routine(77, "Book of Satori", 47)
	$item[78][0] = "(blank)"

	item_define_routine(79, "Wizard's Ring", 0, 48);Restores 16-32 MPs to the user. Every use carries a chance that the ring will be destroyed
	item_define_routine(80, "Black Pepper", 0, 49);
	item_define_routine(81, "Sage's Stone", 0, 50);When used in battle, it has the same effect as a Healus spell. It can be used any number of times.
	item_define_routine(82, "Mirror of Ra", 0, 51);
	item_define_routine(83, "Vase of Drought", 0, 52);
	item_define_routine(84, "Lamp of Darkness", 0, 53);
	item_define_routine(85, "Staff of Change", 0, 54);
	item_define_routine(86, "Stone of Light", 0, 55);
	item_define_routine(87, "Invisibility Herb", 0, 56);
	item_define_routine(88, "Magic Ball", 0, 57);
	item_define_routine(89, "Thief's Key", 0, 58);
	item_define_routine(90, "Magic Key", 0, 59);
	item_define_routine(91, "Final Key", 0, 60);
	$item[92][0] = "Dream Ruby"
	$item[93][0] = "Wake Up Powder"
	$item[94][0] = "Royal Scroll"
	$item[95][0] = "Oricon"
	$item[96][0] = "Strength Seed"
	$item[97][0] = "Agility Seed"
	$item[98][0] = "Vitality Seed"
	$item[99][0] = "Luck Seed"
	$item[100][0] = "Intelligence Seed"
	$item[101][0] = "Acorns of Life"
	$item[102][0] = "Medical Herb"
	$item[103][0] = "Antidote Herb"
	$item[104][0] = "Fairy Water"
	$item[105][0] = "Wing of Wyvern"
	$item[106][0] = "Leaf of World Tree"
	$item[107][0] = "(blank)"
	$item[108][0] = "Locket of Love"
	$item[109][0] = "Full Moon Herb"
	$item[110][0] = "Water Blaster"
	$item[111][0] = "Sailor's Thigh Bone"
	$item[112][0] = "Echoing Flute"
	$item[113][0] = "Fairy Flute"
	$item[114][0] = "Silver Harp"
	$item[115][0] = "Sphere of Light"
	item_define_routine(116, "Poison Moth Powder", 0, 10);Provides the same effect as a Chaos spell, confusing enemies
	$item[117][0] = "Spider's Web"
	$item[118][0] = "Stones of Sunlight"
	$item[119][0] = "Rainbow Drop"
	$item[120][0] = "Silver Orb"
	$item[121][0] = "Red Orb"
	$item[122][0] = "Yellow Orb"
	$item[123][0] = "Purple Orb"
	$item[124][0] = "Blue Orb"
	$item[125][0] = "Green Orb"
	$item[126][0] = "Stick Slime"
	$item[127][0] = "Black Raven"
	$item[128][0] = "Sword Horned"

	; Store Total n
	$item[0][0] = 128

	out("items_define: " & $item[0][0] & "Completed in: " & TimerDiff($timer))
	out(); Carrage Return

EndFunc   ;==>items_define

; Console
Func console_out($sMsg, $iPlayerNet_index = -1, $iCmd_type = -1)

	; Write to log file
	Local $file = FileOpen($gConsole_log_path, BitOR($FO_CREATEPATH, $FO_APPEND))

	FileWriteLine($file, $sMsg)

	FileClose($file)

	sound_play("windowopen.wav"); Play sound to alert console update

	If $gConsole_show = 1 Then

		$gConsole_cursor += 1

		If $gConsole_cursor > $gConsole_line_max - 1 Then $gConsole_cursor = 0

	EndIf

	Local $cursor_po_y = 5 + $gConsole_cursor * ($font.iH * 2 + $gConsole_text_pad_y)

	; Clear Text Row
	_SDL_FillRect($gConsole_text_surf, _SDL_Rect_Create(5, $cursor_po_y, $gaGui_rect[2], $font.iH), 0)

	;$time= "[ "& @hour&":"&@Min&":"&@SEC&" ] "
	print2($sMsg, $gConsole_text_surf, 5, $cursor_po_y); Print msg on Console
	$gConsole_print_rect = $sdlt_rectreturn
	out("Rect: " & $gConsole_print_rect.x)
	out("Rect: " & $gConsole_print_rect.y)
	out("Rect: " & $gConsole_print_rect.w)
	out("Rect: " & $gConsole_print_rect.h)
	; Set Timer used to hide console
	$gConsole_timer = TimerInit()

	$gConsole_show = 1; Console is now shown to display update

EndFunc   ;==>console_out

Func sound_play($sound_filename, $repeat= 0, $dont_play= 0, $volume= 100)

	; Stop
	out("Stop channel: "&$gSound_cur)

	_BASS_ChannelStop($gaSound[$gSound_cur])

	; Free
	_BASS_StreamFree($gaSound[$gSound_cur])

	; Load
	$gaSound[$gSound_cur] = _BASS_StreamCreateFile(False, $gSounds_path & $sound_filename, 0, 0, $repeat)

	;if FileExists( $gSounds_path & $sound_filename) then ShellExecute( $gSounds_path & $sound_filename)

	; Set Volume
	_BASS_ChannelSetVolume($gaSound[$gSound_cur], $volume)

	;Iniate playback
	if $dont_play= 0 then

		_BASS_ChannelPlay($gaSound[$gSound_cur], $repeat)

	endif

	; Incroment Sound_cur Index
	$gSound_cur+= 1

	If $gSound_cur >= $gSound_max Then $gSound_cur = 1

EndFunc   ;==>sound_play

Func _exit()

	; Sockets
	UDPCloseSocket($gaSocket_send[$eSocket])
	UDPCloseSocket($gaSocket_recv[$eSocket])

	; Network
	UDPShutdown()

	; Audio
	_BASS_Free(); All your base
	If $__SDL_DLL <> -1 Then _SDL_Quit()
	If $__SDL_DLL_image <> -1 Then _SDL_Shutdown_image()
	If $__SDL_DLL_sge <> -1 Then _SDL_Shutdown_sge()
	If $__SDL_DLL_sprig <> -1 Then _SDL_Shutdown_sprig();)
	If $__SDL_DLL_GFX <> -1 Then _SDL_Shutdown_gfx()

EndFunc   ;==>_exit

Func packet_header_create($player, $cmd_type = $ePacket_type_pos)

	Local $packet_header = ""

	$packet_header = $gPacket_key & $gPacket_Seporator & _
			$gNet_sequence_frame & $gPacket_Seporator & _
			$cmd_type & $gPacket_Seporator & _
			$player.iX & $gPacket_Seporator & _
			$player.iY & $gPacket_Seporator

	Return $packet_header

EndFunc   ;==>packet_header_create

Func client_send($player)

	$gNet_sequence_frame += 1

	If $gNet_sequence_frame > $gNet_sequence_frame_max Then

		$gNet_sequence_frame = 0

	EndIf

	Local $packet_data = packet_header_create($player, $ePacket_type_pos)

	UDPSend($gaSocket_send[$eSocket], $packet_data)

EndFunc   ;==>client_send

Func client_recv()

	Local $timer = TimerInit()

	Local $packet_data = UDPRecv($gaSocket_recv[$eSocket], 255)

	;socket_info($gaSocket_recv, "", 1)

	Local $aSplit = StringSplit($packet_data, $gPacket_Seporator)

	Local $playerNet_socket_index = 0

	Local $note = ""

	Local $x = 0

	;out("client_recv() Split[0]: "&$aSplit[0]&" "&$packet_data)
	If $aSplit[0] >= $ePacket_header_read_type Then

		; Key filters possiable noise
		If $aSplit[$ePacket_header_read_key] = $gPacket_key Then

			; debug
			out("Recv packet: " & $packet_data)

			$playerNet_socket_index = $aSplit[$ePacket_header_read_player_source]

			Switch $aSplit[$ePacket_header_read_type]

				Case 0 To $ePacket_type_connect_player - 1

					; Update playernet positions
					$gaPlayerNet[$playerNet_socket_index][$ePlayerNet_x] = $aSplit[$ePacket_header_read_x]
					$gaPlayerNet[$playerNet_socket_index][$ePlayerNet_y] = $aSplit[$ePacket_header_read_y]

					out("xxx: " & $gaPlayerNet[$playerNet_socket_index][$ePlayerNet_x])

					; This Transfers the Player Information
				Case $ePacket_type_connect_player

					; If not last join packet
					If $gaSocket_recv[$eSocket_connected_sequence] <> $playerNet_socket_index Then

						; This will NULL within 30 seconds
						$gaSocket_recv[$eSocket_connected_sequence] = $playerNet_socket_index

						For $i = 1 To $playerNet_data_max - 1

							$gaPlayerNet[$playerNet_socket_index][$i] = $aSplit[$ePacket_header_read_type + $i]

						Next

						;_ArrayDisplay($gaPlayerNet)

						$note = $gaPlayerNet[$playerNet_socket_index][$ePlayerNet_name] & _; Player Name
								" joined our world.  " & $gVillian & "'s minions grow stronger."

						console_out($note, $playerNet_socket_index, $ePacket_type_connect_player)

						$gaPlayer_indexs[$gServer_players] = $playerNet_socket_index

						$gServer_players += 1

						; Socket Join timeout
						$gSocket_join_timeout = TimerInit()

					EndIf; join timeout

				Case $ePacket_type_disconnect_player

					If $gaSocket_recv[$eSocket_disconnected_sequence] <> $playerNet_socket_index Then

						$gaSocket_recv[$eSocket_disconnected_sequence] = $playerNet_socket_index

						$note = $gaPlayerNet[$playerNet_socket_index][$ePlayerNet_name] & _; Player Name
								" left our world.  " & $gVillian & "'s minions weaken."

						console_out($note, $playerNet_socket_index, $ePacket_type_disconnect_player)

						; Get cell index
						For $i = 0 To $gServer_players - 1

							If $gaPlayer_indexs[$i] = $playerNet_socket_index Then

								$x = $i

								ExitLoop

							EndIf

						Next

						; Shift down
						For $i = $x To $gaPlayer_indexs - 1

							$gaPlayer_indexs[$i] = $gaPlayer_indexs[$i + 1]

						Next

						;_ArrayDisplay($playerNet_socket_index)

						$gServer_players -= 1

					EndIf;

				Case $ePacket_type_chat

					If $aSplit[$ePacket_header_read_type + 2] <> $gaServer_player[$playerNet_socket_index][$eServer_player_chat_sequenece] Then

						$gaServer_player[$playerNet_socket_index][$eServer_player_chat_sequenece] = $aSplit[$ePacket_header_read_type + 2]

						console_out($gaPlayerNet[$playerNet_socket_index][$ePlayerNet_name] & ": " & $aSplit[$ePacket_header_read_type + 1]);, $gaPlayerNet[$playerNet_socket_index][$ePlayerNet_name], $ePacket_type_chat)

						;$gaSocket_recv[$playerNet_socket_index][$eSocket_chat_sequence]

					EndIf

					;console_out($gaPlayerNet[$playerNet_socket_index][$ePlayerNet_name]&" : "&$aSplit[$ePacket_header_read_type+1]);, $gaPlayerNet[$playerNet_socket_index][$ePlayerNet_name], $ePacket_type_chat)

					;MsgBox(0, @ScriptName, "socket_index: "&$playerNet_socket_index&" "&$aSplit[$ePacket_header_read_type+1]&" Name: "&$gaPlayerNet[$playerNet_socket_index][$ePlayerNet_name], 1, $ghGUI)

			EndSwitch; type


			If WinActive($ghGui) Then

				If _IsPressed('7A') Then; F11

					MsgBox(0, @ScriptName, "Recieved: " & $packet_data, 1, $ghGui)

				EndIf; ispressed(7A)

			EndIf; winactive()

			$gServer_timeout = 0

		EndIf; key

	Else

		$gServer_timeout += 1

		; Connection Timed out
		If $gServer_timeout > $gServer_timeout_len Then

			MsgBox(0, @ScriptName, "gServer_timeout> gServer_timeout_len", 2, $ghGui)

			$gServer_timeout = 0

			$gNet_role = $eNet_role_private

		EndIf

	EndIf; aSplit[0] >= ePacket_header_type (enough data)

	out("gNet_role: " & $gNet_role)
	Return $gNet_role

	;out("client_recv timer: "&TimerDiff($timer))

EndFunc   ;==>client_recv

;Global Enum $ePlayer_x, $ePlayer_y, $ePlayer_world, $ePlayer_name, $ePlayer_class, $ePlayer_lvl, $ePlayer_gold, $ePlayer_xp
Func packet_player($player, $aPlayer_item)

	; Key
	Local $packet_data = $gPacket_key & $gPacket_Seporator

	; Sequence Number
	$packet_data &= $gNet_sequence_frame & $gPacket_Seporator

	; Type
	$packet_data &= $ePacket_type_connect_player & $gPacket_Seporator; This is a type

	; Data
	$packet_data &= $player.iX & $gPacket_Seporator & _
			$player.iY & $gPacket_Seporator & _
			$player.iWorld_cur & $gPacket_Seporator & _
			$player.caName & $gPacket_Seporator & _
			$player.iLvl & $gPacket_Seporator & _
			$player.iClass & $gPacket_Seporator & _
			$player.iXp & $gPacket_Seporator & _
			$player.iGold & $gPacket_Seporator

	For $i = 0 To $player_item_max - 1

		For $ii = 0 To $player_item_data_max - 1
			$packet_data &= $aPlayer_item[$i][$ii] & $gPacket_Seporator
		Next

		debug_key($packet_data)

	Next

	out("Packet_data: " & $packet_data & " > " & StringLen($packet_data))

	Return $packet_data
EndFunc   ;==>packet_player

Func packet_player_recv($packet_data)

	;Local $packet_data = $gPacket_key & $gPacket_Seporator &_
EndFunc   ;==>packet_player_recv

Func server_config_save()

	; Save Settings
	Local $file = FileOpen(@ScriptDir & "\Settings\" & $gScriptname & "_Last_IP_Port.txt", BitOR($FO_OVERWRITE, $FO_CREATEPATH))
	FileWriteLine($file, $gServer_ip)
	FileWriteLine($file, $gServer_port_base)
	FileClose($file)

EndFunc   ;==>server_config_save

Func server_config_load()

	Local $aRet[3]

	Local $file = FileOpen(@ScriptDir & "\Settings\" & $gScriptname & "_Last_IP_Port.txt")

	$aRet[0] = UBound($aRet)
	$aRet[1] = FileReadLine($file)
	$aRet[2] = FileReadLine($file)

	FileClose($file)

	Return $aRet

EndFunc   ;==>server_config_load

Func item_list_clear(ByRef $aPlayer_item)

	For $i = 0 To $player_item_max - 1

		For $ii = 0 To $player_item_data_max - 1

			$aPlayer_item[$i][$ii] = 0; item name string

		Next

	Next

EndFunc   ;==>item_list_clear

Func client_connect()

	Local $aRet = server_config_load()

	Local $iError = 0
	; need global sockets so they can be closed on callback function
	;Local $sIPAddress = @IPAddress1;"127.0.0.1"
	;Local $iPort = $gServer_port_base

	If $aRet[1] <> "" And $aRet[1] <> "EOF" Then $gServer_ip = $aRet[1]
	If $aRet[2] <> "" And $aRet[2] <> "EOF" Then $gServer_port_base = $aRet[2]

	Local $socket_join_send = 0
	Local $confirm = 0
	Local $setting_height = 30

	; GUI
	Enum $eNetwork_ip, $eNetwork_port
	Local $aidSettings = [[0, "Server IP: ", "input", "Connect to Server on this IP Address", $gServer_ip, 65], _
			[0, "Port: ", "input", "Connect to Server through this Port ", $gServer_port_base, 65] _
			]
	Local Const $iSettings_max = UBound($aidSettings)

	$gaGui_rect = WinGetPos($ghGui)

	Local $hGui = GUICreate("Client Connect", 420, $iSettings_max * $setting_height, $gaGui_rect[0] + $gaGui_rect[2] / 2, $gaGui_rect[1] + $gaGui_rect[3] / 2, Default, Default, $ghGui)
	Local $gui_rect = WinGetPos($hGui)
	For $i = 0 To $iSettings_max - 1
		label_control($hGui, $aidSettings, $i, $aidSettings[$i][$eControl_label], 5, 5 + $i * 20, 55, 20, $aidSettings[$i][$eControl_type], 65, 5 + $i * 20, 95, 20, $aidSettings[$i][$eControl_data_val])
	Next

	Local $connect_button = GUICtrlCreateButton("Connect", $gui_rect[2] - 80, $gui_rect[3] - 60, 60, 20)

	GUISetState()

	; GUI END

	Local $data = ""
	Local $aData = 0
	; Capture Data from GUI
	Local $msg

	Do

		$msg = GUIGetMsg()

		If WinActive($hGui) Or WinActive($ghGui) Then

			If _IsPressed("0d") Or $msg = $connect_button Then; Enter

				$confirm = 1

				keyreleased("0d")

				ExitLoop

			EndIf; user connect

			If _IsPressed("1b") Then; Escape

				keyreleased("1b")

				ExitLoop

			EndIf

		EndIf

	Until $msg = $gui_event_close

	Local $socket_created = 0
	Local $timer
	Local $timer_handshake_len = 1000 * 6

	Local $connected_to_server = 0
	Local $socket_join_recv = 0

	Local $error = 0

	If $confirm = 1 Then

		; Read Data from window
		$gServer_ip = GUICtrlRead($aidSettings[$eNetwork_ip][$eControl_data])
		$gServer_port_base = GUICtrlRead($aidSettings[$eNetwork_port][$eControl_data])

		; The Join port - base_port
		$error = socket_open($socket_join_send, $eSocket_open_method_open, $gServer_ip, $gServer_port_base)

		If $error = 0 Then

			$socket_created = 1

		EndIf

		Local $timer_timeout = 0

		; This number needs to be larger for real world use
		; Should be about: 15
		Local $join_send_attempts = 2

		Local $timer_send_delay = 0
		Local $timer_send_delay_len = 50

		Local $listen_retry_attemps = 100
		Local $note = ""
		Local $port_recv = 0

		; This number needs to be larger for real world use
		; Should be about: 15


		; Send join string to Server
		If $socket_created = 1 Then

			; Send Join Message to Server
			$timer_timeout = TimerInit()
			For $i = 0 To $join_send_attempts - 1

				$error = 0

				; Send the string "hiya" converted to binary to the server.

				; Get open port
				;$port = port_find_available($gServer_ip, 0)
				;$port= $gServer_port_base+1

				$note = $gPacket_key & $gPacket_Seporator & $gsNet_join

				UDPSend($socket_join_send, StringToBinary($note));open

				$error = @error

				If $error <> 0 Then

					MsgBox(0, @ScriptName & " UDPSend", "Error Sending Join Message to Server", 0, $ghGui)
					out("Send Error: " & $error)

				EndIf

				; Delay loop to re-send
				$timer_send_delay = TimerInit()
				While TimerDiff($timer_send_delay) < $timer_send_delay_len

					Sleep(10); task

				WEnd

			Next;i join_send_attempts

			UDPCloseSocket($socket_join_send)

			; Wait for Port
			$error = socket_open($socket_join_recv, $eSocket_open_method_bind, @IPAddress1, $gServer_port_base + 1)

			; Set timeout timer
			$timer_timeout = TimerInit()

			out("Listening for Port: ")

			; Recieve Player Port from Server
			For $i = 0 To $listen_retry_attemps - 1

				; Listen for Data
				$data = UDPRecv($socket_join_recv, 255); bind

				socket_info($socket_join_recv)

				out("recv data: " & $data)

				$aData = StringSplit($data, $gPacket_Seporator)

				;_ArrayDisplay($aData)
				If $aData[$ePacket_header_read_data_num] > 0 Then; If anything received

					If $aData[$ePacket_header_read_key] = $gPacket_key Then; It's a message for us

						out("Data num " & $aData[$ePacket_header_read_data_num] & " key " & $aData[$ePacket_header_read_key] & " type " & $aData[$ePacket_header_read_type])
						out("key: " & $aData[$ePacket_header_read_key])
						out("type: " & $aData[$ePacket_header_read_type])

						If $aData[$ePacket_header_read_type] = $ePacket_type_connect_port Then; We're looking for a Port

							out("PORT RETURNED: " & $aData[$ePacket_header_read_type])

							; Assign Game Connection Port
							$port_recv = $aData[$ePacket_header_read_type + 1]

							$gServer_players = $aData[$ePacket_header_read_type + 2]; Server Players

							$gServer_socket_id = $aData[$ePacket_header_read_type + 3]; Server Socket Index

							MsgBox(0, @ScriptName & " Port_Recv: ", "Port: " & $port_recv, 1, $hGui)

							$connected_to_server = 1

							ExitLoop

						EndIf

					EndIf
				EndIf

				; Delay loop to re-send
				$timer_send_delay = TimerInit()
				While TimerDiff($timer_send_delay) > $timer_send_delay_len

					Sleep(200); task

				WEnd
			Next

			If $connected_to_server = 1 Then

				$error = socket_open($gaSocket_send[$eSocket], $eSocket_open_method_open, $gServer_ip, $port_recv)

				; Open global Bind Socket
				socket_open($gaSocket_recv[$eSocket], $eSocket_open_method_bind, @IPAddress1, $port_recv + 1)

			Else
				console_out("Dropped due to timeout")
			EndIf

		Else; Error Connecting

			; The server is probably offline/port is not opened on the server.
			MsgBox(BitOR($MB_SYSTEMMODAL, $MB_ICONHAND), "", "Client:" & @CRLF & "Could not connect, Error code: " & $error)

			server_config_save()

			GUIDelete($hGui)

			Return False

		EndIf; socket_created = 1

	EndIf

	server_config_save()

	; Close Join Socket
	UDPCloseSocket($socket_join_send)
	UDPCloseSocket($socket_join_recv)

	; Delete the Client Connection Window
	GUIDelete($hGui)

	Return $connected_to_server

EndFunc   ;==>client_connect

Func chat_console_create()

	;Local $a[3]

	; Make Chat window console
	Local $window_margin_x = 15, $window_margin_y = 10, $window_width = $gaGui_rect[2] - 15, $window_height = 30

	$gChat_window_surf = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $window_width, $window_height, 32, 0, 0, 0, 255)
	$gChat_window_drect = _SDL_Rect_Create($window_margin_x, $gaGui_rect[3] - ($window_height + 50), $window_width, $window_height)
	$gChat_window_edit = GUICtrlCreateInput("", 15, -200, 200, 50)

	_SDL_SetAlpha($gChat_window_surf, $_SDL_SRCALPHA, 200)
;~ 	$a[0] = _SDL_CreateRGBSurface($_SDL_SWSURFACE, $window_width, $window_height, 32, 0, 0, 0, 255)
;~ 	$a[1] = _SDL_Rect_Create($window_margin_x, $gaGui_rect[3] - ($window_height + 50), $window_width, $window_height)
;~ 	$a[2] = GUICtrlCreateEdit("", 15, -200, 200, 50)


	;$gChat_console_open = 1

	;Return $a

EndFunc   ;==>chat_console_create

Func chat_console(ByRef $iChat_sequence_frame)

	; Focus the hidden text control
	;guictrlsetstate($gChat_window_edit, $gui_focus)

	; Force data len of control
	;ControlSend($ghGUI, "", $gChat_window_edit, "{end}")

	; Read text control
	Local $text = GUICtrlRead($gChat_window_edit)

	If $text <> $gChat_window_edit_text Then

		; Assign last text
		$gChat_window_edit_text = $text

		; clear
		_SDL_FillRect($gChat_window_surf, 0, 0)

		print2($text, $gChat_window_surf, 1, 1)

	EndIf; text changed

	_SDL_BlitSurface($gChat_window_surf, 0, $screen, $gChat_window_drect)

	;out("GUICtrlRead($gChat_window_edit): " & $text)

	;out("$gChat_window_edit_text "&$gChat_window_edit_text)

	; Dispatch Chat Message to Server
	If _IsPressed("0d") Then; Enter

		$gChat_console_open = 0

		If $text <> "" Then

			For $i = 0 To $gChat_send_packets - 1

				; Make a packet
				; We need Chat_sequence_frame else a chat 'could' be lost
				$data = $gPacket_key & $gPacket_Seporator & _
						$gNet_sequence_frame & $gPacket_Seporator & _
						$ePacket_type_chat & $gPacket_Seporator & _
						$text & $gPacket_Seporator & _
						$iChat_sequence_frame

				UDPSend($gaSocket_send[$eSocket], $data)

				;MsgBox(0, @ScriptName, $data, 2, $ghGUI)

			Next

			; Incroment chat sequence frame
			$iChat_sequence_frame += 1

			; Wrap around chat sequence frame
			If $iChat_sequence_frame > $gNet_sequence_frame_max Then

				$iChat_sequence_frame = 0

			EndIf

			; Turn off chat console
			$gChat_console_open = 0

			; Clear Control
			GUICtrlSetData($gChat_window_edit, "")

		EndIf; text<> ""

		keyreleased("0d")

	Else; check escape

		If _IsPressed('1b') Then; Escape

			; Turn chat window off
			$gChat_console_open = 0

		EndIf; escape

	EndIf; enter

EndFunc   ;==>chat_console

;~ func client_test_start()

;~ 	$gNet_role= $eNet_role_client

;~ 	Local $aRet = server_config_load()


;~ 	If $aRet[1] <> "" And $aRet[1] <> "EOF" Then $gServer_ip = $aRet[1]
;~ 	If $aRet[2] <> "" And $aRet[2] <> "EOF" Then $gServer_port_base = $aRet[2]

;~ 	UDPCloseSocket($gaSocket_send)
;~ 	$gaSocket_send = UDPOpen($gServer_ip, $gServer_port_base+2)

;~ 	UDPCloseSocket($gaSocket_recv)
;~ 	$gaSocket_recv = UDPBind(@IPAddress1, $gServer_port_base+3)

;~ EndFunc

Func socket_info($aSocket, $index = "", $msgbox = 0)

	If IsArray($aSocket) Then

		Local $msg = $index & " Socket_info() 0: " & $aSocket[0] & " 1: " & $aSocket[1] & " 2: " & $aSocket[2] & " 3: " & $aSocket[3]
		out($msg)

		If $msgbox = 1 Then MsgBox(0, @ScriptName, $msg, 1, $ghGui)

	EndIf

EndFunc   ;==>socket_info

Func socket_open(ByRef $socket, $iMethod, $sIPAddress, $iPort, $sCalled_from_function = "")

	; Close Socket
	UDPCloseSocket($socket)

	Switch $iMethod

		Case $eSocket_open_method_open; Send

			$socket = UDPOpen($sIPAddress, $iPort)

		Case $eSocket_open_method_bind; Receive

			$socket = UDPBind($sIPAddress, $iPort)

	EndSwitch

	Local $error = @error

	Local $aError_text = ["UDPOpen", "UDPBind"]

	; UDPBind Error
	If $error <> 0 Then

		Local $socket_info = socket_info($socket)

		MsgBox(0, @ScriptName, "socket = " & $aError_text[$iMethod] & "(IP, PORT) Error: " & $error & @CRLF & $socket_info & @CRLF & $sCalled_from_function)

	EndIf;udpbind error

	Return $error

EndFunc   ;==>socket_open

Func debug_key($msg, $key = "A7")

	If _IsPressed($key) Then

		MsgBox(0, @ScriptName, $msg, 1, $ghGui)

	EndIf

EndFunc   ;==>debug_key

;Func window_print($output, $window, $rectID)
Func window_connect_server_display(ByRef $win, $window_rect_pos, $iNet_role)

	Switch $iNet_role

		Case $eNet_role_client

			window_print('c' & $gServer_socket_id, $win, $window_rect_pos, 0, 255, 0)

		Case $eNet_role_private

			_SDL_BlitSurface($win._surf, $window_rect_pos, $win.surf, $window_rect_pos); Clear Tile_cur

	EndSwitch; $iNet_role

	window_draw($win)

	_SDL_Flip($screen)

EndFunc   ;==>window_connect_server_display

Func client_send_spears($player, $packet_type, $spears = 10, $data = "")

	Local $packet_data = packet_header_create($player, $packet_type)

	For $i = 0 To $spears - 1

		UDPSend($gaSocket_send[$eSocket], $packet_data)

	Next

EndFunc   ;==>client_send_spears

Func board_redraw($aBoard, $aWorld, $aTile, $player, $aArea, $win, $area_impose)

	$redraw = 1

	If $area_impose = 0 Then

		board_draw($aBoard, $aWorld, $aTile, $player)

	Else

		board_draw_area($aBoard, $aWorld, $aTile, $player, $aArea)

	EndIf
	;window_print($player.iBoard_world_x & " " & $player.iBoard_world_y, $win, $iRect_board_world)
	;window_print($player.iX & " " & $player.iY, $win, $iRect_world_x)
	;window_print(StringFormat("%.2f", $player.fCamera_X) & " " & StringFormat("%.2f", $player.fCamera_y), $win, $iRect_camera)

EndFunc   ;==>board_redraw

Func playerNet_draw($player, $player_sprite, $player_way, $player_frame)

	Local $drect = 0

	Local $dis_x = 0, $dis_y = 0

	;out("Players: " & $gServer_players)

	For $i = 0 To $gServer_players - 1

		If $gServer_socket_id <> $gaPlayer_indexs[$i] Then

			;out("gaPlayer_indexs[i]: " & $gaPlayer_indexs[$i])

			;out("gaPlayerNet[gaPlayer_indexs[i]][ePlayerNet_x]: " & $gaPlayerNet[$gaPlayer_indexs[$i]][$ePlayerNet_x])

			$dis_x = $player.iX - $gaPlayerNet[$gaPlayer_indexs[$i]][$ePlayerNet_x]

			$dis_y = $player.iY - $gaPlayerNet[$gaPlayer_indexs[$i]][$ePlayerNet_y]

			$drect = _SDL_Rect_Create($player.iScr_w / 2 - $dis_x * $tile_w, $player.iScr_h / 2 - $dis_y * $tile_h, 32, 32)

			_SDL_BlitSurface($player_sprite[1][$gaPlayerNet[$gaPlayer_indexs[$i]][$ePlayerNet_class]][$player_way][$player_frame], 0, $screen, $drect)

		EndIf

	Next

EndFunc   ;==>playerNet_draw

Func player_create_dialog(ByRef $player, $player_sprite, $person_surf)

	_SDL_FillRect($screen, 0, 0)

	; Center lines
	;_sge_Line($screen, $gaGui_rect[2] / 2, 0, $gaGui_rect[2] / 2, $gaGui_rect[3], _SDL_MapRGB($screen, 255, 0, 0)); Center X TOP BOTTOM
	;_sge_Line($screen, 0, $gaGui_rect[3] / 2, $gaGui_rect[2], $gaGui_rect[3] / 2, _SDL_MapRGB($screen, 255, 0, 0)); Center Y LEFT RIGHT

	_SDL_Flip($screen)

	Local $redraw = 1

	Local $player_create_dialog_class_image_pad = 5

	Local $margin_x = $gaGui_rect[2]/2-$dw3_player_class_max/2*($tile_w+$player_create_dialog_class_image_pad), $margin_y = 100
	Local $cur_y = 5, $pad_y = 10

	Local $player_create_dialog_class_cho = -1

	; Set Class Selection
	if $player_class_chosen > 0 Then

		$player_class_chosen= 1
		$player_create_dialog_class_cho= $player.iClass

	endif

	; Last cho
	Local $player_create_dialog_class_cho_last = $player_create_dialog_class_cho

	; Class Selection Label
	$player_create_dialog_class_label = GUICtrlCreateLabel("Select Hero Class:", $gaGui_rect[2]/2-90/2, $cur_y, 90, 20)
	guictrlsetbkcolor(-1, $GUI_BKCOLOR_TRANSPARENT)
	guictrlsetcolor(-1, 0xb2b300)

	; Place Class Choice Below
	$cur_y+= 20+$pad_y

	; Class Choice Label
	$player_create_dialog_class_cho_label = GUICtrlCreateLabel("", $gaGui_rect[2]/2-15, $cur_y, 55, 20)

	guictrlsetbkcolor(-1, $GUI_BKCOLOR_TRANSPARENT)

	guictrlsetcolor(-1, 0xb2b300)

	; Move curser down
	$cur_y+= 10+$pad_y

	; Class Description
	Local $aPlayer_create_dialog_class_description[$dw3_player_class_max]

	$aPlayer_create_dialog_class_description[$ePlayer_class_hero]= 	"The hero of Dragon Warrior III, you, can use weapons and armor well to fight enemies fiercely."&@CRLF& _
													"You also have the ability to cast spells. Some of the spells which you learn will be exclusive to you."

	$aPlayer_create_dialog_class_description[$ePlayer_class_wizard]=	"A specialist of attack spells. Even at lower levels, the Wizard can use very effective attack spells. However,"&@CRLF& _
													"he/she lacks STRENGTH and his/her Attack Power and Defense Power are low compared to those of characters in the other classes."&@CRLF& _
													"The Wizard can be equipped with a limited number of weapons and armor."

	$aPlayer_create_dialog_class_description[$ePlayer_class_pilgrim]=	"With the ability to cast mainly healing and indirect attack spells, a Pilgrim can back your party up greatly in battles."&@CRLF& _
													"He/she also has relatively good STRENGTH and can be equipped with many weapons and armor."&@CRLF& _
													"At higher levels, he/she will learn powerful attack spells too."

	$aPlayer_create_dialog_class_description[$ePlayer_class_sage]=	"A super character, the Sage can learn all the spells of a Pilgrim and Wizard."&@CRLF& _
													"He/she cannot only fight well, but can be equipped with many weapons and armor."&@CRLF& _
													"No character can start as a Sage, however."&@CRLF& _
													"The only way to become a Sage is to gain enough Experience Points and have a necessary class change."

	$aPlayer_create_dialog_class_description[$ePlayer_class_soldier]=	"A fighting professional."&@CRLF& _
													"The Soldier can be equipped with most weaponsand armor, and since his/her growth rate is high, he/she will become powerful quite quickly."&@CRLF& _
													"He/she is not too agile, though, and cannot cast any spell."

	$aPlayer_create_dialog_class_description[$ePlayer_class_merchant]=	"A Merchant is skillful at finding the most gold pieces."&@CRLF& _
													"He/she also posesses the exclusive ability to appraise items. To use his/her appraisal ability, "&@CRLF& _
													"first select ITEM, then the Merchant's name, the item to be appraised, and finally APPRAISE."

	$aPlayer_create_dialog_class_description[$ePlayer_class_fighter]=	"A master of martial arts, the Fighter posesses a lean, strong body and excellent AGILITY."&@CRLF& _
													"As the level increases, his/her chance of delivering a 'tremendous hit' grows. Being a master of martial arts, he/she can"&@CRLF& _
													"best fight bare-handed. When equipped with ordinary weapons, his/her Attack Power may decrease."

	$aPlayer_create_dialog_class_description[$ePlayer_class_goofoff]=	"Without exaggeration, a useless living-being to take along in your quest."&@CRLF& _
													"The only redeeming quality, if any, is that his/her irresponsible and unpredictable actions and remarks may make you laugh."&@CRLF& _
													"As Goof-off's level increases, his/her uselessness will become more and more apparent. His/her LUCK is tremendous, however."

	; Class Description Label
	Local $player_create_dialog_class_description_label= guictrlcreatelabel("", $gaGui_rect[2]/2-580/2, $cur_y, 580, 15*4, $SS_CENTER)
	guictrlsetbkcolor(-1, $GUI_BKCOLOR_TRANSPARENT)
	guictrlsetcolor(-1, 0xffffff)

	; Add room for hero description
	$cur_y+= 15*4+$pad_y

	; Assign class image y position
	Local $player_create_dialog_class_image_cur_y = $cur_y

	$cur_y += $tile_h*3 + $pad_y

	; Player Name Label
	Local $player_create_dialog_player_name_label = GUICtrlCreateLabel("Random Name:", $gaGui_rect[2]/2-75/2, $cur_y, 75, 20)
	guictrlsetbkcolor(-1, $GUI_BKCOLOR_TRANSPARENT)
	guictrlsetcolor(-1, 0xb2b300)

	; Next Line for Actual Player Name Input
	$cur_y+= 20

	; Player Name Input
	Local $player_create_dialog_player_name_input = GUICtrlCreateInput("", 40, $cur_y, $gaGui_rect[2] - 50- 40, 20, $ES_AUTOHSCROLL, 0)
	guictrlsetbkcolor(-1, 0x101010)
	guictrlsetcolor(-1, 0xffffff)

	; Set Name
	GUICtrlSetData($player_create_dialog_player_name_input, $player.caName)

	$cur_y+= 20+$pad_y

	; Gender
	Local $aGender_name = ["Male", "Female"]

	; Gender Choice
	Local $player_create_dialog_gender_cho = int($player.iClass/$dw3_player_class_max);Random(0, 1, 1)

	; Gender Label, button
	$player_create_dialog_gender_label = GUICtrlCreateLabel("Gender:", $gaGui_rect[2]/2-50, $cur_y, 40, 20)
	guictrlsetbkcolor(-1, $GUI_BKCOLOR_TRANSPARENT)
	guictrlsetcolor(-1, 0xb2b300)

	$player_create_dialog_gender_button = GUICtrlCreateButton($aGender_name[$player_create_dialog_gender_cho], $gaGui_rect[2]/2 - 10, $cur_y, 50, 20)

	; Class Sprite Home Position
	Local $integrel= 360/2/($dw3_player_class_max-1)

	Local $class_radius= 30

	Local $class_sprite_movement_rate= .5

	; Player Class Home Rect
	Local $aClass_sprite_home_rect[$dw3_player_class_max]

	; Player Class Images
	For $i = 0 To $dw3_player_class_max - 1

		;$aClass_sprite_home_rect[$i] = _SDL_Rect_Create($margin_x + $i * ($tile_w + $player_create_dialog_class_image_pad), $player_create_dialog_class_image_cur_y, $tile_w, $tile_h)

		$aClass_sprite_home_rect[$i] = _SDL_Rect_Create($margin_x + $i * ($tile_w + $player_create_dialog_class_image_pad), $player_create_dialog_class_image_cur_y - (cos($integrel*$i-90) *$class_radius )+$class_radius, $tile_w, $tile_h)

		_SDL_BlitSurface($player_sprite[1][$i][0][0], 0, $screen, $aClass_sprite_home_rect[$i])

	Next

	Local $aClass_sprite_dest_rect[$dw3_player_class_max]

	; Fire Rect
	Local $fire_rect= _SDL_Rect_Create($gaGui_rect[2]/2-$tile_w/2, $player_create_dialog_class_image_cur_y+$tile_h*2, $tile_w, $tile_h)

	Local $player_create_dialog_fire_layer= 0

	Local $fire_dive= 0

	; Sprite Class
	Enum $eClass_sprite_x, $eClass_sprite_y, $eClass_sprite_way, $eClass_sprite_frame

	Local $aClass_sprite[$dw3_player_class_max][4]; x, y, way, frame

	for $i= 0 to $dw3_player_class_max-1

		; Copy home position to aClass_sprite position (to start)
		$aClass_sprite[$i][$eClass_sprite_x]= $aClass_sprite_home_rect[$i].x

		$aClass_sprite[$i][$eClass_sprite_y]= $aClass_sprite_home_rect[$i].y

		; Destination Rect at Fire
		$aClass_sprite_dest_rect[$i]= _SDL_Rect_Create($fire_rect.x, $fire_rect.y-random(1, 8, 1), $fire_rect.w, $fire_rect.h)

	next

	Local $player_create_dialog_confirm_button=guictrlcreatebutton("Confirm", $gaGui_rect[2]-85, $gaGui_rect[3]-75, 55, 20)

	Local $player_create_dialog_exit_button=guictrlcreatebutton("Exit", 25, $gaGui_rect[3]-75, 55, 20)

	Local $frame = 0

	Local $way = 0

	if $player_create_dialog_class_cho > -1 and $player_create_dialog_class_cho < $dw3_player_class_max * 2 then

		; Set Class Type
		GUICtrlSetData($player_create_dialog_class_cho_label, $dw3_player_class_name[$player_create_dialog_class_cho])

		; Set Class Description
		GUICtrlSetData($player_create_dialog_class_description_label, $aPlayer_create_dialog_class_description[$player_create_dialog_class_cho])

	endif

	; Timers
	Local $animation_timer = 0
	Local $animation_timer_len = 700

	Local $class_cho_spin_timer= 0
	Local $class_cho_spin_timer_len = 500

	Local $player_create_dialog_name_warp_end_timer= 0
	Local $player_create_dialog_name_warp_end_timer_len= 2000

	$cur_y += $tile_h * 3 + $pad_y

	$cur_y += 40 + $pad_y

	Local $msg = ""

	Local $confirm = 0

	Local $player_create_dialog_name_cur_y= ControlGetPos($ghGui, "", $player_create_dialog_player_name_input)
	Local $player_create_dialog_name_cur_x= $player_create_dialog_name_cur_y= $player_create_dialog_name_cur_y[2] - 5
	$player_create_dialog_name_cur_y= $player_create_dialog_name_cur_y[1] + $player_create_dialog_name_cur_y[3]/2

	; Sounds and Music
	$gSound_cur= 0

	Local $music_index= $gSound_cur

	sound_play("Music\introedit.mp3", $BASS_SAMPLE_LOOP)

	Local $music_playing= 1

	Local $sound_file[$dw3_player_class_max][2][2]; class, gender, sound frame

	; Male

#Region Sound Assignment
	$sound_file[$ePlayer_class_hero][0][0]= "intro\amazon select.wav"
	$sound_file[$ePlayer_class_hero][0][1]= "intro\amazon deselect.wav"

	$sound_file[$ePlayer_class_wizard][0][0]= "intro\necromancer select.wav"
	$sound_file[$ePlayer_class_wizard][0][1]= "intro\necromancer deselect.wav"

	$sound_file[$ePlayer_class_pilgrim][0][0]= "intro\paladin select.wav"
	$sound_file[$ePlayer_class_pilgrim][0][1]= "intro\paladin deselect.wav"

	$sound_file[$ePlayer_class_sage][0][0]= "intro\druid select.wav"
	$sound_file[$ePlayer_class_sage][0][1]= "intro\druid deselect.wav"

	$sound_file[$ePlayer_class_soldier][0][0]= "intro\barbarian select.wav"
	$sound_file[$ePlayer_class_soldier][0][1]= "intro\barbarian deselect.wav"

	$sound_file[$ePlayer_class_merchant][0][0]= "intro\necromancer select.wav"
	$sound_file[$ePlayer_class_merchant][0][1]= "intro\necromancer deselect.wav"

	$sound_file[$ePlayer_class_fighter][0][0]= "intro\sorceress select.wav"
	$sound_file[$ePlayer_class_fighter][0][1]= "intro\sorceress deselect.wav"

	$sound_file[$ePlayer_class_goofoff][0][0]= "intro\amazon select.wav"
	$sound_file[$ePlayer_class_goofoff][0][1]= "intro\amazon deselect.wav"

	; Female

	$sound_file[$ePlayer_class_hero][1][0]= "intro\amazon select.wav"
	$sound_file[$ePlayer_class_hero][1][1]= "intro\amazon deselect.wav"

	$sound_file[$ePlayer_class_wizard][1][0]= "intro\sorceress select.wav"
	$sound_file[$ePlayer_class_wizard][1][1]= "intro\sorceress deselect.wav"

	$sound_file[$ePlayer_class_pilgrim][1][0]= "intro\assassin select.wav"
	$sound_file[$ePlayer_class_pilgrim][1][1]= "intro\assassin deselect.wav"

	$sound_file[$ePlayer_class_sage][1][0]= "intro\druid select.wav"
	$sound_file[$ePlayer_class_sage][1][1]= "intro\druid deselect.wav"

	$sound_file[$ePlayer_class_soldier][1][0]= "intro\sorceress select.wav"
	$sound_file[$ePlayer_class_soldier][1][1]= "intro\sorceress deselect.wav"

	$sound_file[$ePlayer_class_merchant][1][0]= "intro\necromancer select.wav"
	$sound_file[$ePlayer_class_merchant][1][1]= "intro\necromancer deselect.wav"

	$sound_file[$ePlayer_class_fighter][1][0]= "intro\paladin select.wav"
	$sound_file[$ePlayer_class_fighter][1][1]= "intro\paladin deselect.wav"

	$sound_file[$ePlayer_class_goofoff][1][0]= "intro\assassin select.wav"
	$sound_file[$ePlayer_class_goofoff][1][1]= "intro\assassin deselect.wav"
#EndRegion

	; Random Names
	Local $random_name_max = 25
	Local $aRandom_name[$random_name_max]

#Region Random Name
	$aRandom_name[0] = "Jeff_Goldblum"
	$aRandom_name[1] = "TylerDurden"
	$aRandom_name[2] = "DimOnyx"
	$aRandom_name[3] = "DimAzure"
	$aRandom_name[4] = "DimSapphire"
	$aRandom_name[5] = "Dimruby"
	$aRandom_name[6] = "DimBuddy"
	$aRandom_name[7] = "LoganJMV"
	$aRandom_name[8] = "Dimruby"
	$aRandom_name[9] = "Dimjade"
	$aRandom_name[10] = "Dimonyx"
	$aRandom_name[11] = "Dimazure"
	$aRandom_name[12] = "Dimsapphire"
	$aRandom_name[13] = "TylerDurden"
	$aRandom_name[14] = "TyIerDurden"
	$aRandom_name[15] = "MarIaSinger"
	$aRandom_name[16] = "MarlaSinger"
	$aRandom_name[17] = "JeffGoldblum"
	$aRandom_name[18] = ""
	$aRandom_name[19] = ""
	$aRandom_name[20] = "LoganJMV"
	$aRandom_name[21] = "Critler"
	$aRandom_name[22] = "Critler"
	$aRandom_name[23] = "LoganJMV"
	$aRandom_name[24] = ""
#EndRegion

	Local $random_name_index= -1

	Local $player_create_dialog_class_clicked= 0

	Local $player_create_dialog_player_sprite_index= 0

	Local $x= 0

	; Fire Surface
	Local $player_create_dialog_fire_surf[2]

	$player_create_dialog_fire_surf[0] = _SDL_DisplayFormat($person_surf[1][20][1][0]); frame 0
	$player_create_dialog_fire_surf[1] = _SDL_DisplayFormat($person_surf[1][20][1][1]); frame 1

	; Fire Surface Alpha
	_SDL_SetAlpha($player_create_dialog_fire_surf[0], $_SDL_SRCALPHA, 180)
	_SDL_SetAlpha($player_create_dialog_fire_surf[1], $_SDL_SRCALPHA, 220)

	; Gui Control Focus Player Name Control
	GUICtrlSetState($player_create_dialog_player_name_input, $gui_focus)

	ControlSend($ghGui, "", $player_create_dialog_player_name_input, "{DOWN}")

	Do

		If WinActive($ghGui) Or $debug_songersoft = 1 Then

			$msg = GUIGetMsg()

			Switch $msg

				; Name
				Case $player_create_dialog_player_name_label

					$random_name_index+= 1

					if $random_name_index> $random_name_max-1 Then

						$random_name_index= 0

					endif

					guictrlsetdata($player_create_dialog_player_name_input, $aRandom_name[$random_name_index])

				; Gender Label and Button
				Case $player_create_dialog_gender_label, $player_create_dialog_gender_button

					sound_play("Button.wav")

					$player_create_dialog_gender_cho += 1

					If $player_create_dialog_gender_cho > 1 Then

						$player_create_dialog_gender_cho = 0

					EndIf

					guictrlsetdata($player_create_dialog_gender_button, $aGender_name[$player_create_dialog_gender_cho])
					$animation_timer = 0

				Case $player_create_dialog_exit_button

					ExitLoop

				Case Else

					If _IsPressed(1) Then; Left Mouse

						For $i = 0 To $dw3_player_class_max - 1

							If mouseoverrect($aClass_sprite_home_rect[$i].x, $aClass_sprite_home_rect[$i].y, $aClass_sprite_home_rect[$i].w, $aClass_sprite_home_rect[$i].h) Then

								$player_create_dialog_class_cho = $i

								;$way+=1

								If $player_create_dialog_class_cho <> $player_create_dialog_class_cho_last Then

									; Class Type
									GUICtrlSetData($player_create_dialog_class_cho_label, $dw3_player_class_name[$player_create_dialog_class_cho])

									; Class Description
									GUICtrlSetData($player_create_dialog_class_description_label, $aPlayer_create_dialog_class_description[$player_create_dialog_class_cho])

									$player_create_dialog_class_cho_last = $player_create_dialog_class_cho

								EndIf

								$class_cho_spin_timer = 0

								sound_play($sound_file[$player_create_dialog_class_cho][$player_create_dialog_gender_cho][0])

								;keyreleased(1)

								ExitLoop

							EndIf

						Next; i

						if TimerDiff($player_create_dialog_name_warp_end_timer) >= $player_create_dialog_name_warp_end_timer_len then

							;$awin_po= WinGetPos($ghGUI, "")

							;for $i= 0 to 2

								; Warp to END of Player Name Control
								;ControlSend($ghGui, "", $player_create_dialog_player_name_input, "{DOWN}")

							;next

							;Send("{DOWN}")

							;ControlClick($ghGui, "", $player_create_dialog_player_name_input, "Left", 1, $awin_po[0]+$player_create_dialog_name_cur_x, $awin_po[1]+$player_create_dialog_name_cur_y)

							$player_create_dialog_name_warp_end_timer= TimerInit()

						endif

					EndIf; Left Mouse

			EndSwitch

			if _IsPressed("0D") or $msg=$player_create_dialog_confirm_button then; ENTER

				if $player_create_dialog_class_cho> -1 and GUICtrlRead($player_create_dialog_player_name_input)<> "" then

					$confirm = 1

					ExitLoop

					keyreleased("0D"); ENTER

				else

					MsgBox(0, "Confirm", "First you must Choose a Class"&@CRLF&"Player Name may not be blank", 3, $ghGUI)

				EndIf

			endif

			if _IsPressed('1B') then; Escape

				if $player_create_dialog_class_cho> -1 then

					$player_create_dialog_class_cho= -1

					keyreleased('1B')

				else; No Class, Exit Function

					ExitLoop

				endif; Class Selected

			EndIf; Escape key

			if _IsPressed('11') then; CTRL

				if _IsPressed('4D') then; M

					if $music_playing= 1 then

						_BASS_ChannelStop($gaSound[$music_index])

						$music_playing= 0

					else

						_BASS_ChannelPlay($gaSound[$music_index], 1)

						$music_playing= 1

					endif; music_playing

					keyreleased('4D')

				endif; m

			endif

			if _IsPressed('70') then; F1

				if $fire_dive= 0 then

					$fire_dive= 1

				else

					$fire_dive= 0

				endif

				keyreleased(70); F1

			endif; F1

			if _IsPressed('71') then; F2

				if $class_sprite_movement_rate<> .5 then

					$class_sprite_movement_rate= .5

				else

					$class_sprite_movement_rate= random(1, 5)

				endif

				keyreleased(71); F2

			endif; F2

		endif; winactive()

		If TimerDiff($animation_timer) >= $animation_timer_len Then

			$frame += 1

			If $frame > 1 Then

				$frame = 0

			EndIf; frame> 1

			$animation_timer = TimerInit()

			$redraw= 1

		EndIf

		if TimerDiff($class_cho_spin_timer)>= $class_cho_spin_timer_len then

			If $player_create_dialog_class_cho > -1 Then

				$way += 1

				If $way > 2 Then

					$way = 0

				EndIf

			EndIf; class cho > -1

			$class_cho_spin_timer= TimerInit()

			$redraw= 1

		EndIf

		if $redraw= 1 then

			; Clear Sprites of the Class Types and Fires
			_SDL_FillRect($screen, _SDL_Rect_Create(0, $player_create_dialog_class_image_cur_y-1, $gaGui_rect[2]-5, $tile_h*3+$font.iH*3),0); _SDL_MapRGB($screen, 0, 255, 0))

			$player_create_dialog_fire_layer= random(0, 1, 1)

			; Draw Fire
			if $player_create_dialog_fire_layer= 0 then

				if random(0, 1, 1) = 0 then

					_SDL_BlitSurface($player_create_dialog_fire_surf[0], 0, $screen, _SDL_Rect_Create($fire_rect.x, $fire_rect.y-($frame+2)*4, $fire_rect.w, $fire_rect.h))

				else

					_SDL_BlitSurface($player_create_dialog_fire_surf[1], 0, $screen, _SDL_Rect_Create($fire_rect.x, $fire_rect.y-($frame+2)*4, $fire_rect.w, $fire_rect.h))

				endif

			endif

			_SDL_BlitSurface($player_create_dialog_fire_surf[$frame], 0, $screen, _SDL_Rect_Create($fire_rect.x+5, $fire_rect.y-5, $fire_rect.w, $fire_rect.h))

			;_SDL_BlitSurface($person_surf[1][20][1][$frame], 0, $screen, _SDL_Rect_Create($fire_rect.x+5, $fire_rect.y-5, $fire_rect.w, $fire_rect.h))

			; Player Class Images
			For $i = 0 To $dw3_player_class_max - 1

				$drect=_SDL_Rect_Create($aClass_sprite[$i][$eClass_sprite_x], $aClass_sprite[$i][$eClass_sprite_y], $tile_w, $tile_h)

				$player_create_dialog_player_sprite_index= ($player_create_dialog_gender_cho * $dw3_player_class_max) + $i

				If $i = $player_create_dialog_class_cho Then

					if $aClass_sprite[$i][$eClass_sprite_x]= $aClass_sprite_home_rect[$i].x and $aClass_sprite[$i][$eClass_sprite_y]= $aClass_sprite_home_rect[$i].y then

						_SDL_BlitSurface($player_sprite[1][$player_create_dialog_player_sprite_index][$way][$frame], 0, $screen, $drect)

					else

						_SDL_BlitSurface($player_sprite[1][$player_create_dialog_player_sprite_index][$aClass_sprite[$i][$eClass_sprite_way]][$frame], 0, $screen, $drect)

					endif

					_SDL_BlitSurface($player_sprite[1][$player_create_dialog_player_sprite_index][$way][$frame], 0, $screen, $drect)

				Else

					_SDL_BlitSurface($player_sprite[1][$player_create_dialog_player_sprite_index][$aClass_sprite[$i][$eClass_sprite_way]][$frame], 0, $screen, $drect)

				EndIf

			Next

			; Draw Fire
			; Switching Layer Fire
			if $player_create_dialog_fire_layer= 1 then

				_SDL_BlitSurface($player_create_dialog_fire_surf[random(0, 1, 1)], 0, $screen, _SDL_Rect_Create($fire_rect.x, $fire_rect.y-($frame+2)*4, $fire_rect.w, $fire_rect.h))

			endif

			; Up, Left Fire
			_SDL_BlitSurface($player_create_dialog_fire_surf[$frame], 0, $screen, _SDL_Rect_Create($fire_rect.x-5, $fire_rect.y-5, $fire_rect.w, $fire_rect.h))

			;_SDL_BlitSurface($person_surf[1][20][1][$frame], 0, $screen, _SDL_Rect_Create($fire_rect.x+5, $fire_rect.y-5, $fire_rect.w, $fire_rect.h))

			;_SDL_UpdateRect($screen, 0, $player_create_dialog_class_image_cur_y-$font.iH*3, $gaGui_rect[2] - 15, $tile_h*3)

			; Center Lines
			;_sge_Line($screen, $gaGui_rect[2] / 2, 0, $gaGui_rect[2] / 2, $gaGui_rect[3], _SDL_MapRGB($screen, 255, 0, 0)); Center X TOP BOTTOM
			;_sge_Line($screen, 0, $gaGui_rect[3] / 2, $gaGui_rect[2], $gaGui_rect[3] / 2, _SDL_MapRGB($screen, 255, 0, 0)); Center Y LEFT RIGHT

			; Draw Point at
			;_SDL_FillRect($screen, _SDL_Rect_Create(10, $player_create_dialog_class_image_cur_y, 560, $player_create_dialog_class_image_cur_y), _SDL_MapRGB($screen, 255, 0, 0))

			; Update Screen
 			_SDL_UpdateRect($screen, 0, $player_create_dialog_class_image_cur_y-1, $gaGui_rect[2] - 5, $tile_h*3+1)

		endif; redraw

		for $i=0 to $dw3_player_class_max-1

			if $player_create_dialog_class_cho = $i or $fire_dive = 1 then

				; Go Destination
				if $aClass_sprite[$i][$eClass_sprite_x]> $aClass_sprite_dest_rect[$i].x then

					; Left
					$aClass_sprite[$i][$eClass_sprite_x]-= $class_sprite_movement_rate

				else

					if $class_sprite_movement_rate<= $aClass_sprite_dest_rect[$i].x then

						; Right
						$aClass_sprite[$i][$eClass_sprite_x]+= $class_sprite_movement_rate

					EndIf

				endif

				if $aClass_sprite[$i][$eClass_sprite_y]> $aClass_sprite_dest_rect[$i].y then

					; Up
					$aClass_sprite[$i][$eClass_sprite_y]-= $class_sprite_movement_rate

				else

					if $class_sprite_movement_rate<= $aClass_sprite_dest_rect[$i].y then

						; Down
						$aClass_sprite[$i][$eClass_sprite_y]+= $class_sprite_movement_rate

					EndIf

				endif

			Else

				; Return Home
				if $aClass_sprite[$i][$eClass_sprite_x]> $aClass_sprite_home_rect[$i].x then

					; Left
					$aClass_sprite[$i][$eClass_sprite_x]-= $class_sprite_movement_rate

				else

					if $class_sprite_movement_rate<= $aClass_sprite_home_rect[$i].x then

						; Right
						$aClass_sprite[$i][$eClass_sprite_x]+= $class_sprite_movement_rate

					EndIf

				endif

				if $aClass_sprite[$i][$eClass_sprite_y]> $aClass_sprite_home_rect[$i].y then

					; Up
					$aClass_sprite[$i][$eClass_sprite_y]-= $class_sprite_movement_rate

				else

					if $class_sprite_movement_rate<= $aClass_sprite_home_rect[$i].y then

						; Down
						$aClass_sprite[$i][$eClass_sprite_y]+= $class_sprite_movement_rate

					EndIf

				endif

			endif; player_create_dialog_class_cho> -1

		next

	Until $msg = $gui_event_close

	keyreleased('1B')

	If $confirm = 1 Then

		$player.caName = GUICtrlRead($player_create_dialog_player_name_input)

		$player.iClass = ($player_create_dialog_gender_cho * $dw3_player_class_max) + $player_create_dialog_class_cho

	EndIf

	GUICtrlDelete($player_create_dialog_player_name_label)
	GUICtrlDelete($player_create_dialog_player_name_input)
	GUICtrlDelete($player_create_dialog_class_label)
	GUICtrlDelete($player_create_dialog_class_cho_label)
	GUICtrlDelete($player_create_dialog_gender_label)
	GUICtrlDelete($player_create_dialog_gender_button)
	GUICtrlDelete($player_create_dialog_confirm_button)

	;_BASS_ChannelStop($gaSound[0])
	_BASS_ChannelStop($gaSound[$music_index])
	;_BASS_ChannelStop($gaSound[2])
	;_BASS_ChannelStop($gaSound[3])
	;_BASS_ChannelStop($gaSound[4])
	;_BASS_ChannelStop($gaSound[5])
	;_BASS_ChannelStop($gaSound[6])
	;_BASS_ChannelStop($gaSound[7])

	Return $confirm

EndFunc   ;==>player_create_dialog

func blit_surface_alpha(byref $surf_dest, $surf_source, $bg_color= 0)

	; Clear surface
	_SDL_FillRect($surf_dest, 0, $bg_color)

	_SDL_BlitSurface($surf_source, 0, $surf_dest, 0)

EndFunc