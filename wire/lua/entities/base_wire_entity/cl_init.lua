
include('shared.lua')


function ENT:Draw()
	//self.BaseClass.BaseClass.Draw(self)
	
	self:DoNormalDraw()
	
    Wire_Render(self.Entity)
end

function ENT:DoNormalDraw()
	
	if ( LocalPlayer():GetEyeTrace().Entity == self.Entity && EyePos():Distance( self.Entity:GetPos() ) < 512 ) then
		
		if ( self.RenderGroup == RENDERGROUP_OPAQUE ) then
			self.OldRenderGroup = self.RenderGroup
			self.RenderGroup = RENDERGROUP_TRANSLUCENT
		end
		
		self:DrawEntityOutline( 1.0 )
		self.Entity:DrawModel()
		
		if ( self:GetOverlayText() != "" ) then
			AddWorldTip( self.Entity:EntIndex(), self:GetOverlayText(), 0.5, self.Entity:GetPos(), self.Entity  )
		end
		
	else
		
		if ( self.OldRenderGroup != nil ) then
			
			self.RenderGroup = self.OldRenderGroup
			self.OldRenderGroup = nil
			
		end
		
		self.Entity:DrawModel()
		
	end
end

function ENT:Think()
	if (CurTime() >= (self.NextRBUpdate or 0)) then
	    self.NextRBUpdate = CurTime()+2
		Wire_UpdateRenderBounds(self.Entity)
	end
end
