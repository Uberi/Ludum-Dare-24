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

InitializeStart()
Activate(hDC,s,Func("StepStart"),DurationLimit)
Return

GuiClose:
ExitApp

Activate(hDC,Surface,Step,DurationLimit)
{
    TickFrequency := 0, Ticks1 := 0, Ticks := 0
    If !DllCall("QueryPerformanceFrequency","Int64*",TickFrequency) ;obtain ticks per second
        throw Exception("Could not obtain performance counter frequency.")
    If !DllCall("QueryPerformanceCounter","Int64*",Ticks1) ;obtain the performance counter value
        throw Exception("Could not obtain performance counter value.")
    Loop
    {
        If !DllCall("QueryPerformanceCounter","Int64*",Ticks) ;obtain the performance counter value
            throw Exception("Could not obtain performance counter value.")
        Duration := (Ticks - Ticks1) / TickFrequency, Ticks1 := Ticks
        If Duration < 0
            Duration := 0
        If (Duration > DurationLimit)
            Duration := DurationLimit

        If Step.(Duration)
            Break
        DllCall("BitBlt","UPtr",hDC,"Int",0,"Int",0,"Int",Surface.Width,"Int",Surface.Height,"UPtr",Surface.hMemoryDC,"Int",0,"Int",0,"UInt",0xCC0020) ;SRCCOPY

        Sleep, (DurationLimit - Duration) * 1000
    }
}

InitializeStart()
{
    global b := new Canvas.Brush(0xFFFFFFFF)
    global Subtitle := new Canvas.Format("Georgia",24)
    global Title := new Canvas.Format("Georgia",72)
}

StepStart(Duration)
{
    global s
    global b
    global Subtitle, Title
    static Timer := 0
    Timer += Duration

    s.Clear()

    If Timer < 1
    {
        Alpha := Floor(Timer * 0xFF)
        b.Color := (b.Color & 0xFFFFFF) | ((Alpha & 0xFF) << 24)
    }
    Else If Timer < 3
    {
    }
    Else If Timer < 4
    {
        Alpha := Floor((3 - Timer) * 0xFF)
        b.Color := (b.Color & 0xFFFFFF) | ((Alpha & 0xFF) << 24)
    }
    If Timer < 4
    {
        s.Text(b,Subtitle,"Uberi & Ton80 present",50,500)
    }

    If Timer > 5
    {
        If Timer < 6
        {
            Alpha := Floor((Timer - 5) * 0xFF)
            b.Color := (b.Color & 0xFFFFFF) | ((Alpha & 0xFF) << 24)
        }

        s.Text(b,Title,"GAME NAME HERE",50,200)
         .Text(b,Subtitle,"Made, with love, during Ludum Dare #24",50,500)
    }
}
Return

#Include Parasol\Parasol.ahk

#Include Canvas-AHK\
#Include Canvas.ahk