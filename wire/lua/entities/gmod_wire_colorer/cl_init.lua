
include('shared.lua')

ENT.RenderGroup 		= RENDERGROUP_BOTH


function ENT:Draw()
	self.BaseClass.Draw(self)
	local vStart = self.Entity:GetPos()
	local vForward = self.Entity:GetUp()
	
    local trace = {}
	   trace.start = vStart
	   trace.endpos = vStart + (vForward * self:GetBeamRange())
	   trace.filter = { self.Entity }
	local trace = util.TraceLine( trace ) 
	
	local endpos
	if(trace.Hit)then
	   endpos = trace.HitPos
	else
	   endpos = vStart + (vForward * self:GetBeamRange())
	end
	render.SetMaterial(Material("tripmine_laser"))
	render.DrawBeam(vStart, endpos, 6, 0, 10, Color(self.Entity:GetColor()))
    Wire_Render(self.Entity)
end
