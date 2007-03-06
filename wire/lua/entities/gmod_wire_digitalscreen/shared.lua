ENT.Type 			= "anim"
ENT.Base 			= "base_wire_entity"

ENT.PrintName		= ""
ENT.Author			= ""
ENT.Contact			= ""
ENT.Purpose			= ""
ENT.Instructions	= ""

ENT.Spawnable			= false
ENT.AdminSpawnable		= false

function ENT:SetDisplayPixelX( float )
	self.Entity:SetNetworkedFloat( "DisX", float )
	self:SetDisplayClk(self.Entity:GetNetworkedFloat( "DisClk" ))
	self:SetDisplayRowClk(self.Entity:GetNetworkedFloat( "DisRowClk" ))
	self:SetDisplayColClk(self.Entity:GetNetworkedFloat( "DisColClk" ))
	self:SetDisplayFullClk(self.Entity:GetNetworkedFloat( "DisFullClk" ))
end

function ENT:SetDisplayPixelY( float )
	self.Entity:SetNetworkedFloat( "DisY", float )
	self:SetDisplayClk(self.Entity:GetNetworkedFloat( "DisClk" ))
	self:SetDisplayRowClk(self.Entity:GetNetworkedFloat( "DisRowClk" ))
	self:SetDisplayColClk(self.Entity:GetNetworkedFloat( "DisColClk" ))
	self:SetDisplayFullClk(self.Entity:GetNetworkedFloat( "DisFullClk" ))
end

function ENT:SetDisplayPixelG( float )
	self.Entity:SetNetworkedFloat( "DisG", float )
	self:SetDisplayClk(self.Entity:GetNetworkedFloat( "DisClk" ))	
	self:SetDisplayRowClk(self.Entity:GetNetworkedFloat( "DisRowClk" ))
	self:SetDisplayColClk(self.Entity:GetNetworkedFloat( "DisColClk" ))
	self:SetDisplayFullClk(self.Entity:GetNetworkedFloat( "DisFullClk" ))
end

function ENT:SetDisplayClk( float )
	if ( float >= 1.0 ) then
		local x = math.floor(self:GetDisplayPixelX())
		local y = math.floor(self:GetDisplayPixelY())
		local a = x + y*32
		if (x >= 0) and (x < 32) and (y >= 0) and (y < 32) then
			self.Entity:SetNetworkedFloat("DispData"..a, self:GetDisplayPixelG())
		end
	end
	self.Entity:SetNetworkedFloat("DisClk", float)
end

function ENT:SetDisplayRowClk( float )
	if ( float >= 1.0 ) then
		local y = math.floor(self:GetDisplayPixelY())
		if (y >= 0) and (y < 32) then
			for x = 0,31 do
				a = x + y*32
				self.Entity:SetNetworkedFloat("DispData"..a, self:GetDisplayPixelG())
			end
		end
	end
	self.Entity:SetNetworkedFloat("DisRowClk", float)
end

function ENT:SetDisplayColClk( float )
	if ( float >= 1.0 ) then
		local x = math.floor(self:GetDisplayPixelX())
		if (x >= 0) and (x < 32) then
			for y = 0,31 do
				a = x + y*32
				self.Entity:SetNetworkedFloat("DispData"..a, self:GetDisplayPixelG())
			end
		end
	end
	self.Entity:SetNetworkedFloat("DisColClk", float)
end

function ENT:SetDisplayFullClk( float )
	if ( float >= 1.0 ) then
		for y = 0,31 do
			for x = 0,31 do
				a = x + y*32
				self.Entity:SetNetworkedFloat("DispData"..a, self:GetDisplayPixelG())
			end
		end
	end
	self.Entity:SetNetworkedFloat("DisFullClk", float)
end

function ENT:GetDisplayPixelX( )
	return self.Entity:GetNetworkedFloat( "DisX" )
end

function ENT:GetDisplayPixelY( )
	return self.Entity:GetNetworkedFloat( "DisY" )
end

function ENT:GetDisplayPixelG( )
	return self.Entity:GetNetworkedFloat( "DisG" )
end

function ENT:GetDisplayClk( )
	return self.Entity:GetNetworkedFloat( "DisClk" )
end