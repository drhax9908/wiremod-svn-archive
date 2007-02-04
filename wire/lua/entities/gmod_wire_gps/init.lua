AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "GPS"

local MODEL = Model("models/jaanus/wiretool/wiretool_speed.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "X", "Y", "Z" })
end

function ENT:Setup()
	self.Value = 0
	self.PrevOutput = nil

	self:ShowOutput(0, 0, 0)
	Wire_TriggerOutput(self.Entity, "X", 0)
	Wire_TriggerOutput(self.Entity, "Y", 0)
	Wire_TriggerOutput(self.Entity, "Z", 0)
end

function ENT:Think()
	self.BaseClass.Think(self)

    local pos = self.Entity:GetPos()
	Wire_TriggerOutput(self.Entity, "X", pos.x)
	Wire_TriggerOutput(self.Entity, "Y", pos.y)
	Wire_TriggerOutput(self.Entity, "Z", pos.z)
	self:ShowOutput(pos.x, pos.y, pos.z)
	
	self.Entity:NextThink(CurTime()+0.04)
	return true
end

function ENT:ShowOutput(x, y, z)
	self:SetOverlayText( "Position = " .. math.Round(x*1000)/1000 .. "," .. math.Round(y*1000)/1000 .. "," .. math.Round(z*1000)/1000 )
end
