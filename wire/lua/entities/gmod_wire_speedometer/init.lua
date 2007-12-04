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

function ENT:Setup( xyz_mode, AngVel )
	self.XYZMode = xyz_mode
	self.AngVel = AngVel
	self:SetModes( xyz_mode,AngVel )
	
	local outs = {}
	if (xyz_mode) then
		outs = { "X", "Y", "Z" }
	else
		outs = { "Out", "MPH" }
	end
	if (AngVel) then
		table.Add(outs, {"AngVel_P", "AngVel_Y", "AngVel_R" } )
	end
	Wire_AdjustOutputs(self.Entity, outs)
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
	
	if (self.XYZMode) then
		local ang = self.Entity:GetPhysicsObject():GetAngleVelocity()
		Wire_TriggerOutput(self.Entity, "AngVel_P", ang.y)
		Wire_TriggerOutput(self.Entity, "AngVel_Y", ang.z)
		Wire_TriggerOutput(self.Entity, "AngVel_R", ang.x)
	end
	
	self.Entity:NextThink(CurTime()+0.04)
	return true
end
