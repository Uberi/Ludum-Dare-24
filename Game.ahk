#NoEnv

#Warn All
#Warn LocalSameAsGlobal, Off

Width := 800
Height := 600
DurationLimit := 1 / 15

global Infinity := 0xFFFFFFFFFFFFFFF

SetBatchLines, -1

s := new Canvas.Surface(Width,Height)
s.Smooth := "Best"
p := new Parasol

Gui, +LastFound
hWindow := WinExist()
hDC := DllCall("GetDC","UPtr",hWindow,"UPtr")

Gui, Show, w%Width% h%Height%, Physics Test

SoundPlay, %A_ScriptDir%\Sounds\Maple Leaf.mp3

;InitializeStart()
;Activate(hDC,s,p,Func("StepStart"),DurationLimit)

InitializeGame()
Activate(hDC,s,p,Func("StepGame"),DurationLimit)
Return

#Include %A_ScriptDir%\Code\Start.ahk
#Include %A_ScriptDir%\Code\Game.ahk

GuiClose:
ExitApp

TransparentCopy(Surface1,Surface2,Color,X,Y,W,H,SourceX = 0,SourceY = 0,SourceW = "",SourceH = "")
{
    If (SourceW = "")
        SourceW := Surface1.Width
    If (SourceH = "")
        SourceH := Surface1.Height
    If !DllCall("TransparentBlt","UPtr",Surface2.hMemoryDC,"Int",X,"Int",Y,"Int",W,"Int",H
        ,"UPtr",Surface1.hMemoryDC,"Int",SourceX,"Int",SourceY,"Int",SourceW,"Int",SourceH
        ,"UInt",Color)
        throw Exception("It's not you, it's me.")
}

Activate(hDC,Surface,Parasol,Step,DurationLimit)
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
        Parasol.Step(Duration)
        DllCall("BitBlt","UPtr",hDC,"Int",0,"Int",0,"Int",Surface.Width,"Int",Surface.Height,"UPtr",Surface.hMemoryDC,"Int",0,"Int",0,"UInt",0xCC0020) ;SRCCOPY

        Sleep, (DurationLimit - Duration) * 1000
    }
}

KeyState(Key)
{
    global hWindow
    If !WinActive("ahk_id " . hWindow)
        Return, False
    If GetKeyState(Key,"P")
        Return, True
    Return, False
}

PlayAsync(Path)
{
    StringReplace, Path, Path, `,, ```,, All
    Script = 
    (
    #NoTrayIcon
    SoundPlay, %Path%, WAIT
    )
    Execute(Script)
}

Execute(Script,Parameters = "")
{
    ;create named pipes to hold the script code
    PipeName := "\\.\pipe\AHK_Script_" . A_ScriptHwnd . "_" . A_TickCount ;create a globally unique pipe name
    hTempPipe := DllCall("CreateNamedPipe","Str",PipeName,"UInt",2,"UInt",0,"UInt",255,"UInt",0,"UInt",0,"UInt",0,"UInt",0) ;temporary pipe
    If hTempPipe = -1
        throw Exception("Could not create temporary named pipe.")
    hExecutablePipe := DllCall("CreateNamedPipe","Str",PipeName,"UInt",2,"UInt",0,"UInt",255,"UInt",0,"UInt",0,"UInt",0,"UInt",0) ;executable pipe
    If hExecutablePipe = -1
        throw Exception("Could not create executable named pipe.")

    ;start the script
    CodePage := A_IsUnicode ? 1200 : 65001 ;UTF-16 or UTF-8
    Run, % """" . A_AhkPath . """ /CP" . CodePage . " """ . PipeName . """ " . Parameters,, UseErrorLevel, ScriptPID
    If ErrorLevel
    {
        DllCall("CloseHandle","UPtr",hTempPipe) ;close the temporary pipe
        DllCall("CloseHandle","UPtr",hExecutablePipe) ;close the executable pipe
        throw Exception("Could not run script.")
    }

    ;wait for the script to connect to the temporary pipe and close it
    DllCall("ConnectNamedPipe","UPtr",hTempPipe,"UPtr",0)
    DllCall("CloseHandle","UPtr",hTempPipe)

    ;wait for the script to connect the executable pipe and transfer the code
    DllCall("ConnectNamedPipe","UPtr",hExecutablePipe,"UPtr",0)
    DllCall("WriteFile","UPtr",hExecutablePipe,"Str",Script,"UInt",StrLen(Script) << !!A_IsUnicode,"UPtr",0,"UPtr",0)
    DllCall("CloseHandle","UPtr",hExecutablePipe)

    Return, ScriptPID
}

#Include Parasol\Parasol.ahk

#Include Canvas-AHK\
#Include Canvas.ahk