InitializeGame()
{
    global
    Water := new Canvas.Brush(0xAA9999BB)
    DeepWater := new Canvas.Brush(0xAAAA8844)

    Fish := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Salmon.png")
    Elephant := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Elephant.png")
    Goat := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Goat.png")
    Kangaroo := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Kangaroo.png")

    Fisherman1 := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 1.png")
    Fisherman2 := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 2.png")
    Clouds := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Clouds.png")

    FishEntity := new p.Entity(400,400)
    FishEntity.RotationalInertia := 200
    p.AddEntity(FishEntity)
    p.Register(new p.Drag(FishEntity,0.5))
    p.Register(new p.Gravity(FishEntity,120))
    LiquidLevel := 200
    FishBuoyancy := new Buoyancy(FishEntity,120,LiquidLevel,0.8)
    p.Register(FishBuoyancy)
    p.Register(new KeyboardController(FishEntity))
}

StepGame(Duration)
{
    global s, Fish, Elephant, Goat, Kangaroo, Fisherman1, Fisherman2, Clouds
    global DeepWater, Water
    global FishEntity, FishBuoyancy
    global LiquidLevel
    static InWater := True, LastOut := 0

    CameraX := FishEntity.X - 400
    CameraY := FishEntity.Y - 300

    s.Clear(0xFFFFFFFF)
     .FillRectangle(Water,0,LiquidLevel - CameraY,800,600)
     .FillRectangle(DeepWater,0,(LiquidLevel + 600) - CameraY,800,200)
     .Push()
     .Translate(-CameraX,-CameraY)

    s.Draw(Fisherman1,500,20,Fisherman1.Width,Fisherman1.Height)
    s.Draw(Fisherman2,1600,40,Fisherman2.Width,Fisherman2.Height)
    s.Draw(Clouds,200,-200,Clouds.Width,Clouds.Height)
    s.Draw(Clouds,400,-400,Clouds.Width,Clouds.Height)

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
            LastOut := A_TickCount
        }
    }
    Else
    {
        FishBuoyancy.Volume := 120
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
        this.Entity.Transformed(50,0,X,Y)
        If KeyState("Left") || KeyState("A")
            this.Entity.Force(X,Y,-80,0)
        If KeyState("Right") || KeyState("D")
            this.Entity.Force(X,Y,80,0)
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
            If Depth > 600
                this.Entity.Force(this.Entity.X,this.Entity.Y,0,-this.Volume * 2 * this.LiquidDensity)
        }
    }
}