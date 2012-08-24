#Warn All
#Warn LocalSameAsGlobal, Off

Box1 := new Box(200,200,60,80,45)
Box2 := new Box(250,250,30,60,45)

s := new Canvas.Surface(400,400)
s.Smooth := "Good"

Gui, +LastFound ;wip: use Canvas.Viewport
hWindow := WinExist()
hDC := DllCall("GetDC","UPtr",hWindow,"UPtr")

Gui, Show, w400 h400, Physics Test

DllCall("ShowCursor","UInt",0)

CoordMode, Mouse, Client
Loop
{
    MouseGetPos, X, Y
    Box2.X := X
    Box2.Y := Y

    Draw(Box1,Box2,s)
    Sleep, 50
}
Return

GuiClose:
ExitApp

#Include Canvas-AHK\
#Include Canvas.ahk

Left::Box1.Angle -= 5
Right::Box1.Angle += 5

Up::Box2.Angle += 5
Down::Box2.Angle -= 5

Draw(Entity1,Entity2,Surface)
{
    global hDC

    static Box := new Canvas.Pen(0xFFFFFFFF,2)
    static Mark := new Canvas.Pen(0xFFFF0000,2)

    Surface.Clear()

    If Intersects(Entity1,Entity2,Surface)
        b := Mark
    Else
        b := Box

    Surface.Push()
           .Translate(Entity1.X,Entity1.Y)
           .Rotate(Entity1.Angle)
           .DrawRectangle(b,Entity1.W * -0.5,Entity1.H * -0.5,Entity1.W,Entity1.H)
           .Pop()
    Surface.Push()
           .Translate(Entity2.X,Entity2.Y)
           .Rotate(Entity2.Angle)
           .DrawRectangle(b,Entity2.W * -0.5,Entity2.H * -0.5,Entity2.W,Entity2.H)
           .Pop()

    DllCall("BitBlt","UPtr",hDC,"Int",0,"Int",0,"Int",Surface.Width,"Int",Surface.Height,"UPtr",Surface.hMemoryDC,"Int",0,"Int",0,"UInt",0xCC0020) ;SRCCOPY
}

CheckPoint(Entity1,Entity2,OffsetX,OffsetY,PointX,PointY,Extent1X,Extent1Y,Extent2X,Extent2Y,s)
{
    static b := new Canvas.Pen(0xFF00FF00,4) ;wip: debug

    Rotate(PointX,PointY,Entity2.Angle - Entity1.Angle,X,Y)
    X += OffsetX, Y += OffsetY
    If (X > -Extent1X && X < Extent1X && Y > -Extent1Y && Y < Extent1Y) ;point inside second entity
    {
        PenetrationX := Extent1X - OffsetX
        PenetrationY := Extent1Y - OffsetY

        ValueX := 1
        ValueY := 1
        If OffsetX < 0
        {
            PenetrationX := Entity1.W - PenetrationX
            ValueX := -1
        }
        If OffsetY < 0
        {
            PenetrationY := Entity1.H - PenetrationY
            ValueY := -1
        }
        PenetrationX += Abs(X - OffsetX)
        PenetrationY += Abs(Y - OffsetY)
        ValueX *= PenetrationX
        ValueY *= PenetrationY
        If (PenetrationX < PenetrationY)
            Rotate(ValueX,0,Entity1.Angle,NewX,NewY)
        Else
            Rotate(0,ValueY,Entity1.Angle,NewX,NewY)

        Rotate(PointX,PointY,Entity2.Angle,PointX,PointY)
        PointX += Entity2.X, PointY += Entity2.Y
        NewX += PointX, NewY += PointY

        s.Line(b,PointX,PointY,NewX,NewY)
        Return, True
    }
    Return, False
}

Intersects(Entity1,Entity2,s)
{
    Extent1X := Entity1.W / 2
    Extent1Y := Entity1.H / 2

    Extent2X := Entity2.W / 2
    Extent2Y := Entity2.H / 2

    Collided := False

    Rotate(Entity2.X - Entity1.X,Entity2.Y - Entity1.Y,-Entity1.Angle,OffsetX,OffsetY)
    Collided |= CheckPoint(Entity1,Entity2,OffsetX,OffsetY,-Extent2X,-Extent2Y,Extent1X,Extent1Y,Extent2X,Extent2Y,s)
    Collided |= CheckPoint(Entity1,Entity2,OffsetX,OffsetY,-Extent2X,Extent2Y,Extent1X,Extent1Y,Extent2X,Extent2Y,s)
    Collided |= CheckPoint(Entity1,Entity2,OffsetX,OffsetY,Extent2X,-Extent2Y,Extent1X,Extent1Y,Extent2X,Extent2Y,s)
    Collided |= CheckPoint(Entity1,Entity2,OffsetX,OffsetY,Extent2X,Extent2Y,Extent1X,Extent1Y,Extent2X,Extent2Y,s)

    Rotate(Entity1.X - Entity2.X,Entity1.Y - Entity2.Y,-Entity2.Angle,OffsetX,OffsetY)
    Collided |= CheckPoint(Entity2,Entity1,OffsetX,OffsetY,-Extent1X,-Extent1Y,Extent2X,Extent2Y,Extent1X,Extent1Y,s)
    Collided |= CheckPoint(Entity2,Entity1,OffsetX,OffsetY,-Extent1X,Extent1Y,Extent2X,Extent2Y,Extent1X,Extent1Y,s)
    Collided |= CheckPoint(Entity2,Entity1,OffsetX,OffsetY,Extent1X,-Extent1Y,Extent2X,Extent2Y,Extent1X,Extent1Y,s)
    Collided |= CheckPoint(Entity2,Entity1,OffsetX,OffsetY,Extent1X,Extent1Y,Extent2X,Extent2Y,Extent1X,Extent1Y,s)

    Return, Collided
}

Intersects1(Entity1,Entity2,Surface)
{
    static Radians := 3.141592653589793 / 180

    ;obtain rotated points of first entity
    Angle := Entity1.Angle - Entity2.Angle
    Rotate(Entity1.W / 2,Entity1.H / 2,Angle,X1,Y1)
    Rotate(Entity1.W / -2,Entity1.H / 2,Angle,X2,Y2)

    ;ensure minimums and maximums are correct
    If (Sin(Angle * Radians) * Cos(Angle * Radians)) < 0
    {
        Temp1 := X1, X1 := X2, X2 := Temp1
        Temp1 := Y1, Y1 := Y2, Y2 := Temp1
    }
    If Sin(Angle * Radians) < 0
    {
        X2 := -X2
        Y2 := -Y2
    }

    ;obtain axis aligned second entity coordinates
    Rotate(Entity2.X - Entity1.X,Entity2.Y - Entity1.X,-Entity2.Angle,CenterX,CenterY)

    ;obtain points of transformed second entity
    Corner1X := CenterX - (Entity2.W / 2)
    Corner1Y := CenterY - (Entity2.H / 2)
    Corner2X := CenterX + (Entity2.W / 2)
    Corner2Y := CenterY + (Entity2.H / 2)

    ;horizontal bounds check
    If (X2 > Corner2X || X2 > -Corner1X)
        Return, False

    ;find vertical minimum and maximum in horizontal range
    Bound := Corner1X - X1
    Value := Corner2X - X1
    Extent1 := Y1
    If (Bound * Value) > 0 ;first vertical minimum or maximum not in horizontal range
    {
        ;find second vertical minimum or maximum
        If Bound < 0
        {
            DisplacementX := X1 - X2
            Extent1 -= Y2
            Bound := Value
        }
        Else
        {
            DisplacementX := X1 + X2
            Extent1 += Y2
        }
        Extent1 := ((Extent1 * Bound) / DisplacementX) + Y1
    }

    Bound := Corner1X + X1
    Value := Corner2X + X1
    Extent2 := -Y1
    If (Bound * Value) > 0 ;second vertical minimum or maximum not in horizontal range
    {
        ;find the third vertical minimum or maximum
        If Bound < 0
        {
            DisplacementX := -X2 - X1
            Extent2 -= Y2
            Bound := Value
        }
        Else
        {
            DisplacementX := X2 - X1
            Extent2 += Y2
        }
        Extent2 := ((Extent2 * Bound) / DisplacementX) - Y1
    }

    If (Extent1 < Corner1Y && Extent2 < Corner1Y)
        Return, False
    If (Extent1 > Corner2Y && Extent2 > Corner2Y)
        Return, False

    Return, True
}

Rotate(X,Y,Angle,ByRef NewX,ByRef NewY)
{
    static Radians := 3.141592653589793 / 180

    Opposite := Sin(Angle * Radians)
    Adjacent := Cos(Angle * Radians)

    NewX := (X * Adjacent) - (Y * Opposite)
    NewY := (X * Opposite) + (Y * Adjacent)
}

class Box
{
    __New(X,Y,W,H,Angle = 0)
    {
        this.X := X
        this.Y := Y
        this.W := W
        this.H := H
        this.Angle := Angle
    }
}