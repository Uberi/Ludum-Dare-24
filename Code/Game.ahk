InitializeGame()
{
    global
    Waves := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Waves.png")
    Riverbed := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Riverbed.png")

    Fish := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Salmon.png")
    Elephant := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Elephant.png")
    Goat := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Goat.png")

    Fisherman1 := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 1.png")
    Fisherman2 := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 2.png")
    Coral := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Coral.png")
    Shell := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Shells.png")
    Clouds := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Clouds.png")

    FishEntity := new p.Entity(400,400)
    FishEntity.RotationalInertia := 200
    p.AddEntity(FishEntity)
    p.Register(new p.Drag(FishEntity,0.5))
    p.Register(new p.Gravity(FishEntity,120))
    LiquidLevel := 200
    FishBuoyancy := new Buoyancy(FishEntity,180,LiquidLevel,0.8)
    p.Register(FishBuoyancy)
    p.Register(new KeyboardController(FishEntity))
}

StepGame(Duration)
{
    global s, Fish, Elephant, Goat, Kangaroo, Fisherman1, Fisherman2, Clouds, Waves, Riverbed, Coral, Shell
    global FishEntity, FishBuoyancy
    global LiquidLevel
    static CameraX := 0, CameraY := 0
    static InWater := True, LastOut := 0
    static CloudX := 200, CloudY := -100
    static CoralX := 800, ShellX := 400

    Weight := Duration
    CameraX := (CameraX * (1 - Weight)) + ((FishEntity.X - 100) * Weight)
    CameraY := (CameraY * (1 - Weight)) + ((FishEntity.Y - 300) * Weight)
    If CameraY > 90
        CameraY := 90

    s.Clear(0xFFFFFFFF)
     .Draw(Waves,Mod(-CameraX,800),(LiquidLevel - CameraY) - (Waves.Height * 0.5),Waves.Width,Waves.Height)
     .Draw(Waves,Mod(-CameraX,800) + 800,(LiquidLevel - CameraY) - (Waves.Height * 0.5),Waves.Width,Waves.Height)
     .Draw(Riverbed,Mod(-CameraX,800),((LiquidLevel + 300) - CameraY),Riverbed.Width,Riverbed.Height)
     .Draw(Riverbed,Mod(-CameraX,800) + 800,((LiquidLevel + 300) - CameraY),Riverbed.Width,Riverbed.Height)

    s.Push()
     .Translate(-CameraX,-CameraY)

    s.Draw(Fisherman1,500,20,Fisherman1.Width,Fisherman1.Height)
    s.Draw(Fisherman2,1600,40,Fisherman2.Width,Fisherman2.Height)

    If ((CoralX - CameraX) + Coral.Width) < 0
    {
        Random, Temp1, 1000, 1600
        CoralX += Temp1
    }
    s.Draw(Coral,CoralX,LiquidLevel + 380,Coral.Width * 1.5,Coral.Height * 1.5)

    If ((ShellX - CameraX) + Shell.Width) < 0
    {
        Random, Temp1, 800, 1000
        ShellX += Temp1
    }
    s.Draw(Shell,ShellX,LiquidLevel + 420,Shell.Width,Shell.Height)

    If ((CloudX - CameraX) + Clouds.Width) < 0
    {
        Random, Temp1, 1200, 1400
        CloudX += Temp1
        Random, CloudY, 0, -200
    }
    s.Draw(Clouds,CloudX,CloudY,Clouds.Width,Clouds.Height)

    s.Push()
     .Translate(FishEntity.X,FishEntity.Y)
     .Rotate(FishEntity.Angle)

    Depth := FishEntity.Y - LiquidLevel

    If KeyState("j")
    {
        FishBuoyancy.Volume := 500
        s.Draw(Elephant,Elephant.Width * -0.3,Elephant.Height * -0.3,Elephant.Width * 0.6,Elephant.Height * 0.6)
        If InWater && Depth < 0 && (A_TickCount - LastOut) > 5000 ;just got out of the water
        {
            PlayAsync(A_ScriptDir . "\Sounds\Elephant.mp3")
            PlayAsync(A_ScriptDir . "\Sounds\Splash.mp3")
            LastOut := A_TickCount
        }
    }
    Else If KeyState("k")
    {
        FishBuoyancy.Volume := 400
        s.Draw(Goat,Goat.Width * -0.2,Goat.Height * -0.2,Goat.Width * 0.4,Goat.Height * 0.4)
        If InWater && Depth < 0 && (A_TickCount - LastOut) > 5000 ;just got out of the water
        {
            PlayAsync(A_ScriptDir . "\Sounds\Goat.mp3")
            PlayAsync(A_ScriptDir . "\Sounds\Splash.mp3")
            LastOut := A_TickCount
        }
    }
    Else
    {
        FishBuoyancy.Volume := 160
        s.Draw(Fish,Fish.Width * -0.1,Fish.Height * -0.1,Fish.Width * 0.2,Fish.Height * 0.2)
        If InWater && Depth < 0 && (A_TickCount - LastOut) > 5000 ;just got out of the water
        {
            PlayAsync(A_ScriptDir . "\Sounds\Splash.mp3")
            LastOut := A_TickCount
        }
    }

    If Depth > 0
        InWater := True
    Else
        InWater := False

    s.Pop()

    s.Pop()
}

class KeyboardController
{
    __New(Entity)
    {
        this.Entity := Entity
    }

    Step(Duration,Instance)
    {
        global LiquidLevel
        this.Entity.Transformed(50,0,X,Y)
        this.Entity.Force(X,Y,100,0)
        Depth := this.Entity.Y - LiquidLevel
        If Depth < 0
            Return
        If KeyState("Up") || KeyState("W")
            this.Entity.Force(X,Y,0,-80)
        If KeyState("Down") || KeyState("S")
            this.Entity.Force(X,Y,0,80)
    }
}

class Buoyancy
{
    __New(Entity,Volume,LiquidLevel,LiquidDensity)
    {
        this.Entity := Entity
        this.Volume := Volume
        this.LiquidLevel := LiquidLevel
        this.LiquidDensity := LiquidDensity
    }

    Step(Duration,Instance)
    {
        Depth := this.Entity.Y - this.LiquidLevel
        If Depth > 0 ;inside of the liquid
        {
            this.Entity.Force(this.Entity.X,this.Entity.Y,0,-this.Volume * this.LiquidDensity)
            If Depth > 400
                this.Entity.Force(this.Entity.X,this.Entity.Y,0,-this.Volume * 2 * this.LiquidDensity)
        }
    }
}