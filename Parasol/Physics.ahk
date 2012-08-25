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
            this.Entity.Force(this.Entity.X,this.Entity.Y,0,-this.Volume * this.LiquidDensity)
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