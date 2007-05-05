
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Satellite Dish"


function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Transmitter = nil
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "Satellite Dish" )
		self.PrevOutput = value
	end
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

