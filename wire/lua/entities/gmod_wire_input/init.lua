
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Input"
ENT.OverlayDelay = 0

local keylist = {"0","1","2","3","4","5","6","7","8","9",".","Enter","+","-","*","/"}

local MODEL = Model("models/jaanus/wiretool/wiretool_input.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )

	// Used to keep track of numpad.OnUp/Down returns
	// Fixes bug where player cannot change numpad key (TheApathetic)
	self.OnUpImpulse = nil
	self.OnDownImpulse = nil

	self.Outputs = Wire_CreateOutputs(self.Entity, { "Out" })
end

function ENT:Setup(keygroup, toggle, value_off, value_on)
	self.keygroup = keygroup
	self.Toggle = (toggle == 1)
	self.toggle = toggle
	self.value_off = value_off
	self.value_on = value_on
	self.Value = value_off

	if (self.OnUpImpulse) then
		numpad.Remove(self.OnUpImpulse)
		numpad.Remove(self.OnDownImpulse)
	end

	local pl = self:GetPlayer()
	self.OnDownImpulse = numpad.OnDown( pl, keygroup, "WireInput_On", self.Entity, 1 )
	self.OnUpImpulse = numpad.OnUp( pl, keygroup, "WireInput_Off", self.Entity, 1 )


	self:ShowOutput(self.value_off)
	Wire_TriggerOutput(self.Entity, "Out", self.value_off)
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
		self:ShowOutput(self.value_on)
		self.Value = self.value_on
	else
		self:ShowOutput(self.value_off)
		self.Value = self.value_off
	end

	Wire_TriggerOutput(self.Entity, "Out", self.Value)

	return true
end

function ENT:ShowOutput(value)
	self:SetOverlayText( "Numpad Input ("..keylist[self.keygroup + 1]..")\n(" .. self.value_off .. " - " .. self.value_on .. ") = " .. value )
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
