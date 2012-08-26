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
    Kangaroo := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Kangaroo Title.jpg")
}

StepStart(Duration)
{
    global s, Kangaroo
    global White
    global Subtitle, Title, Prompt
    static Timer := 0

    s.Clear(0xFF000000)

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
        s.Text(White,Subtitle,"Uberi & Ton80 proudly present",50,550)

    If Timer > 5
    {
        White.Color := (White.Color & 0xFFFFFF) | 0xFF << 24

        s.Text(White,Prompt,"Press Space to begin",0,50,800)
         .Text(White,Title,"Evolutionary",0,100,800)
         .Draw(Kangaroo,300,250,200,200)
         .Text(White,Subtitle,"Lovingly crafted during Ludum Dare #24 (theme: evolution)",350,550)

        If KeyState("Space")
            Return, True
    }

    Timer += Duration
}