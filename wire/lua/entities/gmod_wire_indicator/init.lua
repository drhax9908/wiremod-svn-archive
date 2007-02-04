
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Indicator"

function ENT:Initialize()
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.A = 0
	self.AR = 0
	self.AG = 0
	self.AB = 0
	self.AA = 0
	self.B = 0
	self.BR = 0
	self.BG = 0
	self.BB = 0
	self.BA = 0

	self.Inputs = Wire_CreateInputs(self.Entity, { "A" })
end

function ENT:Setup(a, ar, ag, ab, aa, b, br, bg, bb, ba)
	self.A = a or 0
	self.AR = ar or 255
	self.AG = ag or 0
	self.AB = ab or 0
	self.AA = aa or 255
	self.B = b or 1
	self.BR = br or 0
	self.BG = bg or 255
	self.BB = bb or 0
	self.BA = ba or 255

	local factor = math.max(0, math.min(self.Inputs.A.Value-self.A/(self.B-self.A), 1))
	self:TriggerInput("A", 0)
end

function ENT:TriggerInput(iname, value)
	if (iname == "A") then
		local factor = math.Clamp((value-self.A)/(self.B-self.A), 0, 1)
		self:ShowOutput(factor)

		local r = math.Clamp((self.BR-self.AR)*factor+self.AR, 0, 255)
		local g = math.Clamp((self.BG-self.AG)*factor+self.AG, 0, 255)
		local b = math.Clamp((self.BB-self.AB)*factor+self.AB, 0, 255)
		local a = math.Clamp((self.BA-self.AA)*factor+self.AA, 0, 255)
		self.Entity:SetColor(r, g, b, a)
	end
end

function ENT:ShowOutput(value)
	if (value ~= self.PrevOutput) then
		self:SetOverlayText( "Color = " .. string.format("%.2f", value) )
		self.PrevOutput = value
	end
end
