SetBatchLines -1
#NoEnv
#SingleInstance Force
if (!FileExist("sprites008.bmp"))
	URLDownloadToFile, http://www.autohotkey.net/~ton80/ludum/sprites008.bmp,%A_Scriptdir%/sprites008.bmp
gosub, initialize_variables
gosub, initialize_graphics
gosub, initialize_objects							;this for testing only
gosub, main_loop
return

main_loop:
loop
	{
		time_elapsed := (A_TickCount - time_update) / 1000
		time_update := A_TickCount
		offset := player.speed * time_elapsed
		offset *= board.scale
		offset_cloud := 2 * time_elapsed
		offset_cloud *= board.scale
		
		Loop, Parse, all_controls, csv
				If (GetKeyState(A_Loopfield, "P"))
					gosub, %a_loopfield%
		
		gosub, check_collision
		gosub, move_sprites
		gosub, draw_sprites
		gosub, update_screen
	}
return

up:
player.y -= board.height *.003
if (player.y < water.y1)
	player.y := water.y1
return

down:
player.y += board.height *.003
if (player.y + player.height > seabed.y1)
	player.y := seabed.y1 - player.height
return

left:
player.speed -= board.width *.004
if (player.speed < player.speed_min)
	player.speed := player.speed_min
player.x -= board.width *.002
if (player.x < board.width *.1)
	player.x := board.width * .1
return

right:
player.speed += board.width *.004
if (player.speed > player.speed_max)
	player.speed := player.speed_max
player.x += board.width *.002
if (player.x > board.width *.8)
	player.x := board.width * .8
return

check_collision:
for index, sprite in enemies
	if (player.x + player.width >= enemies[index].x) && (player.y >= enemies[index].y) && (player.x <= enemies[index].x + enemies[index].width) && (player.y <= enemies[index].y + enemies[index].height)
		{
			player.step()
			if (player.source_x = 0)
				player.x := 100, player.source_x := 9,player.frame := 1
		}
	else player.source_x := 9,player.frame := 1
return

move_sprites:
for index, sprite in plants
	plants[index].offset(offset)
for index, sprite in clouds
	clouds[index].offset(offset_cloud)
for index, sprite in enemies
	{
		enemies[index].step()
		if (enemies[index].direction = 1)
			enemies[index].offset(offset,-board.height *.001)
		else if (enemies[index].direction = 3)
			enemies[index].offset(offset,board.height *.001)
		else 
			enemies[index].offset(offset)
		if (enemies[index].y + enemies[index].height >= seabed.y1 && enemies[index].direction = 3)
			enemies[index].direction := 1
		else if (enemies[index].y <= water.y1 && enemies[index].direction = 1)
			enemies[index].direction := 3
	}
	
for index, sprite in food
	{
		food[index].step()
		if (food[index].direction = 1)
			food[index].offset(offset,-board.height *.001)
		else
			food[index].offset(offset,board.height *.001)
		if (food[index].y + food[index].height >= seabed.y1 && food[index].direction = 3)
			food[index].direction := 1
		else if (food[index].y <= water.y1 && food[index].direction = 1)
			food[index].direction := 3
	}
return

draw_sprites:
for index, sprite in clouds
	draw_transparent(clouds[index].x,clouds[index].y,clouds[index].width,clouds[index].height,clouds[index].source_x,clouds[index].source_y,clouds[index].source_width,clouds[index].source_height)
for index, sprite in plants
	draw_transparent(plants[index].x,plants[index].y,plants[index].width,plants[index].height,plants[index].source_x,plants[index].source_y,plants[index].source_width,plants[index].source_height)
for index, sprite in enemies
	draw_transparent(enemies[index].x,enemies[index].y,enemies[index].width,enemies[index].height,enemies[index].source_x,enemies[index].source_y,enemies[index].source_width,enemies[index].source_height)
for index, sprite in food
	draw_transparent(food[index].x,food[index].y,food[index].width,food[index].height,food[index].source_x,food[index].source_y,food[index].source_width,food[index].source_height)
draw_transparent(player.x,player.y,player.width,player.height,player.source_x,player.source_y,player.source_width,player.source_height)
return

update_screen:			;blit buffer dc to window
DllCall("BitBlt", "uint", hdcWin, "int", 0, "int", 0, "int", board.width, "int", board.height, "uint", hdcBuffer, "int", 0, "int", 0, "uint", 0xCC0020)
DllCall("BitBlt", "uint", hdcBuffer, "int", 0, "int", 0, "int", board.width, "int", board.height, "uint", hdcBackground, "int", 0, "int", 0, "uint", 0xCC0020)
return

initialize_variables:
board := {width:A_ScreenWidth,height:A_ScreenHeight,x:0,y:0,backcolor: 0x32C7F0,scale:1,width_meters:160,height_meters:90}
board.width *= board.scale, board.height *= board.scale
pixels_per_meter := board.width / board.width_meters
water := {x1:0,y1:board.height *.4,x2:board.width,y2:board.height,color:0xB5480D}	;0xF0C732
sky := {x1:0, y1:0, x2:board.width, y2:board.height *.4,color:0xF0C732}		;0xB5480D
seabed := {x1:0,y1:board.height *.9,x2:board.width,y2:board.height,color:0x14AFE3}
sun := {x1:board.width *.90, y1:0, x2:board.width, y2:board.height *.15,color:0x0AF7F7}
VarSetCapacity(ptWater, 16, 0)
NumPut(water.x1,ptWater,0), NumPut(water.y1, ptWater, 4),NumPut(water.x2,ptWater,8), NumPut(water.y2, ptWater, 12)
VarSetCapacity(ptSky, 16, 0)
NumPut(Sky.x1,ptSky,0), NumPut(Sky.y1, ptSky, 4),NumPut(Sky.x2,ptSky,8), NumPut(Sky.y2, ptSky, 12)
VarSetCapacity(ptSeabed, 16, 0)
NumPut(seabed.x1,ptSeabed,0), NumPut(seabed.y1, ptSeabed, 4),NumPut(seabed.x2,ptSeabed,8), NumPut(seabed.y2, ptSeabed, 12)
time_update := A_TickCount
return

initialize_objects: 
;__new(xpos,ypos,height,width,direction,source_x,source_y,source_width,source_height,animated=0,frame=0,frame_count=0,frame_delay=0,frame_lastchange=0,isEnemy=0,isFood=0,player_death_type=0){
clouds := [new sprite(board.width * .9,10,board.height * .2,board.width * .15,0,0,0,64,64)
			,new sprite(board.width * .7,20,board.height * .2,board.width * .15,0,64,0,64,64)
			,new sprite(board.width * .3,10,board.height * .2,board.width * .15,0,128,0,64,64)
			,new sprite(board.width * .1,20,board.height * .2,board.width * .15,0,192,0,64,64)]
plants := [new sprite(board.width,board.height *.8,board.height * .1, board.width * .1,1,0,64,64,64)	;also rocks
			,new sprite(board.width * 1.7,board.height *.8,board.height * .1, board.width * .1,1,64,64,64,64)
			,new sprite(board.width * .5,board.height *.8,board.height * .1, board.width * .1,1,128,64,64,64)
			,new sprite(board.width * .3,board.height *.8,board.height * .1, board.width * .1,1,192,64,64,64)
			,new sprite(board.width * 1.1,board.height *.85,board.height * .1, board.width * .1,1,0,128,64,64)
			,new sprite(board.width * .2,board.height *.85,board.height * .1, board.width * .1,1,64,128,64,64)
			,new sprite(board.width * .6,board.height *.85,board.height * .1, board.width * .1,1,128,128,64,64)
			,new sprite(board.width * 1.8,board.height *.85,board.height * .1, board.width * .1,1,192,128,64,64)]
enemies := [new sprite(board.width *.7,board.height *.7,board.height * .15, board.width *.2,1,1,269,59,31,1,1,3,350,A_TickCount,1,0,1)
			,new sprite(board.width *.5,board.height *.27,board.height * .25, board.width *.3,0,0,384,64,64,1,1,3,450,A_TickCount,1,0,1)]
food := [new sprite(board.width *.9, board.height * .8, board.height *.05, board.width *.05,3,0,320,64,64,1,1,3,200,A_TickCount,0,1)
		,new sprite(board.width * 1.5, board.height * .5, board.height *.03, board.width *.03,3,0,320,64,64,1,1,3,200,A_TickCount,0,1)
		,new sprite(board.width *.7, board.height * .8, board.height *.032, board.width *.031,3,0,320,64,64,1,1,3,200,A_TickCount,0,1)
		,new sprite(board.width * 1.2, board.height * .9, board.height *.033, board.width *.035,3,0,320,64,64,1,1,3,200,A_TickCount,0,1)]
player := new sprite(board.width * .2,board.height *.7, board.height * .1, board.width * .15,0,9,206,55,46,1,1,3,200,A_TickCount)
player.lives :=3
player.speed := 2 * pixels_per_meter
player.speed_max := 30 * pixels_per_meter
player.speed_min := 2 * pixels_per_meter
player.control_right := "right"
player.control_left := "left"
player.control_up := "up"
player.control_down := "down"

all_controls := player.control_right "," player.control_left "," player.control_up "," player.control_down
return

initialize_graphics:
gui, -caption
gui, color, %board_backcolor%
gui, show, % "h"board.height "w"board.width "x"board.x "y"board.y
hdcWin := DllCall("GetDC", "uint", hwnd:=WinExist("A"))
hdcBackground := DllCall("CreateCompatibleDC", "uint", hdcWin)
hbmBackground := DllCall("CreateCompatibleBitmap", "uint", hdcwin, "int", board.width, "int", board.height)
DllCall("SelectObject", "uint", hdcBackground, "uint", hbmBackground)
hdcBuffer := DllCall("CreateCompatibleDC", "uint", hdcWin)
hbmBuffer := DllCall("CreateCompatibleBitmap", "uint", hdcwin, "int", board.width, "int", board.height)
DllCall("SelectObject", "uint", hdcBuffer, "uint", hbmBuffer)
hdcSprites := DllCall("CreateCompatibleDC", "uint", hdcWin)
hbmSprites := DllCall("CreateCompatibleBitmap", "uint", hdcwin, "int", board.width, "int", board.height)
DllCall("SelectObject", "uint", hdcSprites, "uint", hbmSprites)
brush_background := DllCall("CreateSolidBrush", "int", board_backcolor)
brush_Water := DllCall("CreateSolidBrush", "uint", water.color)
brush_Sky := DllCall("CreateSolidBrush", "uint", Sky.color)
brush_Sun := DllCall("CreateSolidBrush", "int", Sun.color)
brush_Seabed := DllCall("CreateSolidBrush", "int", Seabed.color)
pen_black := DllCall("CreatePen", int, 1, int, 5, int, 0x000000)
DllCall("SelectObject", "uint", hdcBackground, "uint", brush_Sun)
DllCall("SelectObject", "uint", hdcBackground, "uint", pen_black)
hbmBM := DllCall("LoadImage", "int", 0, str, "sprites008.bmp", "int", 0, "int", 0, "int",0, "uint", 0x2010)
maskBM := CreateBitMapMask(hbmBM, 0x1DE6B5)
DllCall("FillRect", "uint", hdcBackground, "uint", &ptWater, "uint", brush_Water)
DllCall("FillRect", "uint", hdcBackground, "uint", &ptSky, "uint", brush_Sky)
DllCall("FillRect", "uint", hdcBackground, "uint", &ptSeabed, "uint", brush_Seabed)
DllCall("Ellipse", "uint", hdcBackground, "int", sun.x1, "int", sun.y1, "int", sun.x2, "int", sun.y2)
all_dcs := "hdcBackground,hdcBuffer,hdcSprites"
all_objects := "brush_background,brush_water,brush_sky,brush_sun,brush_seabed,pen_black,hbmBM,maskBM"
return

esc::
guiclose:
DllCall("ReleaseDC", uint, hwnd, uint, hdcWin)
loop, parse, all_dcs, csv
	DllCall("DeleteDC", uint, %a_loopfield%)
loop, parse, all_objects, csv
	DllCall("DeleteObject", uint, %a_loopfield%)
ExitApp

draw_transparent(destX,destY,destW,destH,sourceX,sourceY,sourceW,sourceH){
	global
	DllCall("SelectObject", "uint", hdcSprites, "uint", maskBM)
	DllCall("StretchBlt", "uint", hdcBuffer, "int", destX, "int", destY, "int", destW, "int", destH, "uint", hdcSprites, "int", sourceX, "int", sourceY, "int", sourceW, "int", sourceH, "uint", 0x8800C6)
	DllCall("SelectObject", "uint", hdcSprites, "uint", hbmBM)
	DllCall("StretchBlt", "uint", hdcBuffer, "int", destX, "int", destY, "int", destW, "int", destH, "uint", hdcSprites, "int", sourceX, "int", sourceY, "int", sourceW, "int", sourceH, "uint", 0xEE0086)
}

CreateBitmapMask(hbmColor, crTransparent)
{
	VarSetCapacity(bm,24,0)
	DllCall("GetObject", "UInt", hbmcolor, "UInt", 24, "UInt", &bm)
	bmwidth 	:= NumGet(bm,4)
	bmHeight	:= NumGet(bm, 8)
	hbmMask := DllCall("CreateBitmap", "Int", bmwidth, "Int", bmHeight, "Int", 1, "Int", 1, "Int", 0)
	hdcMem1 := DllCall("CreateCompatibleDC", "Int", 0)
	hdcMem2 := DllCall("CreateCompatibleDC", "Int", 0)
	DllCall("SelectObject", "UInt", hdcMem1, "UInt", hbmColor)
	DllCall("SelectObject", "UInt", hdcMem2, "UInt", hbmMask)
	DllCall("SetBkColor", "UInt", hdcMem1, "Int", crTransparent)
	DllCall("BitBlt", "UInt", hdcMem2, "Int", 0, "Int", 0, "Int", bmWidth, "Int", bmHeight, "UInt", hdcMem1, "Int", 0, "Int", 0, "Int", 0xCC0020)
	DllCall("BitBlt", "UInt", hdcMem1, "Int", 0, "Int", 0, "Int", bmWidth, "Int", bmHeight, "UInt", hdcMem2, "Int", 0, "Int", 0, "Int", 0x660046)
	DllCall("DeleteDC", "UInt", hdcMem1)
	DllCall("DeleteDC", "UInt", hdcMem2)
	return hbmMask
}

class sprite
{
	__new(xpos,ypos,height,width,direction,source_x,source_y,source_width,source_height,animated=0,frame=0,frame_count=0,frame_delay=0,frame_lastchange=0,isEnemy=0,isFood=0,player_death_type=0){
	this.x := xpos
	this.y := ypos
	this.height := height
	this.width := width
	this.direction := direction
	this.source_x := source_x
	this.source_y := source_y
	this.source_height := source_height
	this.source_width := source_width
	this.animated := animated
	this.frame := 0
	this.frame_count := frame_count
	this.frame_delay := frame_delay
	this.frame_lastchange := frame_lastchange
	this.isEnemy := isEnemy
	this.isFood := isFood
	this.player_death_type := player_death_type
	if (this.frame_lastchange = 0)
		this.frame_lastchange := A_TickCount
	}
	
	Offset(x=0,y=0){											;move sprite
	this.x -= x
	this.y += y
	if (this.x + this.width < 0)
		{
			random, newX,2000, 3000
			this.x := newX
		}
	}
	
	step(){														;display next frame of animated sprite
	if (!this.animated)											;sprite not animated
		return
	if (A_TickCount - this.frame_lastchange < this.frame_delay)			;sprite not ready to change to next frame
		return
	this.source_x += 64
	if (this.source_x / 64 > this.frame_count)
		this.source_x := 0
	this.frame_lastchange := A_TickCount
	}
}
