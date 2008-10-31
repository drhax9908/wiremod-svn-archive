
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "EMarker"
ENT.OverlayDelay = 0

local MODEL = Model( "models/jaanus/wiretool/wiretool_siren.mdl" )

function ENT:Initialize()
	self.Entity:SetModel( MODEL )	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.Outputs = WireLib.CreateSpecialOutputs(self.Entity, { "Entity" }, { "ENTITY" })
	self:SetOverlayText( "No Mark selected" )
end

function ENT:Setup(mark)
	self.mark = mark
	Wire_TriggerOutput(self.Entity, "Entity", self.mark)
	self:SetOverlayText( "Mark - " .. self.mark:GetClass() )
end
