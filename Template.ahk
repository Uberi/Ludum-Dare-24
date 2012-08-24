#NoEnv

#Warn All
#Warn LocalSameAsGlobal, Off

Width := 400
Height := 400
DurationLimit := 1 / 20

global Infinity := 0xFFFFFFFFFFFFFFF

SetBatchLines, -1

s := new Canvas.Surface(Width,Height)
p := new Parasol

Gui, +LastFound
hWindow := WinExist()
hDC := DllCall("GetDC","UPtr",hWindow,"UPtr")

Gui, Show, w%Width% h%Height%, Physics Test

TickFrequency := 0, Ticks1 := 0, Ticks := 0
If !DllCall("QueryPerformanceFrequency","Int64*",TickFrequency) ;obtain ticks per second
    throw Exception("Could not obtain performance counter frequency.")
If !DllCall("QueryPerformanceCounter","Int64*",Ticks1) ;obtain the performance counter value
    throw Exception("Could not obtain performance counter value.")

Initialize()
Loop
{
    If !DllCall("QueryPerformanceCounter","Int64*",Ticks) ;obtain the performance counter value
        throw Exception("Could not obtain performance counter value.")
    Duration := (Ticks - Ticks1) / TickFrequency, Ticks1 := Ticks
    If Duration < 0
        Duration := 0
    If (Duration > DurationLimit)
        Duration := DurationLimit

    Step(Duration)
    DllCall("BitBlt","UPtr",hDC,"Int",0,"Int",0,"Int",s.Width,"Int",s.Height,"UPtr",s.hMemoryDC,"Int",0,"Int",0,"UInt",0xCC0020) ;SRCCOPY

    Sleep, (DurationLimit - Duration) * 1000
}
Return

GuiClose:
ExitApp

Initialize()
{
    global b := new Canvas.Brush(0xFFFF0000)
}

Step(Duration)
{
    global s
    global b
    b.Color := (b.Color & 0xFFFFFF) | ((((b.Color >> 24) + 1) & 0xFF) << 24)
    SetFormat, Integer, H
    s.Clear()
     .FillEllipse(b,100,100,200,200)
}
Return

#Include Parasol\Parasol.ahk

#Include Canvas-AHK\
#Include Canvas.ahk