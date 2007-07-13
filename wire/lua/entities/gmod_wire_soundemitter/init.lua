
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Sound"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self:SetOn( false )

	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
end

function ENT:OnRemove()
	-- Immediately stops annoying saunds, when getting removed
	self:StopSounds(self.sound);
end

function ENT:Think()
	self.BaseClass.Think(self)

	self:Switch(self.Inputs.A.Value > 0, self.Inputs.A.Value)
end

function ENT:Switch( on, mul )
	if (!self.Entity:IsValid()) then return false end
	
	local vol = math.max(0, math.min((mul or 0), 2))

	if (self:IsOn() == on) then return end
	self:SetOn( on )

	if (on) then 
		self:SetOverlayText( "Sound: " .. self.sound .. "\nVolume: " .. string.format("%.2f", vol) )
		
		self:StartSounds( self.sound, 100*vol )
	else
		self:SetOverlayText( "Sound: " .. self.sound .. "\nVolume: Off" )

		self:StopSounds( self.sound )
	end

	return true
end

function ENT:SetSound(sound)
	if (sound) then
		self:StopSounds(self.sound);
		self.sound = (sound or ""):gsub("[/\\]+","/");
	end
end

function ENT:OnRestore()
	self:Switch(self.Inputs.A.Value > 0, self.Inputs.A.Value)

    self.BaseClass.OnRestore(self)
end
