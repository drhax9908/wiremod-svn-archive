AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Speedo"

local MODEL = Model("models/jaanus/wiretool/wiretool_speed.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out", "MPH" })
end

function ENT:Setup(xyz_mode)
	self.XYZMode = xyz_mode
	self:SetXYZMode( xyz_mode )

	if (xyz_mode) then
		Wire_AdjustOutputs(self.Entity, { "X", "Y", "Z" })
		Wire_TriggerOutput(self.Entity, "X", 0)
		Wire_TriggerOutput(self.Entity, "Y", 0)
		Wire_TriggerOutput(self.Entity, "Z", 0)
	else
		Wire_AdjustOutputs(self.Entity, { "Out", "MPH" })
		Wire_TriggerOutput(self.Entity, "Out", 0)
		Wire_TriggerOutput(self.Entity, "MPH", 0)
	end
end

function ENT:Think()
	self.BaseClass.Think(self)

	if (self.XYZMode) then
	    local vel = self.Entity:WorldToLocal(self.Entity:GetVelocity()+self.Entity:GetPos())
		Wire_TriggerOutput(self.Entity, "X", -vel.y)
		Wire_TriggerOutput(self.Entity, "Y", vel.x)
		Wire_TriggerOutput(self.Entity, "Z", vel.z)
	else
	    local vel = self.Entity:GetVelocity():Length()
		Wire_TriggerOutput(self.Entity, "Out", vel)
		Wire_TriggerOutput(self.Entity, "MPH", vel / 17) --what is it for KPH?
	end
	
	self.Entity:NextThink(CurTime()+0.04)
	return true
end
