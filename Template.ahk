#NoEnv

#Warn All
#Warn LocalSameAsGlobal, Off

Width := 800
Height := 600
DurationLimit := 1 / 20

global Infinity := 0xFFFFFFFFFFFFFFF

SetBatchLines, -1

s := new Canvas.Surface(Width,Height)
s.Smooth := "Best"
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
    global b := new Canvas.Brush(0xFFFFFFFF)
    global f := new Canvas.Format("Georgia",36)
}

Step(Duration)
{
    global s
    global b
    global f
    static Timer := 0

    Timer += Duration
    If Timer < 1
    {
        Alpha := Floor(Timer * 0xFF)
        b.Color := (b.Color & 0xFFFFFF) | ((Alpha & 0xFF) << 24)
    }
    Else If Timer < 2
    {
    }
    Else If Timer < 3
    {
        Alpha := Floor((2 - Timer) * 0xFF)
        b.Color := (b.Color & 0xFFFFFF) | ((Alpha & 0xFF) << 24)
    }
    If Timer < 3
    {
        s.Clear()
         .Text(b,f,"Uberi & Ton80 present",50,500)
    }
}
Return

#Include Parasol\Parasol.ahk

#Include Canvas-AHK\
#Include Canvas.ahk