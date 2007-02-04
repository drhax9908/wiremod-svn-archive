AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

ENT.WireDebugName = "Screen"

function ENT:Initialize()
	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Inputs = Wire_CreateInputs(self.Entity, { "A", "B" })
end

function ENT:Use()
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		self:SetDisplayA( string.format("%.2f", value) )
	elseif (iname == "B") then
		self:SetDisplayB( string.format("%.2f", value) )
	end
end
