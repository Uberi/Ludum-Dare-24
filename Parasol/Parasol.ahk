class Parasol
{
    __New()
    {
        this.Entities := Object()
        this.Generators := []
    }

    AddEntity(Entity)
    {
        this.Entities[Entity] := True
        Return, this
    }

    RemoveEntity(Entity)
    {
        If !this.Entities.HasKey(Entity)
            throw Exception("INVALID_INPUT",-1,"Entity not found.")
        this.Entities.Remove(Entity)
        Return, this
    }

    Register(Generator)
    {
        this.Generators.Insert(Generator)
        Return, this
    }

    Unregister(Generator)
    {
        For Index, Value In this.Generators
        {
            If (Generator = Value)
            {
                this.Generators.Remove(Index)
                Return, this
            }
        }
        throw Exception("INVALID_INPUT",-1,"Generator not found.")
    }

    Step(Duration)
    {
        For Entity In this.Entities
            Entity.Begin(Duration)

        this.Contacts := []

        ;step generators
        Index := 1, MaxIndex := this.Generators.MaxIndex()
        While, Index <= MaxIndex ;wip: more elegant way to do this
        {
            If this.Generators[Index].Step(Duration,this)
                this.Generators.Remove(Index), MaxIndex --
            Index ++
        }

        this.ResolveContacts(Duration,this.Contacts,this.Contacts.MaxIndex() * 2)

        For Entity In this.Entities
            Entity.End(Duration)

        Return, this
    }

    ResolveContacts(Duration,Contacts,Iterations)
    {
        Loop, %Iterations%
        {
            MaxVelocity := Infinity
            LargestContact := False
            For Index, Contact In Contacts
            {
                ;determine the relative velocity along the contact normal
                VelocityX := Contact.Entity1.VelocityX - Contact.Entity2.VelocityX
                VelocityY := Contact.Entity1.VelocityY - Contact.Entity2.VelocityY
                SeparatingVelocity := (VelocityX * Contact.NormalX) + (VelocityY * Contact.NormalY)

                If (SeparatingVelocity < MaxVelocity)
                {
                    If (SeparatingVelocity < 0 || Contact.Penetration > 0)
                    {
                        MaxVelocity := SeparatingVelocity
                        LargestContact := Contact
                    }
                }
            }

            If !LargestContact ;no contacts to resolve
                Break

            Entity1X := LargestContact.Entity1.X
            Entity1Y := LargestContact.Entity1.Y
            Entity2X := LargestContact.Entity2.X
            Entity2Y := LargestContact.Entity2.Y
            LargestContact.Resolve(Duration)
            Entity1X -= LargestContact.Entity1.X
            Entity1Y -= LargestContact.Entity1.Y
            Entity2X -= LargestContact.Entity2.X
            Entity2Y -= LargestContact.Entity2.Y

            ;update particle interpenetrations
            For Index, Contact In Contacts
            {
                If Contact.Entity1 = LargestContact.Entity1
                    Contact.Penetration += (Entity1X * Contact.NormalX) + (Entity1Y * Contact.NormalY)
                Else If Contact.Entity1 = LargestContact.Entity2
                    Contact.Penetration += (Entity2X * Contact.NormalX) + (Entity2Y * Contact.NormalY)
                If Contact.Entity2 = LargestContact.Entity1
                    Contact.Penetration -= (Entity1X * Contact.NormalX) + (Entity1Y * Contact.NormalY)
                Else If Contact.Entity2 = LargestContact.Entity2
                    Contact.Penetration -= (Entity2X * Contact.NormalX) + (Entity2Y * Contact.NormalY)
            }
        }
    }

    class Contact
    {
        __New(Entity1,Entity2,X,Y,NormalX,NormalY,Penetration,Restitution,Friction)
        {
            this.Entity1 := Entity1
            this.Entity2 := Entity2
            this.NormalX := NormalX
            this.NormalY := NormalY
            this.Penetration := Penetration
            this.Restitution := Restitution
            this.Friction := Friction
        }

        Resolve(Duration)
        {
            this.ResolveVelocity(Duration)
            this.ResolveInterpenetration(Duration)
        }

        ResolveVelocity(Duration)
        {
            ;check if both entities have infinite mass
            If this.Entity1.Mass = Infinity && this.Entity2.Mass = Infinity
                Return

            ;determine the relative velocity along the contact normal
            VelocityX := this.Entity1.VelocityX - this.Entity2.VelocityX
            VelocityY := this.Entity1.VelocityY - this.Entity2.VelocityY
            SeparatingVelocity := (VelocityX * this.NormalX) + (VelocityY * this.NormalY)
            If SeparatingVelocity >= 0 ;entities are separating or stationary relative to each other
                Return

            ;calculate the amount of impulse for each entity
            Impulse := SeparatingVelocity * (1 + this.Restitution)
            TotalMass := this.Entity1.Mass + this.Entity2.Mass
            Impulse1 := Impulse * this.Entity2.Mass / TotalMass
            Impulse2 := Impulse * this.Entity1.Mass / TotalMass

            ;apply impulse
            this.Entity1.Impulse(0,0,Impulse1 * -this.NormalX,Impulse1 * -this.NormalY) ;wip: offsets in world coords
            this.Entity2.Impulse(0,0,Impulse2 * this.NormalX,Impulse2 * this.NormalY) ;wip: offsets in world coords
        }

        ResolveInterpenetration(Duration)
        {
            ;check if objects are interpenetrating
            If this.Penetration <= 0
                Return

            ;check if both entities have infinite mass
            If this.Entity1.Mass = Infinity && this.Entity2.Mass = Infinity
                Return

            ;calculate the amount of displacement for each entity
            TotalMass := this.Entity1.Mass + this.Entity2.Mass
            Displacement1 := this.Penetration * this.Entity2.Mass / TotalMass
            Displacement2 := this.Penetration * this.Entity1.Mass / TotalMass

            ;apply displacement
            this.Entity1.X += Displacement1 * this.NormalX
            this.Entity1.Y += Displacement1 * this.NormalY
            this.Entity2.X -= Displacement2 * this.NormalX
            this.Entity2.Y -= Displacement2 * this.NormalY
        }
    }

    class Force ;wip: transform coords
    {
        __New(Entity,X,Y,ForceX,ForceY)
        {
            this.Entity := Entity
            this.X := X
            this.Y := Y
            this.ForceX := ForceX
            this.ForceY := ForceY
        }

        Step(Duration,Instance)
        {
            this.Entity.Force(this.X,this.Y,this.ForceX,this.ForceY)
        }
    }

    class Motor
    {
        __New(Entity,Value)
        {
            this.Entity := Entity
            this.Value := Value
        }

        Step(Duration,Instance)
        {
            this.Entity.Torque(this.Value)
        }
    }

    class Drag
    {
        __New(Entity,Coefficient)
        {
            this.Entity := Entity
            this.Coefficient := Coefficient
        }

        Step(Duration,Instance)
        {
            this.Entity.Force(this.Entity.X,this.Entity.Y,this.Coefficient * -this.Entity.VelocityX,this.Coefficient * -this.Entity.VelocityY) ;apply linear drag
            this.Entity.Torque(this.Coefficient * -this.Entity.AngularVelocity) ;apply rotational drag
        }
    }

    class Gravity
    {
        __New(Entity,Amount)
        {
            this.Entity := Entity
            this.Amount := Amount
        }

        Step(Duration,Instance)
        {
            If this.Entity.Mass < Infinity
                this.Entity.Force(this.Entity.X,this.Entity.Y,0,this.Entity.Mass * this.Amount)
        }
    }

    class Spring
    {
        __New(Entity1,Entity2,X1,Y1,X2,Y2,Length,Stiffness)
        {
            this.Entity1 := Entity1
            this.Entity2 := Entity2
            this.X1 := X1
            this.Y1 := Y1
            this.X2 := X2
            this.Y2 := Y2
            this.Length := Length
            this.Stiffness := Stiffness
        }

        Step(Duration,Instance)
        {
            this.Entity1.Transformed(this.X1,this.Y1,X1,Y1)
            this.Entity2.Transformed(this.X2,this.Y2,X2,Y2)

            DisplacementX := X2 - X1
            DisplacementY := Y2 - Y1
            Distance := Sqrt((DisplacementX ** 2) + (DisplacementY ** 2))
            StretchForce := (Distance - this.Length) * this.Stiffness
            StretchX := StretchForce * (DisplacementX / Distance)
            StretchY := StretchForce * (DisplacementY / Distance)
            this.Entity1.Force(X1,Y1,StretchX,StretchY)
            this.Entity2.Force(X2,Y2,-StretchX,-StretchY)
        }
    }

    class Bungee
    {
        __New(Entity1,Entity2,X1,Y1,X2,Y2,Length,Stiffness)
        {
            this.Entity1 := Entity1
            this.Entity2 := Entity2
            this.X1 := X1
            this.Y1 := Y1
            this.X2 := X2
            this.Y2 := Y2
            this.Length := Length
            this.Stiffness := Stiffness
        }

        Step(Duration,Instance)
        {
            this.Entity1.Transformed(this.X1,this.Y1,X1,Y1)
            this.Entity2.Transformed(this.X2,this.Y2,X2,Y2)

            DisplacementX := X2 - X1
            DisplacementY := Y2 - Y1
            Distance := Sqrt((DisplacementX ** 2) + (DisplacementY ** 2))
            If (Distance <= this.Length)
                Return
            StretchForce := (Distance - this.Length) * this.Stiffness
            StretchX := StretchForce * (DisplacementX / Distance)
            StretchY := StretchForce * (DisplacementY / Distance)
            this.Entity1.Force(X1,Y1,StretchX,StretchY)
            this.Entity2.Force(X2,Y2,-StretchX,-StretchY)
        }
    }

    class Cable
    {
        __New(Entity1,Entity2,Length,Restitution) ;wip: X and Y attach points for this as well as rod
        {
            this.Entity1 := Entity1
            this.Entity2 := Entity2
            this.Length := Length
            this.Restitution := Restitution
        }

        Step(Duration,Instance)
        {
            DisplacementX := this.Entity2.X - this.Entity1.X
            DisplacementY := this.Entity2.Y - this.Entity1.Y
            Distance := Sqrt((DisplacementX ** 2) + (DisplacementY ** 2))
            Penetration := Distance - this.Length
            If Penetration < 0 ;within cable limit
                Return
            NormalX := DisplacementX / Distance
            NormalY := DisplacementY / Distance
            Instance.Contacts.Insert(new Instance.Contact(this.Entity1,this.Entity2,0,0,NormalX,NormalY,Penetration,this.Restitution,0))
        }
    }

    class Rod
    {
        __New(Entity1,Entity2,Length)
        {
            this.Entity1 := Entity1
            this.Entity2 := Entity2
            this.Length := Length
        }

        Step(Duration,Instance)
        {
            DisplacementX := this.Entity2.X - this.Entity1.X
            DisplacementY := this.Entity2.Y - this.Entity1.Y
            Distance := Sqrt((DisplacementX ** 2) + (DisplacementY ** 2))
            Penetration := Distance - this.Length
            NormalX := DisplacementX / Distance
            NormalY := DisplacementY / Distance
            If Penetration > 0 ;rod is overextended
                Instance.Contacts.Insert(new Instance.Contact(this.Entity1,this.Entity2,0,0,NormalX,NormalY,Penetration,0,0))
            Else If Penetration < 0 ;rod is underextended
                Instance.Contacts.Insert(new Instance.Contact(this.Entity1,this.Entity2,0,0,-NormalX,-NormalY,-Penetration,0,0))
        }
    }

    class Entity
    {
        __New(X,Y,Angle = 0,VelocityX = 0,VelocityY = 0,AngularVelocity = 0)
        {
            this.X := X
            this.Y := Y
            this.Angle := Angle
            this.VelocityX := VelocityX
            this.VelocityY := VelocityY
            this.AngularVelocity := AngularVelocity
            this.ForceX := 0
            this.ForceY := 0
            this.ForceTorque := 0
            this.Mass := 1
            this.RotationalInertia := this.Mass * 0.1
        }

        Begin(Duration)
        {
            this.ForceX := 0
            this.ForceY := 0
            this.ForceTorque := 0
        }

        Impulse(X,Y,ImpulseX,ImpulseY)
        {
            ;apply impulse
            this.VelocityX += ImpulseX
            this.VelocityY += ImpulseY

            ;transform point into local, non-rotated coordinates
            X -= this.X
            Y -= this.Y

            this.AngularVelocity := (X * ImpulseX) - (Y * ImpulseY) ;add angular velocity caused by impulse ;wip: not sure if correct
        }

        Force(X,Y,ForceX,ForceY)
        {
            ;apply force
            this.ForceX += ForceX
            this.ForceY += ForceY

            ;transform point into local, non-rotated coordinates
            X -= this.X
            Y -= this.Y

            this.ForceTorque += (X * ForceY) - (Y * ForceX) ;add torque caused by force
        }

        Torque(Value) ;wip: support adding torque at position and add support for that in motor
        {
            this.ForceTorque += Value
        }

        Transformed(X,Y,ByRef NewX,ByRef NewY)
        {
            static Radians := 3.141592653589793 / 180
            Opposite := Sin(this.Angle * Radians)
            Adjacent := Cos(this.Angle * Radians)
            NewX := this.X + (X * Adjacent) - (Y * Opposite)
            NewY := this.Y + (X * Opposite) + (Y * Adjacent)
        }

        End(Duration)
        {
            ;calculate the new position and rotation
            this.X += this.VelocityX * Duration
            this.Y += this.VelocityY * Duration
            this.Angle += this.AngularVelocity * Duration

            ;calculate acceleration
            AccelerationX := this.ForceX / this.Mass
            AccelerationY := this.ForceY / this.Mass
            AngularAcceleration := this.ForceTorque / this.RotationalInertia

            ;apply acceleration
            this.VelocityX += AccelerationX * Duration
            this.VelocityY += AccelerationY * Duration
            this.AngularVelocity += AngularAcceleration * Duration

            ;determine the instantaneous velocity at a point given the object origin and angular velocity ;wip
            PointX := 0, PointY := 0
            PointVelocityX := (this.AngularVelocity * (PointY - this.Y)) + this.VelocityX
            PointVelocityY := (this.AngularVelocity * (PointX - this.X)) + this.VelocityY
        }
    }

    class Particle extends Parasol.Entity
    {
        __New(X,Y,VelocityX = 0,VelocityY = 0)
        {
            this.X := X
            this.Y := Y
            this.Angle := 0
            this.VelocityX := VelocityX
            this.VelocityY := VelocityY
            this.ForceX := 0
            this.ForceY := 0
            this.Mass := 1
        }

        Begin(Duration)
        {
            this.ForceX := 0
            this.ForceY := 0
        }

        Impulse(X,Y,ImpulseX,ImpulseY)
        {
            this.VelocityX += ImpulseX
            this.VelocityY += ImpulseY
        }

        Force(X,Y,ForceX,ForceY)
        {
            this.ForceX += ForceX
            this.ForceY += ForceY
        }

        Torque(Value)
        {
            
        }

        Transformed(X,Y,ByRef NewX,ByRef NewY)
        {
            NewX := this.X
            NewY := this.Y
        }

        End(Duration)
        {
            ;calculate the new position
            this.X += this.VelocityX * Duration
            this.Y += this.VelocityY * Duration

            ;calculate acceleration
            AccelerationX := this.ForceX / this.Mass
            AccelerationY := this.ForceY / this.Mass

            ;apply acceleration
            this.VelocityX += AccelerationX * Duration
            this.VelocityY += AccelerationY * Duration
        }
    }

    class Box extends Parasol.Entity
    {
        __New(X,Y,W,H,Angle = 0,VelocityX = 0,VelocityY = 0,AngularVelocity = 0)
        {
            base.__New(X,Y,Angle,VelocityX,VelocityY,AngularVelocity)
            this.W := W
            this.H := H
            this.Mass := W * H
            this.RotationalIntertia := (this.Mass * ((this.W ** 2) + (this.H ** 2))) / 12
        }
    }
}