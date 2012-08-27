InitializeGame()
{
    global
    TotalDuration := 0

    Waves := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Waves.png")
    Riverbed := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Riverbed.png")

    Black := new Canvas.Brush(0xFF000000)
    Prompt := new Canvas.Format("Georgia",36)

    Elephant := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Elephant.png")
    ElephantW := Elephant.Width, ElephantH := Elephant.Height
    Goat := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Goat.png")
    GoatW := Goat.Width, GoatH := Goat.Height
    Fish := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Salmon.png")
    FishW := Fish.Width, FishH := Fish.Height

    Fishermen := [new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 1.png")
                 ,new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 2.png")
                 ,new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 3.png")
                 ,new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 4.png")
                 ,new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 5.png")
                 ,new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 6.png")]
    Fisherman := Fishermen[1]
    Hook := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Hook.png")
    Lobster := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Lobster.png")

    Coral := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Coral.png")
    Shell := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Shells.png")
    Water := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Water.png")
    Clouds := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Clouds.png")

    CurrentEvolution := Fish
    Available := [Goat,Elephant]

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
    global s, Fish, Elephant, Goat, Kangaroo, Fishermen, Fisherman, Hook, Clouds, Waves, Riverbed, Coral, Shell, Water, Lobster
    global ElephantW, ElephantH, GoatW, GoatH, FishW, FishH, p
    global Black, Prompt
    global FishEntity, FishBuoyancy
    global LiquidLevel
    global hWindow
    static CameraX := 0, CameraY := 0
    static InWater := True, LastOut := 0
    static CloudX := 200, CloudY := -100
    static CoralX := 800, ShellX := 400, FishermanX := 2000, LobsterX := 2600, LobsterShown := True
    static DisplayAngle := 0
    global CurrentEvolution, Available
    static CurrentTimer := 0
    static HookOffsets := [-83,60,70,150,170,180], HookOffset := HookOffsets[1]
    static Colliding := False, CollideTimer := 0
    global TotalDuration

    TotalDuration += Duration

    Weight := Duration
    CameraX := (CameraX * (1 - Weight)) + ((FishEntity.X) * Weight)
    CameraY := (CameraY * (1 - Weight)) + ((FishEntity.Y - 300) * Weight)
    If CameraY > 90
        CameraY := 90

    s.Clear(0xFFFFFFFF)
     .Draw(Water,0,(LiquidLevel - CameraY),800,500)
     .Draw(Waves,Mod(-CameraX,800),(LiquidLevel - CameraY) - (Waves.Height * 0.5),Waves.Width,Waves.Height)
     .Draw(Waves,Mod(-CameraX,800) + 800,(LiquidLevel - CameraY) - (Waves.Height * 0.5),Waves.Width,Waves.Height)
     .Draw(Riverbed,Mod(-CameraX,800),((LiquidLevel + 300) - CameraY),Riverbed.Width,Riverbed.Height)
     .Draw(Riverbed,Mod(-CameraX,800) + 800,((LiquidLevel + 300) - CameraY),Riverbed.Width,Riverbed.Height)

    s.Push()
     .Translate(-CameraX,-CameraY)

    s.Text(Black,Prompt,"Warning: fishermen ahead!",400,500)
    s.Text(Black,Prompt,"Press Space to evolve!",1400,500)
    s.Text(Black,Prompt,"Move up and down with arrow keys!",2800,500)

    If ((FishermanX - CameraX) + Fisherman.Width) < 0
    {
        Random, Temp1, 1, 6
        Fisherman := Fishermen[Temp1]
        HookOffset := HookOffsets[Temp1]

        Random, Temp1, 2000, 2500
        FishermanX += Temp1
    }
    s.Draw(Fisherman,FishermanX,20,Fisherman.Width,Fisherman.Height)
    s.Draw(Hook,FishermanX + HookOffset,Fisherman.Height,Hook.Width,Hook.Height)

    Depth := FishEntity.Y - LiquidLevel

    ;check for intersection with hook or line
    If (Depth > 0)
        && FishEntity.X > (FishermanX + HookOffset + 50)
        && FishEntity.X < (FishermanX + HookOffset + 100)
        Colliding := True

    ;check for intersection with land
    If (Depth > -100 && Depth < 0)
        && FishEntity.X > (FishermanX + 50)
        && FishEntity.X < (FishermanX + Fisherman.Width - 100)
        Colliding := True

    If ((LobsterX - CameraX) + Lobster.Width) < 0
    {
        Random, Temp1, 1000, 1200
        LobsterX += Temp1
        LobsterShown := True
    }
    If LobsterShown
    {
        s.Push()
         .Translate(LobsterX,500)
         .Rotate(DisplayAngle)
         .Draw(Lobster,Lobster.Width * -0.15,Lobster.Height * -0.15,Lobster.Width * 0.3,Lobster.Height * 0.3)
         .Pop()

        ;check for lobster collision
        Distance := Sqrt(((FishEntity.X - LobsterX) ** 2) + ((FishEntity.Y - 500) ** 2))
        If Distance < 150
        {
            Random, Temp1, 1, 3
            If Temp1 = 1
                Available.Insert(Elephant)
            Else
                Available.Insert(Goat)
            LobsterShown := False
        }
    }

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

    If Colliding
    {
        If CollideTimer > 1
        {
            If CollideTimer > 3
            {
                s.Pop()
                Return, True
            }
        }
        Else
        {
            If CollideTimer = 0
                p.RemoveEntity(FishEntity)
            ElephantW := Elephant.Width * (1 - CollideTimer)
            ElephantH := Elephant.Height * (1 - CollideTimer)
            GoatW := Goat.Width * (1 - CollideTimer)
            GoatH := Goat.Height * (1 - CollideTimer)
            FishW := Fish.Width * (1 - CollideTimer)
            FishH := Fish.Height * (1 - CollideTimer)
        }
        CollideTimer += Duration
    }

    s.Push()
     .Translate(FishEntity.X,FishEntity.Y)
     .Rotate(FishEntity.Angle)

    If (CurrentEvolution = Fish)
    {
        If KeyState("Space") && Available.MaxIndex()
        {
            CurrentEvolution := Available.Remove(1)
            CurrentTimer := 6
        }
    }
    Else
    {
        CurrentTimer -= Duration
        If CurrentTimer <= 0
            CurrentEvolution := Fish
    }

    If (CurrentEvolution = Elephant)
    {
        FishBuoyancy.Volume := 500
        s.Draw(Elephant,ElephantW * -0.3,ElephantH * -0.3,ElephantW * 0.6,ElephantH * 0.6)
        If InWater && Depth < 0 && (A_TickCount - LastOut) > 5000 ;just got out of the water
        {
            PlayAsync(A_ScriptDir . "\Sounds\Elephant.mp3")
            PlayAsync(A_ScriptDir . "\Sounds\Splash.mp3")
            LastOut := A_TickCount
        }
    }
    Else If (CurrentEvolution = Goat)
    {
        FishBuoyancy.Volume := 400
        s.Draw(Goat,GoatW * -0.2,GoatH * -0.2,GoatW * 0.4,GoatH * 0.4)
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
        s.Draw(Fish,FishW * -0.1,FishH * -0.1,FishW * 0.2,FishH * 0.2)
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

    For Index, Evolution In Available
    {
        s.Push()
         .Translate((Index * 75) - 25,500)
         .Rotate(DisplayAngle)
         .Draw(Evolution,-25,-25,50,50)
         .Pop()
    }
    DisplayAngle += Duration * 200
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
        If KeyState("Up")
            this.Entity.Force(X,Y,0,-90)
        If KeyState("Down")
            this.Entity.Force(X,Y,0,90)
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