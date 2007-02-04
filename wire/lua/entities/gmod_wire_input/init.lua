
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Input"
ENT.OverlayDelay = 0

local MODEL = Model("models/jaanus/wiretool/wiretool_input.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end

function ENT:Setup(keygroup, toggle, value_off, value_on)
	self.KeyGroup = keygroup
	self.Toggle = (toggle == 1)
	self.ValueOff = value_off
	self.ValueOn = value_on
	self.Value = value_off

	self:ShowOutput(self.ValueOff)
	Wire_TriggerOutput(self.Entity, "Out", self.ValueOff)
end

function ENT:InputActivate( mul )
	if ( self.Toggle ) then
		return self:Switch( !self.On, mul )
	end

	return self:Switch( true, mul )
end

function ENT:InputDeactivate( mul )
	if ( self.Toggle ) then return true end
	
	return self:Switch( false, mul )
end

function ENT:Switch( on, mul )
	if (!self.Entity:IsValid()) then return false end

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

local function On( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputActivate( mul )
end

local function Off( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputDeactivate( mul )
end

numpad.Register( "WireInput_On", On )
numpad.Register( "WireInput_Off", Off )
