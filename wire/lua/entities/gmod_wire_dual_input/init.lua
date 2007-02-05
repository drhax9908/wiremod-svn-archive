
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "DualInput"
ENT.OverlayDelay = 0

local MODEL = Model("models/jaanus/wiretool/wiretool_input.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end

function ENT:Setup(keygroup, keygroup2, toggle, value_off, value_on, value_on2)
	self.KeyGroup = keygroup
	self.KeyGroup2 = keygroup2
	self.Toggle = (toggle == 1)
	self.ValueOff = value_off
	self.ValueOn = value_on
	self.ValueOn2 = value_on2
	self.Value = value_off
	self.Select = 0
	
	self:ShowOutput(self.ValueOff)
	Wire_TriggerOutput(self.Entity, "Out", self.ValueOff)
end

function ENT:InputActivate( mul )
	if ( self.Toggle && self.Select == mul ) then
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
	self.Select = mul

	if (on && mul == 1) then
		self:ShowOutput(self.ValueOn)
		self.Value = self.ValueOn
	elseif (on && mul == -1) then
		self:ShowOutput(self.ValueOn2)
		self.Value = self.ValueOn2
	else
		self:ShowOutput(self.ValueOff)
		self.Value = self.ValueOff
	end

	Wire_TriggerOutput(self.Entity, "Out", self.Value)

	return true
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "(" .. self.ValueOn2 .. " - " .. self.ValueOff .. " - " .. self.ValueOn .. ") = " .. value )
end

local function On( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputActivate( mul )
end

local function Off( pl, ent, mul )
	if (!ent:IsValid()) then return false end
	return ent:InputDeactivate( mul )
end

numpad.Register( "WireDualInput_On", On )
numpad.Register( "WireDualInput_Off", Off )
