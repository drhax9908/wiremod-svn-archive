
include('shared.lua')


function ENT:Draw()
	self.BaseClass.BaseClass.Draw(self)

    Wire_Render(self.Entity)
end


function ENT:Think()
	if (CurTime() >= (self.NextRBUpdate or 0)) then
	    self.NextRBUpdate = CurTime()+2
		Wire_UpdateRenderBounds(self.Entity)
	end
end
