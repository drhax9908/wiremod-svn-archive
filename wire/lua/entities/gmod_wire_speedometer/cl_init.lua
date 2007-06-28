
ENT.Spawnable			= false
ENT.AdminSpawnable		= false

include('shared.lua')

--handle overlay text client side instead (TAD2020)
function ENT:Think()
	self.BaseClass.Think(self)

	if (self:GetXYZMode()) then
	    local vel = self.Entity:WorldToLocal(self.Entity:GetVelocity()+self.Entity:GetPos())
		self:ShowOutput(-vel.y, vel.x, vel.z)
	else
	    local vel = self.Entity:GetVelocity():Length()
		self:ShowOutput(vel)
	end
	
	self.Entity:NextThink(CurTime()+0.04)
	return true
end

function ENT:ShowOutput(x, y, z)
	local txt
	if (self:GetXYZMode()) then
		txt =  "Velocity = " .. math.Round((x or 0)*1000)/1000 .. "," .. math.Round((y or 0)*1000)/1000 .. "," .. math.Round((z or 0)*1000)/1000
	else
		txt =  "Speed = " .. math.Round((x or 0)*1000)/1000
	end
	self.Entity:SetNetworkedBeamString( "GModOverlayText", txt )
	//self.Entity:SetNetworkedString( "GModOverlayText", txt )
	//self.BaseClass.BaseClass.SetOverlayText( self, txt )
end
