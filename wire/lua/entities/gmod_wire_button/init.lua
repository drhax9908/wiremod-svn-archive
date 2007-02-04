AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Button"
ENT.OverlayDelay = 0

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:SetUseType( SIMPLE_USE )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end

function ENT:Use(ply)
	if (not ply:IsPlayer()) then return end
	if (self.PrevUser) and (self.PrevUser:IsValid()) then return end

	if (self.On) then
		if (self.Toggle) then self:Switch(false) end
		
		return
	end

	self:Switch(true)
	self.PrevUser = ply
end

function ENT:Think()
	self.BaseClass.Think(self)

	if (self.On) then
		if (not self.PrevUser) or (not self.PrevUser:IsValid()) or (not self.PrevUser:KeyDown(IN_USE)) then
		    if (not self.Toggle) then
				self:Switch(false)
			end
			
			self.PrevUser = nil
		end

		self.Entity:NextThink(CurTime()+0.05)
		return true
	end
end

function ENT:Setup(toggle, value_off, value_on)
	self.Toggle = toggle
	self.ValueOff = value_off
	self.ValueOn = value_on
	self.Value = value_off
	self.On = false

	self:ShowOutput(self.ValueOff)
	Wire_TriggerOutput(self.Entity, "Out", self.ValueOff)
end

function ENT:Switch(on)
	if (not self.Entity:IsValid()) then return end

	self.On = on

	if (on) then
		self:ShowOutput(self.ValueOn)
		self.Value = self.ValueOn
	else
		self:ShowOutput(self.ValueOff)
		self.Value = self.ValueOff
	end

	Wire_TriggerOutput(self.Entity, "Out", self.Value)

	return true
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "(" .. self.ValueOff .. " - " .. self.ValueOn .. ") = " .. value )
end
