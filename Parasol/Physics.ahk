#NoEnv

;wip: see if angular velocity calculations are right (using degrees/s instead of rads/s?)
;wip: add support for arbitrary polygons and calculate area/centroid with http://paulbourke.net/geometry/polyarea/, moment of inertia with http://math.stackexchange.com/questions/59470/calculating-moment-of-inertia-in-2d-planar-polygon or http://www.gamedev.net/topic/342822-moment-of-inertia-of-a-polygon-2d/

#Warn All
#Warn LocalSameAsGlobal, Off

SetBatchLines, -1

global Infinity := 0xFFFFFFFFFFFFFFF

DurationLimit := 1 / 60

s := new Canvas.Surface(200,200)
s.Smooth := "Good"

Gui, +LastFound ;wip: use Canvas.Viewport
hWindow := WinExist()
hDC := DllCall("GetDC","UPtr",hWindow,"UPtr")

Gui, Show, w200 h200, Physics Test

TickFrequency := 0, Ticks1 := 0, Ticks := 0
If !DllCall("QueryPerformanceFrequency","Int64*",TickFrequency) ;obtain ticks per second
    throw Exception("Could not obtain performance counter frequency.")
If !DllCall("QueryPerformanceCounter","Int64*",Ticks1) ;obtain the performance counter value
    throw Exception("Could not obtain performance counter value.")

p := new Parasol

;/*
Particles := [new p.Particle(2.5,2.5)
             ,new p.Particle(7.5,7.5)
             ,new p.Particle(2.5,5)
             ,new p.Particle(7.5,5)
             ,new p.Particle(6,1)]
For Index, Particle In Particles
{
    p.AddEntity(Particle)
    p.Register(new p.Gravity(Particle,5))
    p.Register(new p.Drag(Particle,0.9))
    ;p.Register(new Buoyancy(Particle,6,4,5))
    p.Register(new Ground(Particle,7.5,0.1))
}

p.Register(new p.Rod(Particles[1],Particles[4],2))
p.Register(new p.Cable(Particles[1],Particles[2],3,0.5))
p.Register(new p.Rod(Particles[3],Particles[4],2.5))
p.Register(new p.Rod(Particles[1],Particles[3],2.5))
p.Register(new p.Rod(Particles[1],Particles[5],2.5))
p.Register(new p.Rod(Particles[2],Particles[5],2.5))
p.Register(new p.Spring(Particles[2],Particles[4],0,0,0,0,3,10))
*/

/*
;Anchor := new p.Particle(6,1)
;Anchor.Mass := Infinity
;p.AddEntity(Anchor)
Block1 := new p.Box(2,2.5,3,2,0)
Block1.Mass := 6
p.AddEntity(Block1)
p.Register(new p.Gravity(Block1,5))
p.Register(new p.Drag(Block1,0.3))
;p.Register(new p.Motor(Block1,90))
;p.Register(new p.Bungee(Block1,Anchor,1.5,0,0,0,1,15))

Block2 := new p.Box(4,6,3,2,65)
Block2.Mass := Infinity
Block2.RotationalInertia := Infinity
p.AddEntity(Block2)

p.Register(new Collision)
*/

Loop
{
    If !DllCall("QueryPerformanceCounter","Int64*",Ticks) ;obtain the performance counter value
        throw Exception("Could not obtain performance counter value.")
    Duration := (Ticks - Ticks1) / TickFrequency, Ticks1 := Ticks
    If Duration < 0
        Duration := 0
    If (Duration > DurationLimit)
        Duration := DurationLimit

    p.Step(Duration)

    Draw(p,s)
    Sleep, 10
}
Return

GuiClose:
ExitApp

#Include ..\Canvas-AHK\
#Include Canvas.ahk

Draw(Parasol,Surface)
{
    global hDC
    static ScaleX := 200 / 10
    static ScaleY := 200 / 10

    static Cable := new Canvas.Pen(0xFFFF00FF,3)
    static Rod := new Canvas.Pen(0xFF00FFFF,3)
    static Spring := new Canvas.Pen(0xBB00FF00,3)
    static Bungee := new Canvas.Pen(0xBB0000FF,3)
    static Buoyancy := new Canvas.Pen(0xBBFFFF00,3)
    static Ground := new Canvas.Pen(0xBB00FF00,3)
    static Box := new Canvas.Pen(0xFFFFFFFF,5)
    static Particle := new Canvas.Brush(0xFFFF0000)

    Surface.Clear()
    Radians := 3.141592653589793 / 180
    For Index, g In Parasol.Generators
    {
        If g.__Class = "Parasol.Cable"
            Surface.Line(Cable,g.Entity1.X * ScaleX,g.Entity1.Y * ScaleY,g.Entity2.X * ScaleX,g.Entity2.Y * ScaleY)
        Else If g.__Class = "Parasol.Rod"
            Surface.Line(Rod,g.Entity1.X * ScaleX,g.Entity1.Y * ScaleY,g.Entity2.X * ScaleX,g.Entity2.Y * ScaleY)
        Else If g.__Class = "Buoyancy"
            Surface.Line(Buoyancy,0,g.LiquidLevel * ScaleY,10 * ScaleX,g.LiquidLevel * ScaleY)
        Else If g.__Class = "Ground"
            Surface.Line(Ground,0,g.Level * ScaleY,10 * ScaleX,g.Level * ScaleY)
        Else If g.__Class = "Parasol.Spring"
        {
            g.Entity1.Transformed(g.X1,g.Y1,X1,Y1)
            g.Entity2.Transformed(g.X2,g.Y2,X2,Y2)
            Surface.Line(Spring,X1 * ScaleX,Y1 * ScaleY,X2 * ScaleX,Y2 * ScaleY)
        }
        Else If g.__Class = "Parasol.Bungee"
        {
            g.Entity1.Transformed(g.X1,g.Y1,X1,Y1)
            g.Entity2.Transformed(g.X2,g.Y2,X2,Y2)
            Surface.Line(Bungee,X1 * ScaleX,Y1 * ScaleY,X2 * ScaleX,Y2 * ScaleY)
        }
    }
    For Entity In Parasol.Entities
    {
        If Entity.__Class = "Box"
            Surface.Push()
                   .Translate(Entity.X * ScaleX,Entity.Y * ScaleY)
                   .Rotate(Entity.Angle)
                   .DrawRectangle(Box,Entity.W * -0.5 * ScaleX,Entity.H * -0.5 * ScaleY,Entity.W * ScaleX,Entity.H * ScaleY)
                   .Pop()
        Else
            Surface.FillEllipse(Particle,(Entity.X * ScaleX) - 5,(Entity.Y * ScaleY) - 5,10,10)
    }
    DllCall("BitBlt","UPtr",hDC,"Int",0,"Int",0,"Int",Surface.Width,"Int",Surface.Height,"UPtr",Surface.hMemoryDC,"Int",0,"Int",0,"UInt",0xCC0020) ;SRCCOPY
}

class Collision
{
    __New()
    {
        
    }

    Step(Duration,Instance)
    {
        Candidates := []

        ;broadphase collision ;wip: this just returns all possible contact pairs, is terribly inefficient
        For Entity1 In Instance.Entities
        {
            For Entity2 In Instance.Entities
            {
                If (&Entity1 < &Entity2) ;wip: this isn't guaranteed to always get the right pairs
                    Candidates.Insert([Entity1, Entity2])
            }
        }

        ;narrowphase collision
        For Index, Candidate In Candidates
        {
            Entity1 := Candidate[1]
            Entity2 := Candidate[2]

            ;detect box-box collision
            If Entity1.__Class = "Box" && Entity2.__Class = "Box" ;wip
            {
                If this.CollideBoxBox(Entity1,Entity2)
                    MsgBox
            }
        }
    }

    CollideBoxBox(Entity1,Entity2)
    {
        ;obtain transform relative to the local space of the first entity
        CenterX := Entity2.X - Entity1.X
        CenterY := Entity2.Y - Entity1.X
        Angle := Entity1.Angle - Entity2.Angle

        ;obtain rotated coordinates of second entity as axis aligned rectangle
        this.Rotate(Entity2.X,Entity2.Y,Angle,CenterX,CenterY)

        ;obtain rotated points of first entity
        this.Rotate(Entity1.W / 2,Entity1.H / 2,Angle,X1,Y1)
        this.Rotate(Entity1.W / -2,Entity1.H / 2,Angle,X2,Y2)

        ;ensure minimums and maximums are correct
        If (Sin(Angle) * Cos(Angle)) < 0
        {
            Temp1 := X1, X1 := X2, X2 := Temp1
            Temp1 := Y1, Y1 := Y2, Y2 := Temp1
        }
        If Sin(Angle) < 0
        {
            X2 := -X2
            Y2 := -Y2
        }

        ;obtain points of transformed second entity
        Corner1X := CenterX - (Entity2.W / 2)
        Corner1Y := CenterY - (Entity2.H / 2)
        Corner2X := CenterX + (Entity2.W / 2)
        Corner2Y := CenterY + (Entity2.H / 2)

        ;ensure rectangles are within horizontal range
        If (X2 > Corner2X || X2 > -Corner1X)
            Return, 0

        ;find vertical minimum and maximum in horizontal range
        X := Corner1X - X1
        A := Corner2X - X1
        Extent1 := Y1
        If (X * A) > 0 ;first vertical minimum or maximum not in horizontal range
        {
            dx := Corner1X
            If X < 0
            {
                dx -= Corner2X
                Extent1 -= Corner2Y
                X := A
            }
            Else
            {
                dx += Corner2X
                Extent1 += Corner2Y
            }
            Extent1 := ((Extent1 * X) / dx) + Corner1Y
        }

        X := Corner1X + X1
        A := Corner2X + X1
        Extent2 := -Y1
        If (X * A) > 0 ;second vertical minimum or maximum not in horizontal range
        {
            dx := -Corner1X
            If X < 0
            {
                dx -= Corner2X
                Extent2 -= Corner2Y
                X := A
            }
            Else
            {
                dx += Corner2X
                Extent2 += Corner2Y
            }
            Extent2 := ((Extent2 * X) / dx) - Corner1Y
        }

        Return, !((Extent1 < Corner1Y && Extent2 < Corner1Y) || (Extent1 > Corner2Y && Extent2 > Corner2Y))
    }

    Rotate(X,Y,Angle,ByRef NewX,ByRef NewY)
    {
        static Radians := 3.141592653589793 / 180

        Opposite := Sin(Angle * Radians)
        Adjacent := Cos(Angle * Radians)

        NewX := (X * Adjacent) - (Y * Opposite)
        NewY := (X * Opposite) + (Y * Adjacent)
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

    Step(Duration,Instance) ;wip: doesn't work with rigid bodies (see page 244 for other implementation or src/fgen.cpp), for box add bouyancy check at each of four points
    {
        Depth := this.Entity.Y - this.LiquidLevel
        If Depth < -5 ;outside of the liquid
            Return
        If Depth > 5 ;fully submerged ;wip
            this.Entity.Force(this.Entity.X,this.Entity.Y,0,-this.Volume * this.LiquidDensity)
        Else
            this.Entity.Force(this.Entity.X,this.Entity.Y,0,-this.Volume * this.LiquidDensity * ((Depth + 5) / 10))
    }
}

class Ground
{
    __New(Entity,Level,Restitution)
    {
        this.Entity := Entity
        this.Level := Level
        this.Restitution := Restitution
        this.GroundEntity := new Parasol.Particle(0,0)
        this.GroundEntity.Mass := Infinity
        global p ;wip: hack
        p.AddEntity(this.GroundEntity)
    }

    Step(Duration,Instance)
    {
        Penetration := this.Entity.Y - this.Level
        If Penetration < 0 ;not touching ground
            Return
        Instance.Contacts.Insert(new Instance.Contact(this.Entity,this.GroundEntity,0,0,0,-1,Penetration,this.Restitution,0.2))
    }
}

#Include %A_ScriptDir%\Parasol.ahk