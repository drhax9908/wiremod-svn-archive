
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Weight"
ENT.OverlayDelay = 0.1

//local MODEL = Model("models/jaanus/wiretool/wiretool_range.mdl")
local MODEL = Model("models/props_interiors/pot01a.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Inputs = Wire_CreateInputs(self.Entity,{"Weight"})
	self.Outputs = Wire_CreateOutputs(self.Entity,{"Weight"})
	self:ShowOutput(self.Entity:GetPhysicsObject():GetMass())
end

function ENT:TriggerInput(iname,value)
    if(value>0)then
		local phys = self.Entity:GetPhysicsObject()
		if ( phys:IsValid() ) then 
			phys:SetMass(value)
			phys:Wake()
	        self:ShowOutput(value)
	        Wire_TriggerOutput(self.Entity,"Weight",value)
		end
    end
    return true
end

function ENT:Think()
	self.BaseClass.Think(self)
end

function ENT:Setup()
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "Weight: "..tostring(value) )
end

