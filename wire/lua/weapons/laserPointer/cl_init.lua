include('shared.lua')
SWEP.PrintName = "Laser Pointer"
SWEP.Slot = 0
SWEP.SlotPos = 4
SWEP.DrawAmmo = false
SWEP.DrawCrosshair = true

function SWEP:ViewModelDrawn()
    local pos = self.Owner:GetShootPos()
    local ang = self.Owner:GetAimVector()
    local tracedata = {}
    tracedata.start = pos
    tracedata.endpos = pos + ang * 100000
    tracedata.filter = self.Owner
    local trace = util.TraceLine(tracedata)
    if(self.pointing) then
        //Draw the laser beam.
        render.SetMaterial(Material("tripmine_laser"))
	    render.DrawBeam(trace.StartPos, trace.HitPos, 6, 0, 10, Color(255,0,0,255))
        //Msg("Laser\n")
    end
end
