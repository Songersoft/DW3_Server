#include-once
#cs ----------------------------------------------------------------------------

	AutoIt Version: 3.3.14.2
	Author:         Joshua Songer

	Script Function:


#ce ----------------------------------------------------------------------------

#include <GuiConstants.au3>
#include <File.au3>
#include <Misc.au3>
#include <windowsconstants.au3>
#include <editconstants.au3>
#include <guiconstantsEx.au3>
#include <GuiListView.au3>
#include <GuiComboBox.au3>; _guictrlcombobox_setcursel()
; ListView Double-Click
#include <StructureConstants.au3>
#include <WindowsConstants.au3>
#include <GUIConstantsEx.au3>
; end listview
#include "TTS.au3"; Author: Beege, text to speach


Global $gDebug_songersoft = 0
Global $gDebug_game_file_create_off = 1
Global $gError_one = 0

Global $ghGui = Null
Global $gaGui_rect[4]

Global $gScriptName; = file_remove_ext(@ScriptName)
Global $gMSG_new_game= "*New*"
Global $gConsole= Null

; ListView Control
Global $gListview= 0
Global $gListview_double_click= 0

; Paths
Global $gPath_game_files_source= @ScriptDir & "\..\Graphics\DW3\"
Global $gPath_game_files = @ScriptDir & "\..\Server Games\"
Global $gPath_game_playing = Null
Global $gPath_win_po = @ScriptDir & "\System\" & $gScriptName & "_win_po.txt"

; World
Global $world_max= 0; Return from _filelisttoarrayrec()

; Netplay
Global $gServer_Ip = @IPAddress1
Global $gServer_port_base = 18000
Global $gServer_port_max = 100
Global $gServer_listening = 0

; Sockets
Global $gSocket_max = 8
Global $gSocket_data_max=4
Global Enum $eSocket, $eSocket_connected, $eSocket_position_sequence, $eSocket_chat_sequence
; _connected 0 off, 1 solid, 1< timing out

Global $gaSocket_send[$gSocket_max][$gSocket_data_max]

Global $gaSocket_recv[$gSocket_max][$gSocket_data_max]

Global $gSequence_frame = 0
Global $gSequence_frame_max = 99

Global $gSequence_frame_recieved_last = -1

Global $gNet_command_data_max = 10
Global $gaNet_command[$gSocket_max][$gNet_command_data_max]
Global $gNet_connections = 0

Global $gPacket_key = "DW"; Code to specify signal is for our netplay and not random

Global $gNet_connection_timeout_len = 1000 * 10
; Net Role, None, Client, Server
Global Enum $eNet_role_private, $eNet_role_client, $eNet_role_server
Global $gNet_role = $eNet_role_private

; Packet Compose
; ---------------
; ATH CODE: This is fixed so can be stripted without seporator
; Packet Id: Packets need sent more than once, use this number to react only once to specific packet
; Instruction Type
;

; Example: DW;PKT_ID;TYPE;TYPE DATA..

Global $gPacket_Seporator = ";"
Global $gPacket_Id_max = 60
Global $aPacket_Id_ack[$gSocket_max][$gPacket_Id_max]

Global Enum $eNet_cmd_pos, $eNet_cmd_world


; Packet CMD Types
Global Enum $eNet_cmd_type_change_tile_world, $eNet_cmd_type_change_tile_layer, $eNet_cmd_type_change_tile_x, $eNet_cmd_type_change_tile_y
;Global $aNet_player[$gSocket_max][$aNet_data_max]

Global $gsNet_join = 'hiya'

; Control Data Enum
Global $control_data_max = 9
Global Enum $eControl_data, $eControl_label, $eControl_type, $eControl_data_val, $eControl_tip, $eControl_width, $eControl_height, $eControl_pad_x, $eControl_pad_y

Global Enum $eArea_x, $eArea_y, $eArea_w, $eArea_h, _						; Area World Bound Rect
		$eArea_ob_tile, $eArea_ob_world, $eArea_ob_x, $eArea_ob_y, _ 	; Out of Bounds Repeat Tile and World Destination if Out of Bounds
		$eArea_hotspots, $eArea_items, $eArea_people ; Total Hotspots per Area, Items and People

Enum $eWi_filename, $eWi_layers, $eWi_w, $eWi_h, $eWi_tiles;5

; Main World Array
Global $world_max= 2

; world_info
Global $world_info_data_max= 5
Global $world_info[$world_max][$world_info_data_max]

; World Array
Global $world_max_layer= 2, $world_max_x= 500, $world_max_y= 500
Global $aWorld[$world_max][$world_max_layer][$world_max_x][$world_max_y]

; Area Array
Global $area_max = 60
Global $area_data_max = 11;x, y, w, h, outbounds_tile, outbounds_goto_world, outbounds_goto goto_x, goto_y, hotspots, items, people
Global $aArea[$world_max][$area_max][$area_data_max]

; Hotspot Array
Global $hotspot_max = 50
Global $hotspot_data_max = 5
Global $aHotspot[$world_max][$area_max][$hotspot_max][$hotspot_data_max]

Global $tagPerson_struct, $tagSun_struct, $tagBG_struct, $tagPlayer_struct, $tagWorld_struct

; Send files
Global Enum $eidSettings_upload_folder, $eidSettings_server_ip, $eidSettings_server_port
Global Enum $eSend_control_file_name, $eSend_control_progress, $eSend_control_error

Global Const $gaidIP_controls = [[0, "Upload Folder: ", "edit", "", "Upload new files added to this folder", 295, 40, 0, 22], _
		[0, "Server IP: ", "input", @IPAddress1, "IP address to upload contents of folder", 100, 20, 75, 0], _
		[0, "Port: ", "input", "10018", "Port to upload on", 65, 20, 75, 0], _
		[0, "SHIFT + PAUSE to Close Program", "label", "hidden", "If program gets stuck, Hotkey might solve the issue.", 0, 20, 65, 0] _
		]

Global $gFile_send_max_len = 5 * 1024

;Global $ghGui_send_file = Null

Global $player_max = 8
Global $player_data_max= 8
Global $gaPlayer[$player_max][$player_data_max]
Global Enum $ePlayer_x, $ePlayer_y, $ePlayer_world, $ePlayer_name, $ePlayer_class, $ePlayer_lvl, $ePlayer_gold, $ePlayer_xp

Global $player_item_max = 8
Global $player_item_data_max = 5
Global Enum $ePlayer_item_id, $ePlayer_item_quanity, $ePlayer_item_durability, $ePlayer_item_mod_1, $ePlayer_item_mod_2
Global $gaPlayer_item[$gSocket_max][$player_item_max][$player_item_data_max]

;~ Global $que_join_data_max =10
;~ Global $gQue_join[$player_max][$que_join_data_max]
;~ Global Enum $eQue_address, $eQue_data, $eQue_ack

;Global $gQue_join_n= 0

Global $gSocket_join_recv= 0

Global $gDll_Ws2_32=DllOpen("ws2_32.dll")

Global Enum $ePacket_header_data_num, $ePacket_header_key, $ePacket_header_sequence, $ePacket_header_type, $ePacket_header_x, $ePacket_header_y

Global $gPath_network_settings = "\Settings\Server_Network_Settings.txt"

Global $voice_obj = _StartTTS(); A voice object

Global $gOut_delay_timer = 0

; Number of connected sockets, I think the user label is: 'Players'
Global $gSockets_connected_num = 0

; Input control to display sockets connected
; Global so my sloppy funtions can overwrite the display without parameter
Global $gSockets_connected_input= 0