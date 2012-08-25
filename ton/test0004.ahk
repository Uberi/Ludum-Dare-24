SetBatchLines -1
#NoEnv
#SingleInstance Force

gosub, initialize_variables
gosub, initialize_graphics
gosub, initialize_cells
gosub, initialize_grid_display						;this is for design only..
gosub, initialize_objects							;this for testing only
gosub, main_loop
return

main_loop:
testx:=A_ScreenWidth
testy:= 500
offsetx := .05
loop
	{
		gosub, draw_overlay
		gosub, update_screen
		cloud1.x -= offsetx				; these are just to show the sprites, all gets removed
		cloud2.x -= offsetx
		cloud3.x -= offsetx
		cloud4.x -= offsetx
		plant1.x -= offsetx * 2
		plant2.x -= offsetx * 2
		plant3.x -= offsetx * 2
		plant4.x -= offsetx * 2
	}
return

draw_overlay:
draw_transparent(hdcBase,cloud1.x,cloud1.y,cloud1.width,cloud1.height,hdcOverlay,cloud1.source_x,cloud1.source_y,cloud1.source_width,cloud1.source_height)
draw_transparent(hdcBase,cloud2.x,cloud2.y,cloud2.width,cloud2.height,hdcOverlay,cloud2.source_x,cloud2.source_y,cloud2.source_width,cloud2.source_height)
draw_transparent(hdcBase,cloud3.x,cloud3.y,cloud3.width,cloud3.height,hdcOverlay,cloud3.source_x,cloud3.source_y,cloud3.source_width,cloud3.source_height)
draw_transparent(hdcBase,cloud4.x,cloud4.y,cloud4.width,cloud4.height,hdcOverlay,cloud4.source_x,cloud4.source_y,cloud4.source_width,cloud4.source_height)

draw_transparent(hdcBase,plant1.x,plant1.y,plant1.width,plant1.height,hdcOverlay,plant1.source_x,plant1.source_y,plant1.source_width,plant1.source_height)
draw_transparent(hdcBase,plant2.x,plant2.y,plant2.width,plant2.height,hdcOverlay,plant2.source_x,plant2.source_y,plant2.source_width,plant2.source_height)
draw_transparent(hdcBase,plant3.x,plant3.y,plant3.width,plant3.height,hdcOverlay,plant3.source_x,plant3.source_y,plant3.source_width,plant3.source_height)
draw_transparent(hdcBase,plant4.x,plant4.y,plant4.width,plant4.height,hdcOverlay,plant4.source_x,plant4.source_y,plant4.source_width,plant4.source_height)
return

update_screen:			;bitblt	the memdcs to the window dc
if (cell.showgrid)
	DllCall("BitBlt", "uint", hdcBase, "int", 0, "int", 0, "int", board.width, "int", board.height, "uint", hdcGrid, "int", 0, "int", 0, "uint", 0x00EE0086)			;srcpaint
	
DllCall("BitBlt", "uint", hdcWin, "int", 0, "int", 0, "int", board.width, "int", board.height, "uint", hdcBase, "int", 0, "int", 0, "uint", 0xCC0020)

;redraw rough water, sky, and sun ; this wont change, so draw them now.
DllCall("FillRect", "uint", hdcBase, "uint", &ptWater, "uint", brush_Water)
DllCall("FillRect", "uint", hdcBase, "uint", &ptSky, "uint", brush_Sky)
DllCall("Ellipse", "uint", hdcBase, "int", sun.x1, "int", sun.y1, "int", sun.x2, "int", sun.y2)
return

initialize_variables:
board := {width:A_ScreenWidth,height:A_ScreenHeight,x:0,y:0,backcolor: 0x32C7F0,scale:.5}
board.width *= board.scale, board.height *= board.scale
cell := {rows:100,columns:200,showgrid:0,gridcolor:0xFFFFFF}
cell.width := board.width / cell.columns
cell.height := board.height / cell.rows
cell.count := cell.rows * cell.columns

water := {x1:0,y1:board.height *.4,x2:board.width,y2:board.height,color:0xF0C732}
sky := {x1:0, y1:0, x2:board.width, y2:board.height *.4,color:0xB5480D}
sun := {x1:board.width *.90, y1:0, x2:board.width, y2:board.height *.15,color:0x0AF7F7}
VarSetCapacity(ptWater, 16, 0)
NumPut(water.x1,ptWater,0), NumPut(water.y1, ptWater, 4),NumPut(water.x2,ptWater,8), NumPut(water.y2, ptWater, 12)
VarSetCapacity(ptSky, 16, 0)
NumPut(Sky.x1,ptSky,0), NumPut(Sky.y1, ptSky, 4),NumPut(Sky.x2,ptSky,8), NumPut(Sky.y2, ptSky, 12)
return

initialize_objects:  ;this  just for testing
;some clouds, just showing each cloud sprite
cloud1 := {x:board.width *.9,y:10,speed:.1,height:board.height * .2,width:board.width *.15,source_x:0,source_y:0,source_height:64,source_width:64}
cloud2 := {x:board.width *.7,y:20,speed:.1,height:board.height * .2,width:board.width *.15,source_x:64,source_y:0,source_height:64,source_width:64}
cloud3 := {x:board.width *.3,y:10,speed:.1,height:board.height * .2,width:board.width *.15,source_x:128,source_y:0,source_height:64,source_width:64}
cloud4:= {x:board.width *.1,y:20,speed:.1,height:board.height * .2,width:board.width *.15,source_x:192,source_y:0,source_height:64,source_width:64}

;some plants, just showing each sprite
plant1 := {x:board.width *.8,y:board.height *.82,speed:.1,height:board.height * .2,width:board.width *.15,source_x:0,source_y:64,source_height:64,source_width:64}
plant2 := {x:board.width *.5,y:board.height *.82,speed:.1,height:board.height * .2,width:board.width *.15,source_x:64,source_y:64,source_height:64,source_width:64}
plant3 := {x:board.width *.3,y:board.height *.82,speed:.1,height:board.height * .2,width:board.width *.15,source_x:128,source_y:64,source_height:64,source_width:64}
plant4 := {x:board.width *.15,y:board.height *.82,speed:.1,height:board.height * .2,width:board.width *.15,source_x:192,source_y:64,source_height:64,source_width:64}
return


initialize_graphics:
gui, -caption
gui, color, %board_backcolor%
;gui, show, h%board.height% w%board.width% x%board_x% y%board_y%
gui, show, % "h"board.height "w"board.width "x"board.x "y"board.y
hdcWin := DllCall("GetDC", "uint", hwnd:=WinExist("A"))

hdcBase := DllCall("CreateCompatibleDC", "uint", hdcWin)
hbmBase := DllCall("CreateCompatibleBitmap", "uint", hdcwin, "int", board.width, "int", board.height)
DllCall("SelectObject", "uint", hdcBase, "uint", hbmBase)

hdcOverlay := DllCall("CreateCompatibleDC", "uint", hdcWin)
hbmOverlay := DllCall("CreateCompatibleBitmap", "uint", hdcwin, "int", board.width, "int", board.height)
DllCall("SelectObject", "uint", hdcOverlay, "uint", hbmOverlay)

brush_background := DllCall("CreateSolidBrush", "int", board_backcolor)

;create grid overlay for design reasons only.
hdcGrid := DllCall("CreateCompatibleDC", "uint", hdcWin)
hbmGrid := DllCall("CreateCompatibleBitmap", "uint", hdcwin, "int", board.width, "int", board.height)
DllCall("SelectObject", "uint", hdcGrid, "uint", hbmGrid)
pen_grid := DllCall("CreatePen", "int", 0, "int", 1, "int", cell.gridcolor)

brush_Water := DllCall("CreateSolidBrush", "uint", water.color)
brush_Sky := DllCall("CreateSolidBrush", "uint", Sky.color)
brush_Sun := DllCall("CreateSolidBrush", "int", Sun.color)
DllCall("SelectObject", "uint", hdcBase, "uint", brush_Sun)

hbmBM := DllCall("LoadImage", "int", 0, str, "sprites.bmp", "int", 0, "int", 0, "int",0, "uint", 0x2010)
maskBM := CreateBitMapMask(hbmBM, 0x1DE6B5)
return

initialize_cells:			;create array of cells
ypos := 0,cell_num := 0
Loop, % cell.rows
	{
		row := A_Index, xpos := 0
		Loop, % cell.columns
			{
				cell_num ++
				cell_%cell_num% := {row:row,column:a_index,type:0,x:xpos,y:ypos}
				xpos += cell.width
			}
		ypos += cell.height
	}
return

initialize_grid_display:	;create the grid overlay, write it to hdcGrid
xpos := 0
DllCall("SelectObject", uint, hdcGrid, uint, pen_grid)
Loop, % cell.columns
	{	
		DllCall("MoveToEx","uint", hdcGrid, "int", xpos, "int", 0, int, 0)
		DllCall("LineTo", "uint", hdcGrid, "int", xpos, "int", board.height)
		xpos += cell.width
	}

ypos := 0
Loop, % cell.rows + 1
	{
		DllCall("MoveToEx","uint", hdcGrid, "int", 0, "int", ypos, "int", 0)
		DllCall("LineTo", "uint", hdcGrid, "int", board.width, "int", ypos, "int", 0)
		ypos += cell.height
	}
return

f2::								;show grid
if cell.showgrid
	cell.showgrid := 0
else
	cell.showgrid := 1
return

esc::
ExitApp


draw_transparent(destDC,destX,destY,destW,destH,sourceDC,sourceX,sourceY,sourceW,sourceH){
	global
	DllCall("SelectObject", "uint", sourceDC, "uint", maskBM)
	DllCall("StretchBlt", "uint", destDC, "int", destX, "int", destY, "int", destW, "int", destH, "uint", sourceDC, "int", sourceX, "int", sourceY, "int", sourceW, "int", sourceH, "uint", 0x8800C6)
	DllCall("SelectObject", "uint", sourceDC, "uint", hbmBM)
	DllCall("StretchBlt", "uint", destDC, "int", destX, "int", destY, "int", destW, "int", destH, "uint", sourceDC, "int", sourceX, "int", sourceY, "int", sourceW, "int", sourceH, "uint", 0xEE0086)
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
