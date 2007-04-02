
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include('shared.lua')

ENT.WireDebugName = "Numpad"
ENT.OverlayDelay = 0

local MODEL = Model("models/jaanus/wiretool/wiretool_input.mdl")

function ENT:Initialize()
	self.Entity:SetModel( MODEL )
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	self.On = {}
	self.keys = {"0","1","2","3","4","5","6","7","8","9",".","enter","+","-","*","/"}
	self.Outputs = Wire_CreateOutputs(self.Entity, self.keys)
end

function ENT:Setup( toggle, value_off, value_on)
	self.Toggle = (toggle == 1)
	self.ValueOff = value_off
	self.ValueOn = value_on
	
	self:ShowOutput()
end

function ENT:NumpadActivate( key )
	if ( self.Toggle ) then
		return self:Switch( !self.On[ key ], key )
	end

	return self:Switch( true, key )
end

function ENT:NumpadDeactivate( key )
	if ( self.Toggle ) then return true end
	
	return self:Switch( false, key )
end

function ENT:Switch( on, key )
	if (!self.Entity:IsValid()) then return false end

	self.On[ key ] = on

	if (on) then
		self:ShowOutput()
		self.Value = self.ValueOn
	else
		self:ShowOutput()
		self.Value = self.ValueOff
	end

	Wire_TriggerOutput(self.Entity, self.keys[key], self.Value)

	return true
end

function ENT:ShowOutput()
	txt = "Numpad"
	for k = 1, 17 do
		if (self.On[k]) then
			txt = txt..", "..self.keys[k]
		end
	end
	
	self:SetOverlayText( txt )
end

local function On( pl, ent, key )
	if (!ent:IsValid()) then return false end
	return ent:NumpadActivate( key )
end

local function Off( pl, ent, key )
	if (!ent:IsValid()) then return false end
	return ent:NumpadDeactivate( key )
end

numpad.Register( "WireNumpad_On", On )
numpad.Register( "WireNumpad_Off", Off )
