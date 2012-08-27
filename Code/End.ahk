InitializeEnd()
{
    global
    Birds := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Birds.png")
    White := new Canvas.Brush(0xFFFFFFFF)
    Title := new Canvas.Format("Georgia",72)
    Title.Align := "Center"
    Subtitle := new Canvas.Format("Georgia",18)
    Subtitle.Align := "Center"
    Prompt := new Canvas.Format("Georgia",24)
    Prompt.Align := "Center"
}

StepEnd(Duration)
{
    global s, Birds
    global White, Title, Subtitle, Prompt
    global TotalDuration
    s.Clear()
     .Draw(Birds)
     .Text(White,Title,"Game Over!",0,200,800)
     .Text(White,Subtitle,"You lasted " . Round(TotalDuration,1) . " seconds.",0,300,800)
     .Text(White,Prompt,"Press Space to play again.",0,500,800)
    If KeyState("Space")
        Return, True
}