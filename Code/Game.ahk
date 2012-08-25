InitializeGame()
{
    global
    Water := new Canvas.Brush(0xAA8888AA)
    Fish := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Salmon.png")
    Elephant := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Elephant.png")
    Goat := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Goat.png")
    Fisherman1 := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 1.png")
    Fisherman2 := new Canvas.Surface(0,0,A_ScriptDir . "\Images\Fisherman 2.png")

    FishEntity := new p.Entity(400,400)
    FishEntity.RotationalInertia := 200
    p.AddEntity(FishEntity)
    p.Register(new p.Drag(FishEntity,0.5))
    p.Register(new p.Gravity(FishEntity,100))
    FishBuoyancy := new Buoyancy(FishEntity,120,200,0.8)
    p.Register(FishBuoyancy)
    p.Register(new KeyboardController(FishEntity))
}

StepGame(Duration)
{
    global s, Fish, Elephant, Goat, Fisherman1, Fisherman2
    global Water
    global FishEntity, FishBuoyancy

    CameraX := FishEntity.X - 400
    CameraY := FishEntity.Y - 300

    s.Clear(0xFFFFFFFF)
     .FillRectangle(Water,0,200 - CameraY,800,600)
     .Push()
     .Translate(-CameraX,-CameraY)

    s.Draw(Fisherman1,500,20,Fisherman1.Width,Fisherman1.Height)
    s.Draw(Fisherman2,1600,20,Fisherman2.Width,Fisherman2.Height)

    s.Push()
     .Translate(FishEntity.X,FishEntity.Y)
     .Rotate(FishEntity.Angle)
    If KeyState("a")
    {
        FishBuoyancy.Volume := 400
        s.Draw(Elephant,Elephant.Width * -0.3,Elephant.Height * -0.3,Elephant.Width * 0.6,Elephant.Height * 0.6)
    }
    Else If KeyState("s")
    {
        FishBuoyancy.Volume := 300
        s.Draw(Goat,Goat.Width * -0.2,Goat.Height * -0.2,Goat.Width * 0.4,Goat.Height * 0.4)
    }
    Else
    {
        FishBuoyancy.Volume := 120
        s.Draw(Fish,Fish.Width * -0.15,Fish.Height * -0.15,Fish.Width * 0.3,Fish.Height * 0.3)
    }
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
        If KeyState("Left")
            this.Entity.Force(X,Y,-80,0)
        If KeyState("Right")
            this.Entity.Force(X,Y,80,0)
        If KeyState("Up")
            this.Entity.Force(X,Y,0,-80)
        If KeyState("Down")
            this.Entity.Force(X,Y,0,80)

        ;force fish to stay upright
        Value := Mod(this.Entity.Angle,360)
        If Value < 0
            Value += 360
        If Value < 180
            this.Entity.Torque(Value * -25)
        Else
            this.Entity.Torque((360 - Value) * 25)
    }
}