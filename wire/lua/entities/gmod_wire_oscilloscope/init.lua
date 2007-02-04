AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Oscilloscope"

function ENT:Initialize()
	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "X", "Y" })
end

function ENT:Think()
	self.BaseClass.Think(self)

	local x = math.max(-1, math.min(self.Inputs.X.Value or 0, 1))
	local y = math.max(-1, math.min(self.Inputs.Y.Value or 0, 1))
	self:SetNextNode(x, y)

	self.Entity:NextThink(CurTime()+0.08)
	return true
end
