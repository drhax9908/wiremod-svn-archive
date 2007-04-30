
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Weight"

local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity,{"Weight"})
	self.Outputs = Wire_CreateOutputs(self.Entity,{"Weight"})
end

function ENT:OnRemove()
	Wire_Remove(self.Entity)
end

function ENT:TriggerInput(iname,value)
    if(value>0)then
        self.Entity:GetPhysicsObject():SetMass(value)
        Wire_TriggerOutput(self.Entity,"Weight",value)
        self:ShowOutput(value)
    end
    return true
end

function ENT:Think()
end

function ENT:Setup()
end

function ENT:ShowOutput(value)
	local text = "Weight:"
	text = text..tostring(value)
	self:SetOverlayText( text )
	self.PrevOutput = value
end

function ENT:OnRestore()
    Wire_Restored(self.Entity)
end

