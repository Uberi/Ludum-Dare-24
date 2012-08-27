InitializeStart()
{
    global
    White := new Canvas.Brush(0xFFFFFFFF)
    Title := new Canvas.Format("Georgia",72)
    Title.Align := "Center"
    Prompt := new Canvas.Format("Georgia",24)
    Prompt.Align := "Center"
    Subtitle := new Canvas.Format("Georgia",14)
    Subtitle.Italic := True
    Fishing := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fishing.png")
}

StepStart(Duration)
{
    global s, Fishing
    global White
    global Subtitle, Title, Prompt
    static Timer := 0

    If Timer < 1
    {
        Alpha := Floor(Timer * 0xFF)
        White.Color := (White.Color & 0xFFFFFF) | ((Alpha & 0xFF) << 24)
    }
    Else If Timer < 3
    {
    }
    Else If Timer < 4
    {
        Alpha := Floor((3 - Timer) * 0xFF)
        White.Color := (White.Color & 0xFFFFFF) | ((Alpha & 0xFF) << 24)
    }
    If Timer < 4
    {
        s.Clear(0xFF000000)
         .Text(White,Subtitle,"Uberi & Ton80 proudly present",50,550)
    }

    If Timer > 5
    {
        White.Color := (White.Color & 0xFFFFFF) | 0xFF000000

        s.Clear()
         .Draw(Fishing)
         .Text(White,Title,"Out of the Sea",0,200,800)
         .Text(White,Prompt,"Press Space to play.",0,500,800)
         .Text(White,Subtitle,"Lovingly crafted during Ludum Dare #24 (theme: evolution)",50,50)

        If KeyState("Space")
        {
            KeyWait, Space
            Return, True
        }
    }

    Timer += Duration
}