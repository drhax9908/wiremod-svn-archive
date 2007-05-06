
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Satellite Dish"


function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Transmitter = nil
	self:ShowOutput()
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:ShowOutput()
	self:SetOverlayText( "Satellite Dish" )
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

