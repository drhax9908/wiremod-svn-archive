
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
	
	self.Buffer = {}
	for i = 0,31 do
		self.Buffer[i] = 0
	end
end


function ENT:ReadCell( Address )
	if (Address >= 0) && (Address < 32) then
		return self.Buffer[Address]
	else
		return nil
	end

//	if (Address >= 48) && (Address <= 57) then
//		if (self.On[Address-47]) then
//			return self.ValueOn
//		else
//			return self.ValueOff
//		end
//	elseif (Address == 46) then
//		if (self.On[11]) then return self.ValueOn else return self.ValueOff end		
//	elseif (Address == 13) then
//		if (self.On[12]) then return self.ValueOn else return self.ValueOff end		
//	elseif (Address == 43) then
//		if (self.On[13]) then return self.ValueOn else return self.ValueOff end		
//	elseif (Address == 45) then
//		if (self.On[14]) then return self.ValueOn else return self.ValueOff end		
//	elseif (Address == 42) then
//		if (self.On[15]) then return self.ValueOn else return self.ValueOff end		
//	elseif (Address == 47) then
//		if (self.On[16]) then return self.ValueOn else return self.ValueOff end		
//	else
//		if (Address >= 0) && (Address <= 255) then
//			return 0
//		else
//			return nil
//		end
//	end
end

function ENT:WriteCell( Address, value )
	if (Address >= 0) && (Address < 32) then
		return true
	else
		return false
	end
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

	self.Buffer[0] = 0

	for i = 1,10 do
		if (self.On[ i ]) then
			self.Buffer[0] = self.Buffer[0] + 1
			self.Buffer[self.Buffer[0]] = i + 47
		end
	end
	if (self.On[ 11 ]) then
		self.Buffer[0] = self.Buffer[0] + 1
		self.Buffer[self.Buffer[0]] = 46
	end
	if (self.On[ 12 ]) then
		self.Buffer[0] = self.Buffer[0] + 1
		self.Buffer[self.Buffer[0]] = 13
	end
	if (self.On[ 13 ]) then
		self.Buffer[0] = self.Buffer[0] + 1
		self.Buffer[self.Buffer[0]] = 43
	end
	if (self.On[ 14 ]) then
		self.Buffer[0] = self.Buffer[0] + 1
		self.Buffer[self.Buffer[0]] = 45
	end
	if (self.On[ 15 ]) then
		self.Buffer[0] = self.Buffer[0] + 1
		self.Buffer[self.Buffer[0]] = 42
	end
	if (self.On[ 16 ]) then
		self.Buffer[0] = self.Buffer[0] + 1
		self.Buffer[self.Buffer[0]] = 47
	end

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
