SetBatchLines -1
#NoEnv
CoordMode, Mouse, Screen
CoordMode, Pixel, Screen
CoordMode, Tooltip, Screen

files_needed	:= "grass_texture2.bmp,mountain_texture3.bmp,sky_texture.bmp,explode_2.bmp"

Loop, parse, files_needed, csv
	{
		If !FileExist(A_LoopField)
		URLDownloadToFile, http://www.autohotkey.net/~ton80/mortar/%A_Loopfield%,%A_Scriptdir%\%A_Loopfield%
		if errorlevel
			MsgBox Couldnt download file.
	}

gosub, initialize_color_values
gosub, initialize_variables
gosub, initialize_graphics
gosub, update_board
gosub, main_loop
return

main_loop:
	Loop
	{
		gosub, draw_angle_line
		gosub, on_screen_display
		gosub, update_board
	}
return


;osd
draw_angle_line:
DllCall("SetBkColor", "Int", hdcMem, "Int", white)
DllCall("SelectObject", uint, hdcMem, uint, pen_angle)
MouseGetPos, mousex,mousey
_MoveTo(hdcMem, player_1_x, player_1_y)
_LineTo(hdcMem, mousex,mousey)

player_1_cannon_angle := atan2(Player_1_Y - mousey, mousex - Player_1_X)
player_1_cannon_angle *= 57.29578
tempangle := player_1_cannon_angle
Player_1_cannon_angle := round(90 - tempangle)
return

On_Screen_Display:
;DllCall("SetBkColor", "Int", hdcMem, "Int", blue)
DllCall("SelectObject", uint, hdcMem, uint, pen_hud)
DllCall("SelectObject", uint, hdcMem, uint, brush_hud)
DllCall("Rectangle", uint, hdcMem, int, 5, int, 5, int, board_width *.208, int, board_height * .2)
dangle := "Angle : " . player_1_cannon_angle
DllCall("TextOut", "Int", hdcMem, "UInt", 10, "UInt", 10, "UInt", &dangle, "UInt", StrLen(dangle))
return

;fire
c::
DllCall("SelectObject", uint, hdcMem, uint, pen_hud)
player_1_fire:
angle		:= player_1_cannon_angle								;degrees
vi 			:= 230													;velocity meters per sec
ax		 	:= 0													;horizontal acceleration (always 0 for a projectile)
ay			:= -9.80665												;vertical acceleration (gravity)
ix		 	:= player_1_x											;initial x position
iy		 	:= player_1_y											;initial y position
vix			:= 0													;initial x velocity
viy			:= 0													;initial y velocity
t			:= 0													;time
ts			:= 0													;time shot was fired
x			:= ix													;current x position
y			:= iy													;current y position
yd 			:= y - iy												;for display purposes, yd (y display)
gy			:= ground_elevation											;ground elevation
theta := angle * .0174532925										;angle converted to radians
vix := vi * cos(theta)												;initial x velocity
viy := vi * sin(theta)												;initial y velocity


ts := A_TickCount													;start time of shot
;_moveto(hdcBoard,x,y)
while y <= board_height
{
	t := round((A_TickCount - ts)/1000,5)	* 8						; time
	y := viy * t + .5 * ay * t**2									; calculate y coord
	y /= meters_per_pixel_h
	y := iy - y														; calculate for screen cood (on screen higher number of Y, is lower in position)
	x :=  vix * t + .5 * ax * t**2									; calculate x coord
	x /= meters_per_pixel_w
	x += ix
	;_lineto(hdcBoard,x,y)
	DllCall("Ellipse", uint, hdcmem, int, x, int, y, int, x + cannonball_size, int, y + cannonball_size)
	if (DllCall("PtInRegion", uint, mountain, int, x + cannonball_size / 2, int, y + + cannonball_size / 2))
		{
			gosub, collision_mountain
			break
		}
	if (DllCall("PtInRegion", uint,ground, int, x + cannonball_size / 2, int, y + + cannonball_size / 2))
		{
			gosub, collision_ground
			break
		}
	gosub, draw_angle_line
	gosub, on_screen_display
	gosub, update_board
	if (x > board_width)
		break
}
return

collision_mountain:
x := round(x)
y := round(y)
gosub, explosion
cball := DllCall("CreateEllipticRgn", int, x, int, y, int, x + cannonball_size, int, y + cannonball_size)
DllCall("CombineRgn", uint, mountain, uint,mountain, uint, cball, int, 4)
DllCall("DeleteObject", "Int", cball)
return

collision_ground:
x := round(x)
y := round(y)
gosub, explosion
cball := DllCall("CreateEllipticRgn", int, x, int, y, int, x + cannonball_size, int, y + cannonball_size)
DllCall("CombineRgn", uint, ground, uint,ground, uint, cball, int, 4)
DllCall("DeleteObject", "Int", cball)
return

explosion:
cy := 1
Loop, 4
{
	
	cx := 0
	Loop, 4
		{
			DllCall("SelectObject", "UInt", hdcMem2, "UInt", maskExplosion)
			DllCall("BitBlt", "UInt", hdcMem, "Int", x - 32, "Int", y - 32, "Int",64, "Int", 64, "UInt", hdcMem2, "Int", cx, "Int", cy, "Int", 0x8800C6)
			DllCall("SelectObject", "UInt", hdcMem2, "UInt", hbmExplosion)
			DllCall("BitBlt", "UInt", hdcMem, "Int", x - 32, "Int", y - 32, "Int",64, "Int", 64, "UInt", hdcMem2, "Int", cx, "Int", cy, "Int", 0xEE0086)
			cx += 64
			gosub, draw_angle_line
			gosub, on_screen_display
			gosub, update_board
			sleep, 10
		}
		cy +=64
}
return

;misc on screen
update_board:
gosub, draw_player_1

;fill background objects
DllCall("FillRgn", uint, hdcMem, uint, ground, uint, brush_ground)
DllCall("FillRgn", uint, hdcMem, uint, mountain, uint, brush_mountain)
DllCall("BitBlt", "uint", hdcBoard, "int", 0, "int", 0, "int", board_width, "int", board_height, "uint", hdcMem, "int", 0, "int", 0, "uint", 0xCC0020)
;clear hdcmem
DllCall("FillRect", "uint", hdcMem, "UInt", &ptWin, "uint", brush_sky)
return

draw_player_1:
DllCall("Ellipse", uint, hdcMem, int, player_1_x, int, player_1_y, int, player_1_x + player_1_width, int, player_1_y + player_1_height)
return

;exit routine
esc::
DllCall("ReleaseDC", uint, hwndBoard, uint, hdcBoard)
DllCall("DeleteDC", uint, hdcMem)
DllCall("DeleteDC", uint, hdcMem2)
DllCall("DeleteObject", uint, hbm)
DllCall("DeleteObject", uint, brush_ground)
DllCall("DeleteObject", uint, brush_mountain)
DllCall("DeleteObject", uint, ground)
DllCall("DeleteObject", uint, mountain)
DllCall("DeleteObject", uint, pen_angle)
DllCall("DeleteObject", uint, pen_hud)
DllCall("DeleteObject", uint,hbmexplosion)
DllCall("DeleteObject", uint, maskexplosion)
ExitApp

;setup
initialize_color_values:
Green:= "0x008000",Silver:= "0xC0C0C0",Lime:= "0x00FF00",Gray:= "0x808080",Olive:= "0x008080", White:= "0xFFFFFF",Yellow:= "0x00FFFF",Maroon:= "0x000080",Navy:= "0x800000",Red   := "0x0000FF",Blue:= "0xFF0000",Purple:= "0x800080",Teal:= "0x808000",Fuchsia:= "0xFF00FF",Aqua:= "0xFFFF00",Black:= "0x000000",Brown:= "0x2A2AA5"
RGN_AND:= 1,RGN_COPY:= 5,RGN_DIFF:= 4,RGN_OR:= 2,RGN_XOR:= 3
PS_SOLID := 0,PS_DASH := 1, PS_DOT := 2, PS_DASHDOT := 3, PS_DASHDOTDOT := 4, PS_NULL := 5, PS_INSIDEFRAME := 6
return

initialize_variables:
board_width			:=		A_ScreenWidth
board_height		:=		A_ScreenHeight
board_width_meters	:=		5000
board_height_meters :=		3000
;board_width		:=		600
;board_height		:=		400
board_x				:=		0
board_y				:=		0
meters_per_pixel_w	:=		board_width_meters / board_width
meters_per_pixel_h	:=		board_height_meters / board_height

sky_color			:=		blue

ground_color		:=		green
ground_elevation	:=		board_height *.83

mountain_height		:=		board_height *.7, mountain_height := board_height - mountain_height
mountain_width		:=		board_width	*.55
mountain_x			:=		board_width /2 - mountain_width /2
mountain_y			:=		ground_elevation
mountain_cx			:= board_width / 2
mountain_cy			:= mountain_height
mountain_climb_max	:= mountain_height *.2
mountain_climb_min	:= mountain_height *.09
mountain_dist_max	:= mountain_width *.1
mountain_dist_min	:= mountain_width *.01

player_1_color		:=		red
player_1_height		:=		board_height *.03
player_1_width		:=		board_width *.01
player_1_x			:=		board_width *.01
player_1_y			:=		ground_elevation - player_1_height

cannonball_size		:=		board_width *.01
cannonball_color	:=		black

hud_color			:=		gray

return



initialize_graphics:
VarSetCapacity(ptWin, 16, 0)
NumPut(board_width, ptWin, 8) , NumPut(board_height, ptWin, 12)
gui, -caption
gui, color, %sky_color%
gui, show, x%board_x% y%board_y% h%board_height% w%board_width%
hwndBoard := WinExist("A")
hdcBoard := DllCall("GetDC", uint, hwndBoard)
hdcMem := DllCall("CreateCompatibleDC", "UInt", hdcBoard)
hbm := DllCall("CreateCompatibleBitmap", "uint", hdcBoard, "int", board_width, "int", board_height)
DllCall("SelectObject", "uint", hdcMem, "uint", hbm)

;fill background of hdcmem
hBM2 := DllCall( "LoadImage", "Int",0, "Str","sky_texture.bmp", "Int",0,"Int",board_width, "Int",board_height, "UInt",0x2010 ) 
brush_sky := DllCall( "CreatePatternBrush", UInt,hBM2 )
DllCall("DeleteObject", "Int", hbm2)
DllCall("FillRect", "uint", hdcMem, "UInt", &ptWin, "uint", brush_sky)

;draw ground
hBM2 := DllCall( "LoadImage", "Int",0, "Str","grass_texture2.bmp", "Int",0,"Int",board_width, "Int",300, "UInt",0x2010 ) 
brush_ground := DllCall( "CreatePatternBrush", UInt,hBM2 )
DllCall("DeleteObject", "Int", hbm2)
ground_points := board_x "," ground_elevation "," board_width ","  board_height
VarSetCapacity(ptGround,16)
	loop, parse, ground_points, `,
		NumPut(Round(A_Loopfield),ptGround, A_Index*4-4)
ground := DllCall("CreateRectRgnIndirect", int, &ptGround)
DllCall("FillRgn", uint, hdcMem, uint, ground, uint, brush_ground)

;draw_mountain
hBM2 := DllCall( "LoadImage", "Int",0, "Str","mountain_texture3.bmp", "Int",0,"Int",600, "Int",600, "UInt",0x2010 ) 
brush_mountain := DllCall( "CreatePatternBrush", UInt,hBM2 )
DllCall("DeleteObject", "Int", hbm2)
mountain_points := CreateMountain(hdcBoard,mountain_width, mountain_height, mountain_x, mountain_y, mountain_cx, mountain_cy, mountain_climb_max, mountain_climb_min, mountain_dist_max, mountain_dist_min)
Loop, parse, mountain_points, `,
		mountain_points_number := a_Index * 4

VarSetCapacity(ptMountain,mountain_points_number)
mountain_points_number /= 2
loop, parse, mountain_points, `,
		NumPut(Round(A_Loopfield),ptMountain, A_Index*4-4)
mountain :=	DllCall("CreatePolygonRgn", uint, &ptMountain, int, mountain_points_number / 4, int, 1)
DllCall("FillRgn", uint, hdcMem, uint, mountain, uint, brush_mountain)

pen_angle 	:= DllCall("CreatePen", int, 2, int, 1, int, black)
pen_hud		:= DllCall("CreatePen", int, 0, int, 2, int, black)
brush_hud	:= DllCall("CreateSolidBrush", int, hud_color)
font_hud :=DllCall("CreateFont", "int", font_width, "int",font_height, "int", 0, "int", 0, "int", 1000,"uint",0,"uint",0,"uint",0,"uint",1,"uint",0,"uint",0,"uint",0,"uint",0,"str", "Comic Sans MS Bold")
DllCall("SelectObject", "uint", hdcMem, "uint", font_hud)
DllCall("SetTextColor", "Int", hdcMem, "Int", black)

;explosions
hbmExplosion := DllCall("LoadImage", "Int",0, "Str","explode_2.bmp", "Int",0,"Int",0, "Int",0, "UInt",0x2010)
maskExplosion := CreateBitMapMask(hbmExplosion, 0x000000)
hdcMem2 := DllCall("CreateCompatibleDC", "Int", hdcBoard)			;explosions
return


;functions
_MoveTo(dc,endx,endy){
	Return DllCall("MoveToEx",uint, dc, int, endx, int, endy, uint, 0)
}

_LineTo(dc,endx,endy){
	Return DllCall("LineTo",uint, dc, int, endx, int, endy)
}

atan2(x,y) { 
   Return dllcall("msvcrt\atan2","Double",y, "Double",x, "CDECL Double") 
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

CreateMountain(dc,w,h,x,y,cx,cy,cmax,cmin,dmax,dmin){
	tx := x
	ty := y
	mountain_points := round(x) "," round(y) ","
	DllCall("MoveToEx", uint, dc, int, x, int, y, uint, 0)
	;rise from left
	while (tx < cx)
		{
			Random, dist, dmin, dmax
			Random, climb, cmin, cmax
			ty -= climb
			tx += dist
			if (tx > cx)
				tx := cx
			if (ty < cy)
				ty := cy
			mountain_points .= round(tx) "," round(ty) ","
			DllCall("LineTo", uint, dc, int, tx, int, ty)
	}
	;fall to right
	while (ty < y)
		{
			Random, dist, dmin, dmax
			Random, climb, cmin, cmax
			ty += climb
			tx += dist
			if (ty > y)
				ty := y
			mountain_points .= round(tx) "," round(ty) ","
			DllCall("LineTo", uint, dc, int, tx, int, ty)
		}
	StringTrimRight, mountain_points, mountain_points, 1
	return, mountain_points
}

f2::Reload