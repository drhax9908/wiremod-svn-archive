include("shared.lua")

ENT.RenderGroup 		= RENDERGROUP_BOTH

function ENT:Draw()
	self:DoNormalDraw()
    Wire_Render(self.Entity)
end

function ENT:DoNormalDraw()
	local e = self.Entity;
	if (LocalPlayer():GetEyeTrace().Entity == e and EyePos():Distance(e:GetPos()) < 512) then
		if ( self.RenderGroup == RENDERGROUP_OPAQUE) then
			self.OldRenderGroup = self.RenderGroup
			self.RenderGroup = RENDERGROUP_TRANSLUCENT
		end
		self:DrawEntityOutline(1.0)
		self.Entity:DrawModel()
		if(self:GetOverlayText() ~= "") then
			AddWorldTip(e:EntIndex(),self:GetOverlayText(),0.5,e:GetPos(),e)
		end
	else
		if(self.OldRenderGroup) then
			self.RenderGroup = self.OldRenderGroup
			self.OldRenderGroup = nil
		end
		e:DrawModel()
	end
end

function ENT:Think()
	if (CurTime() >= (self.NextRBUpdate or 0)) then
	    self.NextRBUpdate = CurTime()+2
		Wire_UpdateRenderBounds(self.Entity)
	end
end
